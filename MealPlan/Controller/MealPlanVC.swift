//
//  MealPlanVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2021/1/29.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds


class MealPlanVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, GADBannerViewDelegate {
    
    
    var dishArray: [Dish] = []
    var editMode = false
    
    var personArray: [Person] = []
    var dailyTotal: [String:Double] = [:]
    var serveSum: [String:Double] = [:]
    var estimatedPortions: Double = 0
    
    let warningColor = UIColor.systemRed
    
    // Google AdMob
    var bannerView: GADBannerView!
    
    
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var calculatorCollectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(getFilePath(directory: true)!)
        
        S.data.dateFormatter.dateFormat = NSLocalizedString("dd/MM/yyyy", comment: "date format")
        S.data.weekdayFormatter.dateFormat = NSLocalizedString("d MMMM (EEEE)", comment: "date format")
                
        initDatabase()
        
        var foodArray: [Food] = []
        loadFood(to: &foodArray)
        if foodArray.count == 0 {
            importDemoDatabase()
        }
        foodArray = []

        tableView.register(UINib(nibName: "DishCell", bundle: nil), forCellReuseIdentifier: "DishCell")
        
        calculatorCollectionView.delegate = self
        calculatorCollectionView.dataSource = self
        calculatorCollectionView.register(UINib(nibName: "CalculatorCell", bundle: nil), forCellWithReuseIdentifier: "CalculatorCell")
        
        // Google AdMob
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.adUnitID = K.debugMode ? K.adUnitIDTest : K.adUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        bannerView.delegate = self
        addBannerView(bannerView, to: adView)
//        tableView.tableHeaderView?.frame = bannerView.frame
//        tableView.tableHeaderView = bannerView
        
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        onPersonUpdated()
        
        onPlanUpdated()
        
    }
    
    
    //MARK: - Custom functions
    
    func addBannerView(_ bannerView: GADBannerView, to view: UIView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .centerY,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerY,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
        ])
    }
    
    func getSeasonOfToday() -> Season {
        var seasonIndex = 0
        
        // get season
        let todayComponents = Calendar(identifier: .gregorian).dateComponents([.month, .day], from: Date())
        let dateCode = todayComponents.month! * 100 + todayComponents.day!
        switch dateCode {
        case 0..<321:  // up to 20 March: north winter, south summer
            seasonIndex = S.data.northHemisphere ? 3 : 1
        case 321..<621:  // north spring, south autumn
            seasonIndex = S.data.northHemisphere ? 0 : 2
        case 621..<921:  // north summer, south winter
            seasonIndex = S.data.northHemisphere ? 1 : 3
        case 921..<1221: // north autumn, south spring
            seasonIndex = S.data.northHemisphere ? 2 : 0
        default:     // north winter, south summer
            seasonIndex = S.data.northHemisphere ? 3 : 1
        }
        
        return S.data.seasonArray[seasonIndex]
    }
    
    func createDish(from recipe: Recipe, season: Season, preferredFoodGroup: FoodGroup? = nil) -> Dish {
        let dish = Dish(context: K.context)
        let oldPlans = dish.plans?.allObjects as! [Plan]
        dish.plans = NSSet(array: oldPlans + [S.data.selectedPlan!])
        dish.recipe = recipe
        dish.portion = estimatedPortions
        var selectedIngredients = (recipe.ingredients?.allObjects as! [Ingredient]).filter({$0.alternative == nil})
        
        if let alters = recipe.alternatives {
            for alt in alters.allObjects as! [Alternative] {
                var ingredients = (alt.ingredients?.allObjects as! [Ingredient]).filter({
                    ($0.food?.seasons?.allObjects as! [Season]).contains(season)
                })
                
                if preferredFoodGroup != nil,
                    let foodgroupTitle = preferredFoodGroup!.title {
                    let preferredIngredients = ingredients.filter({ ingredient in
                        ingredient.food?.foodgroupLabel?.contains(foodgroupTitle) ?? false
                    })
                    if preferredIngredients.count > 0 {
                        ingredients = preferredIngredients
                    }
                }
                
                if let randomIngredient = ingredients.randomElement() {
                    selectedIngredients.append(randomIngredient)
                }
            }
        }
        
        dish.ingredients = NSSet(array: selectedIngredients)
        
        return dish
    }
    
    
    func ingredientFoodgroupIndice(_ ingredients: [Ingredient]) -> [Int16] {
        // only look at healthy 5 food groups
        let foodgroupIndice = ingredients.compactMap({$0.food}).flatMap({$0.serveSizes?.allObjects as! [ServeSize]}).compactMap({$0.foodgroup?.order}).filter({$0 < 5})
        return Array(Set(foodgroupIndice))
    }
    
    
    func filterRecipeByFoodGroup(_ recipes: [Recipe], meal: Meal) -> [Recipe] {
        return recipes.filter({ recipe in
            
            let foodgroupIndexArray = ingredientFoodgroupIndice(recipe.ingredients?.allObjects as! [Ingredient])
            
            /* foodgroup index:
            0    Vegetable    蔬菜
            1    Fruit    水果
            2    Protein    蛋白质
            3    Grain    谷物
            4    Calcium    钙质
            5    Oil    油脂
            6    Other    其他
            */
            switch meal.order {
            case 0: //breakfast must have grains
                return [3].allSatisfy({foodgroupIndexArray.contains($0)})
            case 2: //lunch must have vegetable, protein
                return [0,2].allSatisfy({foodgroupIndexArray.contains($0)})
            case 4: //dinner must have vegetable, protein
                return [0,2].allSatisfy({foodgroupIndexArray.contains($0)})
            default:
                return true
            }
        })
    }
    
    
    func getRecipeCandidates(with foods: [Food], season: Season, meal: Meal) -> [Recipe] {
        
        var recipeCandidates: [Recipe] = []
        let mealPredicate = NSPredicate(format: "ANY meals == %@", meal)
        let seasonPredicate = NSPredicate(format: "ANY seasons == %@", season)
        let mealSeasonPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mealPredicate, seasonPredicate])
        
        //load recipes of the meal & season
        if foods.count == 0 {
            loadRecipe(to: &recipeCandidates, predicate: mealSeasonPredicate)
        } else {

            let foodPredicate = NSPredicate(format: "ANY ingredients.food IN %@", foods)
            let foodMealSeasonPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [foodPredicate, mealPredicate, seasonPredicate])
            loadRecipe(to: &recipeCandidates, predicate: foodMealSeasonPredicate)
            if recipeCandidates.count == 0 {
                loadRecipe(to: &recipeCandidates, predicate: mealSeasonPredicate)
            }
        }
        
        recipeCandidates = filterRecipeByFoodGroup(recipeCandidates, meal: meal)
        
        return recipeCandidates
    }
    
//    func complexity(of recipe: Recipe) -> Int {
//        let alternatives = (recipe.alternatives?.allObjects as! [Alternative]).count
//        let essentialIngredients = (recipe.ingredients?.allObjects as! [Ingredient]).filter({$0.isOptional == false && $0.alternative == nil})
//        let essentialFoodgroups = ingredientFoodgroupIndice(essentialIngredients).count
//        return alternatives + essentialFoodgroups
//    }
//
//
//    func addSideDishIfUnbalanced(season: Season){
//        var recipeInSeason: [Recipe] = []
//        loadRecipe(to: &recipeInSeason, predicate: NSPredicate(format: "ANY seasons == %@", season))
//
//        for day in 0..<Int(S.data.days) {
//
//            //check if diet unbalanced. Add side dish for less-than-target food group
//            for foodgroup in S.data.foodgroupArray.prefix(5) {
//                var dishesOfDay = (S.data.selectedPlan?.dishes?.allObjects as! [Dish]).filter({$0.day == day})
//                let oneDayServeSum = calculateServeSum(from: dishesOfDay)
//                if let currentSum = oneDayServeSum[foodgroup.title!],
//                    let targetSum = dailyTotal[foodgroup.title!],
//                    currentSum < targetSum * 0.8,
//                    let foodgroupIndex = S.data.foodgroupArray.firstIndex(of: foodgroup) {
//
//                    var sideRecipeCandidates = recipeInSeason.filter({ recipe in
//                        let indexArray = self.ingredientFoodgroupIndice(recipe.ingredients?.allObjects as! [Ingredient])
//                        return indexArray.contains(Int16(foodgroupIndex))
//                    })
//
//                    sideRecipeCandidates.sort(by: {
//                        self.complexity(of: $0) < self.complexity(of: $1)
//                    })
//                    sideRecipeCandidates = sideRecipeCandidates.prefix(5).shuffled()
//
//                    for randomRecipe in sideRecipeCandidates {
//
//                        let dish = createDish(from: randomRecipe, season: season, preferredFoodGroup: foodgroup)
//                        dish.day = Int16(day)
//                        dish.meal = (randomRecipe.meals?.allObjects as! [Meal]).randomElement()
//
//                        print("foodgroup: \(foodgroup.title!)")
//                        if dishesOfDay.contains(where: {$0.ingredients == dish.ingredients}) {
//                            print("delete day: \(day) dish: \(dish.recipe!.title!)")
//                            K.context.delete(dish)
//                        } else {
//                            print("save   day: \(day) dish: \(dish.recipe!.title!)")
//                            dishesOfDay = (S.data.selectedPlan?.dishes?.allObjects as! [Dish]).filter({$0.day == day})
//                            break
//                        }
//                    }
//
//                    saveContext()
//                }
//            }
//        }
//    }
    
    
    func autoGeneratePlan(with foods: [Food] = []) -> String {
        
        S.data.selectedPlan?.dishes = nil
        
        let seasonOfToday = getSeasonOfToday()
        
        for meal in S.data.mealArray {
            
            let recipeCandidates = getRecipeCandidates(with: foods, season: seasonOfToday, meal: meal)
            
            for day in 0..<Int(S.data.days) {
                
                if let randomRecipe = recipeCandidates.randomElement() {
                    
                    let dish = createDish(from: randomRecipe, season: seasonOfToday)
                    dish.day = Int16(day)
                    dish.meal = meal
                    saveContext()
                }
            }
        }
        
//        addSideDishIfUnbalanced(season: seasonOfToday)
//
//        onPlanUpdated()
//
//        normalizePortions()

        onPlanUpdated()
        
        saveContext()
        
        return seasonOfToday.title!
    }

    
//    func normalizePortions(){
//        // normalize portions by protein target serves
//        let foodgroup = S.data.foodgroupArray[2].title!  //protein
//        let multiplier = dailyTotal[foodgroup]! * S.data.days / serveSum[foodgroup]!
//        if let dishes = S.data.selectedPlan?.dishes?.allObjects as? [Dish] {
//            for dish in dishes {
//                if [0, 2, 4].contains(dish.meal?.order) {  //breakfast, lunch, dinner
//                    dish.portion = roundToHalf(dish.portion * multiplier)
//                }
//            }
//        }
//    }
    
    
    func onPersonUpdated(){
        loadPerson(to: &personArray)
        estimatedPortions = 0
        for person in personArray {
            if Calendar(identifier: .gregorian).dateComponents([.year], from: person.dateOfBirth!, to: Date()).year! < 9 {
                estimatedPortions += 0.5
            } else {
                estimatedPortions += 1
            }
        }
        headerLabel.text = String(
            format: "%@ %d %@",
            NSLocalizedString("Recommended serves for", comment: "header"),
            personArray.count,
            NSLocalizedString("person(s)", comment: "header")
        )
        calculateDailyTotalServes(from: personArray, to: &dailyTotal)
    }
    
    func onPlanUpdated() {
        
        if S.data.selectedPlan == nil {
            var plans: [Plan] = []
            loadPlan(to: &plans, predicate: NSPredicate(format: "title == %@", NSLocalizedString("[Current Plan]", comment: "plan")))
            if plans.first == nil {
                let newPlan = Plan(context: K.context)
                newPlan.title = "[Current Plan]"
                S.data.selectedPlan = newPlan
            } else {
                S.data.selectedPlan = plans.first
            }
        }
        
        dishArray = (S.data.selectedPlan!.dishes?.allObjects as! [Dish]).sorted(by: {
            if $0.day == $1.day {
                if $0.meal!.order == $1.meal!.order {
                    return $0.recipe!.title! < $1.recipe!.title!
                } else {
                    return $0.meal!.order < $1.meal!.order
                }
            } else {
                return $0.day < $1.day
            }
        })
        onDishUpdated()
    }
    
    
    func onDishUpdated(){
        
        serveSum = calculateServeSum(from: dishArray)
        
        tableView.reloadData()
        calculatorCollectionView.reloadData()
    }
    
    
    func calculateServeSum(from dishes: [Dish]) -> [String:Double]{
        var result: [String:Double] = [:]
        
        for dish in dishes {
            let multiplier = dish.portion / dish.recipe!.portion
            for ingredient in dish.ingredients?.allObjects as! [Ingredient] {
                for serveSize in (ingredient.food!.serveSizes?.allObjects as! [ServeSize]).filter({$0.unit == ingredient.unit}) {
                    
                    if result[serveSize.foodgroup!.title!] == nil {
                        result[serveSize.foodgroup!.title!] = 0
                    }
                    result[serveSize.foodgroup!.title!]! += ingredient.quantity * multiplier / serveSize.quantity
                }
                
            }
        }
        return result
    }
    
    //MARK: - IBAction
    
    @IBAction func addButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "GoToEditDish", sender: nil)
    }
    
    @IBAction func modeButtonPressed(_ sender: UIBarButtonItem) {
        editMode = !editMode
        sender.title = editMode ? NSLocalizedString("Done", comment: "button") : NSLocalizedString("Edit", comment: "button")
        sender.style = editMode ? .done : .plain
        tableView.reloadData()
    }
    
    
    @IBAction func settingsButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "GoToSettings", sender: nil)
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        dataEntryByAlert(title: NSLocalizedString("Enter a name to save plan", comment: "alert"), presenter: self) { text in
            
            let newPlan = Plan(context: K.context)
            newPlan.title = text
            newPlan.dishes = NSSet(array: self.dishArray)
            self.saveContext()
        }
    }
    
    
    
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Int(S.data.days)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dishArray.filter({$0.day == section}).count
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if let firstDate = S.data.firstDate {
            
            let dateString = S.data.weekdayFormatter.string(from: dateAfter(section - 1, from: firstDate))
            return String(format: NSLocalizedString("Day %d - %@", comment: "picker format"), section + 1, dateString)
            
        } else {
            return String(format: NSLocalizedString("Day %d", comment: "picker format"), section + 1)
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DishCell", for: indexPath) as! DishCell
        
        let day = indexPath.section
        let dishes = dishArray.filter({$0.day == day})
        if dishes.count >= indexPath.row {
            let dish = dishes[indexPath.row]
            cell.mealLabel.text = K.mealIcon[Int(dish.meal!.order)]
            cell.recipeLabel.text = dish.recipe?.title
            let alternativeIngredients = (dish.ingredients?.allObjects as! [Ingredient]).filter({$0.isOptional || $0.alternative != nil})
            cell.ingredientLabel.text = alternativeIngredients.map({$0.food!.title!}).sorted().joined(separator: "\n")
            cell.onStepperValueChangedUpdateCell(dish.portion)
            cell.onStepperValueChanged = { value in
                dish.portion = value
                self.saveContext()
                self.onDishUpdated()
            }
        }
        
        if editMode {
            cell.portionStepper.isHidden = false
        } else {
            cell.portionStepper.isHidden = true
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if editMode {
            performSegue(withIdentifier: "GoToEditDish", sender: nil)
        } else {
            performSegue(withIdentifier: "GoToViewRecipe", sender: nil)
        }
    }

    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        
        if editingStyle == .delete {
            
            let day = indexPath.section
            let dish = dishArray.filter({$0.day == day})[indexPath.row]
            let plans = dish.plans?.allObjects as! [Plan]
            if plans.count > 1 {
                dish.plans = NSSet(array: plans.filter({$0 != S.data.selectedPlan}))
            } else {
                K.context.delete(dish)
            }

            saveContext()
            dishArray = dishArray.filter({$0 != dish})
            onDishUpdated()
        }
        
    }
    
    
    
    //MARK: - UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return S.data.foodgroupArray.count - 1 //except 'Other'
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = calculatorCollectionView.dequeueReusableCell(withReuseIdentifier: "CalculatorCell", for: indexPath) as! CalculatorCell
        
        let foodgroup = S.data.foodgroupArray[indexPath.row].title!
        let targetServes = dailyTotal[foodgroup]! * S.data.days
        let sum = serveSum[foodgroup] ?? 0
        
        cell.titleLabel.text = foodgroup
        
        cell.sumLabel.text = NSLocalizedString("Now: ", comment: "calculator") + limitDigits(sum)

        if foodgroup == NSLocalizedString("Oil", comment: "food group") {
            cell.targetLabel.text = NSLocalizedString("Less than: ", comment: "calculator") + limitDigits(targetServes)
            cell.sumLabel.textColor = (sum <= targetServes ? .label : warningColor)
        } else {
            cell.targetLabel.text = NSLocalizedString("Target: ", comment: "calculator") + limitDigits(targetServes)
            cell.sumLabel.textColor = (
                (sum >= targetServes * 0.9 && sum <= targetServes * 1.1) ?
                    .label :
                warningColor
            )
        }
        
        
        return cell
    }
    
    
    //MARK: - UICollectionViewDelegate
    
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//        performSegue(withIdentifier: "GoToEditIngredient", sender: nil)
//        ingredientCollectionView.deselectItem(at: indexPath, animated: true)
//    }
    
    
    
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "GoToEditDish" {
            
            let vc = segue.destination as! EditDishTVC

            if let indexPath = tableView.indexPathForSelectedRow {
            
                vc.selectedDish = dishArray.filter({$0.day == indexPath.section})[indexPath.row]
            }
            
        } else if segue.identifier == "GoToViewRecipe",
            let indexPath = tableView.indexPathForSelectedRow {
            
            let vc = segue.destination as! ViewRecipeTVC
            vc.selectedDish = dishArray.filter({$0.day == indexPath.section})[indexPath.row]
            
        } else if segue.identifier == "GoToSettings" {
            
            let vc = segue.destination as! SettingsTVC
            vc.mealPlanVC = self
        }
    }
    
    
}



