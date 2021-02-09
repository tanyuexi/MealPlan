//
//  ChoosePlanTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/29.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit

class ChoosePlanTVC: UITableViewController {
    
    var onCellSelected: ((Plan) -> Void)?
    
    var planArray: [Plan] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        loadPlan(to: &planArray)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return planArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlanCell", for: indexPath)

        cell.textLabel?.text = planArray[indexPath.row].title

        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        onCellSelected?(planArray[indexPath.row])
        navigationController?.popViewController(animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        
        if editingStyle == .delete {
            
            askToConfirmMessage("Delete plan?", confirmHandler: { action in
                let plan = self.planArray[indexPath.row]
                if plan == S.data.selectedPlan {
                    S.data.selectedPlan = nil
                }
                self.planArray.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .none)
                K.context.delete(plan)
                self.saveContext()
            })
            
            
        }
        
    }

    
//    // MARK: - Navigation
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        if segue.identifier == "GoToMealPlan" {
//
//        }
//
//    }
    

}
