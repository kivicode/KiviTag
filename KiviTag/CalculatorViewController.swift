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
        
        var frm = "EUR"
        var t  = "EUR"
        let defaults = UserDefaults.standard
        if let from = defaults.string(forKey: defaultsKeys.settingsFrom) {
            frm = from
        }
        if let to = defaults.string(forKey: defaultsKeys.settingsTo) {
            t = to
        }
        
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
        
        
        var txt = baseLabel.text ?? "0"
        txt = txt.replacingOccurrences(of: ",", with: ".", options: .literal, range: nil)
        let toBase = (Float(txt) ?? 0) / Float(defaultsKeys.rates[frm] ?? 1)
        var cnv: Float = toBase * Float(defaultsKeys.rates[t] ?? 1)
        cnv = Float(round(100 * cnv) / 100)
        goalLabel.text = String(cnv)
        
        if sender.tag == 14 {
            mem += Float(goalLabel.text ?? "0") ?? 0.0
            memory.text = "\(mem) \(t)"
        }
        if sender.tag == 13 {
            mem = 0
            memory.text = "0 \(t)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
