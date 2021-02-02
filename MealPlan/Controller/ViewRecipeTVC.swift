//
//  ViewRecipeTVC.swift
//  MealPlan
//
//  Created by Yuexi Tan on 2020/11/27.
//  Copyright © 2020 Yuexi Tan. All rights reserved.
//

import UIKit

class ViewRecipeTVC: UITableViewController {

    var selectedRecipe: Recipe!
    var ingredientArray: [Ingredient] = []
    var methodArray: [String] = []
    var alternativeArray: [Alternative] = []
    
    var selectedDish: Dish?
    var portionMultiplier: Double = 1
    
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    var methodImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ButtonCell", bundle: nil), forCellReuseIdentifier: "ButtonCell")
        
        if let dish = selectedDish {
            selectedRecipe = dish.recipe
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDataToForm()
        tableView.reloadData()
    }


    //MARK: - IBAction

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "GoToEditRecipe", sender: nil)
    }
    
    
    //MARK: - Custom function
    
    func loadDataToForm(){
        
        ingredientArray = (selectedRecipe.ingredients?.allObjects as! [Ingredient]).sorted(by: {$0.food!.title! < $1.food!.title!})

        alternativeArray = getAlternative(from: ingredientArray)

        let method = selectedRecipe.method!.replacingOccurrences(of: "\(K.lineBreakReplaceString)\(K.lineBreakReplaceString)", with: "\n\(K.lineBreakReplaceString)")
        methodArray = method.components(separatedBy: K.lineBreakReplaceString)
        
        if selectedRecipe.methodImage != "",
            let imgUrl = getFilePath(selectedRecipe.methodImage),
            let image = UIImage(contentsOfFile: imgUrl.path) {
            
            methodImage = image
        } else {
            methodImage = nil
        }
        
        if let dish = selectedDish {
            portionMultiplier = dish.portion / selectedRecipe.portion
            let selectedIngredients = dish.alternativeIngredients?.allObjects as! [Ingredient]
//            selectedIngredients += ingredientArray.filter({$0.alternative == nil})
            ingredientArray = ingredientArray.filter({$0.alternative == nil || selectedIngredients.contains($0)})

        }
    }
    
    func openUrl(_ string: String){
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
    
    

    func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(ViewRecipeTVC.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if (scrollView.zoomScale > scrollView.minimumZoomScale) { //zoom out
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else { //zoom in
            let zoomRect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view))
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    

    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    //MARK: - TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 5
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0: //title
            return 1
        case 1: //meal
            return 1
        case 2: //portion and season
            return 1
        case 3: //ingredients
            return ingredientArray.count
        default: //method
            return methodArray.count + 2
        }
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0: //title
            return nil
        case 1: //meal
            return nil
        case 2: //portion and season
            return nil
        case 3: //ingredients
            return NSLocalizedString("Ingredients", comment: "header")
        default: //method
            return NSLocalizedString("Method", comment: "header")
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0: //title
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleCell", for: indexPath)
            cell.textLabel?.text = selectedRecipe.title
            return cell
            
        case 1: //meal
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "MealCell", for: indexPath)
            cell.textLabel?.text = (selectedRecipe.meals?.allObjects as! [Meal]).sorted(by: {$0.order < $1.order}).map({$0.title!}).joined(separator: ", ")
            return cell
            
        case 2: //portion and season
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "PortionSeasonCell", for: indexPath)
            cell.textLabel?.text = selectedRecipe.seasonLabel
            cell.detailTextLabel?.text =  "\(limitDigits(selectedRecipe.portion * portionMultiplier)) \(K.portionIcon)"
            cell.accessoryType = .none
            return cell
            
        case 3: //ingredients
            
            let i = ingredientArray[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
            cell.textLabel?.text = "\(limitDigits(i.quantity * portionMultiplier)) \(i.unit!)"
            if i.optional {
                cell.detailTextLabel?.text = "*" + i.food!.title!
            } else {
                cell.detailTextLabel?.text = i.food!.title
            }
            if i.alternative != nil,
                let alternativeIndex = alternativeArray.firstIndex(of: i.alternative!) {

                cell.backgroundColor = K.cellBackgroundColors[alternativeIndex % 10]
            } else {
                cell.backgroundColor = UIColor.clear
            }
            return cell
            
        default: //method
            
            if indexPath.row < methodArray.count { //method text
                
                let method = methodArray[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "MethodCell", for: indexPath)
                cell.textLabel?.text = method
                return cell
                
            } else if indexPath.row == methodArray.count { //method link
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonCell
                if selectedRecipe.methodLink != "" {
                    cell.titleButton.isEnabled = true
                    cell.titleButton.setTitle(selectedRecipe.methodLink, for: .normal)
                    cell.onButtonPressed = {
                        self.openUrl(self.selectedRecipe.methodLink!)
                    }
                } else {
                    cell.titleButton.isEnabled = false
                    cell.titleButton.setTitle(NSLocalizedString("No link", comment: "button"), for: .normal)
                }
                return cell
                
            } else { //method image
                
                if let image = methodImage {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)

                    scrollView = UIScrollView(frame: cell.bounds)
                    imageView = UIImageView(image: image)
                    scrollView.addSubview(imageView)
                    cell.addSubview(scrollView)
                    
                    cell.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height ).isActive = true

//                    let aspect = image.size.height / image.size.width
//                    imageView.widthAnchor.constraint(greaterThanOrEqualTo: cell.widthAnchor).isActive = true
//                    imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: aspect).isActive = true
                    imageView.contentMode = .scaleAspectFill

                    
                    scrollView.contentSize = imageView.intrinsicContentSize
                    scrollView.backgroundColor = .systemBackground
                    scrollView.minimumZoomScale = cell.bounds.width / image.size.width
                    scrollView.maximumZoomScale = 1.0
                    scrollView.delegate = self
                    scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    
                    scrollView.zoomScale = scrollView.minimumZoomScale
                    setupGestureRecognizer()
                    
                    return cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! ButtonCell

                    cell.titleButton.isEnabled = false
                    cell.titleButton.setTitle(NSLocalizedString("No image", comment: "button"), for: .normal)
                    return cell
                }
            }
            
        
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section >= 3,  //ingredient and method
            indexPath.row < methodArray.count,
            let cell = tableView.cellForRow(at: indexPath) {
            
            cell.accessoryType = (cell.accessoryType == .none ? .checkmark : .none)
            
        }
            
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    //MARK: - Scroll View
    
    override func viewForZooming(in scrollView: UIScrollView) -> UIView? {
       
        return imageView
    }
  
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "GoToEditRecipe",
            let vc = segue.destination as? EditRecipeTVC {
            
            vc.selectedRecipe = selectedRecipe
            vc.completionHandler = { recipe, operationString in
                
                switch operationString {
                case K.operationDelete:
                    self.navigationController?.popViewController(animated: true)
                default:
                    self.loadDataToForm()
                }
            }
        }
    }
    

}
