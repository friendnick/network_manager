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
    @IBOutlet var selectButton: UIBarButtonItem!
    @IBOutlet var cancelButton: UIBarButtonItem!

    let sshManager = SSHManager()
    var users = [User]()
    var isReadCompleted = false

    override func viewDidLoad() {
        super.viewDidLoad()

        sshManager.connect()

        usersTableView.allowsMultipleSelectionDuringEditing = true
        updateToolbarButtons()

        self.reloadUsers()
    }

    @IBAction func selectPressed(_ sender: Any) {
        setSelectingMode(true)
    }

    @IBAction func cancelPressed(_ sender: Any) {
        setSelectingMode(false)
    }

    func setSelectingMode(_ isSelecting: Bool) {
        usersTableView.setEditing(isSelecting, animated: true)
        self.navigationController?.setToolbarHidden(!isSelecting, animated: true)
        updateToolbarButtons()
    }

    func updateToolbarButtons() {
        if usersTableView.isEditing {
            self.navigationItem.rightBarButtonItem = self.cancelButton
            //self.toolbarItems
        } else {
            self.navigationItem.rightBarButtonItem = self.selectButton
        }
        self.selectButton.isEnabled = false
        self.cancelButton.isEnabled = true
        self.selectButton.isEnabled = false
        self.selectButton.isEnabled = true
    }

    @IBAction func enablePressed(_ sender: Any) {
        if !usersTableView.isEditing {
            return
        }
        guard let selectedIndicies = usersTableView.indexPathsForSelectedRows else {
            return
        }

        var confirmMessage = "These users will be enabled:\n\n"
        for selectedIndex in selectedIndicies {
            confirmMessage += users[selectedIndex.row].surname + " " + users[selectedIndex.row].name + "\n"
        }

        askForConfirmation(message: confirmMessage) { (_) in
            for selectedIndex in selectedIndicies {
                self.setEnabled(user: &self.users[selectedIndex.row], enabled: true)
            }

            self.usersTableView.reloadRows(at: selectedIndicies, with: .none)

            self.setSelectingMode(false)
        }
    }
    @IBAction func disablePressed(_ sender: Any) {
        if !usersTableView.isEditing {
            return
        }
        guard let selectedIndicies = usersTableView.indexPathsForSelectedRows else {
            return
        }

        var confirmMessage = "These users will be disabled:\n\n"
        for selectedIndex in selectedIndicies {
            confirmMessage += users[selectedIndex.row].surname + " " + users[selectedIndex.row].name + "\n"
        }

        askForConfirmation(message: confirmMessage) { (_) in
            for selectedIndex in selectedIndicies {
                self.setEnabled(user: &self.users[selectedIndex.row], enabled: false)
            }

            self.usersTableView.reloadRows(at: selectedIndicies, with: .none)

            self.setSelectingMode(false)
        }
    }

    @IBAction func disableOthersPressed(_ sender: Any) {
        if !usersTableView.isEditing {
            return
        }
        guard let selectedIndicies = usersTableView.indexPathsForSelectedRows else {
            return
        }
        let selectedRows = selectedIndicies.reduce([Int](), { $0 + [$1.row] })

        var confirmMessage = "Only these users will be enabled, others will be disabled:\n\n"
        for selectedRow in selectedRows {
            confirmMessage += users[selectedRow].surname + " " + users[selectedRow].name + "\n"
        }

        askForConfirmation(message: confirmMessage) { (_) in
            for (index, _) in self.users.enumerated() {
                if selectedRows.contains(index) {
                    self.setEnabled(user: &self.users[index], enabled: true)
                } else {
                    self.setEnabled(user: &self.users[index], enabled: false)
                }
            }

            let range = NSMakeRange(0, self.usersTableView.numberOfSections)
            let sections = NSIndexSet(indexesIn: range)
            self.usersTableView.reloadSections(sections as IndexSet, with: .none)
            //self.usersTableView.reloadRows(at: selectedIndicies, with: .none)
            self.setSelectingMode(false)
        }
    }

    func setEnabled( user: inout User, enabled: Bool) {
        user.hasInternet = enabled
        let setEnabledCommands = Reader.getEnableCommands(for: user, enabled: enabled)
        let str = setEnabledCommands.reduce("", { $0 + $1 + "\n" })
        print("\(user.fullName):")
        print(str)
    }

    func askForConfirmation(message: String, ifConfirmed: @escaping (UIAlertAction) -> ()) {
        let confirmationDialog = UIAlertController(
            title: "Confirm Action",
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )

        confirmationDialog.addAction(UIAlertAction(
            title: "Confirm",
            style: .default,
            handler: ifConfirmed))
        confirmationDialog.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { _ in
                // Don't do stuff
        }))
        present(confirmationDialog, animated: true, completion: nil)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if usersTableView.isEditing {
            return false
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let editUserViewController as EditUserViewController:
            guard let senderCell = sender as? UITableViewCell else {
                print("no sender")
                return
            }
            if senderCell.tag < 0 || senderCell.tag >= users.count {
                print("tag out of bounds")
                return
            }
            let user = users[senderCell.tag]
            editUserViewController.user = user
            print("user name: \(user.fullName), \(user.macs.first?.mac ?? "no mac")")
            for mac in user.macs {
                print("mac:\(mac.mac) desc:\(mac.description)")
            }

        default:
            print("unknown destination")
            return
        }
    }

    @IBAction func refreshPressed(_ sender: Any) {
        reloadUsers()
    }

    func reloadUsers() {
        while !self.isReadCompleted {
            self.getUsers()
        }
        self.isReadCompleted = false

        self.usersTableView.reloadData()

//        DispatchQueue.global(qos: .background).async {
//            print("This is run on the background queue")
//            while !self.isReadCompleted {
//                self.getUsers()
//            }
//            self.isReadCompleted = false
//
//            DispatchQueue.main.async {
//                print("This is run on the main queue, after the previous code in outer block")
//                self.usersTableView.reloadData()
//            }
//        }
    }

    func getUsers() {
        let startConnection = DispatchTime.now().uptimeNanoseconds
        isReadCompleted = false
        //let ssh = SSHManager()
        sshManager.startCommands()
        sshManager.execute(command: "show macfilter summary")
        sshManager.execute(command: "y")
        sshManager.endCommands { (response) in
            self.users = Reader.getUsers(from: response).sorted(by: { $0.fullName < $1.fullName })
            self.isReadCompleted = true
        }
        let startReading = DispatchTime.now().uptimeNanoseconds
        while DispatchTime.now().uptimeNanoseconds - startReading < 3000000000 && !isReadCompleted {
        }
        let finishTime = DispatchTime.now().uptimeNanoseconds
        print("time connection: \((finishTime - startConnection) / 1000000)ms")
        print("time reading:\((finishTime - startReading) / 1000000)ms")
        //ssh.disconnect()
    }

    @objc func switchChanged(_ sender: UISwitch!) {

    }

    deinit {
        sshManager.disconnect()
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        let user = users[indexPath.row]
        cell.textLabel?.text = user.surname + " " + user.name
//        cell.detailTextLabel?.text = user.hasInternet ? "Yes" : "No"
//        cell.detailTextLabel?.textColor = user.hasInternet ? UIColor.green : UIColor.red

        let switchView = UISwitch(frame: .zero)
        switchView.setOn(user.hasInternet, animated: false)
        switchView.tag = indexPath.row // for detect which row switch Changed
        switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView

        cell.tag = indexPath.row
        return cell
    }


}

