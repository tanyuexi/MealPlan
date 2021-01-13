//
//  EditServeSizeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/12/30.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class EditServeSizeTVC: UITableViewController {
    
    var selectedServeSize: ServeSize?
    var completionHandler: ((ServeSize, String) -> Void)?
    
    var foodGroupButtons: [UIButton] = []
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var vegetableButton: UIButton!
    @IBOutlet weak var fruitButton: UIButton!
    @IBOutlet weak var proteinButton: UIButton!
    @IBOutlet weak var grainButton: UIButton!
    @IBOutlet weak var calciumButton: UIButton!
    @IBOutlet weak var oilButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var unitTextField: UITextField!
    @IBOutlet weak var quantityCellContentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        foodGroupButtons = [vegetableButton, fruitButton, proteinButton, grainButton, calciumButton, oilButton, otherButton]
        
        if let serveSize = selectedServeSize {
            loadDataToForm(serveSize)
            deleteButton.isEnabled = true
        } else {
            deleteButton.isEnabled = false
        }
        
        verifyData()
    }

    
    
    //MARK: - IBAction
    
    @IBAction func foodGroupButtonsPressed(_ sender: UIButton) {
        if sender.isSelected {
            sender.isSelected = false
        } else {
            for i in foodGroupButtons {
                i.isSelected = false
            }
            sender.isSelected = true
            if sender.tag == 6 {
                quantityTextField.text = "1"
                quantityCellContentView.isHidden = true
            } else {
                quantityCellContentView.isHidden = false
            }
        }
        verifyData()
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        verifyData()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        let foodGroupIndex = foodGroupButtons.firstIndex(where: {$0.isSelected == true})
        var operationString = ""
        
        var serveSize: ServeSize!
        if let s = selectedServeSize {
            serveSize = s
            operationString = K.operationUpdate
        } else {
            serveSize = ServeSize(context: K.context)
            operationString = K.operationAdd
        }
        serveSize.foodGroup = S.dt.foodGroupArray[foodGroupIndex!]
        serveSize.quantity = Double(quantityTextField.text!)!
        serveSize.unit = unitTextField.text
        
        completionHandler?(serveSize, operationString)
        saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        
        if let serveSize = selectedServeSize {
            askToConfirmMessage(NSLocalizedString("Delete serve size?", comment: "alert"), confirmHandler: { action in
                
                self.completionHandler?(serveSize, K.operationDelete)
                K.context.delete(serveSize)
                self.saveContext()
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    
    
    
    //MARK: - Custom functions
    
    func loadDataToForm(_ data: ServeSize){
        
        foodGroupButtons[Int(data.foodGroup!.order)].isSelected = true
        quantityTextField.text = limitDigits(data.quantity)
        unitTextField.text = data.unit
    }
    
    
    func verifyData(){
        
        confirmLabel.text = ""
        var valid = true
        
        if foodGroupButtons.allSatisfy({$0.isSelected == false}) {
            confirmLabel.text! += NSLocalizedString("Missing Food Group. ", comment: "confirm")
            valid = false
        }
        
        if Double(quantityTextField.text!) == nil {
            confirmLabel.text! += NSLocalizedString("Invalid quantity. ", comment: "confirm")
            valid = false
        }
        
        if unitTextField.text == "" {
            confirmLabel.text! += NSLocalizedString("Missing unit. ", comment: "confirm")
            valid = false
        }
        
        saveButton.isEnabled = valid
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
