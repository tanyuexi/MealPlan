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
    var unitArray: [ServeSize] = []


    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var foodEditButton: UIButton!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var seasonLabel: UILabel!
    @IBOutlet weak var quantityTextField: UITextField!
    @IBOutlet weak var unitCollectionView: UICollectionView!
    @IBOutlet weak var optionalSegControl: UISegmentedControl!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        unitCollectionView.delegate = self
        unitCollectionView.dataSource = self
        unitCollectionView.register(UINib(nibName: K.collectionCellID, bundle: nil), forCellWithReuseIdentifier: K.collectionCellID)

        
        if let ingredient = selectedIngredient {
            loadDataToForm(ingredient)
        } else {
            deleteButton.isEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        verifyData()
        unitCollectionView.reloadData()
    }
    



    //MARK: - Custom functions


    func loadDataToForm(_ data: Ingredient){
        selectedFood = data.food
        quantityTextField.text = limitDigits(data.quantity)
        optionalSegControl.selectedSegmentIndex = data.optional ? 0 : 1
    }


    func verifyData(){
        var valid = true
        confirmLabel.text = ""
        categoryLabel.text = ""
        seasonLabel.text = ""
        
        if let food = selectedFood {
            foodEditButton.setTitle(food.title, for: .normal)
            categoryLabel.text = (food.categories!.allObjects as! [FoodGroup]).map({$0.title!}).joined(separator: ", ")
            seasonLabel.text = (food.seasons!.allObjects as! [Season]).map({$0.title!}).joined(separator: ", ")
            unitArray = food.serveSizes?.allObjects as! [ServeSize]
            unitArray.sort(by: {$0.unit! < $1.unit!})
        } else {
            confirmLabel.text! += NSLocalizedString("Unchosen food. ", comment: "confirm")
            valid = false
        }

        if let q = Double(quantityTextField.text!),
            let i = unitCollectionView.indexPathsForSelectedItems?.first,
            let u = unitArray[i.row].unit {

            confirmLabel.text! += "\(limitDigits(q)) \(u). "

        } else if Double(quantityTextField.text!) == nil {
            confirmLabel.text! += NSLocalizedString("Invalid quantity. ", comment: "confirm")
            valid = false
        } else {
            confirmLabel.text! += NSLocalizedString("Unchosen unit. ", comment: "confirm")
            valid = false
        }

        if optionalSegControl.selectedSegmentIndex == 0 {
            confirmLabel.text! += NSLocalizedString("Optional. ", comment: "confirm")
        }

        if valid {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }


    func getFoodByTitle(_ title: String) -> Food? {
        var foodByTitle: [Food] = []
        let request : NSFetchRequest<Food> = Food.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)

        do{
            foodByTitle = try K.context.fetch(request)
        } catch {
            print("Error loading Food \(error)")
        }
        return foodByTitle.first
    }

    func selectUnit(_ indexPath: IndexPath){
        unitCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
        let cell = unitCollectionView.cellForItem(at: indexPath) as! CollectionCell
        cell.isSelected = true
        unitCollectionView.delegate?.collectionView?(unitCollectionView, didSelectItemAt: indexPath)
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

    
    @IBAction func optionalSegControlValueChanged(_ sender: UISegmentedControl) {
        verifyData()
    }

    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {

        let serveSize = unitArray[unitCollectionView.indexPathsForSelectedItems!.first!.row]
        let optional = (optionalSegControl.selectedSegmentIndex == 0)
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
        ingredient.serveSize = serveSize
        ingredient.optional = optional
        ingredient.quantity = ingredientQuantity
        ingredient.serves = ingredientQuantity / serveSize.quantity

        completionHandler?(ingredient, operationString)
        saveContext()
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
        return unitArray.count
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = unitCollectionView.dequeueReusableCell(withReuseIdentifier: K.collectionCellID, for: indexPath) as! CollectionCell
        let serveSize = unitArray[indexPath.row]
        cell.titleLabel.text = serveSize.unit
        cell.detailLabel.text = ""
        if serveSize == selectedIngredient?.serveSize {
            unitCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
            cell.isSelected = true
            unitCollectionView.delegate?.collectionView?(unitCollectionView, didSelectItemAt: indexPath)
        }
        
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        verifyData()
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
