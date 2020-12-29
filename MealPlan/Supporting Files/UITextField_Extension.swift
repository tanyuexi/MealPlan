//
//  UITextField_Extension.swift

//  Source: https://medium.com/swift2go/swift-add-keyboard-done-button-using-uitoolbar-c2bea50a12c7
//  Title: SWIFT — Add keyboard Done button using UIToolbar
//  Author: Dejan Atanasov
//  Jul 7, 2017





import UIKit

extension UITextField {
    
    
    @IBInspectable var doneAccessory: Bool {
        get{
            return self.doneAccessory
        }
        set (hasDone) {
            if hasDone{
                addDoneButtonOnKeyboard()
            }
        }
    }
    
    func addDoneButtonOnKeyboard()
    {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: "keyboard toolbar button"), style: .done, target: self, action: #selector(self.doneButtonAction))
        
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        self.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction()
    {
        self.resignFirstResponder()
    }
}
