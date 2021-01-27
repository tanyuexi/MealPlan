//
//  PickerCell.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/20.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit

class PickerCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    

    var pickerTitles: [String] = []
    var onSelectedRow: ((Int) -> Void)?
    var tableView: UITableView?
    
    @IBOutlet weak var titleButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.isHidden = true

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func titleButtonPressed(_ sender: UIButton) {
        pickerView.isHidden = !pickerView.isHidden
        tableView?.reloadData()
    }
    
    //MARK: - Custom functions
    
    func selectRow(at row: Int){
        pickerView.selectRow(row, inComponent: 0, animated: false)
        onPickerViewRowSelectedUpdateCell()
    }
    
    
    func onPickerViewRowSelectedUpdateCell(){
        titleButton.setTitle(pickerTitles[pickerView.selectedRow(inComponent: 0)], for: .normal)
    }
    
    
    
    //MARK: - UIPickerView
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerTitles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerTitles[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        onPickerViewRowSelectedUpdateCell()
        onSelectedRow?(row)
    }
    
}
