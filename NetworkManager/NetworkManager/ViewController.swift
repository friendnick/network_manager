//
//  ViewController.swift
//  NetworkManager
//
//  Created by Mykola Vankovych on 03.02.18.
//  Copyright © 2018 Mykola Vankovych. All rights reserved.
//

import UIKit
import NMSSH

class ViewController: UIViewController, NMSSHChannelDelegate {

    @IBOutlet weak var usersTableView: UITableView!
    var completeResponse = String()
    let endOfResponse = "endOfTheMacFilterTableResponse"
    var timer: Timer? = nil

    var usersMacs = [User: [Mac]]()

    @IBAction func startTimerPressed(_ sender: Any) {

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //trySSH()
        reloadUsers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {

        guard let text = message else {
            return
        }

        completeResponse += text
        if completeResponse.contains(endOfResponse) {
            Reader.getUsers(from: completeResponse)
            completeResponse = ""
        }
        
        print("message read:\(message)")
    }

    func reloadUsers() {
        let ssh = SSHManager()
        ssh.connect()
        ssh.startCommands()
        ssh.execute(command: "show macfilter summary")
        ssh.execute(command: "y")
        ssh.endCommands { (response) in
            self.usersMacs = Reader.getUsers(from: response)
        }
        sleep(1)
        ssh.disconnect()
        usersTableView.reloadData()
    }

    func trySSH() {
        guard let session = NMSSHSession(host: "192.168.178.2", andUsername: "cisco") else {
            print("no session")
            return
        }
        session.channel.delegate = self
        session.connect()
        if session.isConnected == true{
            session.authenticate(byPassword: "Alpen$4410")
            if session.isAuthorized == true {
                print("works")
            }
        }
        do {
            try session.channel.startShell()
            try session.channel.write("cisco\n")
            try session.channel.write("Alpen$4410\n")
            try session.channel.write("config paging disable\n")
            try session.channel.write("show macfilter summary\n")
            try session.channel.write("y")
            try session.channel.write(endOfResponse + "\n")
        } catch let err {
            print("shell writing err:\(err)")
        }

        sleep(1)
        session.channel.closeShell()
    }


}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersMacs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        let user = usersMacs.sorted(by: {  $0.key.surname < $1.key.surname })[indexPath.row].key
        cell.textLabel?.text = user.surname + " " + user.name
        cell.detailTextLabel?.text = user.hasInternet ? "Yes" : "No"
        cell.detailTextLabel?.textColor = user.hasInternet ? UIColor.green : UIColor.red
        return cell
    }


}

