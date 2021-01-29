//
//  EditDishTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/20.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class EditDishTVC: UITableViewController {
    
    var selectedDish: PlannedDish?
    var selectedRecipe: Recipe?
    var titleButton: UIButton?
    var portionButton: UIButton?
    var dayRow = 0
    var mealRow = 0
    var portion: Double = 0
    var alternativeRow: [Int] = []
    var alternativeArray: [Alternative] = []
    var alternativeIngredients: [Int:[Ingredient]] = [:]
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UINib(nibName: "PickerCell", bundle: nil), forCellReuseIdentifier: "PickerCell")
        tableView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: "ButtonCell")
        
        if let dish = selectedDish {
            selectedRecipe = dish.recipe
            onRecipeSelected(dish.recipe!)
            dayRow = Int(dish.day)
            mealRow = S.data.mealArray.firstIndex(of: dish.meal!) ?? 0
            portion = dish.portion

            for i in 0..<alternativeArray.count {
                if let ingredients = alternativeIngredients[i],
                    let selectedIngredients = dish.alternativeIngredients {
                    
                    if let selectedIndex = ingredients.firstIndex(where: {selectedIngredients.contains($0)}) {
                        
                        alternativeRow[i] = selectedIndex
                        
                    } else {
                        
                        alternativeRow[i] = ingredients.count
                        
                    }
                }
            }
            deleteButton.isEnabled = true
        } else {
            deleteButton.isEnabled = false
        }
    }
    
    
    //MARK: - Custom functions
    
    func onRecipeSelected(_ recipe: Recipe){
        titleButton?.setTitle(recipe.title, for: .normal)
        alternativeArray = recipe.alternatives?.allObjects as! [Alternative]
        for i in 0..<alternativeArray.count {
            alternativeIngredients[i] = (alternativeArray[i].ingredients?.allObjects as! [Ingredient]).sorted(by: {$0.food!.title! < $1.food!.title!})
        }
        alternativeRow = Array(repeating: 0, count: alternativeArray.count)
    }
    
    
    
    func entryError() -> String? {
        var errorMessage = ""
        
        if selectedRecipe == nil {
            errorMessage += NSLocalizedString("Missing recipe. ", comment: "alert")
        }
        
        if portion == 0 {
            errorMessage += NSLocalizedString("Missing portion. ", comment: "alert")
        }
        
        return errorMessage == "" ? nil : errorMessage
    }
    
    
    
    
    //MARK: - IBAction
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        if let message = entryError() {
            notifyMessage(message)
            return
        }
        
        let dish: PlannedDish!
        if selectedDish == nil {
            dish = PlannedDish(context: K.context)
        } else {
            dish = selectedDish
        }
        dish.recipe = selectedRecipe!
        dish.day = Int16(dayRow)
        dish.meal = S.data.mealArray[mealRow]
        dish.portion = portion
        var selectedIngredients: [Ingredient] = []
        for i in 0..<alternativeRow.count {
            if alternativeRow[i] < alternativeIngredients[i]!.count {
                selectedIngredients.append(alternativeIngredients[i]![alternativeRow[i]])
            }
        }
//        let allIngredients = selectedRecipe!.ingredients?.allObjects as! [Ingredient]
//        let ingredientsInDish = allIngredients.filter({$0.alternative == nil || selectedIngredients.contains($0)})
        dish.alternativeIngredients = NSSet(array: selectedIngredients)
        
        saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        
        if let dish = selectedDish {
            askToConfirmMessage(NSLocalizedString("Delete dish?", comment: "alert"), confirmHandler: { action in
                
                K.context.delete(dish)
                self.saveContext()
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if selectedRecipe == nil {
            return 4
        } else {
            return 6
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0..<4:
            return 1
        case 4:
            return alternativeArray.count
        default: // method
            return 1
        }
    }

    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0..<4:
            return nil
        case 4:
            return alternativeArray.count == 0 ? nil : NSLocalizedString("Alternative ingredients", comment: "header")
        default:
            return NSLocalizedString("Method", comment: "header")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0: // recipe
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonCell
            if let recipe = selectedRecipe {
                cell.titleButton.setTitle(recipe.title, for: .normal)
            } else {
                cell.titleButton.setTitle(NSLocalizedString("< Choose recipe >", comment: "button"), for: .normal)
            }
            titleButton = cell.titleButton
            cell.onButtonPressed = {
                self.performSegue(withIdentifier: "GoToChooseRecipe", sender: nil)
            }
            return cell
            
        case 1: // day
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath) as! PickerCell
            
            cell.tableView = tableView
            
            let indexArray = Array(0..<Int(S.data.days))
            if let firstDate = S.data.firstDate {
                let dateArray = indexArray.map({S.data.weekdayFormatter.string(from: dateAfter($0, from: firstDate))})
                cell.pickerTitles = indexArray.map({
                    String(format: NSLocalizedString("Day %d - %@", comment: "picker format"), $0 + 1, dateArray[$0])
                })
            } else {
                cell.pickerTitles = indexArray.map({
                    String(format: NSLocalizedString("Day %d", comment: "picker format"), $0 + 1)
                })
            }
            
            cell.selectRow(at: dayRow )
            cell.onSelectedRow = { row in
                self.dayRow = row
            }
            return cell
            
        case 2: // meal
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath) as! PickerCell
            
            cell.tableView = tableView
            cell.pickerTitles = S.data.mealArray.map({$0.title!})
            cell.selectRow(at: mealRow )
            cell.onSelectedRow = { row in
                self.mealRow = row
            }
            return cell
            
        case 3: // portion
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonCell
            if portion == 0 {
                cell.titleButton.setTitle(NSLocalizedString("< Set portions >", comment: "button"), for: .normal)
            } else {
                cell.titleButton.setTitle(String(format: NSLocalizedString("Portions", comment: "button") + ": %@", limitDigits(portion)), for: .normal)
            }
            portionButton = cell.titleButton
            cell.onButtonPressed = {
                var textField = UITextField()
                
                let alert = UIAlertController(title: NSLocalizedString("Enter the portions", comment: "alert"), message: "", preferredStyle: .alert)
                
                let action = UIAlertAction(title: NSLocalizedString("Done", comment: "alert"), style: .default) { (action) in
                    //what will happen once the user clicks the Add Item button on our UIAlert
                    if let number = Double(textField.text!) {
                        self.portion = number
                        self.portionButton?.setTitle(String(format: NSLocalizedString("Portions", comment: "button") + ": %@", self.limitDigits(self.portion)), for: .normal)
                    }
                }
                
                alert.addTextField { (alertTextField) in
                    alertTextField.placeholder = "Number"
                    alertTextField.keyboardType = .decimalPad
                    textField = alertTextField
                }
                
                alert.addAction(action)
                
                self.present(alert, animated: true, completion: nil)
            }
            return cell
            
        case 4: // alternative ingredients
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PickerCell", for: indexPath) as! PickerCell
            
            cell.tableView = tableView
            
            if let ingredients = alternativeIngredients[indexPath.row] {
                cell.pickerTitles = ingredients.map({$0.food!.title!})
                if ingredients.first!.optional {
                    cell.pickerTitles.append(NSLocalizedString("< None >", comment: "picker"))
                }
                cell.selectRow(at: alternativeRow[indexPath.row] )
                cell.onSelectedRow = { row in
                    self.alternativeRow[indexPath.row] = row
                }
            }
            return cell
            
        default: // method
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "MethodCell", for: indexPath)
            
            if let recipe = selectedRecipe {
                cell.textLabel?.text = convertMultiLineToDisplay(from: recipe.method!)
            } else {
                cell.textLabel?.text = ""
            }
            
            return cell
            
        }
        
        
    }
    


    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToChooseRecipe",
            let vc = segue.destination as? ChooseRecipeTVC {
            
            vc.newRecipeSelectedHandler = {
                vc.notifyMessage(NSLocalizedString("Please choose an existing recipe.", comment: "alert"))
            }
            
            vc.existingRecipeSeclectedHandler = { recipe in
                self.selectedRecipe = recipe
                self.onRecipeSelected(recipe)
                vc.navigationController?.popViewController(animated: true)
                self.tableView.reloadData()
            }
        }
    }
    

}
