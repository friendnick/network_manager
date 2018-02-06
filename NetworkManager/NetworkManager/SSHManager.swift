//
//  SSHManager.swift
//  NetworkManager
//
//  Created by Mykola Vankovych on 06.02.18.
//  Copyright © 2018 Mykola Vankovych. All rights reserved.
//

import Foundation
import NMSSH

class SSHManager: UIViewController {

    var listenToResponse = true

    private var session: NMSSHSession? = nil

    private var completeResponse = String()
    private let startOfResponse = "startOfTheResponse"
    private let endOfResponse = "endOfTheResponse"
    private var recievedEndOfResponse = false
    private var getResponseCallback: ((String) -> ())? = nil

    func connect() {
        session = NMSSHSession(host: "192.168.178.2", andUsername: "cisco")
        if session == nil {
            print("no session?")
            return
        }

        session?.channel.delegate = self
        session?.connect()
        if session?.isConnected == true{
            session?.authenticate(byPassword: "Alpen$4410")
            if session?.isAuthorized != true {
                print("session is not authenticated.")
            }
        } else {
            print("session? couldn't connect")
        }

        do {
            try session?.channel.startShell()
            try session?.channel.write("cisco\n")
            try session?.channel.write("Alpen$4410\n")
            try session?.channel.write("config paging disable\n")
        } catch let err {
            print("connect: shell writing err:\(err)")
        }
    }
    func disconnect() {
        session?.channel.closeShell()
        session?.disconnect()
    }

    func startCommands() {
        recievedEndOfResponse = false
        do {
            try session?.channel.write(startOfResponse + "\n")
        } catch let err {
            print("startCommands: shell writing err: \(err)")
        }

    }
    func endCommands(getResponse: @escaping (String) -> ()) {
        do {
            try session?.channel.write(endOfResponse + "\n")
            getResponseCallback = getResponse
        } catch let err {
            print("endCommands: shell writing err: \(err)")
        }
    }

    func execute(command: String) {
        do {
            try session?.channel.write(command + "\n")
        } catch let err {
            print("execute: shell writing err: \(err)")
        }
    }
}

extension SSHManager: NMSSHChannelDelegate {
    func channel(_ channel: NMSSHChannel!, didReadData message: String!) {
        if !listenToResponse {
            return
        }

        guard let text = message else {
            return
        }

        if !recievedEndOfResponse {
            completeResponse += text
        }
        if completeResponse.contains(endOfResponse) {
            getResponseCallback?(completeResponse)
            //Reader.getUsers(from: completeResponse)
            recievedEndOfResponse = true
            completeResponse = ""
        }
    }
}
