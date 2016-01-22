//
//  Server.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/21/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

enum ServerStatus {
    case Starting, Running, Stopping, Stopped
}

public class Server: ListenerSocketDelegate, ConnectionDelegate {
    // MARK: - Internal Properties

    let socket: ListenerSocket
    var requestPool = Set<Connection>(minimumCapacity: 10) // TODO: global option?
    var concurrency: Int = 10

    var status: ServerStatus = .Stopped

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
        status = .Starting

        Signals.trap(.TERM, action: stop)
        Signals.trap(.TERM, action: stop)

        socket.open()
        status = .Running

        NSRunLoop.currentRunLoop().run()
    }

    public func stop() {
        status = .Stopping

        while !requestPool.isEmpty {}

        self.socket.close()
        status = .Stopped

        dispatch_sync(dispatch_get_main_queue()) {
            exit(0)
        }
    }

    // MARK: - Internal API

    func addConnection(conn: Connection) {
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            self.requestPool.insert(conn)
        }
    }

    func removeConnection(conn: Connection) {
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            self.requestPool.remove(conn)
        }
//        print("pressure: \(Int(Float(requestPool.count) / Float(concurrency) * 100))% - removing connection \(conn.socket.socketFD)")
    }

    func createConnection(socket: IOSocket) -> Connection {
        return Connection(socket: socket)
    }

    // MARK: - ListenerSocketDelegate

    func shouldAcceptConnection(socket: ListenerSocket) -> Bool {
        let spaceAvailable = requestPool.count < concurrency

        if spaceAvailable {
//            print("pressure: \(Int(Float(requestPool.count) / Float(concurrency) * 100))% - accepting connection")
        }
        else {
//            print("pressure: \(Int(Float(requestPool.count) / Float(concurrency) * 100))% - refusing connection")
        }

        return spaceAvailable
    }

    func didAcceptConnection(socket: ListenerSocket, ioSocket: IOSocket) {
        guard status == .Running else {
            return
        }

        let connection = createConnection(ioSocket)
        connection.delegate = self

//        print("              - accepted connection on FD \(ioSocket.socketFD)")

        addConnection(connection)
        connection.start()
    }

    // MARK: - ConnectionDelegate

    func didCompleteConnection(connection: Connection) {
        removeConnection(connection)
    }
}
