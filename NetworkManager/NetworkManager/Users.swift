//
//  Users.swift
//  NetworkManager
//
//  Created by Mykola Vankovych on 05.02.18.
//  Copyright © 2018 Mykola Vankovych. All rights reserved.
//

import Foundation

extension String {
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }

//    subscript (i: Int) -> String {
//        return String(self[i] as Character)
//    }
//
//    subscript (r: Range<Int>) -> String {
//        let start = index(startIndex, offsetBy: r.lowerBound)
//        let end = index(startIndex, offsetBy: r.upperBound)
//        return self[Range(start ..< end)]
//    }
}
extension Collection {

    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct Mac {
    var mac: String
    var description: String
}

struct User {
    var surname: String
    var name: String
    var hasInternet: Bool
    //var macs: [Mac]
}

extension User: Hashable {
    var hashValue: Int {
        return (surname + name).hashValue
    }

    static func ==(lhs: User, rhs: User) -> Bool {
        return (lhs.surname + lhs.name) == (rhs.surname + lhs.name)
    }
}

class Reader {
    static func getUsers(from terminalStr: String) -> [User: [Mac]] {

        var userMacs = [User:[Mac]]()

        let foundIndecies = terminalStr.indicesOf(string: "MAC Address")
        if foundIndecies.isEmpty {
            return userMacs
        }

        var tableChunks = [String]()

        var iter = 0
        while iter < foundIndecies.count - 1 {
            let lowerBound = terminalStr.index(terminalStr.startIndex, offsetBy: foundIndecies[iter])
            let upperBound = terminalStr.index(terminalStr.startIndex, offsetBy: foundIndecies[iter + 1])
            tableChunks.append(String(terminalStr[lowerBound...upperBound]))
            iter += 1
        }
        let lowerBound = terminalStr.index(terminalStr.startIndex, offsetBy: foundIndecies[iter])
        let upperBound = terminalStr.endIndex
        tableChunks.append(String(terminalStr[lowerBound..<upperBound]))

        for chunk in tableChunks {
            let rows = chunk.split(separator: "\r\n")
            var rowIter = 2 // Macs start 2 rows after the header
            while rowIter < rows.count && startsWithMac(str: String(rows[rowIter])) {
                let rowFields = rows[rowIter].components(separatedBy: .whitespaces).filter {!$0.isEmpty}
                // Reading columns
                let macStr = rowFields[safe: 0] ?? ""
                let hasInternet = (rowFields[safe: 1] ?? "") == "3" ? true : false
                let surname = rowFields[safe: 3] ?? ""
                let name = rowFields[safe: 4] ?? ""
                let description = rowFields[safe: 5] ?? ""
                // Creating User and Mac
                let user = User(surname: surname, name: name, hasInternet: hasInternet)
                let mac = Mac(mac: macStr, description: description)
                // Adding mac for user
                if userMacs[user] == nil {
                    userMacs[user] = [mac]
                } else {
                    userMacs[user]?.append(mac)
                }
                rowIter += 1
            }
        }
        for usr in userMacs {
            print("user:\(usr.key.surname + " " + usr.key.name) has \(usr.key.hasInternet ? "" : "no") internet")
            print("macs:\(usr.value.reduce("", { $0 + " " + $1.mac + "-" + $1.description }))")
        }
        return userMacs
    }

    private static func startsWithMac(str: String) -> Bool {
        if str.count < 18 || str[2] != ":" || str[5] != ":" || str[8] != ":" || str[11] != ":" || str[14] != ":" {
            return false
        }

        return true
    }
}
