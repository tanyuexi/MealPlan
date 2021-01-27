//
//  Singleton.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/12/7.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import CoreData

class S {
    static let data = S()
    var mealArray: [Meal] = []
    var seasonArray: [Season] = []
    var foodGroupArray: [FoodGroup] = []
    var northHemisphere: Bool = true
    var days: Double = 0
    var firstDate: Date?
    let dateFormatter = DateFormatter()
    let weekdayFormatter = DateFormatter()
}
