//
//  ViewRecipeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class ViewRecipeTVC: UITableViewController {

    var selectedRecipe: Recipe!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadDataToForm()
    }

    //MARK: - IBAction

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "GoToEditRecipe", sender: nil)
    }
    
    
    //MARK: - Custom function
    
    func loadDataToForm(){
        print("load")
    }
  
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToEditRecipe",
            let vc = segue.destination as? EditRecipeTVC {
            
            vc.selectedRecipe = selectedRecipe
            vc.completionHandler = { recipe, operationString in
                
                switch operationString {
                case K.operationDelete:
                    self.navigationController?.popViewController(animated: true)
                default:
                    self.loadDataToForm()
                }
            }
        }
    }
    

}
