//
//  ChooseFoodTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class ChooseFoodTVC: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    var newFoodSelectedHandler: (() -> Void)?
    var existingFoodSeclectedHandler: ((Food) -> Void)?
    
    var allFood: [Food] = []
    var filteredByText: [Food] = []
    var filteredFinal: [Food] = []
    let searchController = UISearchController(searchResultsController: nil)
    let scopeTitles = [NSLocalizedString("All", comment: "search scope")] + S.data.foodgroupArray.map({$0.title}) as! [String]


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
        loadFood(to: &allFood)
        filteredByText = allFood
        filteredFinal = allFood
        tableView.reloadData()
    }
    
    
    //MARK: - Custom functions
    
    func limitSearchResultToScope(_ selectedScope: Int){
        if selectedScope == 0 {
            filteredFinal = filteredByText
        } else {
            filteredFinal = filteredByText.filter({
                ($0.serveSizes?.allObjects as! [ServeSize]).map({$0.foodgroup!.title!}).contains(scopeTitles[selectedScope])
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddFoodCell", for: indexPath)
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath)
            let food = filteredFinal[indexPath.row]
            cell.textLabel?.text = food.title
            cell.detailTextLabel?.text = "    \(food.seasonLabel ?? "") \(food.foodgroupLabel ?? "")"
            
            return cell
        }
    }
    
    //MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            newFoodSelectedHandler?()
        } else {
            existingFoodSeclectedHandler?(filteredFinal[indexPath.row])
        }
    }
    
    
    //MARK: - Search Bar
    
    //MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text {
            
            if searchText == "" {
                filteredByText = allFood
            } else {
                loadFood(to: &filteredByText, predicate: NSPredicate(format: "title CONTAINS[cd] %@", searchText))
            }
            
            limitSearchResultToScope(searchController.searchBar.selectedScopeButtonIndex)
            tableView.reloadData()
        }
    }
    
    //MARK: - UISearchControllerDelegate
    
    func didDismissSearchController(_ searchController: UISearchController) {
        
        filteredByText = allFood
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
        
        if segue.identifier == "GoToEditFood",
            let vc = segue.destination as? EditFoodTVC,
            let indexPath = tableView.indexPathForSelectedRow {
            
            if indexPath.section > 0 {
                vc.selectedFood = filteredFinal[indexPath.row]
            }
        }
    }
    

}
