[
  // Разворачиваем массив заказов
  { $unwind: "$TaxiOrders" },
  
  // Группируем по городу и месяцу
  {
    $group: {
      _id: {
        city: "$TaxiOrders.City",
        month: { $substr: ["$TaxiOrders.Date", 5, 2] } // Извлекаем месяц из строки "2024-01-22"
      },
      orderCount: { $sum: 1 },
      totalRevenue: { $sum: "$TaxiOrders.Price" }
    }
  },
  
  // Форматируем вывод
  {
    $project: {
      _id: 0,
      city: "$_id.city",
      month: "$_id.month",
      orderCount: 1,
      totalRevenue: 1
    }
  },
  
  // Сортируем по количеству заказов
  { $sort: { orderCount: -1, totalRevenue: -1 } }
]