//
//  MenuTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/24.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class MenuTVC: UITableViewController {
    
    var dishDict: [Int:[PlannedDish]] = [:]
    var editMode = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        S.data.dateFormatter.dateFormat = NSLocalizedString("dd/MM/yyyy", comment: "date format")
        S.data.weekdayFormatter.dateFormat = NSLocalizedString("EEE d MMM", comment: "date format")
        
        
        
        tableView.register(UINib(nibName: "DishCell", bundle: nil), forCellReuseIdentifier: "DishCell")
        
        
        print(getFilePath(directory: true)!)
        initDatabase()
        
        var foodArray: [Food] = []
        loadFood(to: &foodArray)
        if foodArray.count == 0 {
            importDemoDatabase()
        }
        foodArray = []
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        for day in 0..<Int(S.data.days) {
            var dishes: [PlannedDish] = []
            loadPlannedDish(to: &dishes, predicate: NSPredicate(format: "day == %d", day))
            dishDict[day] = dishes
        }

        tableView.reloadData()
    }
    
    
    //MARK: - IBAction
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "GoToSettings", sender: nil)
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        
        editMode = !editMode
        sender.image = editMode ? UIImage(systemName: "eye") : UIImage(systemName: "pencil")
        tableView.reloadData()
    }
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Int(S.data.days) + 1 //'placeholder for calculatorCell' and 'add dish'
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return editMode ? 2 : 1
        default:
            let day = section - 1
            return dishDict[day]?.count ?? 0
        }
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
            
        case 0:
            return nil
            
        default:
            
            if let firstDate = S.data.firstDate {
                
                let dateString = S.data.weekdayFormatter.string(from: dateAfter(section - 1, from: firstDate))
                return String(format: NSLocalizedString("Day %d - %@", comment: "picker format"), section, dateString)
                
            } else {
                return nil
            }
            
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceholderCell", for: indexPath)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddDishCell", for: indexPath)
                return cell
            }
            
        default:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "DishCell", for: indexPath) as! DishCell
            
            let day = indexPath.section - 1
            if dishDict[day] != nil {
                let dish = dishDict[day]![indexPath.row]
                cell.mealLabel.text = K.mealIcon[Int(dish.meal!.order)]
                cell.recipeLabel.text = dish.recipe?.title
                cell.ingredientLabel.text = (dish.selectedIngredients?.allObjects as! [Ingredient]).map({$0.food!.title!}).sorted().joined(separator: "\n")
                cell.onStepperValueChangedUpdateCell(dish.portion)
                cell.onStepperValueChanged = { value in
                    dish.portion = value
                    self.saveContext()
                }
//                cell.portionLabel.text = limitDigits(dish.portion)
//                cell.portionStepper.minimumValue = 0
//                cell.portionStepper.maximumValue = Double.infinity
//                cell.portionStepper.value = dish.portion
//                cell.portionStepper.stepValue = 0.5
            }
            
            if editMode {
                cell.portionStackView.isHidden = false
            } else {
                cell.portionStackView.isHidden = true
            }
            
            return cell
        }
        
        
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.section {
        default:
            performSegue(withIdentifier: "GoToEditDish", sender: nil)
        }
    }
    
    
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
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let indexPath = tableView.indexPathForSelectedRow,
            indexPath.section > 0 {
            
            let vc = segue.destination as! EditDishTVC
            vc.selectedDish = dishDict[indexPath.section - 1]?[indexPath.row]
        }
    }
    
    
}


