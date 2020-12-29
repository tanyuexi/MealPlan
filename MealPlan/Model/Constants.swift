//
//  Constants.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/10/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

struct K {
    static let debugMode = true
    static let adUnitIDTest = "ca-app-pub-3940256099942544/2934735716"
    static let adUnitIDPlan = "ca-app-pub-1617129166971753/7193269207"
    
    static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
    static let collectionCellID = "CollectionCell"
    
    static let foodGroup = ["Vegetable", "Fruit", "Protein", "Grain", "Calcium", "Oil", "Other"]
    static let meals = [
        "1 breakfast": NSLocalizedString("🥣Breakfast", comment: "meals"),
        "2 morningTea": NSLocalizedString("☕️Morning Tea", comment: "meals"),
        "3 lunch": NSLocalizedString("🥪Lunch", comment: "meals"),
        "4 afternoonTea": NSLocalizedString("🍺Afternoon Tea", comment: "meals"),
        "5 dinner": NSLocalizedString("🍽Dinner", comment: "meals")
    ]
    
    static let tagColor = UIColor.systemYellow
    
    static let fieldSeparator = "\t"
    static let propertyFieldSeparator = "##"
    static let propertyRecordSeparator = "^^"
    
    static let operationAdd = "add"
    static let operationUpdate = "update"
    static let operationDelete = "delete"
}
