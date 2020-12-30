//
//  UIViewController_Extension.swift
//  MunchItUp
//
//  Created by Yuexi Tan on 2020/8/3.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData
//import func AVFoundation.AVMakeRect


extension UIViewController {
    
    
    //MARK: - path
    
    func getFilePath(directory: Bool) -> URL? {
        
        let dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return dirUrl
    }
    
    func getFilePath(_ fileName: String?) -> URL? {
        
        let dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        
        if fileName == nil || fileName == "" {
            return nil
        } else {
            return dirUrl?.appendingPathComponent(fileName!)
        }
    }
    
    //MARK: - alert
    
    func notifyMessage(_ message: String){
        
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "alert"), style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func askToConfirmMessage(_ message: String, confirmHandler: ((UIAlertAction) -> Void)?) {

        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "alert"), style: .default, handler: confirmHandler))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "alert"), style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)

    }


    
    //MARK: - bar button
    
    func setBarButton(_ button: UIBarButtonItem, _ toEnable: Bool) {
        if toEnable {
            button.tintColor = .none
            button.isEnabled = true
        } else {
            button.tintColor = .systemGray
            button.isEnabled = false
        }
    }
    
    //MARK: - plist
    //    func updateDays(_ int: Int){
    //        K.defaults.set(int, forKey: "Days")
    //    }
    //
    //
    //    func getDays() -> Double {
    //        let days = K.defaults.integer(forKey: "Days")
    //        return Double(days)
    //    }
    
    
    //MARK: - Core Data
    
    func updateRecipeSeason(of recipe: Recipe) {
        var seasonSet = Set(S.dt.seasonArray)
        
        for i in recipe.ingredients?.allObjects as! [Ingredient] {
            seasonSet = seasonSet.intersection(i.food?.seasons as! Set<Season>)
        }
        recipe.seasons = NSSet(set: seasonSet)
        
    }
    
    func updateRecipeSeason(from ingredients: [Ingredient]) -> Set<Season> {
        var seasonSet = Set(S.dt.seasonArray)
        
        for i in ingredients {
            seasonSet = seasonSet.intersection(i.food?.seasons as! Set<Season>)
        }
        return seasonSet
    }
    
    func updateRecipeFeaturedIngredients(of recipe: Recipe){
        if let ingredients = recipe.ingredients?.allObjects as? [Ingredient] {
            
            let ingredientByServes = ingredients.sorted{$0.maxServes > $1.maxServes}
            recipe.featuredIngredients = ingredientByServes.map{$0.food!.title!}.joined(separator: ", ")
        }
    }

    
    func initDatabase(){
        
        // meal
        loadMeal(to: &S.dt.mealArray)
        if S.dt.mealArray.count == 0 {
            let filePath = Bundle.main.path(forResource: "Meal", ofType: "tsv")
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            while let line = readLine() {
                let fields: [String] = line.components(separatedBy: "\t")
                let newData = Meal(context: K.context)
                newData.order = Int16(fields[0]) ?? 0
                newData.title = fields[1]
                S.dt.mealArray.append(newData)
            }
            fclose(stdin)
            saveContext()
        }
        
        // foodgroup
        loadFoodGroup(to: &S.dt.foodGroupArray)
        if S.dt.foodGroupArray.count == 0 {
            let filePath = Bundle.main.path(forResource: "FoodGroup", ofType: "tsv")
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            while let line = readLine() {
                let fields: [String] = line.components(separatedBy: "\t")
                let newData = FoodGroup(context: K.context)
                newData.order = Int16(fields[0]) ?? 0
                newData.title = fields[1]
                S.dt.foodGroupArray.append(newData)
            }
            fclose(stdin)
            saveContext()
        }
        
        // season
        loadSeason(to: &S.dt.seasonArray)
        if S.dt.seasonArray.count == 0 {
            let filePath = Bundle.main.path(forResource: "Season", ofType: "tsv")
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            while let line = readLine() {
                let fields: [String] = line.components(separatedBy: "\t")
                let newData = Season(context: K.context)
                newData.order = Int16(fields[0]) ?? 0
                newData.title = fields[1]
                S.dt.seasonArray.append(newData)
            }
            fclose(stdin)
            saveContext()
        }
    }
    
    //    func loadPresetData<T: NSManagedObject>(to array: inout [T], asType: T.Type) {
    //        let request = T.fetchRequest()
    //        let sortByTag = NSSortDescriptor(key: "tag", ascending: true)
    //        request.sortDescriptors = [sortByTag]
    //        do{
    //            array = try (K.context.fetch(request) as! [T])
    //        } catch {
    //            print("Error loading \(String(describing: T.self)) \(error)")
    //        }
    //    }
    
    
    func loadMeal(to array: inout [Meal]) {
        let request : NSFetchRequest<Meal> = Meal.fetchRequest()
        let sortBy = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortBy]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Meal \(error)")
        }
    }
    
    func loadFoodGroup(to array: inout [FoodGroup]) {
        let request : NSFetchRequest<FoodGroup> = FoodGroup.fetchRequest()
        let sortBy = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortBy]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading FoodGroup \(error)")
        }
    }
    
    func loadSeason(to array: inout [Season]) {
        let request : NSFetchRequest<Season> = Season.fetchRequest()
        let sortBy = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortBy]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Season \(error)")
        }
    }
    
    func loadRecipe(to array: inout [Recipe]) {
        let request : NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let sortBy = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [sortBy]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Recipe \(error)")
        }
    }
    
    func loadIngredient(to array: inout [Ingredient]) {
        let request : NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Ingredient \(error)")
        }
    }
    

    func loadServeSize(to array: inout [ServeSize], predicates: [NSPredicate] = []) {
        let request : NSFetchRequest<ServeSize> = ServeSize.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        //let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        //let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        let sortBy = NSSortDescriptor(key: "quantity", ascending: true)
        request.sortDescriptors = [sortBy]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading ServeSize \(error)")
        }
    }
    
    func loadFood(to array: inout [Food]) {
        let request : NSFetchRequest<Food> = Food.fetchRequest()
        let sortByTitle = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [sortByTitle]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Food \(error)")
        }
    }
    
    func loadItem(to array: inout [Item]) {
        let request : NSFetchRequest<Item> = Item.fetchRequest()
        let sortByDate = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sortByDate]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Item \(error)")
        }
    }
    
    //    func sortPeopleArray(_ peopleArray: inout [People]){
    //        peopleArray.sort {
    //            if $0.dateOfBirth! != $1.dateOfBirth! {
    //                return $0.dateOfBirth! < $1.dateOfBirth!
    //            } else {
    //                return $0.name! < $1.name!
    //            }
    //        }
    //    }
    //
    //    func resetFoodDatabase(){
    //
    //        //load old food
    //        var oldData: [Food] = []
    //        let request : NSFetchRequest<Food> = Food.fetchRequest()
    //
    //        do{
    //            oldData = try K.context.fetch(request)
    //        } catch {
    //            print("Error loading Food \(error)")
    //        }
    //
    //        //delete data in previous database
    //        var newData: [Food] = []
    //
    //        for i in oldData {
    //            if i.custom {
    //                newData.append(i)
    //            } else {
    //                K.context.delete(i)
    //            }
    //        }
    //
    //        oldData = []
    //
    //        let FoodPath = Bundle.main.path(forResource: "ServeSizes_Australia", ofType: "txt")
    //
    //        if freopen(FoodPath, "r", stdin) == nil {
    //            perror(FoodPath)
    //        }
    //
    //        //read in new serve sizes
    //        while let line = readLine() {
    //            let fields: [String] = line.components(separatedBy: "\t")
    //            let newFood = Food(context: K.context)
    //            newFood.category = fields[0]
    //            newFood.date = Date(timeIntervalSince1970: Double(fields[1])!)
    //            newFood.quantity1 = Double(fields[2]) ?? 0.0
    //            newFood.unit1 = fields[3]
    //            newFood.quantity2 = Double(fields[4]) ?? 0.0
    //            newFood.unit2 = fields[5]
    //            newFood.image = fields[6]
    //            newFood.title = fields[7]
    //            newFood.custom = false
    //            newFood.serves = 1.0
    //            newFood.done = false
    //            newData.append(newFood)
    //        }
    //
    //        saveContext()
    //    }
    //
    //
    func saveContext(){
        if K.context.hasChanges {
            do {
                try K.context.save()
            } catch {
                let nserror = error as NSError
                print("Fatal error while saving context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    //
    //
    //    func loadPeople(to array: inout [People]) {
    //        let request : NSFetchRequest<People> = People.fetchRequest()
    ////        let sortByAge = NSSortDescriptor(key: "dateOfBirth", ascending: true)
    ////        let sortByName = NSSortDescriptor(key: "name", ascending: true)
    ////        request.sortDescriptors = [sortByAge, sortByName]
    //        do{
    //            array = try K.context.fetch(request)
    //        } catch {
    //            print("Error loading People \(error)")
    //        }
    //        sortPeopleArray(&array)
    //    }
    //
    //
    //    func loadItems(to array: inout [Item]) {
    //        let request : NSFetchRequest<Item> = Item.fetchRequest()
    //        let sortByDate = NSSortDescriptor(key: "lastEdited", ascending: false)
    //        request.sortDescriptors = [sortByDate]
    //        do{
    //            array = try K.context.fetch(request)
    //        } catch {
    //            print("Error loading Item \(error)")
    //        }
    //    }
    //
    //    func loadFood(to foodDict: inout [String: [Food]]) {
    //        for category in K.foodGroups {
    //            var foodByCategory: [Food] = []
    //            let request : NSFetchRequest<Food> = Food.fetchRequest()
    //            let categoryPredicate = NSPredicate(format: "category == %@", category)
    //            request.predicate = categoryPredicate
    //            let sortByDate = NSSortDescriptor(key: "date", ascending: true)
    //            request.sortDescriptors = [sortByDate]
    //
    //            do{
    //                foodByCategory = try K.context.fetch(request)
    //            } catch {
    //                print("Error loading Food \(error)")
    //            }
    //            foodDict[category] = foodByCategory
    //        }
    //    }
    
    
    
    //MARK: - Number formatting
    func limitDigits(_ double: Double?, max: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = max
        if let d = double {
            return formatter.string(from: NSNumber(value: d))!
        } else {
            return ""
        }
    }
    
    
    func roundToHalf(_ double: Double) -> Double {
        return round(double*2)/2
    }
    
    
    func formatQuantity(_ quantity: Double, unit: String) -> String {
        let convertableUnits = ["g", "ml", "mL"]
        let newUnit = ["kg", "L", "L"]
        
        if let i = convertableUnits.firstIndex(of: unit),
            quantity >= 1000 {
            
            return limitDigits(quantity/1000) + " " + newUnit[i]
        } else {
            return limitDigits(quantity) + " " + unit
        }
        
    }
    
    //MARK: - undefined
    
    func getFoodGroupInfo(from serveSizes: [ServeSize]) -> String {
        let foodGroups = Array(Set(serveSizes.map({$0.foodGroup!})))
        return foodGroups.sorted(by: {$0.order < $1.order}).map({$0.title!}).joined(separator: ", ")
    }
    
    func getSeasonInfo(from seasons: [Season]) -> String {
        let seasonStrings = seasons.sorted(by: {$0.order < $1.order}).map({$0.title!})
        return seasonStrings.joined(separator: ", ")
    }
    
    //
    //
    //    //MARK: - UI handling
    //    func enableSaveButton(_ button: UIButton, enable: Bool = true){
    //        if enable {
    //            button.isEnabled = true
    //            button.backgroundColor = K.themeColor
    //        } else {
    //            button.isEnabled = false
    //            button.backgroundColor = .systemGray
    //        }
    //    }
    //
    //
    //    //MARK: - Image
    //    func scaleImage(_ image: UIImage, within rect: CGRect) -> UIImage? {
    //
    //        let rect = AVMakeRect(aspectRatio: image.size, insideRect: rect)
    //        let renderer = UIGraphicsImageRenderer(size: rect.size)
    //        return renderer.image { (context) in
    //            image.draw(in: CGRect(origin: .zero, size: rect.size))
    //        }
    //    }
    //
    //
    //    //MARK: - Calculate daily serves
    //    func yearsBeforeToday(_ years: Int) -> Date {
    //        let calendar = Calendar.current
    //        let today = Date()
    //        let component = DateComponents(year: -years)
    //        return calendar.date(byAdding: component, to: today)!
    //    }
    //
    //    func isOlderRangeInAgeZone(_ date: Date, by ageThreshold: inout [Int: Date]) -> Bool {
    //        for i in [4, 9, 12, 14, 19] {
    //            let diff = Calendar.current.dateComponents([.year], from: date, to: ageThreshold[i]!)
    //            if diff.year! == 0 {
    //                return true
    //            }
    //        }
    //        return false
    //    }
    //
    //    func calculateDailyTotalServes(from peopleArray: [People], to totalDict: inout [String: Double]) {
    //
    //        totalDict = [:]
    //
    //        var ageThreshold: [Int: Date] = [:]
    //
    //        for i in [1, 2, 4, 9, 12, 14, 19, 51, 70] {
    //            ageThreshold[i] = yearsBeforeToday(i)
    //        }
    //
    //        //calculate total serves
    //        for person in peopleArray {
    //            var ageZone = 0
    //            let olderRange = isOlderRangeInAgeZone(person.dateOfBirth!, by: &ageThreshold)
    //            if person.pregnant || person.breastfeeding {
    //                if person.dateOfBirth! <= ageThreshold[19]! {
    //                    ageZone = 19
    //                } else {
    //                    ageZone = 1
    //                }
    //            } else {
    //                for i in ageThreshold.keys.sorted() {
    //                    if person.dateOfBirth! <= ageThreshold[i]! {
    //                        ageZone = i
    //                    }
    //                }
    //            }
    //
    //            //if less than 1 yrs old, next member
    //            if ageZone == 0 {continue}
    //
    //            var key = "\(ageZone) "
    //            key += person.female ? "F": "M"
    //            if person.pregnant {key += "P"}
    //            if person.breastfeeding {key += "B"}
    //
    //            for group in K.foodGroups {
    //                if totalDict[group] == nil {
    //                    totalDict[group] = 0.0
    //                }
    //
    //                totalDict[group]! += K.dailyServes[group]![key]!
    //
    //                if (person.additional || olderRange),
    //                    group != K.foodGroups[5] {   //oil
    //
    //                    totalDict[group]! += K.dailyServes[K.additionalString]![key]!/5
    //                }
    //            }
    //        }
    //
    //    }
    //
    //    //MARK: - Notification Center
    //    func postNotification(_ userInfo: [String: Any]){
    //        NotificationCenter.default.post(name: K.notificationName, object: nil, userInfo: userInfo)
    //    }
    //
}
