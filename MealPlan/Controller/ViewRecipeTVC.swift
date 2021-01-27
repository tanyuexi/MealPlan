//
//  ViewRecipeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class ViewRecipeTVC: UITableViewController {

    var selectedRecipe: Recipe!
    var ingredientArray: [Ingredient] = []
    var methodArray: [String] = []
    var alternativeArray: [Alternative] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadDataToForm()
    }

    //MARK: - IBAction

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "GoToEditRecipe", sender: nil)
    }
    
    
    //MARK: - Custom function
    
    func loadDataToForm(){
        ingredientArray = (selectedRecipe.ingredients?.allObjects as! [Ingredient]).sorted(by: {$0.food!.title! < $1.food!.title!})

        alternativeArray = getAlternative(from: ingredientArray)

        let method = selectedRecipe.method!.replacingOccurrences(of: "\(K.lineBreakReplaceString)\(K.lineBreakReplaceString)", with: "\n\(K.lineBreakReplaceString)")
        methodArray = method.components(separatedBy: K.lineBreakReplaceString)
    }
    
    //MARK: - TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 5
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0: //title
            return 1
        case 1: //meal
            return 1
        case 2: //portion and season
            return 1
        case 3: //ingredients
            return ingredientArray.count
        default: //method
            return methodArray.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0: //title
            return nil
        case 1: //meal
            return nil
        case 2: //portion and season
            return nil
        case 3: //ingredients
            return NSLocalizedString("Ingredients", comment: "header")
        default: //method
            return NSLocalizedString("Method", comment: "header")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0: //title
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell", for: indexPath)
            cell.textLabel?.text = selectedRecipe.title
            return cell
            
        case 1: //meal
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "MealCell", for: indexPath)
            cell.textLabel?.text = (selectedRecipe.meals?.allObjects as! [Meal]).sorted(by: {$0.order < $1.order}).map({$0.title!}).joined(separator: ", ")
            return cell
            
        case 2: //portion and season
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PortionSeasonCell", for: indexPath)
            cell.textLabel?.text = selectedRecipe.seasonLabel
            cell.detailTextLabel?.text =  "\(selectedRecipe.portion) 👤"
            cell.accessoryType = .none
            return cell
            
        case 3: //ingredients
            
            let i = ingredientArray[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
            cell.textLabel?.text = "\(limitDigits(i.quantity)) \(i.unit!)"
            if i.optional {
                cell.detailTextLabel?.text = "*" + i.food!.title!
            } else {
                cell.detailTextLabel?.text = i.food!.title
            }
            if i.alternative != nil,
                let alternativeIndex = alternativeArray.firstIndex(of: i.alternative!) {

                cell.backgroundColor = K.cellBackgroundColors[alternativeIndex % 10]
            } else {
                cell.backgroundColor = UIColor.clear
            }
            return cell
            
        default: //method
            
            let method = methodArray[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "MethodCell", for: indexPath)
            cell.textLabel?.text = method
            return cell
        
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section >= 3,  //ingredient and method
            let cell = tableView.cellForRow(at: indexPath) {
            
            cell.accessoryType = (cell.accessoryType == .none ? .checkmark : .none)
        }
            
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
  
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToEditRecipe",
            let vc = segue.destination as? EditRecipeTVC {
            
            vc.selectedRecipe = selectedRecipe
            vc.completionHandler = { recipe, operationString in
                
                switch operationString {
                case K.operationDelete:
                    self.navigationController?.popViewController(animated: true)
                default:
                    self.loadDataToForm()
                }
            }
        }
    }
    

}
