//
//  ChoosePersonTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/18.
//  Copyright © 2021 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData

class ChoosePersonTVC: UITableViewController {

    var personArray: [Person] = []

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadPerson(to: &personArray)
        personArray.sort(by: {
            if $0.dateOfBirth == $1.dateOfBirth {
                return $0.name! < $1.name!
            } else {
                return $0.dateOfBirth! < $1.dateOfBirth!
            }
        })
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
            return personArray.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddPersonCell", for: indexPath)
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell", for: indexPath)

            let person = personArray[indexPath.row]
            cell.textLabel?.text = String(format: "%d - %@",
                                          indexPath.row + 1,
                                          person.name!)
            cell.detailTextLabel?.text = String(
                format: "%@%@%@ %d %@",
                person.isPregnant ? "🤰": "",
                person.isBreastfeeding ? "🤱": "",
                person.needsAdditional ? "🏃": "",
                Calendar.current.dateComponents([.year], from: person.dateOfBirth!, to: Date()).year!,
                NSLocalizedString("yrs", comment: "person list")
            )
            return cell
            
        }
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "GoToEditPerson", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToEditPerson",
            let vc = segue.destination as? EditPersonTVC {
            
            if let indexPath = tableView.indexPathForSelectedRow,
                indexPath.section > 0 {
                
                vc.selectedPerson = personArray[indexPath.row]
            }
        }
    }
    

}
