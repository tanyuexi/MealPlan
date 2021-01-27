//
//  ChooseRecipeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class ChooseRecipeTVC: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    var newRecipeSelectedHandler: (() -> Void)?
    var existingRecipeSeclectedHandler: ((Recipe) -> Void)?
    
    var allRecipe: [Recipe] = []
    var filteredByText: [Recipe] = []
    var filteredFinal: [Recipe] = []
    let searchController = UISearchController(searchResultsController: nil)
    let scopeTitles = [NSLocalizedString("All", comment: "search scope")] + S.data.mealArray.map({$0.title}) as! [String]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Searchbar Controller
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search Recipes"
        searchController.searchBar.sizeToFit()
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.scopeButtonTitles = scopeTitles
        searchController.searchBar.selectedScopeButtonIndex = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadRecipe(to: &allRecipe)
        filteredByText = allRecipe
        filteredFinal = allRecipe
        tableView.reloadData()
    }

    
    //MARK: - Custom functions
    
    func limitSearchResultToScope(_ selectedScope: Int){
        if selectedScope == 0 {
            filteredFinal = filteredByText
        } else {
            filteredFinal = filteredByText.filter({
                ($0.meals?.allObjects as! [Meal]).contains(S.data.mealArray[selectedScope - 1])
            })
        }
    }
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        } else {
            return filteredFinal.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddRecipeCell", for: indexPath)
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecipeCell", for: indexPath)
            let recipe = filteredFinal[indexPath.row]
            
            cell.textLabel?.text = recipe.title
            cell.detailTextLabel?.text = "    \(recipe.seasonLabel!) \(recipe.featuredIngredients!)"
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            newRecipeSelectedHandler?()
        } else {
            existingRecipeSeclectedHandler?(filteredFinal[indexPath.row])
        }
    }

    
    //MARK: - Search Bar
    
    //MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text {
            
            if searchText == "" {
                filteredByText = allRecipe
            } else {
                let textSubpredicates = ["title", "method"].map { property in
                  NSPredicate(format: "%K CONTAINS[cd] %@", property, searchText)
                }
                let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: textSubpredicates)
                loadRecipe(to: &filteredByText, predicate: predicate)
            }
            
            limitSearchResultToScope(searchController.searchBar.selectedScopeButtonIndex)
            tableView.reloadData()
        }
    }
    
    //MARK: - UISearchControllerDelegate
    
    func didDismissSearchController(_ searchController: UISearchController) {
        
        filteredByText = allRecipe
        limitSearchResultToScope(searchController.searchBar.selectedScopeButtonIndex)
        tableView.reloadData()
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        limitSearchResultToScope(selectedScope)
        tableView.reloadData()
    }
    
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToViewRecipe",
            let vc = segue.destination as? ViewRecipeTVC,
            let indexPath = tableView.indexPathForSelectedRow {
            
            vc.selectedRecipe = filteredFinal[indexPath.row]
        }
        
    }
    
    
}
