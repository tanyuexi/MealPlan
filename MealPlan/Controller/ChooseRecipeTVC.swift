//
//  ChooseRecipeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class ChooseRecipeTVC: UITableViewController {
    
    var recipeArray: [Recipe] = []

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecipe(to: &recipeArray)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        } else {
            return recipeArray.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddRecipeCell", for: indexPath)
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
            let recipe = recipeArray[indexPath.row]
            
            cell.textLabel?.text = recipe.title
            cell.detailTextLabel?.text = recipe.featuredIngredients
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            performSegue(withIdentifier: "GoToEditRecipe", sender: self)
        } else {
            performSegue(withIdentifier: "GoToViewRecipe", sender: self)
        }
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToViewRecipe",
            let vc = segue.destination as? ViewRecipeTVC,
        let indexPath = tableView.indexPathForSelectedRow {
            
            vc.selectedRecipe = recipeArray[indexPath.row]
        }
        
    }
    

}
