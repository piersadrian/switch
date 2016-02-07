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

public protocol ServerDelegate: class {
    func connectionForSocket(socket: IOSocket) -> Connection
}

public class Server: ListenerSocketDelegate, ConnectionDelegate {
    // MARK: - Internal Properties

    let socket: ListenerSocket
    let requestQueue: dispatch_queue_t
    let controlQueue: dispatch_queue_t
    var concurrency: Int = 10

    var status: ServerStatus = .Stopped

    // MARK: - Private Properties

    private var requestPool = Set<WrappedConnection>(minimumCapacity: 10) // TODO: global option?

    // MARK: - Public Properties

    public weak var delegate: ServerDelegate?

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

        Signals.trap(.TERM, .INT, action: stop)

        socket.attach()
        status = .Running

        NSRunLoop.currentRunLoop().run()
    }

    public func stop() {
        status = .Stopping

        while !requestPool.isEmpty {}

        status = .Stopped
        socket.detach(immediately: true)
    }

    // MARK: - Private API

    private func addConnection(conn: WrappedConnection) {
        dispatch_sync(controlQueue) {
            let oldPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)
            self.requestPool.insert(conn)
            let newPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)

//            Log.event(conn.socket.socketFD, uuid: conn.socket.uuid, eventName: "connection add", oldValue: oldPressure, newValue: newPressure)
        }
    }

    private func removeConnection(conn: WrappedConnection) {
        dispatch_sync(controlQueue) {
            let oldPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)
            self.requestPool.remove(conn)
            let newPressure = Int(Float(self.requestPool.count) / Float(self.concurrency) * 100)

//            Log.event(conn.socket.socketFD, uuid: conn.socket.uuid, eventName: "connection remove", oldValue: oldPressure, newValue: newPressure)
        }
    }

    // MARK: - ListenerSocketDelegate

    func shouldAcceptConnectionOnSocket(socket: ListenerSocket) -> Bool {
        return requestPool.count < concurrency
    }

    func didAcceptConnectionOnSocket(socket: ListenerSocket, forChildSocket ioSocket: IOSocket) {
        guard status == .Running else { return }

        if var connection = delegate?.connectionForSocket(ioSocket) {
            connection.delegate = self
            addConnection(WrappedConnection(connection: connection))
            dispatch_async(requestQueue) {
                ioSocket.attach()
                connection.start()
            }
        }
        else {
            ioSocket.detach()
        }
    }

    func socketDidClose(socket: ListenerSocket) {
        dispatch_async(dispatch_get_main_queue()) {
            exit(0)
        }
    }

    // MARK: - ConnectionDelegate

    public func didCompleteConnection(connection: Connection) {
        removeConnection(WrappedConnection(connection: connection))
    }
}
