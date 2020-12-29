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
        case [1,0]:
            notifyMessage("Demo database restored")
        case [1,1]:
            performSegue(withIdentifier: "GoToChooseRecipe", sender: self)
        case [1,2]:
            performSegue(withIdentifier: "GoToChooseFood", sender: self)
        case [2,0]:
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
        }
    }
    

}
