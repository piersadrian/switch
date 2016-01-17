//
//  ConnectionHandler.swift
//  Flow
//
//  Created by Piers Mainwaring on 1/16/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

protocol ConnectionDelegate {
    func didCompleteResponse(connection: Connection)
}

class Connection: Hashable {
    let driver: SocketDriver

    var delegate: ConnectionDelegate?

    init(socket: IOSocket) {
        self.driver = SocketDriver(socket: socket)
    }

    // MARK: - Public API

    func run() {
        driver.open()
        driver.readRequest { data in
            let request = self.buildRequest(data)
            self.handleRequest(request)
            self.driver.writeResponse(request.response.data, completion: self.finish)
        }
    }

    func finish() {
        driver.close()
        delegate?.didCompleteResponse(self)
    }

    // override to customize request creation, request data from client, etc
    func buildRequest(data: NSData) -> Request {
        return RawRequest(data: data)
    }

    // main override point for launching application logic
    func handleRequest(req: Request) {}

    // MARK: - Hashable

    var hashValue: Int {
        return Int(driver.socket.socketFD)
    }
}

// MARK: - Hashable

func ==(lhs: Connection, rhs: Connection) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
