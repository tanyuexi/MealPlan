//
//  MealPlanVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/29.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class MealPlanVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var selectedPlan: Plan?
    
    var dishArray: [Dish] = []
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
        
        onPlanUpdated()
    }
    
    
    //MARK: - Custom functions

    func onPlanUpdated() {
        
        if selectedPlan == nil {
            var plans: [Plan] = []
            loadPlan(to: &plans, predicate: NSPredicate(format: "title == %@", NSLocalizedString("[Current Plan]", comment: "plan")))
            if plans.first == nil {
                let newPlan = Plan(context: K.context)
                newPlan.title = "[Current Plan]"
                selectedPlan = newPlan
            } else {
                selectedPlan = plans.first
            }
        }
        
        dishArray = (selectedPlan!.dishes?.allObjects as! [Dish]).sorted(by: {
            if $0.day == $1.day {
                if $0.meal!.order == $1.meal!.order {
                    return $0.recipe!.title! < $1.recipe!.title!
                } else {
                    return $0.meal!.order < $1.meal!.order
                }
            } else {
                return $0.day < $1.day
            }
        })
        onDishUpdated()
    }
    
    
    func onDishUpdated(){
        
        serveSum = [:]
        
        for dish in dishArray {
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
        
        tableView.reloadData()
        calculatorCollectionView.reloadData()
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
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: NSLocalizedString("Enter a name to save plan", comment: "alert"), message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: NSLocalizedString("Done", comment: "alert"), style: .default) { (action) in
            //what will happen once the user clicks the Add Item button on our UIAlert
            let newPlan = Plan(context: K.context)
            newPlan.title = textField.text
            newPlan.dishes = NSSet(array: self.dishArray)
            self.saveContext()
        }
        
        alert.addTextField { (alertTextField) in
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
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
            return dishArray.filter({$0.day == day}).count
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
            let dishes = dishArray.filter({$0.day == day})
            if dishes.count >= indexPath.row {
                let dish = dishes[indexPath.row]
                cell.mealLabel.text = K.mealIcon[Int(dish.meal!.order)]
                cell.recipeLabel.text = dish.recipe?.title
                cell.ingredientLabel.text = (dish.alternativeIngredients?.allObjects as! [Ingredient]).map({$0.food!.title!}).sorted().joined(separator: "\n")
                cell.onStepperValueChangedUpdateCell(dish.portion)
                cell.onStepperValueChanged = { value in
                    dish.portion = value
                    self.saveContext()
                    self.onDishUpdated()
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
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        
        if editingStyle == .delete {
            
            let day = indexPath.section - 1
            let dish = dishArray.filter({$0.day == day})[indexPath.row]
            let plans = dish.plans?.allObjects as! [Plan]
            if plans.count > 1 {
                dish.plans = NSSet(array: plans.filter({$0 != selectedPlan}))
            } else {
                K.context.delete(dish)
            }

            saveContext()
            dishArray = dishArray.filter({$0 != dish})
            onDishUpdated()
        }
        
    }
    
    
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "GoToEditDish" {
            
            let vc = segue.destination as! EditDishTVC
            vc.selectedPlan = selectedPlan!

            if let indexPath = tableView.indexPathForSelectedRow,
                indexPath.section > 0 {
            
                vc.selectedDish = dishArray.filter({$0.day == indexPath.section - 1})[indexPath.row]
            }
            
        } else if segue.identifier == "GoToViewRecipe",
            let indexPath = tableView.indexPathForSelectedRow {
            
            let vc = segue.destination as! ViewRecipeTVC
            vc.selectedDish = dishArray.filter({$0.day == indexPath.section - 1})[indexPath.row]
            
        } else if segue.identifier == "GoToSettings" {
            
            let vc = segue.destination as! SettingsTVC
            vc.mealPlanVC = self
            
        }
    }
    
    
}



