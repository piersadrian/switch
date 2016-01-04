//
//  ListenerSocket.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2015 piersadrian. All rights reserved.
//

import Foundation

protocol ListenerSocketDelegate {
    var queue: dispatch_queue_t { get }

    func didAcceptConnection(childSocket: IOSocket)
}

class ListenerSocket: Socket {
    var delegate: ListenerSocketDelegate?

    override func configure() {
        let eventHandler = {
            let connectionCount = Int(self.events.readSource!.data())
            var acceptedConnections = 0

            while acceptedConnections < connectionCount {
                if self.acceptConnection(socket: self.socket) {
                    acceptedConnections += 1
                }
            }
        }

        self.events.createSource(.Reader, handler: eventHandler, cancelHandler: self.close)
        self.events.readSource!.run()
    }

    // FIXME: this should throw SocketErrors rather than return a Bool
    private func acceptConnection(socket socket: CFSocket) -> Bool {
        guard let delegate = self.delegate else {
            fatalError("couldn't accept connection because delegate isn't set")
        }

        // Accept the incoming connection

        var childAddr = sockaddr()
        var addrLength = socklen_t(sizeof(sockaddr))

        let childFD = withUnsafeMutablePointers(&childAddr, &addrLength) { accept(self.socketFD, $0, $1) }

        guard childFD != -1 else {
            return false
        }

        // Configure the child socket

        guard fcntl_setnonblock(childFD) != -1 else {
            fatalError("couldn't set child socket file descriptor to nonblocking")
        }

        var sockOptionSetting: Int = 1
        guard setsockopt(childFD, SOL_SOCKET, SO_NOSIGPIPE, &sockOptionSetting, socklen_t(sizeof(Int))) != -1 else {
            fatalError("couldn't set child socket to nosigpipe")
        }

        // Create child socket wrapper

        dispatch_async(delegate.queue) {
            let childSocket = IOSocket(fd: childFD)
            delegate.didAcceptConnection(childSocket)
        }
        
        return true
    }
}