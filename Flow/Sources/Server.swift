//
//  Server.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/21/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

protocol ServerDelegate {
    func didReceiveRequest(server: Server, connection: Connection)
}

public class Server: ListenerSocketDelegate, ConnectionDelegate {
    var delegate: ServerDelegate?

    // MARK: - Internal Properties

    let socket: ListenerSocket
    var requestPool = Set<Connection>(minimumCapacity: 10) // TODO: global option?
    var concurrency: Int = 10

    // MARK: - Lifecycle

    public init() {
        self.socket = ListenerSocket()
        self.socket.delegate = self
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    public func start() {
        socket.open()
        Signals.trap(.TERM, action: stop)
        dispatch_main()
    }

    public func stop() {
        self.socket.close()
    }

    // MARK: - Internal API

    func addConnection(conn: Connection) {
        requestPool.insert(conn)
    }

    func removeConnection(conn: Connection) {
        requestPool.remove(conn)
    }

    func createConnection(socket: IOSocket) -> Connection {
        return Connection(socket: socket)
    }

    // MARK: - ListenerSocketDelegate

    func shouldAcceptConnection(socket: ListenerSocket) -> Bool {
        return requestPool.count < concurrency
    }

    func didAcceptConnection(socket: ListenerSocket, ioSocket: IOSocket) {
        let connection = createConnection(ioSocket)

        delegate?.didReceiveRequest(self, connection: connection)
        addConnection(connection)
        connection.run()
    }

    // MARK: - ConnectionDelegate

    func didCompleteResponse(connection: Connection) {
        removeConnection(connection)
    }
}
