//
//  ChooseFoodTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class ChooseFoodTVC: UITableViewController {
    
    var newFoodSelectedHandler: (() -> Void)?
    var existingFoodSeclectedHandler: ((Food) -> Void)?
    
    var foodArray: [Food] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFood(to: &foodArray)
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
            return foodArray.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddFoodCell", for: indexPath)
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath)
            let food = foodArray[indexPath.row]
            cell.textLabel?.text = food.title
            let foodGroups = (food.categories!.allObjects as! [FoodGroup]).map({$0.title!})
            cell.detailTextLabel?.text = foodGroups.joined(separator: ", ")
            
            return cell
        }
    }
    
    //MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            newFoodSelectedHandler?()
        } else {
            existingFoodSeclectedHandler?(foodArray[indexPath.row])
        }
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToEditFood",
            let vc = segue.destination as? EditFoodTVC,
            let indexPath = tableView.indexPathForSelectedRow {
            
            if indexPath.section > 0 {
                vc.selectedFood = foodArray[indexPath.row]
            }
        }
    }
    

}
