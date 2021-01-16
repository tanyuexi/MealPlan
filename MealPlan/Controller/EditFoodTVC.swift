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
    
    var seasonButtons: [UIButton] = []
    var serveSizeArray: [ServeSize] = []
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var quickFillButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var springButton: UIButton!
    @IBOutlet weak var summerButton: UIButton!
    @IBOutlet weak var autumnButton: UIButton!
    @IBOutlet weak var winterButton: UIButton!
    @IBOutlet weak var serveSizeCollectionView: UICollectionView!
    @IBOutlet weak var foodGroupLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serveSizeCollectionView.delegate = self
        serveSizeCollectionView.dataSource = self
        serveSizeCollectionView.register(UINib(nibName: K.collectionCellID, bundle: nil), forCellWithReuseIdentifier: K.collectionCellID)
        
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
    }
    
    
    //MARK: - IBAction
    
    @IBAction func quickFillButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "GoToChooseFood", sender: nil)
    }
    
    
    @IBAction func seasonButtonPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction func addServeSizeButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "GoToEditServeSize", sender: nil)
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        if let errorMessage = entryError() {
            notifyMessage(errorMessage)
            return
        }
        
        let seasons = NSSet(array: seasonButtons.filter({$0.isSelected}).map({$0.tag}).map({S.dt.seasonArray[$0]}))
        var operationString = ""
        
        let food = (selectedFood == nil) ? Food(context: K.context) : selectedFood!
        
        //modify title if same food exists
        var foodOfSameTitle: [Food] = []
        loadFood(to: &foodOfSameTitle, predicate: NSPredicate(format: "title MATCHES[cd] %@", titleTextField.text!))
        foodOfSameTitle = foodOfSameTitle.filter({$0 != food})
        if foodOfSameTitle.count > 0 {
            titleTextField.text! += " - \(foodOfSameTitle.count + 1)"
        }
        
        if selectedFood == nil {
            food.seasons = seasons
            food.seasonLabel = getSeasonIcon(from: (seasons.allObjects as! [Season]))
            food.title = titleTextField.text
            operationString = K.operationAdd
        } else {
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
                
                food.seasons = seasons
                food.seasonLabel = getSeasonIcon(from: (seasons.allObjects as! [Season]))
                saveContext()
                for i in food.ingredients?.allObjects as! [Ingredient] {
                    if let recipe = i.recipe {
                        updateRecipeSeason(of: recipe)
                    }
                }
            }
            
        }
        
        food.serveSizes = NSSet(array: serveSizeArray)
        food.foodGroupLabel = foodGroupLabel.text
        
        saveContext()
        completionHandler?(food, operationString)
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
        cell.titleLabel.text = serveSize.unit! + " (\(serveSize.foodGroup!.title!))"
        cell.detailLabel.text = limitDigits(serveSize.quantity)
        cell.isSelected = false
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "GoToEditServeSize", sender: nil)
        serveSizeCollectionView.deselectItem(at: indexPath, animated: true)
    }
    
    //MARK: - Custom functions

    
    func loadDataToForm(_ data: Food){
        titleTextField.text = data.title
        for i in data.seasons!.allObjects as! [Season] {
            seasonButtons[Int(i.order)].isSelected = true
        }
        serveSizeArray = data.serveSizes?.allObjects as! [ServeSize]
        serveSizeArray.sort{$0.unit! < $1.unit!}
        onServeSizeUpdated()
    }
    
    
    
    func onServeSizeUpdated(){
        serveSizeCollectionView.reloadData()
        foodGroupLabel.text = getFoodGroupInfo(from: serveSizeArray)
    }
    
//    func verifyData(){
//        var valid = true
//        confirmLabel.text = ""
//
//        if titleTextField.text == "" {
//            confirmLabel.text! += NSLocalizedString("Missing title. ", comment: "confirm")
//            valid = false
//        }
//
//        if serveSizeArray.count == 0 {
//            confirmLabel.text! += NSLocalizedString("Missing serve size(s). ", comment: "confirm")
//            valid = false
//        }
//
//        if seasonButtons.allSatisfy({$0.isSelected == false}) {
//            confirmLabel.text! += NSLocalizedString("Missing season(s). ", comment: "confirm")
//            valid = false
//        }
//
//        saveButton.isEnabled = valid
//    }
    
    
    
    func entryError() -> String? {
        
        var message = ""
        
        if titleTextField.text == "" {
            message += NSLocalizedString("Missing title. ", comment: "alert")
        }
        
        if serveSizeArray.count == 0 {
            message += NSLocalizedString("Missing serve size. ", comment: "alert")
        }
        
        if seasonButtons.allSatisfy({$0.isSelected == false}) {
            message += NSLocalizedString("Missing season. ", comment: "alert")
        }
        
        return (message == "" ? nil : message)
        
    }
    
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToEditServeSize",
            let vc = segue.destination as? EditServeSizeTVC {
            
            if let indexPath = serveSizeCollectionView.indexPathsForSelectedItems?.first {
                vc.selectedServeSize = serveSizeArray[indexPath.row]
            }
            vc.completionHandler = {serveSize, operationString in
                switch operationString {
                case K.operationDelete:
                    self.serveSizeArray.removeAll(where: {$0 == serveSize})
//                    self.serveSizeArray.remove(at: self.serveSizeArray.firstIndex(of: serveSize)!)
                case K.operationAdd:
                    self.serveSizeArray.append(serveSize)
                    self.serveSizeArray.sort{$0.unit! < $1.unit!}
                case K.operationUpdate:
                    self.serveSizeArray.sort{$0.unit! < $1.unit!}
                default:
                    print(operationString)
                }
                self.onServeSizeUpdated()
            }
        } else if segue.identifier == "GoToChooseFood",
            let vc = segue.destination as? ChooseFoodTVC {
            vc.newFoodSelectedHandler = {
                vc.notifyMessage(NSLocalizedString("Please choose an existing food.", comment: "alert"))
            }
            vc.existingFoodSeclectedHandler = { food in
                self.titleTextField.text = food.title! + " - 2"
                for i in food.seasons!.allObjects as! [Season] {
                    self.seasonButtons[Int(i.order)].isSelected = true
                }
                self.serveSizeArray = (food.serveSizes?.allObjects as! [ServeSize]).map({self.deepCopy(from: $0)})
                self.serveSizeArray.sort{$0.unit! < $1.unit!}
                self.onServeSizeUpdated()
                vc.navigationController?.popViewController(animated: true)
            }
        }
    }
    
}



