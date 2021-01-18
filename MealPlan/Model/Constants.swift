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
        "1 breakfast": NSLocalizedString("Breakfast", comment: "meals"),
        "2 morningTea": NSLocalizedString("Morning Tea", comment: "meals"),
        "3 lunch": NSLocalizedString("Lunch", comment: "meals"),
        "4 afternoonTea": NSLocalizedString("Afternoon Tea", comment: "meals"),
        "5 dinner": NSLocalizedString("Dinner", comment: "meals")
    ]
    static let seasonIcon = ["🌱","☀️","🍁","❄️"]
    static let seasonUnavailableIcon = "✖️"
    
    static let tagColor = UIColor.systemYellow
    
    static let level1Separator = "\t"
    static let level2Separator = "@;"
    static let level3Separator = "#_"
    static let level4Separator = "$|"
    
    static let operationAdd = "add"
    static let operationUpdate = "update"
    static let operationDelete = "delete"
    
    static let lineBreakReplaceString = "<br>"
    static let cellBackgroundColors = [ #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 0.5), #colorLiteral(red: 1, green: 0.5763723254, blue: 0, alpha: 0.5), #colorLiteral(red: 0.6679978967, green: 0.4751212597, blue: 0.2586010993, alpha: 0.5), #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 0.5), #colorLiteral(red: 1, green: 0.2527923882, blue: 1, alpha: 0.5), #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 0.5), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3), #colorLiteral(red: 0, green: 0.9914394021, blue: 1, alpha: 0.5), #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 0.5), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6) ]
}
