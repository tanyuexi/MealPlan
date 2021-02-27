//
//  ShoppingListTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class ShopFoodChain {
    let dish: Dish
    let recipe: Recipe
    let ingredient: Ingredient
    let serveSize: ServeSize
    
    init(dish: Dish, recipe: Recipe, ingredient: Ingredient, serveSize: ServeSize) {
        self.dish = dish
        self.recipe = recipe
        self.ingredient = ingredient
        self.serveSize = serveSize
    }
}

class ShopFoodCellInfo {
    let food: Food
    let quantityText: String
    let dishText: String
    var accessoryType: UITableViewCell.AccessoryType
    
    init(food: Food, quantityText: String, dishText: String, accessoryType: UITableViewCell.AccessoryType = .none) {
        self.food = food
        self.quantityText = quantityText
        self.dishText = dishText
        self.accessoryType = accessoryType
    }
}

class ItemCellInfo {
    let item: Item
    var accessoryType: UITableViewCell.AccessoryType
    
    init(item: Item, accessoryType: UITableViewCell.AccessoryType = .none) {
        self.item = item
        self.accessoryType = accessoryType
    }
}

class ShoppingListTVC: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
    
    var itemAll: [ItemCellInfo] = []
    var itemByText: [ItemCellInfo] = []
    var itemFinal: [ItemCellInfo] = []
    var foodCellInfoAll: [Int:[ShopFoodCellInfo]] = [:]
    var foodCellInfoByText: [Int:[ShopFoodCellInfo]] = [:]
    var foodCellInfoFinal: [Int:[ShopFoodCellInfo]] = [:]
    var foodgroupIndexArray: [Int] = []

    
    let searchController = UISearchController(searchResultsController: nil)
    let scopeTitles = [NSLocalizedString("All", comment: "search scope")] + S.data.foodgroupArray.map({$0.title}) as! [String] + [NSLocalizedString("Additional item", comment: "header title")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ShopFoodCell", bundle: nil), forCellReuseIdentifier: "ShopFoodCell")
        
        // Searchbar Controller
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search items"
        searchController.searchBar.sizeToFit()
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.scopeButtonTitles = scopeTitles
        searchController.searchBar.selectedScopeButtonIndex = 0
        
        var itemTemp: [Item] = []
        loadItem(to: &itemTemp)
        for i in itemTemp {
            itemAll.append(ItemCellInfo(item: i))
        }
        
        if let plan = S.data.selectedPlan {
            
            var groupFoodChain = sortChain(in: plan)
            
            //config cell info
            for section in 0..<S.data.foodgroupArray.count {
                
                let foodgroup = S.data.foodgroupArray[section]
                
                if groupFoodChain[foodgroup] == nil {
                    groupFoodChain[foodgroup] = [:]
                }
                let foodArray = groupFoodChain[foodgroup]!.keys.sorted(by: {
                    if $0.shoppingLabel == $1.shoppingLabel {
                        return $0.title! < $1.title!
                    } else {
                        return $0.shoppingLabel! < $1.shoppingLabel!
                    }
                })
                
                for food in foodArray {
                    let chainArray = groupFoodChain[foodgroup]![food]!.sorted(by: {
                        if $0.dish.day == $1.dish.day {
                            return $0.dish.meal!.order < $1.dish.meal!.order
                        } else {
                            return $0.dish.day < $1.dish.day
                        }
                    })
                    var unitChain: [String:[ShopFoodChain]] = [:]
                    for chain in chainArray {
                        if unitChain[chain.serveSize.unit!] == nil {
                            unitChain[chain.serveSize.unit!] = []
                        }
                        unitChain[chain.serveSize.unit!]!.append(chain)
                    }
                    var firstServeSize: ServeSize?
                    var serveSum: Double = 0
                    var dishTexts: [String] = []
                    for unit in unitChain.keys {
                        var titles: [String] = []
                        var quantityOfSameUnit: Double = 0

                        for chain in unitChain[unit]! {
                            titles.append(chain.recipe.title!)
                            let multifier = chain.dish.portion / chain.recipe.portion
                            let quantity = chain.ingredient.quantity * multifier
                            quantityOfSameUnit += quantity
                            if firstServeSize == nil {
                                firstServeSize = chain.serveSize
                            }
                            serveSum += quantity / chain.serveSize.quantity

                        }
                        dishTexts.append("\(limitDigits(quantityOfSameUnit)) \(unit): \(Array(Set(titles)).joined(separator: ", "))")
                    }
                    if let serveSize = firstServeSize {
                        let sum = serveSum * serveSize.quantity
                        if foodCellInfoAll[section] == nil {
                            foodCellInfoAll[section] = []
                        }
                        foodCellInfoAll[section]!.append(
                            ShopFoodCellInfo(
                                food: food,
                                quantityText: "\(limitDigits(sum))\n\(serveSize.unit!)",
                                dishText: dishTexts.joined(separator: "\n")
                            )
                        )
                    }
                }
            }
            
        } else {
            navigationController?.popViewController(animated: true)
        }
        
        foodCellInfoFinal = foodCellInfoAll
        foodgroupIndexArray = foodCellInfoFinal.keys.sorted()
        itemFinal = itemAll
    }
    
    
    func sortChain(in plan: Plan) -> [FoodGroup:[Food:[ShopFoodChain]]] {
        var groupFoodChain: [FoodGroup:[Food:[ShopFoodChain]]] = [:]
        for dish in plan.dishes?.allObjects as! [Dish] {
            let recipe = dish.recipe!
            for ingredient in dish.ingredients?.allObjects as! [Ingredient] {
                let food = ingredient.food!
                for foodgroup in S.data.foodgroupArray {
                    if let serveSize = (food.serveSizes?.allObjects as! [ServeSize]).first(where: {$0.unit == ingredient.unit && $0.foodgroup == foodgroup}) {
                        
                        let info = ShopFoodChain(dish: dish, recipe: recipe, ingredient: ingredient, serveSize: serveSize)
                        if groupFoodChain[foodgroup] == nil {
                            groupFoodChain[foodgroup] = [:]
                        }
                        if groupFoodChain[foodgroup]![food] == nil {
                            groupFoodChain[foodgroup]![food] = []
                        }
                        groupFoodChain[foodgroup]![food]!.append(info)
                    }
                }
            }
        }
        return groupFoodChain
    }
    
    //MARK: - IBActions
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        dataEntryByAlert(title: NSLocalizedString("Add item", comment: "alert"), presenter: self) { text in
            
            if text != "" {
                let item = Item(context: K.context)
                item.title = text
                self.saveContext()
                self.itemAll.append(ItemCellInfo(item: item))
                self.itemFinal = self.itemAll
                self.tableView.reloadData()
            }
        }
        
    }
    
    
    @IBAction func copyButtonPressed(_ sender: UIBarButtonItem) {
        let pasteboard = UIPasteboard.general
        
        var list = NSLocalizedString("Shopping List", comment: "export")
        list += "\n\n"
        
        //food
        for groupIndex in foodCellInfoAll.keys.sorted() {
            let group = S.data.foodgroupArray[groupIndex].title!
            list += "######  \(group)  ######\n\n"

            for chain in foodCellInfoAll[groupIndex]! {
                list += String(format: "%@ <%@> %@, %@\n",
                               chain.accessoryType == .checkmark ? "V" : "-",
                               chain.food.shoppingLabel ?? "",
                               chain.food.title ?? "",
                               chain.quantityText.replacingOccurrences(of: "\n", with: " ") )
            }
            list += "\n"
        }
        
        
        //other items
        list += "######  " + NSLocalizedString("Additional item", comment: "export") + "  ######\n\n"
        for itemInfo in itemAll {
            list += String(format: "%@ %@\n",
                           itemInfo.accessoryType == .checkmark ? "V" : "-",
                           itemInfo.item.title ?? "")
        }
        
        pasteboard.string = list
        
        notifyMessage(NSLocalizedString("Shopping list copied to clipboard", comment: "alert"))
    }
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return foodCellInfoFinal.count + 1 //other item
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0..<foodCellInfoFinal.count:
            return foodCellInfoFinal[foodgroupIndexArray[section]]?.count ?? 0
        default:
            return itemFinal.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0..<foodCellInfoFinal.count:
            return S.data.foodgroupArray[foodgroupIndexArray[section]].title
        default:
            return NSLocalizedString("Additional item", comment: "header")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0..<foodCellInfoFinal.count:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ShopFoodCell", for: indexPath) as! ShopFoodCell
            let foodgroupIndex = foodgroupIndexArray[indexPath.section]
            if let info = foodCellInfoFinal[foodgroupIndex]?[indexPath.row] {
                cell.viewController = self
                cell.onFoodUpdated(info.food)
                cell.quantityLabel.text = info.quantityText
                cell.dishLabel.text = info.dishText
                cell.accessoryType = info.accessoryType
            }
            return cell
            
        default:
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
            cell.textLabel?.text = itemFinal[indexPath.row].item.title
            cell.accessoryType = itemFinal[indexPath.row].accessoryType
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = (cell.accessoryType == .none ? .checkmark : .none)
            if indexPath.section < foodCellInfoFinal.count {
                let foodgroupIndex = foodgroupIndexArray[indexPath.section]
                foodCellInfoFinal[foodgroupIndex]![indexPath.row].accessoryType = cell.accessoryType
            } else {
                itemFinal[indexPath.row].accessoryType = cell.accessoryType
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if indexPath.section < foodCellInfoFinal.count {
            return false
        } else {
            return true
        }
    }
    
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        
        if editingStyle == .delete {
            
            askToConfirmMessage("Delete item?", confirmHandler: { action in
                let item = self.itemFinal[indexPath.row].item
                self.itemFinal.remove(at: indexPath.row)
                self.itemAll = self.itemAll.filter({$0.item != item})
                self.itemByText = self.itemByText.filter({$0.item != item})
                self.tableView.deleteRows(at: [indexPath], with: .none)
                K.context.delete(item)
                self.saveContext()
            })
    
        }
        
    }
    
    //MARK: - Search Bar
    
    func limitSearchResultToScope(_ selectedScope: Int){
        if selectedScope == 0 {
            foodCellInfoFinal = foodCellInfoByText
            itemFinal = itemByText
        } else if selectedScope <= S.data.foodgroupArray.count {
            foodCellInfoFinal = [:]
            foodCellInfoFinal[selectedScope - 1] = foodCellInfoByText[selectedScope - 1]
            itemFinal = []
        } else {
            foodCellInfoFinal = [:]
            itemFinal = itemByText
        }
        foodgroupIndexArray = foodCellInfoFinal.keys.sorted()
    }
    
    //MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchText = searchController.searchBar.text {
            
            if searchText == "" {
                foodCellInfoByText = foodCellInfoAll
                itemByText = itemAll
            } else {
                for section in foodCellInfoAll.keys {
                    foodCellInfoByText[section] = foodCellInfoAll[section]!.filter({$0.food.title!.range(of: searchText, options: .caseInsensitive) != nil })
                }
                itemByText = itemAll.filter({$0.item.title!.range(of: searchText, options: .caseInsensitive) != nil })
            }
            
            limitSearchResultToScope(searchController.searchBar.selectedScopeButtonIndex)
            tableView.reloadData()
        }
    }
    
    //MARK: - UISearchControllerDelegate
    
    func didDismissSearchController(_ searchController: UISearchController) {
        
        foodCellInfoByText = foodCellInfoAll
        itemByText = itemAll

        limitSearchResultToScope(searchController.searchBar.selectedScopeButtonIndex)
        tableView.reloadData()
    }
    
    //MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        limitSearchResultToScope(selectedScope)
        tableView.reloadData()
    }
    
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
