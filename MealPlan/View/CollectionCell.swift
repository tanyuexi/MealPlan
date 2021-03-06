//
//  IngredientCell.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/12/4.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class CollectionCell: UICollectionViewCell {
    
    var bgViewColor = UIColor.clear
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            self.bgView.backgroundColor = isSelected ? UIColor.link : bgViewColor
            self.detailLabel.textColor = isSelected ? UIColor.white : UIColor.link
            self.titleLabel.textColor = isSelected ? UIColor.white : UIColor.link
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        bgView.layer.cornerRadius = 10
    }

}
