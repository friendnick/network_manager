//
//  SSHManager.swift
//  NetworkManager
//
//  Created by Mykola Vankovych on 06.02.18.
//  Copyright © 2018 Mykola Vankovych. All rights reserved.
//

import Foundation
import NMSSH

class SSHManager: NSObject {

    var listenToResponse = true
    var disconnectedManually = false

    var isConnected: Bool {
        return session?.isConnected ?? false
    }

    private var session: NMSSHSession? = nil
    private var mainView: UIViewController? = nil
    private var aliveTimer: Timer? = nil

    private var completeResponse = String()
    private let startOfResponse = "startOfTheResponse"
    private let endOfResponse = "endOfTheResponse"
    private var recievedEndOfResponse = false
    private var getResponseCallback: ((String) -> ())? = nil

    init(mainView: UIViewController?) {
        self.mainView = mainView
    }

    func connect() {
        session = NMSSHSession(host: "192.168.178.2", andUsername: "cisco")
        if session == nil {
            showError("Session couldn't be created.")
            return
        }

        session?.channel.delegate = self
        session?.connect()
        if session?.isConnected == true{
            session?.authenticate(byPassword: "Alpen$4410")
            if session?.isAuthorized != true {
                showError("Session is not authorized.")
            }
        } else {
            showError("Session couldn't connect.")
            return
        }

        startShellLogin()
    }
    func disconnect() {
        disconnectedManually = true
        session?.channel.closeShell()
        session?.disconnect()
    }

    func startCommands() {
        recievedEndOfResponse = false
        do {
            try session?.channel.write(startOfResponse + "\n")
        } catch let err {
            showError("StartCommands: shell writing err: \(err).")
        }
    }
    func endCommands(getResponse: ((String) -> ())?) {
        do {
            try session?.channel.write(endOfResponse + "\n")
            getResponseCallback = getResponse
        } catch let err {
            showError("EndCommands: shell writing err: \(err).")
        }
    }

    func execute(command: String) {
        do {
            try session?.channel.write(command + "\n")
        } catch let err {
            showError("Execute: shell writing err: \(err).")
        }
    }

    private func startShellLogin() {
        do {
            try session?.channel.startShell()
            try session?.channel.write("cisco\n")
            try session?.channel.write("Alpen$4410\n")
            try session?.channel.write("config paging disable\n")
            aliveTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true, block: { (_) in
                do {
                    try self.session?.channel.write("youShouldKeepMeActive")
                } catch _ {

                }
                return
            })

        } catch let err {
            showError("Connect: shell writing err:\(err).")
        }
    }

    private func showError(_ message: String, userClosable: Bool = true) -> UIAlertController {
        let errorDialog = UIAlertController(
            title: "SSH Error",
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        if userClosable {
            errorDialog.addAction(UIAlertAction(
                title: "Ok",
                style: .default,
                handler: { _ in
                    // Don't do stuff
            }))
        }
        mainView?.present(errorDialog, animated: true, completion: nil)
        return errorDialog
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

    func channelShellDidClose(_ channel: NMSSHChannel!) {
        guard let currentChannel = session?.channel else {
            return
        }

        if (channel == currentChannel) {
            let errorDialog = showError("Channel: Shell has been closed. Reconnecting...", userClosable: false)
            disconnect()
            connect()
            errorDialog.dismiss(animated: true, completion: nil)
            //startShellLogin()
        } else {
            showError("Peripheral Channel: Shell has been closed.")
        }
    }
}

extension SSHManager: NMSSHSessionDelegate {
    func session(_ session: NMSSHSession!, didDisconnectWithError error: Error!) {
        if session == self.session
           && !disconnectedManually {
            let errorDialog = showError("Session disconnected with error: \(error).\nReconnecting...", userClosable: false)
            //disconnect()
            connect()
            errorDialog.dismiss(animated: true, completion: nil)
        }
        disconnectedManually = false
    }
}
