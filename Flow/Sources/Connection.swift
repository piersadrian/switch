//
//  ConnectionHandler.swift
//  Flow
//
//  Created by Piers Mainwaring on 1/16/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

protocol ConnectionDelegate: class {
    func didCompleteConnection(connection: Connection)
}

class Connection: Hashable, IOSocketDelegate {
    let socket: IOSocket

    weak var delegate: ConnectionDelegate?

    init(socket: IOSocket) {
        self.socket = socket
        self.socket.delegate = self
    }

    var didCallFinish = false
    var didCallDelegate = false

    // MARK: - Public API

    func start() {
        socket.attach()
        socket.readRequest(0.5) { data in
//            let request = self.buildRequest(data)
            let responseData = self.handleRequest(data)
            self.socket.writeResponse(responseData, timeout: 0.5, completion: self.finish)
//            self.finish()
        }
    }

    func finish() {
        didCallFinish = true
        socket.release()
    }

    // main override point for launching application logic
    func handleRequest(data: NSData) -> NSData {
//        sleep(arc4random() % 3)
        return "HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
    }

    // MARK: - IOSocketDelegate

    func socketDidClose(socket: IOSocket) {
        didCallDelegate = true
        delegate?.didCompleteConnection(self)
    }

    // MARK: - Hashable

    var hashValue: Int {
        return Int(socket.socketFD)
    }
}

// MARK: - Hashable

func ==(lhs: Connection, rhs: Connection) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
