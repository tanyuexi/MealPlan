//
//  MenuVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/29.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class MenuVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    var dishDict: [Int:[PlannedDish]] = [:]
    var editMode = false
    
    var personArray: [Person] = []
    var dailyTotal: [String:Double] = [:]
    var serveSum: [String:Double] = [:]
    
    let warningColor = UIColor.systemRed
    
    @IBOutlet weak var calculatorCollectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(getFilePath(directory: true)!)
        
        S.data.dateFormatter.dateFormat = NSLocalizedString("dd/MM/yyyy", comment: "date format")
        S.data.weekdayFormatter.dateFormat = NSLocalizedString("EEE d MMM", comment: "date format")
                
        initDatabase()
        
        var foodArray: [Food] = []
        loadFood(to: &foodArray)
        if foodArray.count == 0 {
            importDemoDatabase()
        }
        foodArray = []
        
        loadPerson(to: &personArray)
        
        calculateDailyTotalServes(from: personArray, to: &dailyTotal)

        tableView.register(UINib(nibName: "DishCell", bundle: nil), forCellReuseIdentifier: "DishCell")
        
        calculatorCollectionView.delegate = self
        calculatorCollectionView.dataSource = self
        calculatorCollectionView.register(UINib(nibName: "CalculatorCell", bundle: nil), forCellWithReuseIdentifier: "CalculatorCell")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for day in 0..<Int(S.data.days) {
            var dishes: [PlannedDish] = []
            loadPlannedDish(to: &dishes, predicate: NSPredicate(format: "day == %d", day))
            dishDict[day] = dishes
        }
        
        serveSum = [:]
//        for i in 0..<6 {
//            let foodGroup = S.data.foodGroupArray[i]
            for dish in dishDict.values.joined() {
                let multiplier = dish.portion / dish.recipe!.portion
                var ingredients = (dish.recipe?.ingredients?.allObjects as! [Ingredient]).filter({$0.alternative == nil})
                ingredients += dish.alternativeIngredients?.allObjects as! [Ingredient]
                for ingredient in ingredients {
                    for serveSize in (ingredient.food!.serveSizes?.allObjects as! [ServeSize]).filter({$0.unit == ingredient.unit}) {
                        
                        if serveSum[serveSize.foodGroup!.title!] == nil {
                            serveSum[serveSize.foodGroup!.title!] = 0
                        }
                        serveSum[serveSize.foodGroup!.title!]! += ingredient.quantity * multiplier / serveSize.quantity
                    }
                    
                }
            }
//        }
        
        tableView.reloadData()
    }
    
    
    //MARK: - IBAction
    
    @IBAction func modeButtonPressed(_ sender: UIBarButtonItem) {
        editMode = !editMode
        sender.image = editMode ? UIImage(systemName: "eye") : UIImage(systemName: "square.and.pencil")
        tableView.reloadData()
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "GoToSettings", sender: nil)

    }
    
    
    //MARK: - Custom functions
    
    
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Int(S.data.days) + 1 //add dish cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return editMode ? 1 : 0
        default:
            let day = section - 1
            return dishDict[day]?.count ?? 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
            
        case 0:
            return nil
            
        default:
            
            if let firstDate = S.data.firstDate {
                
                let dateString = S.data.weekdayFormatter.string(from: dateAfter(section - 1, from: firstDate))
                return String(format: NSLocalizedString("Day %d - %@", comment: "picker format"), section, dateString)
                
            } else {
                return String(format: NSLocalizedString("Day %d", comment: "picker format"), section)
            }
            
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddDishCell", for: indexPath)
            return cell
            
        default:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "DishCell", for: indexPath) as! DishCell
            
            let day = indexPath.section - 1
            if dishDict[day] != nil {
                let dish = dishDict[day]![indexPath.row]
                cell.mealLabel.text = K.mealIcon[Int(dish.meal!.order)]
                cell.recipeLabel.text = dish.recipe?.title
                cell.ingredientLabel.text = (dish.alternativeIngredients?.allObjects as! [Ingredient]).map({$0.food!.title!}).sorted().joined(separator: "\n")
                cell.onStepperValueChangedUpdateCell(dish.portion)
                cell.onStepperValueChanged = { value in
                    dish.portion = value
                    self.saveContext()
                }
            }
            
            if editMode {
                cell.portionStepper.isHidden = false
            } else {
                cell.portionStepper.isHidden = true
            }
            
            return cell
        }
        
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if editMode {
            performSegue(withIdentifier: "GoToEditDish", sender: nil)
        } else {
            performSegue(withIdentifier: "GoToViewRecipe", sender: nil)
        }
    }
    
    
    
    //    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    //
    //        return UITableView.automaticDimension
    //    }
    //
    //
    //    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    //
    //        return UITableView.automaticDimension
    //    }
    
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    //MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return S.data.foodGroupArray.count - 1 //except 'Other'
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = calculatorCollectionView.dequeueReusableCell(withReuseIdentifier: "CalculatorCell", for: indexPath) as! CalculatorCell
        
        let foodGroup = S.data.foodGroupArray[indexPath.row].title!
        let targetServes = dailyTotal[foodGroup]! * S.data.days
        let sum = serveSum[foodGroup] ?? 0
        
        cell.titleLabel.text = foodGroup
        
        cell.sumLabel.text = NSLocalizedString("Now: ", comment: "calculator") + limitDigits(sum)

        if foodGroup == NSLocalizedString("Oil", comment: "food group") {
            cell.targetLabel.text = NSLocalizedString("Less than: ", comment: "calculator") + limitDigits(targetServes)
            cell.sumLabel.textColor = (sum <= targetServes ? .label : warningColor)
        } else {
            cell.targetLabel.text = NSLocalizedString("Target: ", comment: "calculator") + limitDigits(targetServes)
            cell.sumLabel.textColor = (sum >= targetServes ? .label : warningColor)
        }
        
        
        return cell
    }
    
    
    //MARK: - UICollectionViewDelegate
    
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//        performSegue(withIdentifier: "GoToEditIngredient", sender: nil)
//        ingredientCollectionView.deselectItem(at: indexPath, animated: true)
//    }
    
    
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "GoToEditDish",
            let indexPath = tableView.indexPathForSelectedRow,
            indexPath.section > 0 {
            
            let vc = segue.destination as! EditDishTVC
            vc.selectedDish = dishDict[indexPath.section - 1]?[indexPath.row]
            
        } else if segue.identifier == "GoToViewRecipe",
            let indexPath = tableView.indexPathForSelectedRow {
            
            let vc = segue.destination as! ViewRecipeTVC
            vc.selectedDish = dishDict[indexPath.section - 1]?[indexPath.row]
        }
    }
    
    
}



