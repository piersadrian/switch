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
    let requestQueue: dispatch_queue_t
    let controlQueue: dispatch_queue_t
    var requestPool = Set<Connection>(minimumCapacity: 10) // TODO: global option?
    var concurrency: Int = 1

    var status: ServerStatus = .Stopped

    // MARK: - Lifecycle

    public init() {
        self.controlQueue = dispatch_queue_create("com.playfair.server-control", DISPATCH_QUEUE_SERIAL)
        self.requestQueue = dispatch_queue_create("com.playfair.requests", DISPATCH_QUEUE_CONCURRENT)
        self.socket = ListenerSocket(handlerQueue: self.requestQueue)
        self.socket.delegate = self
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    public func start() {
        status = .Starting

//        Signals.trap(.TERM, action: stop)
//        Signals.trap(.TERM, action: stop)

        socket.attach()
        status = .Running

        NSRunLoop.currentRunLoop().run()
    }

    public func stop() {
        status = .Stopping

        while !requestPool.isEmpty {}

        socket.release()
        status = .Stopped

        dispatch_sync(dispatch_get_main_queue()) {
            exit(0)
        }
    }

    // MARK: - Internal API

    func addConnection(conn: Connection) {
        dispatch_sync(controlQueue) {
            let oldPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)
            self.requestPool.insert(conn)
            let newPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)

            Log.event(conn.socket.socketFD, uuid: conn.socket.uuid, eventName: "connection add", oldValue: oldPressure, newValue: newPressure)

            dispatch_async(self.requestQueue) {
                conn.start()
            }
        }
    }

    func removeConnection(conn: Connection) {
        let uuid = conn.socket.uuid

        dispatch_sync(controlQueue) {
            let oldPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)
            let removed = self.requestPool.remove(conn)
            let newPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)

            Log.event(conn.socket.socketFD, uuid: conn.socket.uuid, eventName: "connection remove", oldValue: oldPressure, newValue: newPressure)
        }
    }

    func createConnection(socket: IOSocket) -> Connection {
        return Connection(socket: socket)
    }

    // MARK: - ListenerSocketDelegate

    func shouldAcceptConnection(socket: ListenerSocket) -> Bool {
        return requestPool.count < concurrency
    }

    func didAcceptConnection(socket: ListenerSocket, ioSocket: IOSocket) {
        guard status == .Running else { return }

        let connection = createConnection(ioSocket)
        connection.delegate = self

        addConnection(connection)
    }

    // MARK: - ConnectionDelegate

    func didCompleteConnection(connection: Connection) {
        removeConnection(connection)
    }
}
