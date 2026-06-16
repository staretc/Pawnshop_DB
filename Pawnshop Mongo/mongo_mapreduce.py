from pymongo import MongoClient
from bson.code import Code
from datetime import date, datetime

# Список товаров, принятых в залог (дата, вид товара, количество)
def query_1(collection):
    # В map-функции группируем составной ключ из даты и вида товара
    map_func_1 = Code("""
    function() {
        emit({ date: this.date, type: this.item.type }, 1);
    }
    """)

    # В reduce-функции суммируем единички для одинаковых ключей
    reduce_func_1 = Code("""
    function(key, values) {
        return Array.sum(values);
    }
    """)

    # Выполняем команду
    response_1 = db.command(
        "mapReduce", "contracts",
        map=map_func_1,
        reduce=reduce_func_1,
        out={"inline": 1}
    )

    print("Список принятых товаров (дата, вид, количество):")
    for doc in response_1['results']:
        date = doc['_id']['date']
        item_type = doc['_id']['type']
        count = int(doc['value'])
        print(f"Дата: {date} | Вид товара: {item_type} | Количество: {count}")

    print("\n" + "="*50 + "\n")

# Выручка от комиссионных за 2025 год для каждого вида товара
def query_2(collection):
    # Даты границ выборки
    start_date = datetime(2025, 1, 1)
    end_date = datetime(2025, 12, 31, 23, 59, 59)
    
    # В map-функции ключом будет вид товара, а значением — сумма комиссии
    map_func_2 = Code("""
    function() {
        emit(this.item.type, this.comission);
    }
    """)

    # В reduce-функции суммируем комиссии
    reduce_func_2 = Code("""
    function(key, values) {
        return Array.sum(values);
    }
    """)

    response_2 = db.command(
        "mapReduce", "contracts",
        map=map_func_2,
        reduce=reduce_func_2,
        query={"date": {"$gte": start_date, "$lte": end_date}},
        out={"inline": 1}
    )

    print("Выручка от комиссионных:")
    for doc in response_2['results']:
        item_type = doc['_id']
        revenue = doc['value']
        print(f"Вид товара: {item_type} | Выручка: {revenue} руб.")

# Подключение к mongo
mongo_client = MongoClient("mongodb://localhost:27017/")
db = mongo_client["Pawnshop_Mongo"]
collection = db["contracts"]

#query_1(collection)
query_2(collection)