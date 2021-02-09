//
//  EditIngredientTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class EditIngredientTVC: UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var selectedIngredient: Ingredient?
    var selectedFood: Food?
    var completionHandler: ((Ingredient, String) -> Void)?
    var addedIngredients: [Ingredient] = []
    var unitArray: [String] = []


    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var chooseFoodButton: UIButton!
    @IBOutlet weak var foodgroupLabel: UILabel!
    @IBOutlet weak var seasonLabel: UILabel!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var unitCollectionView: UICollectionView!
    @IBOutlet weak var alternativeCollectionView: UICollectionView!
    @IBOutlet weak var optionalSwitch: UISwitch!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        unitCollectionView.delegate = self
        unitCollectionView.dataSource = self
        unitCollectionView.allowsMultipleSelection = false
        unitCollectionView.register(UINib(nibName: K.collectionCellID, bundle: nil), forCellWithReuseIdentifier: K.collectionCellID)
        
        alternativeCollectionView.delegate = self
        alternativeCollectionView.dataSource = self
        alternativeCollectionView.allowsMultipleSelection = true
        alternativeCollectionView.register(UINib(nibName: K.collectionCellID, bundle: nil), forCellWithReuseIdentifier: K.collectionCellID)

        
        if let ingredient = selectedIngredient {
            loadDataToForm(ingredient)
        } else {
            deleteButton.isEnabled = false
        }
    }
    



    //MARK: - Custom functions


    func loadDataToForm(_ data: Ingredient){
        selectedFood = data.food
        onSelectedFoodUpdated()
        quantityTextField.text = limitDigits(data.quantity)
        optionalSwitch.isOn = data.isOptional
        addedIngredients.removeAll(where: {$0 == data})
        alternativeCollectionView.reloadData()
//        selectAlternativeIngredients(of: data)
    }

    func selectAlternativeIngredients(of ingredient: Ingredient){
        if let alternativeIngredients = ingredient.alternative?.ingredients?.allObjects as? [Ingredient] {

            let indexArray = alternativeIngredients.compactMap({addedIngredients.firstIndex(of: $0)})
            for i in indexArray {
                selectCollectionCell(alternativeCollectionView, at: [0,i])
            }
        }
    }
    
    func onSelectedFoodUpdated(){
        if let food = selectedFood {
            chooseFoodButton.setTitle(food.title, for: .normal)
            let serveSizes = food.serveSizes?.allObjects as! [ServeSize]
            foodgroupLabel.text = getFoodGroupInfo(from: serveSizes)
            seasonLabel.text = getSeasonIcon(from: food.seasons!.allObjects as! [Season])
            unitArray = Array(Set(serveSizes.map({$0.unit!})))
            unitArray.sort()
            onUnitUpdated()
        }
    }
    
    
    func onUnitUpdated(){
        unitCollectionView.reloadData()
    }
    
    
    func entryError() -> String? {
        var message = ""
        
        if selectedFood == nil {
            message += NSLocalizedString("Unchosen food. ", comment: "alert")
        }

        if Double(quantityTextField.text!) == nil {
            message += NSLocalizedString("Invalid quantity. ", comment: "alert")
        }
        
        if unitCollectionView.indexPathsForSelectedItems?.first == nil {
            message += NSLocalizedString("Unchosen unit. ", comment: "alert")
        }

        return (message == "" ? nil : message)
    }


    //MARK: - IBAction
    
    
    @IBAction func chooseFoodButtonPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "GoToChooseFood", sender: nil)
    }
    
    
    @IBAction func editFoodButtonPressed(_ sender: UIButton) {
        
        if selectedFood == nil {
            performSegue(withIdentifier: "GoToChooseFood", sender: nil)
        } else {
            performSegue(withIdentifier: "GoToEditFood", sender: nil)
        }
    }


    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        if let errorMessage = entryError() {
            notifyMessage(errorMessage)
            return
        }

        let unit = unitArray[unitCollectionView.indexPathsForSelectedItems!.first!.row]
        
        let ingredientQuantity = Double(quantityTextField.text!) ?? 0
        var operationString = ""


        // update or add new ingredient
        let ingredient: Ingredient!

        if let editIngredient = selectedIngredient { // update
            ingredient = editIngredient
            operationString = K.operationUpdate
        } else { // add
            ingredient = Ingredient(context: K.context)
            operationString = K.operationAdd
        }
        
        ingredient.food = selectedFood
        ingredient.unit = unit
        ingredient.quantity = ingredientQuantity
        ingredient.isOptional = optionalSwitch.isOn
        
        let serveSizes = selectedFood?.serveSizes?.allObjects as! [ServeSize]
        let minServeSize = serveSizes.filter({$0.unit! == unit}).sorted(by: {$0.quantity < $1.quantity}).first!
        ingredient.maxServes = ingredientQuantity / minServeSize.quantity
        
        if var alternativeIngredients = alternativeCollectionView.indexPathsForSelectedItems?.compactMap({addedIngredients[$0.row]}),
            alternativeIngredients.count > 0{
                        
            alternativeIngredients.append(ingredient)
            
            var oldAlternatives = getAlternative(from: alternativeIngredients)
            let newAlternative: Alternative!
            if oldAlternatives.isEmpty {
                newAlternative = Alternative(context: K.context)
            } else {
                newAlternative = oldAlternatives.remove(at: 0)
                for alter in oldAlternatives {
                    K.context.delete(alter)
                }
            }
            newAlternative.ingredients = NSSet(array: alternativeIngredients)
            
            for i in alternativeIngredients {
                i.isOptional = optionalSwitch.isOn
            }
        }

        saveContext()
        completionHandler?(ingredient, operationString)
        navigationController?.popViewController(animated: true)
    }

    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        if let ingredient = selectedIngredient {
            askToConfirmMessage(NSLocalizedString("Delete ingredient?", comment: "alert"), confirmHandler: { action in

                self.completionHandler?(ingredient, K.operationDelete)
                K.context.delete(ingredient)
                self.saveContext()
                self.navigationController?.popViewController(animated: true)
            })
        }
    }

    
    //MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == unitCollectionView {
            return unitArray.count
        } else { //alternativeCollectionView
            return addedIngredients.count
        }
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == unitCollectionView {
            let cell = unitCollectionView.dequeueReusableCell(withReuseIdentifier: K.collectionCellID, for: indexPath) as! CollectionCell
            let unit = unitArray[indexPath.row]
            cell.titleLabel.text = unit
            cell.detailLabel.text = ""
            if unit == selectedIngredient?.unit {
                unitCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                cell.isSelected = true
            } else {
                cell.isSelected = false
            }
            return cell
            
        } else {  //alternativeCollectionView
            let cell = alternativeCollectionView.dequeueReusableCell(withReuseIdentifier: K.collectionCellID, for: indexPath) as! CollectionCell
            let i = addedIngredients[indexPath.row]
            cell.titleLabel.text = i.food!.title
            cell.detailLabel.text = "\(limitDigits(i.quantity)) \(i.unit!)"
            if let alternativeIngredients = selectedIngredient?.alternative?.ingredients?.allObjects as? [Ingredient],
                alternativeIngredients.contains(i){
                
                alternativeCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                cell.isSelected = true
            } else {
                cell.isSelected = false
            }
            return cell
        }
        
        
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == alternativeCollectionView {
            
            selectAlternativeIngredients(of: addedIngredients[indexPath.row])
        }
    }



// MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToChooseFood",
            let vc = segue.destination as? ChooseFoodTVC {
            
            vc.newFoodSelectedHandler = {
                vc.performSegue(withIdentifier: "GoToEditFood", sender: nil)
            }
            
            vc.existingFoodSeclectedHandler = { food in
                self.selectedFood = food
                self.onSelectedFoodUpdated()
                vc.navigationController?.popViewController(animated: true)
            }
        } else if segue.identifier == "GoToEditFood",
            let vc = segue.destination as? EditFoodTVC {
            
            vc.selectedFood = selectedFood
            vc.completionHandler = { food, operationString in
                switch operationString {
                    //cannot be deleted when associated with ingredient
//                case K.operationDelete:
//                    self.selectedFood = nil
                case K.operationUpdate:
                    self.selectedFood = food
                default:
                    print("operationString: \(operationString)")
                }
                self.onSelectedFoodUpdated()
            }
        }
    }
}
