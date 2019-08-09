//
//  SettingsViewController.swift
//  Kivi Tag
//
//  Created by KiviCode on 09/08/2019.
//  Copyright © 2019 KiviCode. All rights reserved.
//

import Foundation

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView( _ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[pickerView == from ? 0 : 1].count
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[pickerView == to ? 0 : 1][row]
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == from){
            fromVal = pickerData[0][row]
        }else{
            toVal = pickerData[1][row]
        }
        print(fromVal, toVal)
        let defaults = UserDefaults.standard
        defaults.set(fromVal, forKey: defaultsKeys.settingsFrom)
        defaults.set(toVal, forKey: defaultsKeys.settingsTo)
    }
    
    var fromVal = ""
    var toVal = ""
    
    
    //    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String {
    //        return pickerData[component][row]
    //    }
    
    @IBOutlet weak var from: UIPickerView!
    
    @IBOutlet weak var to: UIPickerView!
    
    var pickerData: [[String]] = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.from.delegate = self
        self.from.dataSource = self
        self.to.delegate = self
        self.to.dataSource = self
        pickerData = [["RUB", "EUR", "PL"],
                      ["RUB", "EUR", "PL"]]
        
        fromVal = pickerData[0][0]
        toVal = pickerData[1][0]
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "Camera") as! ViewController
        newViewController.modalTransitionStyle = .flipHorizontal
        self.present(newViewController, animated: true, completion: nil)
    }
}

