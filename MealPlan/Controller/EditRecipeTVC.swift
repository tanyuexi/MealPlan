//
//  EditRecipeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class EditRecipeTVC: UITableViewController {
    
    var selectedRecipe: Recipe?
    var completionHandler: ((Recipe, String) -> Void)?
    var ingredientsByTitle: [Ingredient] = []
    var mealsButton: [UIButton] = []
    var seasons: [Season] = []
    
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var breakfastButton: UIButton!
    @IBOutlet weak var lunchButton: UIButton!
    @IBOutlet weak var dinnerButton: UIButton!
    @IBOutlet weak var morningTeaButton: UIButton!
    @IBOutlet weak var afternoonTeaButton: UIButton!
    @IBOutlet weak var peopleTextField: UITextField!
    @IBOutlet weak var ingredientCollectionView: UICollectionView!
    @IBOutlet weak var seasonLabel: UILabel!
    @IBOutlet weak var methodTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        seasonLabel.text = ""
        mealsButton = [breakfastButton, morningTeaButton, lunchButton, afternoonTeaButton, dinnerButton]
        
        ingredientCollectionView.delegate = self
        ingredientCollectionView.dataSource = self
        ingredientCollectionView.register(UINib(nibName: K.collectionCellID, bundle: nil), forCellWithReuseIdentifier: K.collectionCellID)
        
        
        if let recipe = selectedRecipe {
            loadDataToForm(recipe)
        } else {
            setBarButton(deleteButton, false)
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ingredientCollectionView.reloadData()
        seasons = Array(self.updateRecipeSeason(from: ingredientsByTitle)).sorted(by: {$0.order < $1.order})
        updateSeasonLabel()
        verifyData()
    }
    
        
    //MARK: - IBAction
    
    @IBAction func textFieldEditingDidEnd(_ sender: Any) {
        verifyData()
    }
    
    @IBAction func mealButtonPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
        verifyData()
    }
    
    @IBAction func addIngredientButtonPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "GoToEditIngredient", sender: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        let meals = NSSet(array: mealsButton.filter({$0.isSelected == true}).map({$0.tag}).map({S.dt.mealArray[$0]}))
        let seasonSet = NSSet(array: seasons)
        var operationString = ""
        
        let recipe: Recipe!
        if let r = selectedRecipe { //update
            recipe = r
            operationString = K.operationUpdate
        } else { //add
            recipe = Recipe(context: K.context)
            operationString = K.operationAdd
        }
        recipe.title = titleTextField.text
        recipe.method = methodTextView.text
        recipe.portion = Int16(peopleTextField.text!)!
        recipe.ingredients = NSSet(array: ingredientsByTitle)
        recipe.meals = meals
        recipe.seasons = seasonSet
        updateRecipeFeaturedIngredients(of: recipe)
        
        
        cleanUp()
        saveContext()
        completionHandler?(recipe, operationString)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIBarButtonItem) {
        
        if let recipe = selectedRecipe {
            askToConfirmMessage(NSLocalizedString("Delete recipe?", comment: "alert"), confirmHandler: { action in
                
                self.completionHandler?(recipe, K.operationDelete)
                K.context.delete(recipe)
                self.cleanUp()
                self.saveContext()
                self.navigationController?.popViewController(animated: true)
            })
            
        }
    }
    
    
    //MARK: - Custom functions
    
    func loadDataToForm(_ data: Recipe){
        titleTextField.text = data.title
        
        for i in data.meals?.allObjects as! [Meal] {
            mealsButton[Int(i.order)].isSelected = true
        }
        
        peopleTextField.text = String(data.portion)
        
        let ingredients = data.ingredients?.allObjects as! [Ingredient]
        ingredientsByTitle = ingredients.sorted{$0.food!.title! < $1.food!.title!}

        seasons = data.seasons?.allObjects as! [Season]
        updateSeasonLabel()

        methodTextView.text = data.method
    }
    
    func verifyData(){
        var valid = true
        confirmLabel.text = ""
        
        if titleTextField.text == "" {
            confirmLabel.text! += NSLocalizedString("Missing title. ", comment: "confirm")
            valid = false
        }
        
        if mealsButton.allSatisfy({$0.isSelected == false}) {
            confirmLabel.text! += NSLocalizedString("Missing meal. ", comment: "confirm")
            valid = false
        }
        
        if Int16(peopleTextField.text!) == nil {
            confirmLabel.text! += NSLocalizedString("Invalid number of people. ", comment: "confirm")
            valid = false
        }
        
        if valid {
            setBarButton(saveButton, true)
        } else {
            setBarButton(saveButton, false)
        }
    }
    
    func updateSeasonLabel(){
        seasonLabel.text = seasons.map({$0.title!}).joined(separator: ", ")
    }
    
    func cleanUp(){
        var ingredients: [Ingredient] = []
        loadIngredient(to: &ingredients)
        for abandoned in ingredients.filter({$0.recipe == nil}) {
            K.context.delete(abandoned)
        }
        ingredients = []
        
        var serveSizes: [ServeSize] = []
        loadServeSize(to: &serveSizes)
        for abandoned in serveSizes.filter({$0.food == nil}) {
            K.context.delete(abandoned)
        }
        serveSizes = []
    }
    
}

//MARK: - UICollectionViewDataSource

extension EditRecipeTVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return ingredientsByTitle.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = ingredientCollectionView.dequeueReusableCell(withReuseIdentifier: K.collectionCellID, for: indexPath) as! CollectionCell
        
        let ingredient = ingredientsByTitle[indexPath.row]
        cell.titleLabel.text = ingredient.food!.title
        cell.detailLabel.text = "\(limitDigits(ingredient.quantity)) \(ingredient.unit!)"
        
        return cell
    }
    
}

//MARK: - UICollectionViewDelegate

extension EditRecipeTVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "GoToEditIngredient", sender: nil)
        ingredientCollectionView.deselectItem(at: indexPath, animated: true)
    }
}



//MARK: - navigation

extension EditRecipeTVC {


     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "GoToEditIngredient",
            let vc = segue.destination as? EditIngredientTVC {

            if let selectedIndexPath = ingredientCollectionView.indexPathsForSelectedItems?.first {
                
                vc.selectedIngredient = ingredientsByTitle[selectedIndexPath.row]
            }

            vc.completionHandler = { ingredient, operationString in
                
                switch operationString {
                case K.operationDelete:
                    self.ingredientsByTitle.remove(at: self.ingredientCollectionView.indexPathsForSelectedItems!.first!.row)
                case K.operationUpdate:
                    self.ingredientsByTitle.sort{$0.food!.title! < $1.food!.title!}
                case K.operationAdd:
                    self.ingredientsByTitle.append(ingredient)
                    self.ingredientsByTitle.sort{$0.food!.title! < $1.food!.title!}
                default:
                    print("operationString: \(operationString)")
                }

            }
        }
     }
    
    


}
