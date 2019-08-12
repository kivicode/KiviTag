//
//  SettingsViewController.swift
//  Kivi Tag
//
//  Created by KiviCode on 2019/08/08.
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
    
    @IBOutlet weak var from: UIPickerView!
    
    @IBOutlet weak var to: UIPickerView!
    
    @IBOutlet weak var selector: UISegmentedControl!
    @IBAction func typeSelect(_ sender: Any) {
        UserDefaults.standard.set(selector.selectedSegmentIndex == 1, forKey: defaultsKeys.settingsInk)
    }
    var pickerData: [[String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.from.delegate = self
        self.from.dataSource = self
        self.to.delegate = self
        self.to.dataSource = self
        pickerData = [defaultsKeys.ratesDef,
                      defaultsKeys.ratesDef]
        
        let defaults = UserDefaults.standard
        
        let fromRow = defaultsKeys.ratesDef.firstIndex(of: defaults.string(forKey: defaultsKeys.settingsFrom) ?? "RUB") ?? 0
        let toRow   = defaultsKeys.ratesDef.firstIndex(of: defaults.string(forKey: defaultsKeys.settingsTo)   ?? "RUB") ?? 0
        
        let selectorVal = UserDefaults.standard.bool(forKey: defaultsKeys.settingsInk) ? 1 : 0
        selector.selectedSegmentIndex = selectorVal
        print(defaultsKeys.ratesDef)
        fromVal = defaults.string(forKey: defaultsKeys.settingsFrom) ?? "RUB"
        toVal   = defaults.string(forKey: defaultsKeys.settingsTo)   ?? "RUB"
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
        
        self.from?.selectRow(fromRow, inComponent: 0, animated: true)
        self.to?.selectRow(toRow, inComponent: 0, animated: true)
        
    }
    
    @objc func handleSwipes(_ sender:UISwipeGestureRecognizer) {
        ViewController().request()
    }
}

