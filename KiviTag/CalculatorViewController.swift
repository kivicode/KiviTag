//
//  CalculatorViewController.swift
//  KiviTag
//
//  Created by KiviCode on 2019/13/08.
//  Copyright © 2019 KiviCode. All rights reserved.
//

import Foundation

class CalculatorViewController: UIViewController {
    
    @IBOutlet weak var baseLabel: UILabel!
    
    @IBOutlet weak var goalLabel: UILabel!
    
    @IBOutlet weak var memory: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    var mem: Float = 0.0
    
    @IBAction func pressed(_ sender: UIButton) {
        let defaults = UserDefaults.standard
        if sender.tag <= 10 {
            if baseLabel.text == "0" {
                baseLabel.text = ""
            }
            if sender.tag != 10 || (baseLabel.text ?? "").last! != "," {
                baseLabel.text = (baseLabel.text ?? "") + (sender.titleLabel?.text ?? "0")
            }
        } else {
            switch sender.tag {
            case 11:
                baseLabel.text = "0"
                break
                
            case 12:
                baseLabel.text?.remove(at: (baseLabel.text?.index(before: baseLabel.text!.endIndex))!)
                if baseLabel.text == "" {
                    baseLabel.text = "0"
                }
                break
                
            default:
                break
            }
        }
        
        let t = updateFields()
        
        if sender.tag == 14 {
            mem += Float(goalLabel.text ?? "0") ?? 0.0
            memory.text = "\(mem) \(t)"
        }
        if sender.tag == 13 {
            mem = 0
            memory.text = "0 \(t)"
        }
        
        defaults.set(baseLabel.text ?? "0", forKey: defaultsKeys.settingsCalcBase)
        defaults.set(mem, forKey: defaultsKeys.settingsCalcMemory)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        if let from = defaults.string(forKey: defaultsKeys.settingsCalcBase) {
            baseLabel.text = from
        }
        let memory = defaults.float(forKey: defaultsKeys.settingsCalcMemory)
        mem = memory
        
        let _ = updateFields()
    }
    
    func updateFields() -> String{
        
        var frm = "EUR"
        var t  = "EUR"
        let defaults = UserDefaults.standard
        if let from = defaults.string(forKey: defaultsKeys.settingsFrom) {
            frm = from
        }
        if let to = defaults.string(forKey: defaultsKeys.settingsTo) {
            t = to
        }
        
        toLabel.text = t
        fromLabel.text = frm
        
        var txt = baseLabel.text ?? "0"
        txt = txt.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil)
        let toBase = (Float(txt) ?? 0) / Float(defaultsKeys.rates[frm] ?? 1)
        var cnv: Float = toBase * Float(defaultsKeys.rates[t] ?? 1)
        cnv = Float(round(100 * cnv) / 100)
        goalLabel.text = String(cnv)
        memory.text = "\(mem) \(t)"
        return t
    }
    
}
