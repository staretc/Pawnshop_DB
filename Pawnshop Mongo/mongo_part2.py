import json
from pymongo import MongoClient
from bson import json_util
from datetime import datetime

def import_data(collection):
    file_path = r'C:/Users/89201/Downloads/weather.json'

    collection.drop()  # Очищаем перед импортом

    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
        collection.insert_many(data)
    print(f"Данные успешно импортированы. Записей: {collection.count_documents({})}")
    
# 1. Разница между максимальной и минимальной температурой за год
def query_1(collection):
    pipeline = [
        {"$group": {
            "_id": "$year",
            "max_temp": {"$max": "$temperature"},
            "min_temp": {"$min": "$temperature"}
        }},
        {"$project": {
            "year": "$_id",
            "_id": 0,
            "max_temp": 1,
            "min_temp": 1,
            "diff": {"$subtract": ["$max_temp", "$min_temp"]}
        }}
    ]
    result = list(collection.aggregate(pipeline))
    print("\nРазница минимальной и максимальной температуры:")
    for r in result:
        print(f"Год {r['year']}: max={r['max_temp']}, min={r['min_temp']}, разница={r['diff']}")

# 2. Средняя температура без 10 самых холодных и 10 самых жарких дней
def query_2(collection):
    pipeline = [
        # Группируем по дням (вычисляем среднее за сутки)
        {"$group": {
            "_id": {"y": "$year", "m": "$month", "d": "$day"},
            "daily_avg": {"$avg": "$temperature"}
            }},
        {"$sort": {
            "daily_avg": 1
            }},
        # Пропускаем 10 дней с самой низкой температурой
        {"$skip": 10},
        # Сортируем в обратном порядке, чтобы убрать 10 самых теплых
        {"$sort": {
            "daily_avg": -1
            }},
        {"$skip": 10},
        # Считаем финальное среднее
        {"$group": {
            "_id": None, "final_avg": {"$avg": "$daily_avg"}
            }}
    ]
    result = list(collection.aggregate(pipeline))
    print(f"\nСредняя температура без 10 самых холодных и 10 самых жарких дней: {result[0]['final_avg']:.2f}")


# 3. Первые 10 записей с самой низкой температурой при южном ветре
def query_3(collection):
    pipeline = [
        {"$match": {"wind_direction": "Южный"}},
        {"$sort": {"temperature": 1}},
        {"$limit": 10},
        {"$group": {
            "_id": None,
            "avg_temp": {"$avg": "$temperature"},
            "records": {"$push": "$$ROOT"}
        }}
    ]
    result = list(collection.aggregate(pipeline))
    if result:
        print(f"\nСредняя температура 10 самых холодных записей с южным ветром: {result[0]['avg_temp']:.2f}")
        print("Записи:")
        for rec in result[0]["records"]:
            print(f"{rec['year']}-{rec['month']}-{rec['day']} {rec['hour']}:00 | "
                  f"Темп: {rec['temperature']}°C | Ветер: {rec['wind_direction']} {rec['wind']}")
    else:
        print("\nЗаписи с южным ветром не найдены.")

# 4. Количество дней, когда шел снег (t < 0 и код осадков — снег)
def query_4(collection):
    pipeline = [
        {"$match": {
            "temperature": {"$lt": 0},
            "code": {"$in": SNOW_CODES}
        }},
        {"$group": {
            "_id": {"year": "$year", "month": "$month", "day": "$day"}
        }},
        {"$count": "snow_days"}
    ]
    result = list(collection.aggregate(pipeline))
    count = result[0]["snow_days"] if result else 0
    print(f"\nКоличество дней со снегом: {count}")

# 5. Сравнение количества осадков в виде снега и дождя зимой (месяцы 12, 1, 2)
def query_5(collection):
    pipeline = [
        {"$match": {"month": {"$in": [12, 1, 2]}}},
        {"$project": {
            "precip_type": {
                "$switch": {
                    "branches": [
                        {"case": {"$and": [
                            {"$lt": ["$temperature", 0]},
                            {"$in": ["$code", SNOW_CODES]}
                        ]}, "then": "snow"},
                        {"case": {"$and": [
                            {"$gte": ["$temperature", 0]},
                            {"$in": ["$code", RAIN_CODES]}
                        ]}, "then": "rain"
                        }
                    ], "default": "other"
                }
            }
        }},
        {"$match": {"precip_type": {"$in": ["snow", "rain"]}}},
        {"$group": {
            "_id": "$precip_type",
            "count": {"$sum": 1}
        }}
    ]
    result = {r["_id"]: r["count"] for r in collection.aggregate(pipeline)}
    snow = result.get("snow", 0)
    rain = result.get("rain", 0)
    diff = snow - rain
    
    print(f"\nЗимние осадки: снег = {snow} записей, дождь = {rain} записей.")
    if diff > 0:
        print(f"   Снега больше на {diff} записей.")
    elif diff < 0:
        print(f"   Дождя больше на {abs(diff)} записей.")
    else:
        print("   Количество записей одинаковое.")
    
    # Если в файле есть поле количества осадков (например, 'precipitation'),
    # замени "$sum": 1 на "$sum": "$precipitation" в группировке выше.

# 6. Увеличить температуру на 1°C в нечетный день зимой. На сколько изменилась средняя?
def query_6(collection):
    # Сохраняем старую среднюю
    old_avg = list(collection.aggregate([
        {"$group": {"_id": None, "avg": {"$avg": "$temperature"}}}
    ]))[0]["avg"]
    
    # Обновляем: зима (12, 1, 2) и нечетный день (day % 2 == 1)
    result = collection.update_many(
        {
            "month": {"$in": [12, 1, 2]},
            "day": {"$mod": [2, 1]}  # нечетные дни
        },
        {"$inc": {"temperature": 1}}
    )
    
    # Новая средняя
    new_avg = list(collection.aggregate([
        {"$group": {"_id": None, "avg": {"$avg": "$temperature"}}}
    ]))[0]["avg"]
    
    diff = new_avg - old_avg
    
    print(f"\nОбновлено документов: {result.modified_count}")
    print(f"Старая средняя температура: {old_avg:.4f}")
    print(f"Новая средняя температура:  {new_avg:.4f}")
    print(f"Изменение средней температуры: {diff:.4f}")
    
# 7. Для каждого сезона (зима, весна, лето, осень) посчитать количество ясных дней (код CL)
def query_7(collection):
    pipeline = [
        # Выбираем записи с ясной погодой
        {"$match": {"code": "CL"}},
        
        # Группируем по дате
        {"$group": {
            "_id": {
                "year": "$year",
                "month": "$month",
                "day": "$day"
            }
        }},
        
        # Определяем сезон на основе месяца
        {"$project": {
            "season": {
                "$switch": {
                    "branches": [
                        {"case": {"$in": ["$_id.month", [12, 1, 2]]}, "then": "Winter"},
                        {"case": {"$in": ["$_id.month", [3, 4, 5]]}, "then": "Spring"},
                        {"case": {"$in": ["$_id.month", [6, 7, 8]]}, "then": "Summer"},
                        {"case": {"$in": ["$_id.month", [9, 10, 11]]}, "then": "Autumn"}
                    ],
                    "default": "Unknown"
                }
            }
        }},
        
        # Считаем количество уникальных дней для каждого сезона
        {"$group": {
            "_id": "$season",
            "count": {"$sum": 1}
        }}
    ]
    
    results = list(collection.aggregate(pipeline))
    res_dict = {r["_id"]: r["count"] for r in results}
    
    print("Количество ясных дней в каждом сезоне:")
    for season in ["Winter", "Spring", "Summer", "Autumn"]:
        print(f"{season:6} -> {res_dict.get(season, 0)}")        

# Запуски

# уникальные коды погоды
# unique_codes = collection.distinct("code")
# print(f"Уникальные коды: {unique_codes}")

SNOW_CODES = ["SN", "SNRA", "HL", "SHSN"]
RAIN_CODES = ["RA", "DZ", "SHRA", "SNRA"]

# Подключение к MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['weather_db']
collection = db['weather']

#import_data(collection)

#query_1(collection)
#query_2(collection)
#query_3(collection)
#query_4(collection)
#query_5(collection)
#query_6(collection)
query_7(collection)