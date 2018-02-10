//
//  EditUserViewController.swift
//  NetworkManager
//
//  Created by Mykola Vankovych on 10.02.18.
//  Copyright © 2018 Mykola Vankovych. All rights reserved.
//

import UIKit

class EditUserViewController: UIViewController {

    @IBOutlet weak var macTableView: UITableView!
    var user: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let user = user else {
            return
        }
        super.title = user.surname + " " + user.name


        macTableView.reloadData()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension EditUserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let user = user else {
            return 0
        }
        return user.macs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let user = user,
               indexPath.row >= 0,
               indexPath.row < user.macs.count else {
                print("")
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "macCell", for: indexPath)
        let mac = user.macs[indexPath.row]
        cell.textLabel?.text = mac.description
        cell.detailTextLabel?.text = mac.mac
        cell.tag = indexPath.row
        return cell
    }


}

