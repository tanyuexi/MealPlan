//
//  SettingsTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class SettingsTVC: UITableViewController, UITextFieldDelegate {

    var mealPlanVC: MealPlanVC?
    
    @IBOutlet weak var dayTextField: UITextField!
    @IBOutlet weak var firstDateTextField: UITextField!
    @IBOutlet weak var hemisphereSegControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        firstDateTextField.delegate = self
                
        dayTextField.text = String(Int(S.data.days))
        if let firstDate = S.data.firstDate {
            firstDateTextField.text = S.data.dateFormatter.string(from: firstDate)
        }
    }
    
    
    //MARK: - IBAction
    
    @IBAction func dayTextFieldEditingDidEnd(_ sender: UITextField) {
        
        if let d = Int(sender.text!) {
            if d < 1 {
                sender.text = "1"
            } else {
                sender.text = "\(d)"
            }
        } else {
            sender.text = "1"
        }
        
        S.data.days = Double(sender.text!)!
        setPlistDays(Int(S.data.days))
    }
    
    
    
    @IBAction func firstDateTextFieldEditingDidEnd(_ sender: UITextField) {
        
        S.data.firstDate = S.data.dateFormatter.date(from: firstDateTextField.text!)

        if S.data.firstDate == nil {
            firstDateTextField.text = ""
        }
        
        setPlistFirstDate(firstDateTextField.text!)
    }
    
    
    @IBAction func hemisphereSegControlValueChanged(_ sender: UISegmentedControl) {
        
        S.data.northHemisphere = (hemisphereSegControl.selectedSegmentIndex == 0)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if K.debugMode {
            return 4
        } else {
            return 3
        }
    }


    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath {
        case [0,0]:
            navigationController?.popViewController(animated: true)
        case [0,1]:
            performSegue(withIdentifier: "GoToPreferredFood", sender: self)
        case [0,2]:
            performSegue(withIdentifier: "GoToChoosePlan", sender: self)
        case [0,3]:
            performSegue(withIdentifier: "GoToShoppingList", sender: self)
        case [2,0]:
            performSegue(withIdentifier: "GoToChoosePerson", sender: self)
        case [2,1]:
            performSegue(withIdentifier: "GoToChooseRecipe", sender: self)
        case [2,2]:
            performSegue(withIdentifier: "GoToChooseFood", sender: self)
        case [2,3]:
            askToConfirmMessage("Overwrite current foods and recipes with demo?", confirmHandler: { action in
                self.importDemoDatabase()
                self.notifyMessage("Restored to demo")
            })
        case [3,0]:
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
        } else if segue.identifier == "GoToChoosePlan",
            let vc = segue.destination as? ChoosePlanTVC {
            
            vc.onCellSelected = { plan in
                S.data.selectedPlan = plan
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    

    
    //MARK: - UITextFieldDelegate

    
    //firstDateTextField auto format to "XX/XX/XXXX"
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if textField != firstDateTextField || string == "" {
            return true
        }
        
        let currentText = textField.text! as NSString
        var updatedText = currentText.replacingCharacters(in: range, with: string)
        
        switch updatedText.count {
        case Int(NSLocalizedString("2", comment: "auto format date")):
            updatedText.append("/")
        case Int(NSLocalizedString("5", comment: "auto format date")):
            updatedText.append("/")
        case 11:
            return false
        default:
            return true
        }
        
        textField.text = updatedText
        return false
    }
    
}
