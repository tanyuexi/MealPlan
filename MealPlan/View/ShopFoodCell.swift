//
//  ShopFoodCell.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/2/2.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit

class ShopFoodCell: UITableViewCell {
    
    //set by outside code
    var viewController: UIViewController!
    var selectedFood: Food!  //onFoodUpdated()
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var dishLabel: UILabel!
    
    //handled by itself
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var labelButton: UIButton!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func labelButtonPressed(_ sender: UIButton) {
        
        viewController.dataEntryByAlert(
            title: NSLocalizedString("Enter the label", comment: "alert"),
            message: NSLocalizedString("For easier shopping, e.g. market name (Woolworths, Aldi etc.), food section (fresh, frozen etc.)", comment: "alert"),
            preloadText: (selectedFood.shoppingLabel ?? ""),
            placeHolder: "",
            keyboardType: .default,
            presenter: viewController,
            completionHandler: { text in
                self.onShoppingLabelUpdated(text)
        })
    }
    
    func onFoodUpdated(_ food: Food) {
        selectedFood = food
        titleLabel.text = food.title
        selectedFood.shoppingLabel = food.shoppingLabel!
        labelButton.setTitle(food.shoppingLabel!, for: .normal)
    }
    
    func onShoppingLabelUpdated(_ text: String){
        selectedFood.shoppingLabel = text
        labelButton.setTitle(text, for: .normal)
        viewController.saveContext()
    }
}
