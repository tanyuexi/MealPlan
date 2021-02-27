//
//  UIViewController_Extension.swift
//  MunchItUp
//
//  Created by Yuexi Tan on 2020/8/3.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit
import CoreData
import func AVFoundation.AVMakeRect


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
    
    
    //MARK: - plist
    func setPlistDays(_ int: Int){
        K.defaults.set(int, forKey: "Days")
    }
    
    
    func getPlistDays() -> Int {
        return K.defaults.integer(forKey: "Days")
    }
    
    func setPlistHemisphere(_ hemisphere: String){
        K.defaults.set(hemisphere, forKey: "Hemisphere")
    }
    
    
    func getPlistHemisphere() -> String {
        return K.defaults.string(forKey: "Hemisphere") ?? ""
    }
    
    func setPlistFirstDate(_ firstDate: String){
        K.defaults.set(firstDate, forKey: "First date")
    }
    
    
    func getPlistFirstDate() -> String {
        return K.defaults.string(forKey: "First date") ?? ""
    }
    
    //MARK: - alert
    
    func notifyMessage(_ message: String, handler: ((UIAlertAction) -> Void)? = nil){
        
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "alert"), style: .cancel, handler: handler))
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func askToConfirmMessage(_ message: String, confirmHandler: ((UIAlertAction) -> Void)?) {

        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "alert"), style: .default, handler: confirmHandler))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "alert"), style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)

    }
    
    
    func dataEntryByAlert(title: String, message: String = "", preloadText: String = "", placeHolder: String = "", keyboardType: UIKeyboardType = .default, presenter: UIViewController, completionHandler: @escaping ((String) -> Void) ) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        
        let action = UIAlertAction(title: NSLocalizedString("Done", comment: "alert"), style: .default) { (action) in

            completionHandler(textField.text!)
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.text = preloadText
            alertTextField.clearButtonMode = .always
            alertTextField.placeholder = placeHolder
            alertTextField.keyboardType = keyboardType
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        presenter.present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Time and Date
    
    func dateAfter(_ days: Int, from startDate: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let component = DateComponents(day: days)
        return calendar.date(byAdding: component, to: startDate)!
    }


    
    //MARK: - bar button
    
//    func setBarButton(_ button: UIBarButtonItem, _ toEnable: Bool) {
//        if toEnable {
//            button.tintColor = .none
//            button.isEnabled = true
//        } else {
//            button.tintColor = .systemGray
//            button.isEnabled = false
//        }
//    }
    
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
    
    
    func getAlternative(from ingredients: [Ingredient]) -> [Alternative] {
        let alternatives = Set(ingredients.compactMap({$0.alternative}))
        return Array(alternatives)
    }
    
    func convertDataToStringLine(from person: Person) -> String {
        let line = [
            person.name!,
            S.data.dateFormatter.string(from: person.dateOfBirth!),
            person.needsAdditional ? "Additional" : "None",
            person.isFemale ? "Female" : "Male",
            person.isPregnant ? "Pregnant" : "None",
            person.isBreastfeeding ? "Breastfeeding" : "None",
            "\n"
        ].joined(separator: K.level1Separator)
        return line
    }
    
    func convertDataToStringLine(from food: Food) -> String {
        let seasonField = (food.seasons?.allObjects as! [Season]).sorted(by: {$0.order < $1.order}).map({$0.title!}).joined(separator: K.level2Separator)
        let serveSizeField = (food.serveSizes?.allObjects as! [ServeSize]).sorted(by: {$0.foodgroup!.title! < $1.foodgroup!.title!}).map({
            [$0.foodgroup!.title!, limitDigits($0.quantity), $0.unit!].joined(separator: K.level3Separator)
        }).joined(separator: K.level2Separator)
        let line = [
            food.title!,
            seasonField,
            serveSizeField,
            "\n"
        ].joined(separator: K.level1Separator)
        return line
    }
    
    func convertDataToStringLine(from recipe: Recipe) -> String {
        //attributes: featureIngr method methodimg portion seasonLabel title currentmenu ingredients meal season
        let seasonField = (recipe.seasons?.allObjects as! [Season]).sorted(by: {$0.order < $1.order}).map({$0.title!}).joined(separator: K.level2Separator)
        
        let mealField = (recipe.meals?.allObjects as! [Meal]).sorted(by: {$0.order < $1.order}).map({$0.title!}).joined(separator: K.level2Separator)
        
        //maxServe optional quantity unit food recipe
        let ingredientField = (recipe.ingredients?.allObjects as! [Ingredient]).sorted(by: {$0.food!.title! < $1.food!.title!}).map({
            [
                $0.food!.title!,
                limitDigits($0.maxServes),
                ($0.isOptional ? "Optional" : "Essential"),
                limitDigits($0.quantity),
                $0.unit!
            ].joined(separator: K.level3Separator)
        }).joined(separator: K.level2Separator)
        
        let alternativeField = (recipe.alternatives?.allObjects as! [Alternative]).map({
                ($0.ingredients?.allObjects as! [Ingredient]).map({$0.food!.title!}).joined(separator: K.level3Separator)
        }).joined(separator: K.level2Separator)
        
        //fields: 0-title, 1-portion, 2-meals, 3-seasons, 4-ingredients, 5-alternatives, 6-methodimg, 7-methodLink, 8-method
        let line = [
            recipe.title ?? "",
            String(recipe.portion),
            mealField,
            seasonField,
            ingredientField,
            alternativeField,
            recipe.methodImage ?? "",
            recipe.methodLink ?? "",
            recipe.method ?? "",
            "\n"
        ].joined(separator: K.level1Separator)
        return line
    }
    
    func exportToCsv(){
        //export Person
        var personArray: [Person] = []
        let personFileUrl = getFilePath("Person.tsv")
        do {
            try "".write(to: personFileUrl!, atomically: true, encoding: .utf8)
        } catch {
            print("Error: Unable to write to file \(personFileUrl!)")
        }
        if let fileUpdater = try? FileHandle(forWritingTo: personFileUrl!) {
            
            loadPerson(to: &personArray)
            for person in personArray {
                let line = convertDataToStringLine(from: person)
                fileUpdater.write(line.data(using: .utf8)!)
            }
            fileUpdater.closeFile()
        } else {
            print("Error: Unable to open file handle")
        }
        personArray = []
        
        
        //export Food
        var foodArray: [Food] = []
        let foodFileUrl = getFilePath("Food.tsv")
        do {
            try "".write(to: foodFileUrl!, atomically: true, encoding: .utf8)
        } catch {
            print("Error: Unable to write to file \(foodFileUrl!)")
        }
        if let fileUpdater = try? FileHandle(forWritingTo: foodFileUrl!) {
            
            loadFood(to: &foodArray)
            for food in foodArray {
                let line = convertDataToStringLine(from: food)
                fileUpdater.write(line.data(using: .utf8)!)
            }
            fileUpdater.closeFile()
        } else {
            print("Error: Unable to open file handle")
        }
        foodArray = []
        
        //export Recipe
        var recipeArray: [Recipe] = []
        let recipeFileUrl = getFilePath("Recipe.tsv")
        do {
            try "".write(to: recipeFileUrl!, atomically: true, encoding: .utf8)
        } catch {
            print("Error: Unable to write to file \(recipeFileUrl!)")
        }
        if let fileUpdater = try? FileHandle(forWritingTo: recipeFileUrl!) {
            
            loadRecipe(to: &recipeArray)
            for recipe in recipeArray {
                let line = convertDataToStringLine(from: recipe)
                fileUpdater.write(line.data(using: .utf8)!)
            }
            fileUpdater.closeFile()
        } else {
            print("Error: Unable to open file handle")
        }

    }
    
    func cleanUp(){
        var ingredients: [Ingredient] = []
        let orPredicates = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(format: "recipe == nil"), NSPredicate(format: "food == nil")])
        loadIngredient(to: &ingredients, predicate: orPredicates )
        for abandoned in ingredients {
            K.context.delete(abandoned)
        }
        ingredients = []
        
        var alternatives: [Alternative] = []
        loadAlternative(to: &alternatives)
        for abandoned in alternatives.filter({$0.ingredients == nil || $0.ingredients!.count == 0 || $0.recipe == nil}) {
            K.context.delete(abandoned)
        }
        alternatives = []
        
        var serveSizes: [ServeSize] = []
        loadServeSize(to: &serveSizes)
        for abandoned in serveSizes.filter({$0.food == nil}) {
            K.context.delete(abandoned)
        }
        serveSizes = []
        
        var recipes: [Recipe] = []
        loadRecipe(to: &recipes)
        let imageFiles = recipes.compactMap({$0.methodImage})
        recipes = []
        
        if let documentUrl = getFilePath(directory: true) {
            
            let contentUrls = try! FileManager.default.contentsOfDirectory(at: documentUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            for imgUrl in contentUrls.filter({$0.lastPathComponent.starts(with: K.methodImagePrefix)}) {
                if !imageFiles.contains(imgUrl.lastPathComponent) {
                    do {
                        try FileManager.default.removeItem(at: imgUrl)
                    } catch {
                        print("Error removing image: \(error)")
                    }
                }
            }
        }
        
    }
    
    func deepCopy(from data: ServeSize) -> ServeSize {
        let newData = ServeSize(context: K.context)
        newData.quantity = data.quantity
        newData.unit = data.unit
        //newData.food
        newData.foodgroup = data.foodgroup
        
        return newData
        
    }
    
    func deepCopy(from data: Food) -> Food {
        let newData = Food(context: K.context)
        newData.title = data.title
        //newData.ingredients
        newData.seasons = data.seasons
        let serveSizeCopy = (data.serveSizes?.allObjects as! [ServeSize]).map({self.deepCopy(from: $0)})
        newData.serveSizes = NSSet(array: serveSizeCopy)
        
        return newData
        
    }

    
    func deepCopy(from data: Ingredient) -> Ingredient {
        let newData = Ingredient(context: K.context)
        newData.maxServes = data.maxServes
//        newData.optional = data.optional
        newData.quantity = data.quantity
        newData.unit = data.unit
        newData.food = data.food
//        newData.recipe
        
        return newData
        
    }
    
    func deepCopy(from data: Recipe) -> Recipe {
        let newData = Recipe(context: K.context)
        newData.featuredIngredients = data.featuredIngredients
        newData.method = data.method
        newData.methodImage = data.methodImage
        newData.title = data.title
        newData.portion = data.portion
//        newData.currentMenu
        let ingredientCopy = (data.ingredients?.allObjects as! [Ingredient]).map({self.deepCopy(from: $0)})
        newData.ingredients = NSSet(array: ingredientCopy)
        newData.meals = data.meals
        newData.seasons = data.seasons
        
        return newData
        
    }
    
    
    func updateRecipeSeason(of recipe: Recipe) {
        let seasonSet = updateRecipeSeason(
            ingredients: recipe.ingredients?.allObjects as! [Ingredient],
            alternatives: recipe.alternatives?.allObjects as! [Alternative])
        recipe.seasons = NSSet(set: seasonSet)
        recipe.seasonLabel = getSeasonIcon(from: Array(seasonSet))
    }
    
    func updateRecipeSeason(ingredients: [Ingredient], alternatives: [Alternative]) -> Set<Season> {
        var seasonSet = Set(S.data.seasonArray)
        
        //union for non-optional alternative ingredients
        for alternative in alternatives {
            var alternativeSeason: Set<Season> = Set()
            if let alternativeIngredients = alternative.ingredients?.allObjects as? [Ingredient],
                alternativeIngredients.count > 0,
                alternativeIngredients.allSatisfy({$0.isOptional == false}) {
                
                for i in alternativeIngredients {
                    alternativeSeason = alternativeSeason.union(i.food?.seasons as! Set<Season>)
                }
                seasonSet = seasonSet.intersection(alternativeSeason)
            }
        }
        
        //intersection for all ingredients
        for i in ingredients {
            if i.alternative == nil, i.isOptional == false {
                seasonSet = seasonSet.intersection(i.food?.seasons as! Set<Season>)
            }
        }
        return seasonSet
    }
    
    func updateRecipeFeaturedIngredients(of recipe: Recipe){
        if let ingredients = recipe.ingredients?.allObjects as? [Ingredient] {
            
            let ingredientByServes = ingredients.sorted{$0.maxServes > $1.maxServes}
            recipe.featuredIngredients = ingredientByServes.map{$0.food!.title!}.joined(separator: ", ")
        }
    }
    
    func convertStringLineToFood(from line: String) {
        //fields: 0-name, 1-seasons, 2-serve sizes
        let fields: [String] = line.components(separatedBy: K.level1Separator)
        if fields.count < 3 {
            return
        }
        let food: Food!
        var foodArray: [Food] = []
        loadFood(to: &foodArray, predicate: NSPredicate(format: "title ==[cd] %@", fields[0]))
        if foodArray.count == 0 {
            food = Food(context: K.context)
            food.title = fields[0]
        } else {
            food = foodArray.first!
        }
        
        //season
        let seasonTitles = fields[1].components(separatedBy: K.level2Separator)
        let seasons = S.data.seasonArray.filter({seasonTitles.contains($0.title!)})
        food.seasons = NSSet(array: seasons)
        food.seasonLabel = getSeasonIcon(from: seasons)
        
        //serve size
        food.serveSizes = nil
        for serveSize in fields[2].components(separatedBy: K.level2Separator) {
            //info: 0-food group, 1-quantity, 2-unit
            let info = serveSize.components(separatedBy: K.level3Separator)
            if info.count != 3 {
                continue
            }
            if let foodgroup = S.data.foodgroupArray.first(where: {$0.title == info[0]}),
                let quantity = Double(info[1]),
                info[2] != "" {
                
                let serveSize = ServeSize(context: K.context)
                serveSize.foodgroup = foodgroup
                serveSize.quantity = quantity
                serveSize.unit = info[2]
                serveSize.food = food
                
            }
        }
        let serveSizes = food.serveSizes?.allObjects as! [ServeSize]
        food.foodgroupLabel = getFoodGroupInfo(from: serveSizes)
    }
    
    
    
    func convertStringLineToRecipe(from line: String) {
        //fields: 0-title, 1-portion, 2-meals, 3-seasons, 4-ingredients, 5-alternatives, 6-methodimg, 7-methodLink, 8-method
        let fields: [String] = line.components(separatedBy: K.level1Separator)
        if fields.count < 9 {
            return
        }
        let recipe: Recipe!
        var recipeArray: [Recipe] = []
        loadRecipe(to: &recipeArray, predicate: NSPredicate(format: "title ==[cd] %@", fields[0]))
        if recipeArray.count == 0 {
            recipe = Recipe(context: K.context)
            recipe.title = fields[0]
        } else {
            recipe = recipeArray.first!
        }
        
        recipe.portion = Double(fields[1]) ?? 1

        //meal
        let mealTitles = fields[2].components(separatedBy: K.level2Separator)
        let meals = S.data.mealArray.filter({mealTitles.contains($0.title!)})
        recipe.meals = NSSet(array: meals)
        
        //season
        let seasonTitles = fields[3].components(separatedBy: K.level2Separator)
        let seasons = S.data.seasonArray.filter({seasonTitles.contains($0.title!)})
        recipe.seasons = NSSet(array: seasons)
        recipe.seasonLabel = getSeasonIcon(from: seasons)
        
        //ingredient
        recipe.ingredients = nil
        for ingredient in fields[4].components(separatedBy: K.level2Separator) {
            //info: 0-food.title, 1-maxserve, 2-optional, 3-quantity, 4-unit
            let info = ingredient.components(separatedBy: K.level3Separator)
            if info.count != 5 {
                continue
            }
            var foodByTitle: [Food] = []
            loadFood(to: &foodByTitle, predicate: NSPredicate(format: "title ==[cd] %@", info[0]))
            if let food = foodByTitle.first,
                let maxServes = Double(info[1]),
                let quantity = Double(info[3]) {
                
                let i = Ingredient(context: K.context)
                i.food = food
                i.maxServes = maxServes
                i.isOptional = (info[2] == "Optional")
                i.quantity = quantity
                i.unit = info[4]
                i.recipe = recipe
            }
        }
        updateRecipeFeaturedIngredients(of: recipe)
        
        //alternatives
        recipe.alternatives = nil
        for alternative in fields[5].components(separatedBy: K.level2Separator) {
            let newAlternative = Alternative(context: K.context)
            newAlternative.recipe = recipe
            for title in alternative.components(separatedBy: K.level3Separator) {
                let ingredientByTitle = (recipe.ingredients?.allObjects as! [Ingredient]).filter({$0.food!.title! == title})
                for i in ingredientByTitle {
                    i.alternative = newAlternative
                }
            }
            
        }
        
        //method
        recipe.methodImage = fields[6]
        recipe.methodLink = fields[7]
        recipe.method = fields[8]
    }
    
    
    func importDemoDatabase(){
        // food
        let foodFilePath = Bundle.main.path(forResource: "Food", ofType: "tsv")
        
        if freopen(foodFilePath, "r", stdin) == nil {
            perror("Error: Unable to read Food.tsv \(foodFilePath ?? "nil")")
        }
        
        while let line = readLine() {
            convertStringLineToFood(from: line)
        }
        fclose(stdin)
        saveContext()
        
        //recipe
        let recipeFilePath = Bundle.main.path(forResource: "Recipe", ofType: "tsv")
        
        if freopen(recipeFilePath, "r", stdin) == nil {
            perror("Error: Unable to read Recipe.tsv \(recipeFilePath ?? "nil")")
        }
        
        while let line = readLine() {
            convertStringLineToRecipe(from: line)
        }
        fclose(stdin)
        cleanUp()
        saveContext()
    }
    
    func initDatabase(){
        // days
        if getPlistDays() == 0 {
            setPlistDays(7)
        }
        S.data.days = Double(getPlistDays())
        
        // hemisphere
        if getPlistHemisphere() == "" {
            setPlistHemisphere("North")
        }
        S.data.northHemisphere = (getPlistHemisphere() == "North")
        
        // first date
        S.data.firstDate = S.data.dateFormatter.date(from: getPlistFirstDate())
        
        //daily serves
        if let filePath = Bundle.main.path(forResource: "DailyServes", ofType: "tsv") {
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            let header = [
                NSLocalizedString("Age", comment: "file header"),         //0
                NSLocalizedString("Condition", comment: "file header"),   //1
                NSLocalizedString("Vegetable", comment: "file header"),   //2
                NSLocalizedString("Fruit", comment: "file header"),       //3
                NSLocalizedString("Grain", comment: "file header"),       //4
                NSLocalizedString("Protein", comment: "file header"),     //5
                NSLocalizedString("Calcium", comment: "file header"),     //6
                NSLocalizedString("Additional", comment: "file header"),  //7
                NSLocalizedString("Oil", comment: "file header")          //8
            ]
            while let line = readLine() {
                if line.prefix(2) == "//" {
                    continue
                }
                //0-age, 1-condition, 2-vegetable, 3-fruit, 4-grain, 5-protein, 6-calcium, 7-additional, 8-oil
                let fields: [String] = line.components(separatedBy: K.level1Separator)
                //dailyServes = ["food": ["age gender&condition": serves]]
                for column in 2..<9 {
                    if S.data.dailyServes[header[column]] == nil {
                        S.data.dailyServes[header[column]] = [:]
                    }
                    S.data.dailyServes[header[column]]!["\(fields[0]) \(fields[1])"] = Double(fields[column]) ?? 0
                }
                
            }
            fclose(stdin)
        }
        
        // person
        var personArray: [Person] = []
        loadPerson(to: &personArray)
        if personArray.count == 0 {
            let filePath = Bundle.main.path(forResource: "Person", ofType: "tsv")
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            while let line = readLine() {
                let fields: [String] = line.components(separatedBy: K.level1Separator)
                let person = Person(context: K.context)
                person.name = fields[0]
                person.dateOfBirth = S.data.dateFormatter.date(from: fields[1])
                person.needsAdditional = (fields[2] == "Additional")
                person.isFemale = (fields[3] == "Female")
                person.isPregnant = (fields[4] == "Pregnant")
                person.isBreastfeeding = (fields[5] == "Breastfeeding")
                personArray.append(person)
            }
            fclose(stdin)
        }
        
        // meal
        loadMeal(to: &S.data.mealArray)
        if S.data.mealArray.count == 0 {
            let filePath = Bundle.main.path(forResource: "Meal", ofType: "tsv")
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            while let line = readLine() {
                let fields: [String] = line.components(separatedBy: K.level1Separator)
                let newData = Meal(context: K.context)
                newData.order = Int16(fields[0]) ?? 0
                newData.title = fields[1]
                S.data.mealArray.append(newData)
            }
            fclose(stdin)
        }

        
        // foodgroup
        loadFoodGroup(to: &S.data.foodgroupArray)
        if S.data.foodgroupArray.count == 0 {
            let filePath = Bundle.main.path(forResource: "FoodGroup", ofType: "tsv")
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            while let line = readLine() {
                let fields: [String] = line.components(separatedBy: K.level1Separator)
                let newData = FoodGroup(context: K.context)
                newData.order = Int16(fields[0]) ?? 0
                newData.title = fields[1]
                S.data.foodgroupArray.append(newData)
            }
            fclose(stdin)
        }
        
        // season
        loadSeason(to: &S.data.seasonArray)
        if S.data.seasonArray.count == 0 {
            let filePath = Bundle.main.path(forResource: "Season", ofType: "tsv")
            
            if freopen(filePath, "r", stdin) == nil {
                perror(filePath)
            }
            
            while let line = readLine() {
                let fields: [String] = line.components(separatedBy: K.level1Separator)
                let newData = Season(context: K.context)
                newData.order = Int16(fields[0]) ?? 0
                newData.title = fields[1]
                S.data.seasonArray.append(newData)
            }
            fclose(stdin)
        }
        
        saveContext()

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
    
    
    func loadPlan(to array: inout [Plan], predicate: NSPredicate? = nil) {
        
        let request : NSFetchRequest<Plan> = Plan.fetchRequest()
        let sortBy = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [sortBy]
        
        if predicate != nil {
            //NSPredicate(format: "title ==[cd] %@", fields[0])
            request.predicate = predicate
        }
        
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading SavedPlan \(error)")
        }
    }
    
    
    func loadPerson(to array: inout [Person]) {
        let request : NSFetchRequest<Person> = Person.fetchRequest()
//        let sortBy = NSSortDescriptor(key: "dateOfBirth", ascending: true)
//        request.sortDescriptors = [sortBy]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Person \(error)")
        }
    }
    
    
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
    
    func loadDish(to array: inout [Dish], predicate: NSPredicate? = nil) {
        let request : NSFetchRequest<Dish> = Dish.fetchRequest()
        let sortByDay = NSSortDescriptor(key: "day", ascending: true)
        let sortByMeal = NSSortDescriptor(key: "meal.order", ascending: true)
        let sortByRecipe = NSSortDescriptor(key: "recipe.title", ascending: true)
        request.sortDescriptors = [sortByDay, sortByMeal, sortByRecipe]
        if predicate != nil {
            //NSPredicate(format: "title ==[cd] %@", fields[0])
            request.predicate = predicate
        }
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading PlannedDish \(error)")
        }
    }
    
    
    func loadRecipe(to array: inout [Recipe], predicate: NSPredicate? = nil) {
        let request : NSFetchRequest<Recipe> = Recipe.fetchRequest()
        let sortBy = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [sortBy]
        if predicate != nil {
            //NSPredicate(format: "title ==[cd] %@", fields[0])
            request.predicate = predicate
        }
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Recipe \(error)")
        }
    }
    
    func loadIngredient(to array: inout [Ingredient], predicate: NSPredicate? = nil) {
        //NSPredicate(format: "title ==[cd] %@", fields[0])
        //NSCompoundPredicate(orPredicateWithSubpredicates: textSubpredicates)
        let request : NSFetchRequest<Ingredient> = Ingredient.fetchRequest()
        if predicate != nil {
            request.predicate = predicate
        }
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Ingredient \(error)")
        }
    }
    
    func loadAlternative(to array: inout [Alternative], predicate: NSPredicate? = nil) {
        //NSPredicate(format: "title ==[cd] %@", fields[0])
        //NSCompoundPredicate(orPredicateWithSubpredicates: textSubpredicates)
        let request : NSFetchRequest<Alternative> = Alternative.fetchRequest()
        if predicate != nil {
            request.predicate = predicate
        }
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Ingredient \(error)")
        }
    }
    

    func loadServeSize(to array: inout [ServeSize], predicates: [NSPredicate] = []) {
        let request : NSFetchRequest<ServeSize> = ServeSize.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        //let categoryPredicate = NSPredicate(format: "parentCategory.name == %@", selectedCategory!.name!)
        //let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        let sortBy = NSSortDescriptor(key: "quantity", ascending: true)
        request.sortDescriptors = [sortBy]
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading ServeSize \(error)")
        }
    }
    
    func loadFood(to array: inout [Food], predicate: NSPredicate? = nil) {
        let request : NSFetchRequest<Food> = Food.fetchRequest()
        let sortByTitle = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [sortByTitle]
        if predicate != nil {
            //NSPredicate(format: "title ==[cd] %@", fields[0])
            request.predicate = predicate
        }
        do{
            array = try K.context.fetch(request)
        } catch {
            print("Error loading Food \(error)")
        }
    }
    
    func loadItem(to array: inout [Item]) {
        let request : NSFetchRequest<Item> = Item.fetchRequest()
        let sortBy = NSSortDescriptor(key: "title", ascending: true)
        request.sortDescriptors = [sortBy]
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
    //            let fields: [String] = line.components(separatedBy: K.level1Separator)
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
    //        for category in K.foodgroups {
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
    func limitDigits(_ double: Double?, max: Int = 2) -> String {
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
        let foodgroups = Array(Set(serveSizes.map({$0.foodgroup!})))
        return foodgroups.sorted(by: {$0.order < $1.order}).map({$0.title!}).joined(separator: ", ")
    }
    
//    func getSeasonInfo(from seasons: [Season]) -> String {
//        let seasonStrings = seasons.sorted(by: {$0.order < $1.order}).map({$0.title!})
//        return seasonStrings.joined(separator: ", ")
//    }
    
    func getSeasonIcon(from seasons: [Season]) -> String {
        let seasonOrders = seasons.map({Int($0.order)})
        var seasonString = ""
        for i in 0...3 {
            seasonString += (seasonOrders.contains(i) ? K.seasonIcon[i] : K.seasonUnavailableIcon)
        }
        return seasonString
    }
    
    
    
    //MARK: - UI handling
    
    func convertMultiLineToDisplay(from dataString: String) -> String {
        return dataString.replacingOccurrences(of: K.lineBreakReplaceString, with: "\n")
    }
    
    func convertMultiLineToData(from displayString: String) -> String {
        return displayString.replacingOccurrences(of: "\n", with: K.lineBreakReplaceString)
    }
    
    func selectCollectionCell(_ sender: UICollectionView, at indexPath: IndexPath) {
        sender.selectItem(at: indexPath, animated: false, scrollPosition: .left)
        if let cell = sender.cellForItem(at: indexPath) as? CollectionCell {
            cell.isSelected = true
        }
    }
    
    
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
        //MARK: - Image
        func scaleImage(_ image: UIImage, within rect: CGRect) -> UIImage? {
    
            let rect = AVMakeRect(aspectRatio: image.size, insideRect: rect)
            let renderer = UIGraphicsImageRenderer(size: rect.size)
            return renderer.image { (context) in
                image.draw(in: CGRect(origin: .zero, size: rect.size))
            }
        }
    
    
        //MARK: - Calculate daily serves
        func yearsBeforeToday(_ years: Int) -> Date {
            let calendar = Calendar(identifier: .gregorian)
            let today = Date()
            let component = DateComponents(year: -years)
            return calendar.date(byAdding: component, to: today)!
        }
    
        func isOlderRangeInAgeZone(_ date: Date, by ageThreshold: inout [Int: Date]) -> Bool {
            for i in [4, 9, 12, 14, 19] {
                let diff = Calendar(identifier: .gregorian).dateComponents([.year], from: date, to: ageThreshold[i]!)
                if diff.year! == 0 {
                    return true
                }
            }
            return false
        }
    
        func calculateDailyTotalServes(from personArray: [Person], to totalDict: inout [String: Double]) {
    
            totalDict = [:]
    
            var ageThreshold: [Int: Date] = [:]
    
            for i in [1, 2, 4, 9, 12, 14, 19, 51, 70] {
                ageThreshold[i] = yearsBeforeToday(i)
            }
    
            //calculate total serves
            for person in personArray {
                var ageZone = 0
                let olderRange = isOlderRangeInAgeZone(person.dateOfBirth!, by: &ageThreshold)
                if person.isPregnant || person.isBreastfeeding {
                    if person.dateOfBirth! <= ageThreshold[19]! {
                        ageZone = 19
                    } else {
                        ageZone = 1
                    }
                } else {
                    for i in ageThreshold.keys.sorted() {
                        if person.dateOfBirth! <= ageThreshold[i]! {
                            ageZone = i
                        }
                    }
                }
    
                //if less than 1 yrs old, next member
                if ageZone == 0 {continue}
    
                var key = "\(ageZone) "
                key += person.isFemale ? "F": "M"
                if person.isPregnant {key += "P"}
                if person.isBreastfeeding {key += "B"}
    
                for i in 0..<6 {
                    let group = S.data.foodgroupArray[i].title!
                    if totalDict[group] == nil {
                        totalDict[group] = 0.0
                    }
    
                    totalDict[group]! += S.data.dailyServes[group]![key]!
    
                    if (person.needsAdditional || olderRange),
                    group != NSLocalizedString("Oil", comment: "food group") {   //oil
    
                        totalDict[group]! += S.data.dailyServes[NSLocalizedString("Additional", comment: "food group")]![key]!/5
                    }
                }
            }
    
        }
    //
    //    //MARK: - Notification Center
    //    func postNotification(_ userInfo: [String: Any]){
    //        NotificationCenter.default.post(name: K.notificationName, object: nil, userInfo: userInfo)
    //    }
    //
}
