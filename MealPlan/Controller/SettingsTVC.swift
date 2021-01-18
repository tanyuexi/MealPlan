//
//  SettingsTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class SettingsTVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()


    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if K.debugMode {
            return 3
        } else {
            return 2
        }
    }


    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath {
        case [0,0]:
            performSegue(withIdentifier: "GoToPreferredFood", sender: self)
        case [0,1]:
            navigationController?.popViewController(animated: true)
        case [0,2]:
            performSegue(withIdentifier: "GoToShoppingList", sender: self)
        case [1,2]:
            performSegue(withIdentifier: "GoToChoosePerson", sender: self)
        case [1,3]:
            performSegue(withIdentifier: "GoToChooseRecipe", sender: self)
        case [1,4]:
            performSegue(withIdentifier: "GoToChooseFood", sender: self)
        case [1,5]:
            askToConfirmMessage("Overwrite current data with demo?", confirmHandler: { action in
                self.importDemoDatabase()
                self.notifyMessage("Demo database restored")
            })
        case [2,0]:
            exportToCsv()
            notifyMessage("Database exported")
        default:
            print()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
   

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToChooseFood",
            let vc = segue.destination as? ChooseFoodTVC {
            
            vc.newFoodSelectedHandler = {
                vc.performSegue(withIdentifier: "GoToEditFood", sender: nil)
            }
            vc.existingFoodSeclectedHandler = { food in
                vc.performSegue(withIdentifier: "GoToEditFood", sender: nil)
            }
        } else if segue.identifier == "GoToChooseRecipe",
            let vc = segue.destination as? ChooseRecipeTVC {
            
            vc.newRecipeSelectedHandler = {
                vc.performSegue(withIdentifier: "GoToEditRecipe", sender: self)
            }
            
            vc.existingRecipeSeclectedHandler = { recipe in
                vc.performSegue(withIdentifier: "GoToViewRecipe", sender: self)
            }
        }
    }
    

}
