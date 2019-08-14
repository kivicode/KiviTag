//
//  ReportsViewController.swift
//  KiviTag
//
//  Created by KiviCode on 14/08/2019.
//  Copyright © 2019 KiviCode. All rights reserved.
//

import Foundation
import MessageUI

class ReportsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var bugBodyInput: UITextView!
    
    @IBOutlet weak var userEmail: UITextField!
    
    @IBAction func Send(_ sender: Any) {
        sendEmail()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject("New KiviTag bug")
            mail.setToRecipients(["kivicode.dev@gmail.com"])
            mail.setMessageBody("Hey! Here is a new issue\n\n\(bugBodyInput.text ?? "But... You're just a cool guy. Here is no problem :)")\nUser e-mail: \(userEmail.text ?? "anonymous")", isHTML: false)
            
            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
