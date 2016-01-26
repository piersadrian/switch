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
    var requestPool = Set<Connection>(minimumCapacity: 10) // TODO: global option?
    var concurrency: Int = 10

    var status: ServerStatus = .Stopped

    // MARK: - Lifecycle

    public init() {
        self.requestQueue = dispatch_queue_create("RequestQueue", DISPATCH_QUEUE_SERIAL)
        self.socket = ListenerSocket()
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
        dispatch_async(socket.queue) {
            self.requestPool.insert(conn)
            print("pressure increased to \(Int(Float(self.requestPool.count) / Float(self.concurrency) * 100))%")
        }
    }

    func removeConnection(conn: Connection) {
        dispatch_async(socket.queue) {
            self.requestPool.remove(conn)
            print("pressure decreased to \(Int(Float(self.requestPool.count) / Float(self.concurrency) * 100))%")
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

//        print("              - accepted connection on FD \(ioSocket.socketFD)")

        addConnection(connection)

        dispatch_async(requestQueue) {
            connection.start()
        }
    }

    // MARK: - ConnectionDelegate

    func didCompleteConnection(connection: Connection) {
        removeConnection(connection)
    }
}
