//
//  EditPersonTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/18.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData


class EditPersonTVC: UITableViewController, UITextFieldDelegate {
    
    var selectedPerson: Person?
    var index = -1
    
    var validDOB = false
    let confirmFormatter = DateFormatter()
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var DOBTextField: UITextField!
    @IBOutlet weak var DOBConfirmLabel: UILabel!
    @IBOutlet weak var additionalSwitch: UISwitch!
    @IBOutlet weak var genderSegmentedControl: UISegmentedControl!
    @IBOutlet weak var pregnantCell: UITableViewCell!
    @IBOutlet weak var pregnantSwitch: UISwitch!
    @IBOutlet weak var breastfeedingCell: UITableViewCell!
    @IBOutlet weak var breastfeedingSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DOBTextField.delegate = self
        
        confirmFormatter.dateFormat = NSLocalizedString("(d MMM, yyyy)", comment: "DOB confirm label data format")
        
        if let person = selectedPerson {
            loadDataToForm(person)
            deleteButton.isEnabled = true
        } else {
            deleteButton.isEnabled = false
        }
        
    }
    
    //MARK: - Custom functions
    
    func loadDataToForm(_ data: Person){
        nameTextField.text = data.name
        DOBTextField.text = S.data.dateFormatter.string(from: data.dateOfBirth!)
        DOBConfirmLabel.text = confirmFormatter.string(from: data.dateOfBirth!)
        validDOB = true
        additionalSwitch.isOn = data.additional
        pregnantSwitch.isOn = data.pregnant
        breastfeedingSwitch.isOn = data.breastfeeding
        enableFemaleOptions(data.female)
    }
    
    
    func enableFemaleOptions(_ enable: Bool){
        if enable {
            genderSegmentedControl.selectedSegmentIndex = 0
            pregnantCell.isHidden = false
            breastfeedingCell.isHidden = false
        } else {
            genderSegmentedControl.selectedSegmentIndex = 1
            pregnantCell.isHidden = true
            breastfeedingCell.isHidden = true
            pregnantSwitch.isOn = false
            breastfeedingSwitch.isOn = false
        }
    }
    
    
    func entryError() -> String? {
        var message = ""
        
        if nameTextField.text == "" {
            message += NSLocalizedString("Missing name. ", comment: "alert")
        }
        
        if !validDOB {
            message += NSLocalizedString("Invalid date of birth. ", comment: "alert")
        }
        
        return (message == "" ? nil : message)
    }
    
    
    
    //MARK: - IBAction
    
    @IBAction func DOBTextFieldEditingChanged(_ sender: UITextField) {
        
        if DOBTextField.text == "" {
            
            DOBConfirmLabel.text = NSLocalizedString("(DD/MM/YYYY)", comment: "DOB confirm label")
            DOBConfirmLabel.textColor = .none
            validDOB = false
            
        } else {
            
            if let oldDate = S.data.dateFormatter.date(from: DOBTextField.text!),
                S.data.dateFormatter.date(from: DOBTextField.text!)! <= Date() {
                
                DOBConfirmLabel.text = confirmFormatter.string(from: oldDate)
                DOBConfirmLabel.textColor = .none
                DOBTextField.clearsOnBeginEditing = false
                validDOB = true
            } else {
                DOBConfirmLabel.text = NSLocalizedString("(Invalid date)", comment: "DOB confirm label")
                DOBConfirmLabel.textColor = .red
                DOBTextField.clearsOnBeginEditing = true
                validDOB = false
            }
        }
    }
    
    @IBAction func genderSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        enableFemaleOptions(sender.selectedSegmentIndex == 0)
    }
    
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
                
        if let errorMessage = entryError() {
            notifyMessage(errorMessage)
            return
        }
        
        let person: Person!
        if let p = selectedPerson {
            person = p
        } else {
            person = Person(context: K.context)
        }
        
        person.name = nameTextField.text!
        person.dateOfBirth = S.data.dateFormatter.date(from: DOBTextField.text!)
        person.additional = additionalSwitch.isOn
        person.female = (genderSegmentedControl.selectedSegmentIndex == 0)
        person.pregnant = pregnantSwitch.isOn
        person.breastfeeding = breastfeedingSwitch.isOn
        
        saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        
        if let person = selectedPerson {
            askToConfirmMessage(NSLocalizedString("Delete person?", comment: "alert"), confirmHandler: { action in
                
                K.context.delete(person)
                self.saveContext()
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    
    //MARK: - UITextFieldDelegate

    
    //DOBTextField auto format to "XX/XX/XXXX"
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if textField != DOBTextField || string == "" {
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






