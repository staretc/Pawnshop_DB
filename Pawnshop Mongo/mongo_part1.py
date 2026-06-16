import json
from pymongo import MongoClient
from bson import json_util
from datetime import datetime

def import_data(collection):
    file_path = r'C:/Users/89201/Downloads/restaurants.json'

    collection.drop()  # Очищаем перед импортом

    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.strip():
                doc = json_util.loads(line)
                collection.insert_one(doc)

    print(f"Импортировано: {collection.count_documents({})} документов")

# 1. Все документы в формате: restaurant_id, name, borough и cuisine, вывод _id  для всех документов исключить.
def query_1(collection):
    result = collection.find(
        {},  # все документы
        {'_id': 0,
         'restaurant_id': 1,
         'name': 1,
         'borough': 1,
         'cuisine': 1}
    )

    print("Запрос 1 - Все рестораны:")
    for doc in result:  # покажем первые 5 для примера
        print(doc)
        
# 2. Первые 5 ресторанов в алфавитном порядке из района Bronx
def query_2(collection):
    result = collection.find(
        {'borough': 'Bronx'}
    ).sort('name', 1).limit(5)

    for doc in result:
        print(f"{doc.get('name')} - {doc.get('cuisine')}")

# 3. Рестораны с оценкой более 80, но менее 100 баллов
def query_3(collection):
    results = collection.find(
        {"grades.score": {"$gt": 80, "$lt": 100}},
        {"_id": 0, "name": 1, "grades": 1}
    )
    
    for doc in results:
        print(f"Name: {doc.get('name')}")
        for grade in doc.get('grades', []):
            if 80 < grade.get('score', 0) < 100:
                print(f"  Score: {grade.get('score')}, Grade: {grade.get('grade')}")
        print(f"\n")
    
# 4. Не American кухня, оценка A, не Brooklyn, сортировка по кухне убыванию
def query_4(collection):
    print("\n=== ЗАПРОС 4: Не American, оценка A, не Brooklyn ===")
    results = collection.find(
        {
            "cuisine": {"$ne": "American"},
            "grades.grade": "A",
            "borough": {"$ne": "Brooklyn"}
        },
        {"_id": 0, "restaurant_id": 1, "name": 1, "borough": 1, "cuisine": 1, "grades": 1}
    ).sort("cuisine", -1).limit(10)
    
    for doc in results:
        print(f"Name: {doc.get('name')}")
        print(f"Cuisine: {doc.get('cuisine')}")
        print(f"Grade: {doc.get('grades.grade')}")
        print(f"Borough: {doc.get('borough')}\n")
        
# 5. Рестораны, название которых начинается на "Wil"
def query_5(collection):
    result = collection.find(
        {'name': {'$regex': '^Wil'}},
        {'_id': 0, 'name': 1, 'borough': 1, 'cuisine': 1}
    )

    for doc in result:
        print(f"Name: {doc.get('name')}, "
            f"Borough: {doc.get('borough')}, Cuisine: {doc.get('cuisine')}")
        
# 6. Район Bronx и кухня American или Chinese
def query_6(collection):
    result = collection.find(
        {
            'borough': 'Bronx',
            'cuisine': {'$in': ['American ', 'Chinese']}
        },
        {'_id': 0, 'name': 1, 'cuisine': 1, 'borough': 1}
    )

    for doc in result:
        print(f"{doc.get('name')} - {doc.get('cuisine')}")
            
# 7. Рестораны с оценкой A, 9 баллов, дата 2014-08-11
def query_7(collection):
    from datetime import datetime

    target_date = datetime(2014, 8, 11)

    result = collection.find(
        {
            'grades': {
                '$elemMatch': {
                    'date': target_date,
                    'grade': 'A',
                    'score': 9
                }
            }
        },
        {'_id': 0, 'restaurant_id': 1, 'name': 1, 'grades': 1}
    )

    for doc in result:
        print(f"ID: {doc.get('restaurant_id')}, Name: {doc.get('name')}")
        for grade in doc.get('grades', []):
            if grade.get('date') == target_date:
                print(f"  Grade: {grade}")
            
# 8. Агрегация: количество ресторанов по району и кухне
def query_8(collection):
    pipeline = [
        {
            '$group': {
                '_id': {
                    'borough': '$borough',
                    'cuisine': '$cuisine'
                },
                'count': {'$sum': 1}
            }
        },
        {
            '$project': {
                '_id': 0,
                'borough': '$_id.borough',
                'cuisine': '$_id.cuisine',
                'count': 1
            }
        },
        {'$sort': {'borough': 1, 'cuisine': 1}}
    ]

    result = collection.aggregate(pipeline)

    for doc in list(result):
        print(f"{doc.get('borough')} | {doc.get('cuisine')} | {doc.get('count')}")
    
# 9. Ресторан с минимальной суммой баллов в районе Bronx
def query_9(collection):
    pipeline = [
        # Оставляем только рестораны из Bronx
        {"$match": {"borough": "Bronx"}},
        
        # Разворачиваем массив оценок
        {"$unwind": "$grades"},
        
        # Считаем сумму баллов для каждого ресторана 
        {"$group": {
            "_id": "$_id",
            "name": {"$first": "$name"},
            "borough": {"$first": "$borough"},
            "cuisine": {"$first": "$cuisine"},
            "total_score": {"$sum": "$grades.score"}
        }},
        
        # Сортируем по сумме баллов 
        {"$sort": {"total_score": 1}},
        
        # Группируем ВСЕ рестораны по сумме баллов
        # в _id сумма баллов, в restaurants — массив ресторанов
        {"$group": {
            "_id": "$total_score",           # группируем по сумме баллов
            "restaurants": {"$push": {        # собираем все рестораны с этой суммой
                "id": "$_id",
                "name": "$name",
                "cuisine": "$cuisine",
                "total_score": "$total_score"
            }},
            "count": {"$sum": 1}              # сколько ресторанов в этой группе
        }},
        
        # Берем группу с минимальной суммой
        {"$sort": {"_id": 1}},               # сортируем по сумме баллов
        {"$limit": 1}                         # берем только группу с минимумом
    ]

    result = list(collection.aggregate(pipeline))

    # Вывод результатов
    min_score = result[0]["_id"]
    restaurants = result[0]["restaurants"]

    print(f"Минимальная сумма баллов в Bronx: {min_score}, найдено {len(restaurants)} ресторанов:")
    for r in restaurants:
        print(f"- {r['name']} ({r['cuisine']}): {r['total_score']} баллов") 
    
# 10. Добавление своего любимого ресторана
def query_10(collection):
    my_restaurant = {
        "address": {
            "building": "123",
            "coord": [37.6173, 55.7558],  # Москва
            "street": "Тверская улица",
            "zipcode": "125009"
        },
        "borough": "Москва",
        "cuisine": "Русская",
        "grades": [
            {"date": datetime(2024, 1, 15), "grade": "A", "score": 10}
        ],
        "name": "Мой Любимый Ресторан",
        "restaurant_id": "99999999"
    }

    insert_result = collection.insert_one(my_restaurant)
    print(f"\nЗапрос 10 - Добавлен ресторан, ID: {insert_result.inserted_id}")
    
    # Проверим
    
    
# 11. Добавление информации о времени работы
def query_11(collection):
    collection.update_one(
        {'restaurant_id': '99999999'},
        {
            '$set': {
                'hours': {
                    'monday': '09:00-22:00',
                    'tuesday': '09:00-22:00',
                    'wednesday': '09:00-22:00',
                    'thursday': '09:00-23:00',
                    'friday': '09:00-24:00',
                    'saturday': '10:00-24:00',
                    'sunday': '10:00-21:00'
                }
            }
        }
    )

    # Проверим
    doc = collection.find_one({'restaurant_id': '99999999'}, {'_id': 0, 'name': 1, 'hours': 1})
    print(f"Ресторан: {doc.get('name')}")
    print(f"Часы работы: {doc.get('hours')}")
    
# 12. Изменение времени работы
def query_12(collection):
    collection.update_one(
        {'restaurant_id': '99999999'},
        {'$set': {'hours.friday': '10:00-24:00'}}
    )
    
    collection.update_one(
        {'restaurant_id': '99999999'},
        {'$unset': {'hours.wednesday': ''}}
    )

    # Проверим изменения
    doc = collection.find_one({'restaurant_id': '99999999'}, {'_id': 0, 'name': 1, 'hours': 1})
    print(f"Ресторан: {doc.get('name')}")
    print(f"Обновленные часы работы: {doc.get('hours')}")
    
# 13. Для каждого вида кухни, посчитать, в скольких районах, она представлена 
def query_13(collection):
    pipeline = [
        # Группировка по кухне и району
        {
            "$group": {
                "_id": {
                    "cuisine": "$cuisine",
                    "borough": "$borough"
                }
            }
        },
        
        # Группировка только по кухне и считаем районы
        {
            "$group": {
                "_id": "$_id.cuisine",
                "boroughs_count": {"$sum": 1}
            }
        },
        
        # Форматируем вывод
        {
            "$project": {
                "_id": 0,
                "cuisine": "$_id",
                "boroughs_count": 1
            }
        },
        
        # Сортируем
        {
            "$sort": {"boroughs_count": -1, "cuisine": 1}
        }
    ]
    
    result = collection.aggregate(pipeline)

    for doc in list(result):
        print(f"{doc.get('cuisine')} | {doc.get('boroughs_count')}")

# Запуски

# Подключение к MongoDB
client = MongoClient('mongodb://localhost:27017/')
db = client['restaurants_db']
collection = db['restaurants']

#import_data(collection)

#query_1(collection)
#query_2(collection)
#query_3(collection)
#query_4(collection)
#query_5(collection)
#query_6(collection)
#query_7(collection)
#query_8(collection)
#query_9(collection)
#query_10(collection)
#query_11(collection)
#query_12(collection)
query_13(collection)
