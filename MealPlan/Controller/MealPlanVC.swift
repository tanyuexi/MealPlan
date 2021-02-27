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
    
    
    var dishArray: [Dish] = []
    var editMode = false
    
    var personArray: [Person] = []
    var dailyTotal: [String:Double] = [:]
    var serveSum: [String:Double] = [:]
    var estimatedPortions: Double = 0
    
    let warningColor = UIColor.systemRed
    
    @IBOutlet weak var headerLabel: UILabel!
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

        tableView.register(UINib(nibName: "DishCell", bundle: nil), forCellReuseIdentifier: "DishCell")
        
        calculatorCollectionView.delegate = self
        calculatorCollectionView.dataSource = self
        calculatorCollectionView.register(UINib(nibName: "CalculatorCell", bundle: nil), forCellWithReuseIdentifier: "CalculatorCell")
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        onPersonUpdated()
        
        onPlanUpdated()
        
    }
    
    
    //MARK: - Custom functions
    
    func autoGeneratePlan() -> String {
        
        S.data.selectedPlan?.dishes = nil
        
        var seasonIndex = 0
        
        // get season
        let monthOfToday =  Calendar(identifier: .gregorian).dateComponents([.month], from: Date()).month!
        switch monthOfToday {
        case 0..<3:  // north winter, south summer
            seasonIndex = S.data.northHemisphere ? 3 : 1
        case 3..<6:  // north spring, south autumn
            seasonIndex = S.data.northHemisphere ? 0 : 2
        case 6..<9:  // north summer, south winter
            seasonIndex = S.data.northHemisphere ? 1 : 3
        case 9..<12: // north autumn, south spring
            seasonIndex = S.data.northHemisphere ? 2 : 0
        default:     // north winter, south summer
            seasonIndex = S.data.northHemisphere ? 3 : 1
        }
        
        let seasonOfToday = S.data.seasonArray[seasonIndex]
        
        for meal in S.data.mealArray {
            //load recipes of the meal & season
            var recipeCandidates: [Recipe] = []
            let mealPredicate = NSPredicate(format: "ANY meals.title == %@", meal.title!)
            let seasonPredicate = NSPredicate(format: "ANY seasons.title == %@", seasonOfToday.title!)
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mealPredicate, seasonPredicate])
            loadRecipe(to: &recipeCandidates, predicate: predicate)
            
            for day in 0..<Int(S.data.days) {
                
                if let randomRecipe = recipeCandidates.randomElement() {
                    
                    //create dish from random recipe
                    let dish = Dish(context: K.context)
                    let oldPlans = dish.plans?.allObjects as! [Plan]
                    dish.plans = NSSet(array: oldPlans + [S.data.selectedPlan!])
                    dish.recipe = randomRecipe
                    dish.day = Int16(day)
                    dish.meal = meal
                    dish.portion = estimatedPortions
                    var selectedIngredients = (randomRecipe.ingredients?.allObjects as! [Ingredient]).filter({$0.alternative == nil})
                    
                    if let alters = randomRecipe.alternatives {
                        for alt in alters.allObjects as! [Alternative] {
                            let ingredients = alt.ingredients?.allObjects as! [Ingredient]
                            if let randomIngredient = ingredients.randomElement() {
                                selectedIngredients.append(randomIngredient)
                            }
                        }
                    }
                    
                    dish.ingredients = NSSet(array: selectedIngredients)
                    
                    saveContext()
                }
            }
        }
        
        onPlanUpdated()
        
        let foodgroup = S.data.foodgroupArray[2].title!  //protein
        let multiplier = dailyTotal[foodgroup]! * S.data.days / serveSum[foodgroup]!
        if let dishes = S.data.selectedPlan?.dishes?.allObjects as? [Dish] {
            for dish in dishes {
                dish.portion = roundToHalf(dish.portion * multiplier)
            }
        }

        onPlanUpdated()
        saveContext()
        
        return seasonOfToday.title!
    }

    
    func onPersonUpdated(){
        loadPerson(to: &personArray)
        estimatedPortions = 0
        for person in personArray {
            if Calendar(identifier: .gregorian).dateComponents([.year], from: person.dateOfBirth!, to: Date()).year! < 9 {
                estimatedPortions += 0.5
            } else {
                estimatedPortions += 1
            }
        }
        headerLabel.text = String(
            format: "%@ %d %@",
            NSLocalizedString("Recommended serves for", comment: "header"),
            personArray.count,
            NSLocalizedString("person(s)", comment: "header")
        )
        calculateDailyTotalServes(from: personArray, to: &dailyTotal)
    }
    
    func onPlanUpdated() {
        
        if S.data.selectedPlan == nil {
            var plans: [Plan] = []
            loadPlan(to: &plans, predicate: NSPredicate(format: "title == %@", NSLocalizedString("[Current Plan]", comment: "plan")))
            if plans.first == nil {
                let newPlan = Plan(context: K.context)
                newPlan.title = "[Current Plan]"
                S.data.selectedPlan = newPlan
            } else {
                S.data.selectedPlan = plans.first
            }
        }
        
        dishArray = (S.data.selectedPlan!.dishes?.allObjects as! [Dish]).sorted(by: {
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
            for ingredient in dish.ingredients?.allObjects as! [Ingredient] {
                for serveSize in (ingredient.food!.serveSizes?.allObjects as! [ServeSize]).filter({$0.unit == ingredient.unit}) {
                    
                    if serveSum[serveSize.foodgroup!.title!] == nil {
                        serveSum[serveSize.foodgroup!.title!] = 0
                    }
                    serveSum[serveSize.foodgroup!.title!]! += ingredient.quantity * multiplier / serveSize.quantity
                }
                
            }
        }
        
        tableView.reloadData()
        calculatorCollectionView.reloadData()
    }
    
    //MARK: - IBAction
    
    @IBAction func modeButtonPressed(_ sender: UIBarButtonItem) {
        editMode = !editMode
//        sender.image = editMode ? UIImage(systemName: "eye") : UIImage(systemName: "square.and.pencil")
        sender.title = editMode ? NSLocalizedString("Done", comment: "button") : NSLocalizedString("Click to edit", comment: "button")
        sender.style = editMode ? .done : .plain
        tableView.reloadData()
    }
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "GoToSettings", sender: nil)

    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        dataEntryByAlert(title: NSLocalizedString("Enter a name to save plan", comment: "alert"), presenter: self) { text in
            
            let newPlan = Plan(context: K.context)
            newPlan.title = text
            newPlan.dishes = NSSet(array: self.dishArray)
            self.saveContext()
        }
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
                let alternativeIngredients = (dish.ingredients?.allObjects as! [Ingredient]).filter({$0.isOptional || $0.alternative != nil})
                cell.ingredientLabel.text = alternativeIngredients.map({$0.food!.title!}).sorted().joined(separator: "\n")
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
                dish.plans = NSSet(array: plans.filter({$0 != S.data.selectedPlan}))
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
        
        return S.data.foodgroupArray.count - 1 //except 'Other'
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = calculatorCollectionView.dequeueReusableCell(withReuseIdentifier: "CalculatorCell", for: indexPath) as! CalculatorCell
        
        let foodgroup = S.data.foodgroupArray[indexPath.row].title!
        let targetServes = dailyTotal[foodgroup]! * S.data.days
        let sum = serveSum[foodgroup] ?? 0
        
        cell.titleLabel.text = foodgroup
        
        cell.sumLabel.text = NSLocalizedString("Now: ", comment: "calculator") + limitDigits(sum)

        if foodgroup == NSLocalizedString("Oil", comment: "food group") {
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



