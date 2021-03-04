//
//  PreferredFoodTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class PreferredFoodTVC: UITableViewController {

    var settingsVC: SettingsTVC?
    var mealPlanVC: MealPlanVC?
    var preferredFoodArray: [PreferredFood] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadPreferredFood(to: &preferredFoodArray)
    }

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        let foods = preferredFoodArray.compactMap({$0.food})
        if let season = mealPlanVC?.autoGeneratePlan(with: foods) {
            notifyMessage(String(
                format: "%@ (%@) %@",
                NSLocalizedString("Meal plan", comment: "alert"),
                season,
                NSLocalizedString("generated", comment: "alert")
            )) { action in
                self.navigationController?.popViewController(animated: false)
                self.settingsVC?.navigationController?.popViewController(animated: false)
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return 1
        default:
            return preferredFoodArray.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddPreferredFoodCell", for: indexPath)
            return cell
            
        default:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PreferredFoodCell", for: indexPath)
            cell.textLabel?.text = preferredFoodArray[indexPath.row].food?.title
            return cell
            
        }
        
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: "GoToChooseFood", sender: nil)
        }
    }

    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0:
            return false
        default:
            return true
        }
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        
        if editingStyle == .delete {
            
            K.context.delete(preferredFoodArray[indexPath.row])
            preferredFoodArray.remove(at: indexPath.row)
            tableView.reloadData()
            saveContext()
        }
        
    }
    
    
    // MARK: - Navigation


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToChooseFood",
            let vc = segue.destination as? ChooseFoodTVC {
            
            vc.existingFoodSeclectedHandler = { food in
                let newPreferredFood = PreferredFood(context: K.context)
                newPreferredFood.food = food
                self.preferredFoodArray.append(newPreferredFood)
                self.saveContext()
                self.tableView.reloadData()
                vc.navigationController?.popViewController(animated: false)
            }
        }
    }
    

}
