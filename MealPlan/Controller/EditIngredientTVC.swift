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
    @IBOutlet weak var foodEditButton: UIButton!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var foodGroupLabel: UILabel!
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
            addedIngredients.removeAll(where: {$0 == ingredient})
        } else {
            deleteButton.isEnabled = false
        }
//        alternativeCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        unitCollectionView.reloadData()
        verifyData()
    }
    



    //MARK: - Custom functions


    func loadDataToForm(_ data: Ingredient){
        selectedFood = data.food
        quantityTextField.text = limitDigits(data.quantity)
        optionalSwitch.isOn = data.optional
    }


    func verifyData(){
        var valid = true
        confirmLabel.text = ""
        foodGroupLabel.text = ""
        seasonLabel.text = ""
        
        if let food = selectedFood {
            foodEditButton.setTitle(food.title, for: .normal)
            let serveSizes = food.serveSizes?.allObjects as! [ServeSize]
            foodGroupLabel.text = getFoodGroupInfo(from: serveSizes)
            seasonLabel.text = getSeasonIcon(from: food.seasons!.allObjects as! [Season])
            unitArray = Array(Set(serveSizes.map({$0.unit!})))
            unitArray.sort()
        } else {
            confirmLabel.text! += NSLocalizedString("Unchosen food. ", comment: "confirm")
            valid = false
        }

        if Double(quantityTextField.text!) == nil {
            confirmLabel.text! += NSLocalizedString("Invalid quantity. ", comment: "confirm")
            valid = false
        }
        
        if unitCollectionView.indexPathsForSelectedItems?.first == nil {
            confirmLabel.text! += NSLocalizedString("Unchosen unit. ", comment: "confirm")
            valid = false
        }

        saveButton.isEnabled = valid
    }

    
    func selectCollectionCell(_ sender: UICollectionView, at indexPath: IndexPath) {
        if let cell = sender.cellForItem(at: indexPath) as? CollectionCell {
            sender.selectItem(at: indexPath, animated: false, scrollPosition: .left)
            cell.isSelected = true
//            sender.delegate?.collectionView?(sender, didSelectItemAt: indexPath)
        }
    }
    

    //MARK: - IBAction
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        verifyData()
    }

    
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
        ingredient.optional = optionalSwitch.isOn
        
        let serveSizes = selectedFood?.serveSizes?.allObjects as! [ServeSize]
        let minServeSize = serveSizes.filter({$0.unit! == unit}).sorted(by: {$0.quantity < $1.quantity}).first!
        ingredient.maxServes = ingredientQuantity / minServeSize.quantity
        
        if let alternativeIngredients = alternativeCollectionView.indexPathsForSelectedItems?.compactMap({addedIngredients[$0.row]}) {
            
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
            ingredient.alternative = newAlternative
            
            for i in alternativeIngredients {
                i.optional = optionalSwitch.isOn
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
                unitCollectionView.delegate?.collectionView?(unitCollectionView, didSelectItemAt: indexPath)
            }
            return cell
            
        } else {  //alternativeCollectionView
            let cell = alternativeCollectionView.dequeueReusableCell(withReuseIdentifier: K.collectionCellID, for: indexPath) as! CollectionCell
            let i = addedIngredients[indexPath.row]
            cell.titleLabel.text = i.food!.title
            cell.detailLabel.text = ""
            if let s = selectedIngredient,
                let alternatives = s.alternative?.ingredients?.allObjects as? [Ingredient],
                alternatives.contains(i) {

                alternativeCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
                cell.isSelected = true
                alternativeCollectionView.delegate?.collectionView?(alternativeCollectionView, didSelectItemAt: indexPath)
            }
            return cell
        }
        
        
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == unitCollectionView {
            verifyData()
        } else if collectionView == alternativeCollectionView,
            let alternativeIngredients = addedIngredients[indexPath.row].alternative?.ingredients?.allObjects as? [Ingredient] {
            
            let indexArray = alternativeIngredients.compactMap({addedIngredients.firstIndex(of: $0)})
            for i in indexArray {
                selectCollectionCell(alternativeCollectionView, at: [0,i])
            }
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
               vc.navigationController?.popViewController(animated: true)
           }
       } else if segue.identifier == "GoToEditFood",
           let vc = segue.destination as? EditFoodTVC {
           
           vc.selectedFood = selectedFood
           vc.completionHandler = { food, operationString in
               switch operationString {
               case K.operationDelete:
                   self.selectedFood = nil
               case K.operationUpdate:
                   self.selectedFood = food
               default:
                   print("operationString: \(operationString)")
               }
           }
       }
   }
}
