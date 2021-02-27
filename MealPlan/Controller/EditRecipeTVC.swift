//
//  EditRecipeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class EditRecipeTVC: UITableViewController, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    var selectedRecipe: Recipe?
    var completionHandler: ((Recipe, String) -> Void)?
    var ingredientsByTitle: [Ingredient] = []
    var mealsButton: [UIButton] = []
    var seasons: Set<Season> = Set()
    var alternativeArray: [Alternative] = []
    var methodLink = ""
    var methodImageFile = ""
    var methodImage: UIImage?
    
    var imagePicker = UIImagePickerController()

    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var breakfastButton: UIButton!
    @IBOutlet weak var lunchButton: UIButton!
    @IBOutlet weak var dinnerButton: UIButton!
    @IBOutlet weak var morningTeaButton: UIButton!
    @IBOutlet weak var afternoonTeaButton: UIButton!
    @IBOutlet weak var peopleTextField: UITextField!
    @IBOutlet weak var ingredientCollectionView: UICollectionView!
    @IBOutlet weak var seasonLabel: UILabel!
    @IBOutlet weak var methodLinkButton: UIButton!
    @IBOutlet weak var methodImageButton: UIButton!
    @IBOutlet weak var methodTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        seasonLabel.text = ""
        mealsButton = [breakfastButton, morningTeaButton, lunchButton, afternoonTeaButton, dinnerButton]
        
        ingredientCollectionView.delegate = self
        ingredientCollectionView.dataSource = self
        ingredientCollectionView.register(UINib(nibName: K.collectionCellID, bundle: nil), forCellWithReuseIdentifier: K.collectionCellID)
        
        imagePicker.delegate = self
        
        if let recipe = selectedRecipe {
            loadDataToForm(recipe)
            if (S.data.selectedPlan?.dishes?.allObjects as! [Dish]).compactMap({$0.recipe}).contains(recipe) {
                deleteButton.isEnabled = false
            } else {
                deleteButton.isEnabled = true
            }
        } else {
            deleteButton.isEnabled = false
        }
    }
    
    
    
    //MARK: - Custom functions
    
    func loadDataToForm(_ data: Recipe){
        titleTextField.text = data.title
        
        for i in data.meals?.allObjects as! [Meal] {
            mealsButton[Int(i.order)].isSelected = true
        }
        
        peopleTextField.text = limitDigits(data.portion)
        
        let ingredients = data.ingredients?.allObjects as! [Ingredient]
        ingredientsByTitle = ingredients.sorted{$0.food!.title! < $1.food!.title!}
        onIngredientUpdated()
        
        methodTextView.text = convertMultiLineToDisplay(from: data.method!)
        setMethodLink(data.methodLink)
        loadMethodImage(fileName: data.methodImage)
    }
    
    
    func onIngredientUpdated(){
        alternativeArray = getAlternative(from: ingredientsByTitle)

//        print("alternativeArray: \(alternativeArray.count)")
//        print(alternativeArray.compactMap({($0.ingredients?.allObjects as! [Ingredient]).compactMap({$0.food!.title!}).joined(separator: ",")}))
        
        seasons = updateRecipeSeason(ingredients: ingredientsByTitle, alternatives: alternativeArray)
        seasonLabel.text = getSeasonIcon(from: Array(seasons))
        ingredientCollectionView.reloadData()
    }
    
    
    
    func entryError() -> String? {
        var message = ""
        
        if titleTextField.text == "" {
            message += NSLocalizedString("Missing title. ", comment: "alert")
        }
        
        if mealsButton.allSatisfy({$0.isSelected == false}) {
            message += NSLocalizedString("Missing meal. ", comment: "alert")
        }
        
        if Double(peopleTextField.text!) == nil {
            message += NSLocalizedString("Invalid number of people. ", comment: "alert")
        }
        
        return (message == "" ? nil : message)
    }
    
    
    func choosePhoto(_ type: UIImagePickerController.SourceType){

        if UIImagePickerController.isSourceTypeAvailable(type){

            imagePicker.sourceType = type
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func setMethodLink(_ link: String?){
        if link == nil {
            methodLink = ""
            methodLinkButton.setTitle("", for: .normal)
        } else {
            methodLink = link!
            methodLinkButton.setTitle(link, for: .normal)
        }
    }
    
    
    func loadMethodImage(fileName: String?){

        if let imgUrl = getFilePath(fileName),
            let image = UIImage(contentsOfFile: imgUrl.path),
            fileName != "" {
            
            methodImageFile = fileName!
            methodImage = image
            let smallImage = scaleImage(image, within: methodImageButton.imageView!.bounds)
            methodImageButton.setImage(smallImage, for: .normal)
            
        } else {
            
            methodImageButton.setImage(UIImage(systemName: "photo"), for: .normal)
            methodImage = nil
            methodImageFile = ""
        }
    }
        
    
    //MARK: - IBAction
    
    @IBAction func quickFillButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "GoToChooseRecipe", sender: nil)
    }
    
    
    @IBAction func mealButtonPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction func methodLinkButtonPressed(_ sender: UIButton) {
        
        dataEntryByAlert(title: NSLocalizedString("Add link to method", comment: "alert"), preloadText: (selectedRecipe == nil ? "" : selectedRecipe!.methodLink!), placeHolder: "http(s)://", keyboardType: .URL, presenter: self) { text in
            
            self.setMethodLink(text)
        }
    }
    
    
    @IBAction func methodImageButtonPressed(_ sender: UIButton) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Take a photo", comment: "image picker"), style: .default, handler: {action in self.choosePhoto(.camera)}))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Choose from Library", comment: "image picker"), style: .default, handler: {action in self.choosePhoto(.photoLibrary)}))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "image picker"), style: .destructive, handler: {action in self.loadMethodImage(fileName: nil) }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "image picker"), style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func addIngredientButtonPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "GoToEditIngredient", sender: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        if let errorMessage = entryError() {
            notifyMessage(errorMessage)
            return
        }
        
        let meals = NSSet(array: mealsButton.filter({$0.isSelected == true}).map({$0.tag}).map({S.data.mealArray[$0]}))
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
        recipe.method = convertMultiLineToData(from: methodTextView.text)
        recipe.methodLink = methodLink
        if let imgUrl = getFilePath(methodImageFile),
            let data = methodImage?.pngData() {

            do {
                try data.write(to: imgUrl)
            } catch {
                print("Error saving image \(error)")
            }
            recipe.methodImage = methodImageFile
        } else {
            recipe.methodImage = ""
        }

        
        recipe.portion = Double(peopleTextField.text!)!
        recipe.ingredients = NSSet(array: ingredientsByTitle)
        recipe.alternatives = NSSet(array: alternativeArray)
        recipe.meals = meals
        recipe.seasons = NSSet(set: seasons)
        recipe.seasonLabel = seasonLabel.text
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
    
    

//MARK: - UICollectionViewDataSource

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return ingredientsByTitle.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = ingredientCollectionView.dequeueReusableCell(withReuseIdentifier: K.collectionCellID, for: indexPath) as! CollectionCell
        
        let ingredient = ingredientsByTitle[indexPath.row]
        if ingredient.isOptional {
            cell.titleLabel.text = "*" + ingredient.food!.title!
        } else {
            cell.titleLabel.text = ingredient.food!.title
        }
        cell.detailLabel.text = "\(limitDigits(ingredient.quantity)) \(ingredient.unit!)"
        
        if ingredient.alternative != nil,
            let alternativeIndex = alternativeArray.firstIndex(of: ingredient.alternative!) {

            cell.bgViewColor = K.cellBackgroundColors[alternativeIndex % 10]
        } else {
            cell.bgViewColor = UIColor.clear
        }
        cell.isSelected = false
        return cell
    }
    

//MARK: - UICollectionViewDelegate

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "GoToEditIngredient", sender: nil)
        ingredientCollectionView.deselectItem(at: indexPath, animated: true)
    }

    
    //MARK: - Image picker
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {

            methodImageFile = "\(K.methodImagePrefix)\(Date().timeIntervalSince1970).png"
            methodImage = pickedImage

            let smallImage = scaleImage(pickedImage, within: methodImageButton.imageView!.bounds)
            methodImageButton.setImage(smallImage, for: .normal)
            
            print(methodImageFile)
        }

        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    

//MARK: - navigation
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToChooseRecipe",
            let vc = segue.destination as? ChooseRecipeTVC {
            
            vc.newRecipeSelectedHandler = {
                vc.notifyMessage(NSLocalizedString("Please choose an existing recipe.", comment: "alert"))
            }
            vc.existingRecipeSeclectedHandler = { recipe in
                self.titleTextField.text = recipe.title! + " - 2"
                
                for i in recipe.meals?.allObjects as! [Meal] {
                    self.mealsButton[Int(i.order)].isSelected = true
                }
                
                self.peopleTextField.text = String(recipe.portion)
                
                let ingredients = (recipe.ingredients?.allObjects as! [Ingredient]).map({self.deepCopy(from: $0)})
                self.ingredientsByTitle = ingredients.sorted{$0.food!.title! < $1.food!.title!}
                self.onIngredientUpdated()
                self.methodTextView.text = recipe.method!.replacingOccurrences(of: "<br>", with: "\n")
                vc.navigationController?.popViewController(animated: true)
            }
            
            
        } else if segue.identifier == "GoToEditIngredient",
            let vc = segue.destination as? EditIngredientTVC {
            
            vc.addedIngredients = ingredientsByTitle
            
            if let selectedIndexPath = ingredientCollectionView.indexPathsForSelectedItems?.first {
                
                vc.selectedIngredient = ingredientsByTitle[selectedIndexPath.row]
            }
            
            vc.completionHandler = { ingredient, operationString in
                
                switch operationString {
                case K.operationDelete:
                    self.ingredientsByTitle.removeAll(where: {$0 == ingredient})
                case K.operationUpdate:
                    self.ingredientsByTitle.sort{$0.food!.title! < $1.food!.title!}
                case K.operationAdd:
                    self.ingredientsByTitle.append(ingredient)
                    self.ingredientsByTitle.sort{$0.food!.title! < $1.food!.title!}
                default:
                    print("operationString: \(operationString)")
                }
                self.onIngredientUpdated()
            }
        }
    }
    

    
}
