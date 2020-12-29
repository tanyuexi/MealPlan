//
//  EditFoodTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class EditFoodTVC: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var selectedFood: Food?
    var completionHandler: ((Food, String) -> Void)?
    
    var categoryButtons: [UIButton] = []
    var seasonButtons: [UIButton] = []
    var serveSizeArray: [ServeSize] = []
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var quickFillButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var vegetableButton: UIButton!
    @IBOutlet weak var fruitButton: UIButton!
    @IBOutlet weak var proteinButton: UIButton!
    @IBOutlet weak var grainButton: UIButton!
    @IBOutlet weak var calciumButton: UIButton!
    @IBOutlet weak var oilButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var springButton: UIButton!
    @IBOutlet weak var summerButton: UIButton!
    @IBOutlet weak var autumnButton: UIButton!
    @IBOutlet weak var winterButton: UIButton!
    @IBOutlet weak var serveSizeCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serveSizeCollectionView.delegate = self
        serveSizeCollectionView.dataSource = self
        serveSizeCollectionView.register(UINib(nibName: K.collectionCellID, bundle: nil), forCellWithReuseIdentifier: K.collectionCellID)
        
        categoryButtons = [vegetableButton, fruitButton, proteinButton, grainButton, calciumButton, oilButton, otherButton]
        seasonButtons = [springButton, summerButton, autumnButton, winterButton]
        
        if let food = selectedFood {
            loadDataToForm(food)
            if food.ingredients != nil,
                food.ingredients!.count > 0 {
                deleteButton.isEnabled = false
            }
        } else {
            deleteButton.isEnabled = false
        }
        verifyData()
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func quickFillButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        verifyData()
    }
    
    @IBAction func categoryButtonPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
        verifyData()
    }
    
    @IBAction func seasonButtonPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
        verifyData()
    }
    
    @IBAction func addServeSizeButtonPressed(_ sender: UIButton) {
        editServeSize(nil)
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        let categories = NSSet(array: categoryButtons.filter({$0.isSelected}).map({$0.tag}).map({S.dt.foodgroupArray[$0]}))
        let seasons = NSSet(array: seasonButtons.filter({$0.isSelected}).map({$0.tag}).map({S.dt.seasonArray[$0]}))
        var operationString = ""

        let food: Food!
        
        if selectedFood == nil {
            food = Food(context: K.context)
            food.seasons = seasons
            operationString = K.operationAdd
        } else {
            food = selectedFood
            operationString = K.operationUpdate
            
            //update related recipe featuredIngredients
            if food.title != titleTextField.text {
                food.title = titleTextField.text
                saveContext()

                for i in food.ingredients?.allObjects as! [Ingredient] {
                    if let recipe = i.recipe {
                        updateRecipeFeaturedIngredients(of: recipe)
                    }
                }
            }
            
            //update related recipe seasons
            if !food.seasons!.isEqual(to: seasons as! Set<AnyHashable>) {
                askToConfirmMessage(NSLocalizedString("Change available seasons of this food might affect other recipes. Still want the change?", comment: "alert"), confirmHandler: {action in
                    
                    food.seasons = seasons
                    self.saveContext()
                    for i in food.ingredients?.allObjects as! [Ingredient] {
                        if let recipe = i.recipe {
                            self.updateRecipeSeason(of: recipe)
                        }
                    }
                })
            }
            
        }
        
        food.categories = categories
        food.serveSizes = NSSet(array: serveSizeArray)
        completionHandler?(food, operationString)
        saveContext()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        if let food = selectedFood {
            askToConfirmMessage(NSLocalizedString("Delete food?", comment: "alert"), confirmHandler: { action in
                
                self.completionHandler?(food, K.operationDelete)
                K.context.delete(food)
                self.saveContext()
                self.navigationController?.popViewController(animated: true)
            })
        }
    }
    
    //MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return serveSizeArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = serveSizeCollectionView.dequeueReusableCell(withReuseIdentifier: K.collectionCellID, for: indexPath) as! CollectionCell
        
        let serveSize = serveSizeArray[indexPath.row]
        cell.titleLabel.text = serveSize.unit
        cell.detailLabel.text = limitDigits(serveSize.quantity)
        
        
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        editServeSize(indexPath.row)
        serveSizeCollectionView.deselectItem(at: indexPath, animated: true)
    }
    
    //MARK: - Custom functions
    
    func editServeSize(_ row: Int?){
        var quantityTextField = UITextField()
        var unitTextField = UITextField()
        
        let alert = UIAlertController(title: NSLocalizedString("Edit Unit", comment: "alert"), message: NSLocalizedString("Specify serve size (quantity and unit for 1 serve) for this unit. If having trouble, try 'Quick Fill'.", comment: "alert"), preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive ) { (action) in
            
            let serveSize = self.serveSizeArray[row!]
            if serveSize.ingredients?.count == 0 {
                self.serveSizeArray.remove(at: row!)
                self.serveSizeCollectionView.reloadData()
                K.context.delete(serveSize)
                self.saveContext()
                
            } else {
                self.notifyMessage(NSLocalizedString("Failed to delete serve size. There are ingredients depending on it.", comment: "alert"))
            }
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { (action) in
            
            if Double(quantityTextField.text!) != nil,
                unitTextField.text != "" {
                
                let serveSize: ServeSize!
                if row == nil {
                    serveSize = ServeSize(context: K.context)
                    self.serveSizeArray.append(serveSize)
                } else {
                    serveSize = self.serveSizeArray[row!]
                }
                serveSize.quantity = Double(quantityTextField.text!) ?? 0
                serveSize.unit = unitTextField.text!
                self.serveSizeArray.sort{$0.unit! < $1.unit!}
                self.serveSizeCollectionView.reloadData()
                self.saveContext()
                
            } else {
                self.notifyMessage(NSLocalizedString("Failed to add new unit. Invalid quantity/unit.", comment: "alert"))
            }
        }
        
        alert.addTextField { (alertTextField) in
            if row != nil {
                alertTextField.text = self.limitDigits(self.serveSizeArray[row!].quantity)
            }
            alertTextField.placeholder = "quantity"
            alertTextField.keyboardType = .decimalPad
            quantityTextField = alertTextField
        }
        
        alert.addTextField { (alertTextField) in
            if row != nil {
                alertTextField.text = self.serveSizeArray[row!].unit
            }
            alertTextField.placeholder = "unit"
            unitTextField = alertTextField
        }
        
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        if row != nil {
            alert.addAction(deleteAction)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    
    func loadDataToForm(_ data: Food){
        titleTextField.text = data.title
        for i in data.categories!.allObjects as! [FoodGroup] {
            categoryButtons[Int(i.order)].isSelected = true
        }
        for i in data.seasons!.allObjects as! [Season] {
            seasonButtons[Int(i.order)].isSelected = true
        }
        serveSizeArray = data.serveSizes?.allObjects as! [ServeSize]
        serveSizeArray.sort{$0.unit! < $1.unit!}
        serveSizeCollectionView.reloadData()
    }
    
    
    func verifyData(){
        var valid = true
        confirmLabel.text = ""
        
        if titleTextField.text == "" {
            confirmLabel.text! += NSLocalizedString("Missing title. ", comment: "confirm")
            valid = false
        }
        
        if categoryButtons.allSatisfy({$0.isSelected == false}) {
            confirmLabel.text! += NSLocalizedString("Missing category(ies). ", comment: "confirm")
            valid = false
        }
        
        if seasonButtons.allSatisfy({$0.isSelected == false}) {
            confirmLabel.text! += NSLocalizedString("Missing season(s). ", comment: "confirm")
            valid = false
        }
        
        if valid {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
}
