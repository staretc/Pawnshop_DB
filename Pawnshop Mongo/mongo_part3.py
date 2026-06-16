import pymssql
import pymongo
import json
from datetime import date, datetime
from decimal import Decimal

def json_serial(obj):
    """Помощник для превращения дат и денег в формат, понятный JSON"""
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serializable")

def importFromMS(collection):
    # Подключение к mssql
    sql_conn = pymssql.connect(
        server='staretc_laptop',
        user='sa', 
        password='12345', 
        database='Pawnshop_DB'
    )
    cursor = sql_conn.cursor(as_dict=True)

    # Запрос на вытаскивание данных из mssql
    query = """
    SELECT 
        c.Number as Contract_No, c.Date, c.Date_Of_Redemption, c.Comission, c.Redemption_Info, c.Sale_Info,
        cl.SNILS, cl.Fullname, cl.Address, cl.Passport_Series, cl.Passport_ID,
        i.ID as Item_ID, i.Wear,
        it.Name as Item_Type_Name,
        icm.Weight,
        m.Periodic_Table_Name, m.Cost_Per_Gramm
    FROM [Contract] c
    JOIN Client cl ON c.Client_SNILS = cl.SNILS
    JOIN Item i ON c.Item_ID = i.ID
    JOIN Item_Type it ON i.Type_ID = it.ID
    LEFT JOIN Item_Contains_Material icm ON i.ID = icm.Item_ID
    LEFT JOIN Material m ON icm.Material_Name = m.Periodic_Table_Name
    """

    cursor.execute(query)
    raw_rows = cursor.fetchall()

    # Группировка данных (из плоского списка в дерево)
    contracts_map = {}

    for row in raw_rows:
        contract_no = row['Contract_No']
        
        if contract_no not in contracts_map:
            # Создаем структуру документа
            contracts_map[contract_no] = {
                "contract_number": contract_no,
                "date": row['Date'],
                "redemption_date": row['Date_Of_Redemption'],
                "comission": row['Comission'],
                "status": {
                    "redemption": row['Redemption_Info'],
                    "sale": row['Sale_Info']
                },
                "client": {
                    "snils": row['SNILS'],
                    "fullname": row['Fullname'],
                    "address": row['Address'],
                    "passport": {
                        "series": row['Passport_Series'],
                        "id": row['Passport_ID']
                    }
                },
                "item": {
                    "item_id": row['Item_ID'],
                    "type": row['Item_Type_Name'],
                    "wear_percent": row['Wear'],
                    "materials": [] # Список материалов будет пополняться ниже
                }
            }
        
        # Если в строке есть данные о материале, добавляем его в массив внутри предмета
        if row['Periodic_Table_Name']:
            material_data = {
                "name": row['Periodic_Table_Name'],
                "weight": row['Weight'],
                "cost_per_gramm": row['Cost_Per_Gramm']
            }
            contracts_map[contract_no]["item"]["materials"].append(material_data)

    # Превращаем в список для вставки в Mongo
    mongo_docs = list(contracts_map.values())
    
    # Конвертируем типы для PyMongo
    for doc in mongo_docs:
        # Исправляем даты для BSON
        doc['date'] = datetime.combine(doc['date'], datetime.min.time())
        doc['redemption_date'] = datetime.combine(doc['redemption_date'], datetime.min.time())
        # Исправляем деньги (float)
        doc['comission'] = float(doc['comission'])
        for mat in doc['item']['materials']:
            mat['cost_per_gramm'] = float(mat['cost_per_gramm'])
    
    # 4. Сохранение в JSON
    with open('pawnshop_data.json', 'w', encoding='utf-8') as f:
        json.dump(mongo_docs, f, default=json_serial, ensure_ascii=False, indent=2)
    print("Файл pawnshop_data.json готов")
                
    collection.drop()  # Очищаем перед импортом

    # Загрузка в Mongo
    collection.insert_many(mongo_docs)
    print("Данные перенесены!")
        
    # Проверка
    result = collection.find(
        {},  # все документы
        {}
    )

    for doc in result: 
        print(doc)
        
# (a) Выдать список товаров, выставленных на продажу
def query_1(collection):
    query_a = collection.find(
        {"status.sale": "On sale"}, 
        {"item.item_id": 1, "item.type": 1, "_id": 0}
    )

    for doc in query_a:
        # Выводим как в SQL: ID и Название типа
        print(f"ID: {doc['item']['item_id']}, Type: {doc['item']['type']}")

# (b) Выдать список товаров, принятых в залог (дата, вид товара, количество)
def query_2(collection):
    pipeline_b = [
        {
            "$match": {
                "status.redemption": "Not redeemed",
                "status.sale": {"$ne": "Sold"}
            }
        },
        {
            "$group": {
                "_id": {
                    "Date": "$date",
                    "Type": "$item.type"
                },
                "Count": {"$sum": 1}
            }
        },
        {
            "$project": {
                "Date": "$_id.Date",
                "Type": "$_id.Type",
                "Count": 1, 
                "_id": 0
            }
        },
        {"$sort": {"Date": 1}}
    ]

    for res in collection.aggregate(pipeline_b):
        print(f"Date: {res['Date'].date()}, Type: {res['Type']}, Count: {res['Count']}")
    
# (c) Найти выручку ломбарда от комиссионных с начала текущего года для каждого вида товара
def query_3(collection):
    # Получаем список уникальных типов товаров, которые есть в коллекции
    all_item_types = collection.distinct("item.type")
    print(all_item_types)

    # Даты границ выборки
    start_date = datetime(2025, 1, 1)
    end_date = datetime(2025, 12, 31, 23, 59, 59)

    # Агрегация для подсчета выручки по тем, у кого она есть
    pipeline_c = [
        {
            "$match": {
                "date": {"$gte": start_date, "$lte": end_date}
            }
        },
        {
            "$group": {
                "_id": "$item.type",
                "Total_Comission": {"$sum": "$comission"}
            }
        }
    ]

    # Выполняем агрегацию и сохраняем в словарь
    aggregated_data = {res['_id']: res['Total_Comission'] for res in collection.aggregate(pipeline_c)}

    # 4. Формируем итоговый вывод, проходя по типам товаров
    for item_type in all_item_types:
        revenue = aggregated_data.get(item_type, 0.0)
        print(f"Type: {item_type:<20} | Total Comission: {revenue:>10.2f}")
    
# (d) Найти клиентов, которые не выкупили свой товар в срок
# Опорная дата: 25.09.2025
def query_4(collection):
    check_date = datetime(2025, 9, 25)

    query_d = collection.find(
        {
            "redemption_date": {"$gt": check_date},
            "status.redemption": "Not redeemed"
        },
        {"client.snils": 1, "_id": 0}
    )

    for doc in query_d:
        print(f"SNILS: {doc['client']['snils']}")
    
# (e) Найти клиентов, пользовавшихся услугами ломбарда 2 и более раз и всегда выкупавших все свои товары
def query_5(collection):
    pipeline_e = [
        {
            "$group": {
                "_id": "$client.snils",
                "count_all": {"$sum": 1},
                # Если Sale_Info не равно 'Not on sale', значит товар НЕ был выкуплен вовремя
                "count_bad": {
                    "$sum": {
                        "$cond": [{"$ne": ["$status.sale", "Not on sale"]}, 1, 0]
                    }
                }
            }
        },
        {
            "$match": {
                "count_all": {"$gte": 2},
                "count_bad": 0
            }
        },
        {
            "$project": {
                "SNILS": "$_id",
                "_id": 0
            }
        }
    ]

    for res in collection.aggregate(pipeline_e):
        print(f"SNILS: {res['SNILS']}")
    
# Подключение к mongo
mongo_client = pymongo.MongoClient("mongodb://localhost:27017/")
db = mongo_client["Pawnshop_Mongo"]
collection = db["contracts"]

#importFromMS(collection)

query_1(collection)
query_2(collection)
query_3(collection)
query_4(collection)
query_5(collection)