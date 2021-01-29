//
//  CalculatorCell.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/28.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit

class CalculatorCell: UICollectionViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var sumLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

//        bgView.layer.cornerRadius = 10
    }

}
