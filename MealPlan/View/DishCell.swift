//
//  DishCell.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/19.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit

class DishCell: UITableViewCell {
    
    var onStepperValueChanged: ((Double) -> Void)?
    let tvc = UITableViewController()

    @IBOutlet weak var mealLabel: UILabel!
    @IBOutlet weak var recipeLabel: UILabel!
    @IBOutlet weak var ingredientLabel: UILabel!
    @IBOutlet weak var portionLabel: UILabel!
    @IBOutlet weak var portionStepper: UIStepper!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        portionStepper.minimumValue = 0
        portionStepper.maximumValue = Double.infinity
        portionStepper.stepValue = 0.5
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    
    func onStepperValueChangedUpdateCell(_ value: Double){
        
        portionLabel.text = "\(tvc.limitDigits(value)) \(K.portionIcon)"
        portionStepper.value = value
    }
    
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        onStepperValueChanged?(portionStepper.value)
        onStepperValueChangedUpdateCell(portionStepper.value)
    }
    
}
