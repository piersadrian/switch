//
//  ListenerSocket.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

protocol ListenerSocketDelegate: class {
    func shouldAcceptConnection(socket: ListenerSocket) -> Bool
    func didAcceptConnection(socket: ListenerSocket, ioSocket: IOSocket)

//    func queueFor
}

class ListenerSocket: Socket {
    weak var delegate: ListenerSocketDelegate?

    // MARK: - Socket Overrides

    override func configure() {
        let eventHandler = { [unowned self] in
            let connectionCount = Int(self.readSource!.data())
            var acceptedConnections = 0

            while acceptedConnections < connectionCount {
                if self.delegate?.shouldAcceptConnection(self) ?? true {
                    let childSocket = try! self.acceptConnection()

                    if let delegate = self.delegate {
                        delegate.didAcceptConnection(self, ioSocket: childSocket)
                    }
                    else {
                        // close the socket immediately as there's no delegate to handle it
                        childSocket.release()
                    }

                    acceptedConnections += 1
                }
            }
        }

        readSource = createSource(DISPATCH_SOURCE_TYPE_READ, handler: eventHandler) {}
        readSource!.run()
    }

    // MARK: - Private API

    private func acceptConnection() throws -> IOSocket {
        // Accept the incoming connection

        var childAddr = sockaddr()
        var addrLength = socklen_t(sizeof(sockaddr))

        let childFD = withUnsafeMutablePointers(&childAddr, &addrLength) { accept(self.socketFD, $0, $1) }

        guard childFD != -1 else {
            throw SocketError(errno: errno)
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

        let childSocket = IOSocket(fd: childFD, handlerQueue: handlerQueue)
        return childSocket
    }
}