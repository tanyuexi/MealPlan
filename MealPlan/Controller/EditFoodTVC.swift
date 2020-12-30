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
    @IBOutlet weak var confirmLabel: UILabel!
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
        verifyData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        verifyData()
        onServeSizeUpdated()
    }
    
    //MARK: - IBAction
    
    @IBAction func quickFillButtonPressed(_ sender: UIButton) {
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        verifyData()
    }
    
    @IBAction func seasonButtonPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
        verifyData()
    }
    
    @IBAction func addServeSizeButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "GoToEditServeSize", sender: nil)
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        let seasons = NSSet(array: seasonButtons.filter({$0.isSelected}).map({$0.tag}).map({S.dt.seasonArray[$0]}))
        var operationString = ""

        let food: Food!
        
        if selectedFood == nil {
            food = Food(context: K.context)
            food.seasons = seasons
            food.title = titleTextField.text
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
        cell.titleLabel.text = serveSize.unit! + " (\(serveSize.foodGroup!.title!))"
        cell.detailLabel.text = limitDigits(serveSize.quantity)
        
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
    
    func verifyData(){
        var valid = true
        confirmLabel.text = ""
        
        if titleTextField.text == "" {
            confirmLabel.text! += NSLocalizedString("Missing title. ", comment: "confirm")
            valid = false
        }
        
        if serveSizeArray.count == 0 {
            confirmLabel.text! += NSLocalizedString("Missing serve size(s). ", comment: "confirm")
            valid = false
        }
        
            if seasonButtons.allSatisfy({$0.isSelected == false}) {
                confirmLabel.text! += NSLocalizedString("Missing season(s). ", comment: "confirm")
                valid = false
            }
            
            saveButton.isEnabled = valid
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
                    self.serveSizeArray.remove(at: self.serveSizeCollectionView.indexPathsForSelectedItems!.first!.row)
                case K.operationAdd:
                    self.serveSizeArray.append(serveSize)
                    self.serveSizeArray.sort{$0.unit! < $1.unit!}
                case K.operationUpdate:
                    self.serveSizeArray.sort{$0.unit! < $1.unit!}
                default:
                    print(operationString)
                }
            }
        }
    }
    
}


