//
//  ConnectionHandler.swift
//  Flow
//
//  Created by Piers Mainwaring on 1/16/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

public protocol ConnectionDelegate: class {
    func didCompleteConnection(connection: Connection)
}

public protocol Connection: class, IOSocketDelegate {
    var delegate: ConnectionDelegate? { get set }
    var socket: IOSocket { get }

    func start()
}

class WrappedConnection: Hashable {
    // MARK: - Private Properties

    var hashValue: Int {
        return connection.socket.hashValue
    }

    // MARK: - Internal Properties

    let connection: Connection

    // MARK: - Lifecycle

    init(connection: Connection) {
        self.connection = connection
    }
}

func ==(lhs: WrappedConnection, rhs: WrappedConnection) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
