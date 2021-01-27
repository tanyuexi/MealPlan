//
//  ButtonCell.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/26.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit

class ButtonCell: UITableViewCell {
    
    var onButtonPressed: (() -> Void)?

    @IBOutlet weak var titleButton: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    
    @IBAction func titleButtonPressed(_ sender: UIButton) {
        onButtonPressed?()
    }
    
}
