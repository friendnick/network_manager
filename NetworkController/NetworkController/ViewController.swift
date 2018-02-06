//
//  ViewController.swift
//  NetworkController
//
//  Created by Mykola Vankovych on 04.02.18.
//  Copyright © 2018 Mykola Vankovych. All rights reserved.
//

import UIKit
import SwiftSH

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        trySSH()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func trySSHPressed(_ sender: Any) {
        trySSH()
    }
    func trySSH() {
        textView.text = ""
        guard let command = Command(host: "192.168.178.2") else {
            textView.text = "Couldn't connect."
            print("Couldn't connect.")
            return
        }
        // ...
        command.connect { (error) in
            print("Error:\(error)")
        }
        command
//        command.connect()
//            .authenticate(AuthenticationChallenge.byKeyboardInteractive(username: "cisco") { (result) -> String in
//                print("auth result:\(result)")
//                return "Alpen$4410"
//            })
//            .authenticate(.byPassword(username: "demo", password: "password"))
//            .execute("show macfilter summary") { (command, result: String?, error) in
//                if let result = result {
//
//                    self.textView.text = self.textView.text + "\n\(result)"
//                    print("\(result)")
//                } else {
//                    self.textView.text = self.textView.text + "\nexecute ERROR: \(error)"
//                    print("ERROR: \(error)")
//                }
//        }
//        command.connect()
//            .authenticate(.byPassword(username: "cisco", password: "Alpen$4410"))
//            .execute(command, completion: { (command: String, result: String?, error: Error?) -> Void in
//                if let result = result {
//                    print("\(result)")
//                } else {
//                    print("ERROR: \(error)")
//                }
//        })
//        let auth = command.connect()
//            .authenticate(.byPassword(username: "cisco", password: "Alpen$4410"))
//        auth.
//        auth.execute(command, completion: (command: String, result: String? , error: Error?) {
//            if let result = result {
//                print("\(result)")
//            } else {
//                print("ERROR: \(error)")
//            }
//        })
    }


}

