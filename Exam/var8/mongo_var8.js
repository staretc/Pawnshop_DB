
[
  // Разворачиваем массив гейтов
  {
    $unwind: "$AirportExport"
  },
  // Разворачиваем самолёты на каждом гейте
  {
    $unwind: "$AirportExport.AssignedAircrafts"
  },
  // Разворачиваем историю обслуживания
  {
    $unwind:
      "$AirportExport.AssignedAircrafts.MaintenanceHistory"
  },
  // Фильтруем по ServiceRate > 1.20
  {
    $match: {
      "AirportExport.AssignedAircrafts.MaintenanceHistory.ServiceRate":
        {
          $gt: 1.2
        }
    }
  },
  // Группируем по самолёту
  {
    $group: {
      _id: "$AirportExport.AssignedAircrafts.TailNumber",
      TailNumber: {
        $first:
          "$AirportExport.AssignedAircrafts.TailNumber"
      },
      TotalBaggage: {
        $sum: "$AirportExport.AssignedAircrafts.MaintenanceHistory.BaggageKG"
      },
      TotalCost: {
        $sum: {
          $multiply: [
            "$AirportExport.AssignedAircrafts.MaintenanceHistory.BaggageKG",
            "$AirportExport.AssignedAircrafts.MaintenanceHistory.ServiceRate"
          ]
        }
      }
    }
  },
  // Проецируем результат
  {
    $project: {
      _id: 0,
      TailNumber: 1,
      TotalBaggage: 1,
      TotalCost: {
        $round: ["$TotalCost", 2]
      }
    }
  },
  // Сортируем по убыванию TotalCost
  {
    $sort: {
      TotalCost: -1
    }
  }
]