//
//  Listener.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/21/15.
//  Copyright © 2015 piersadrian. All rights reserved.
//

import Foundation

public class Listener: ListenerSocketDelegate, MiddlewareStackDelegate {
    // MARK: - Internal Properties

    let socket: ListenerSocket
    var queue: dispatch_queue_t
    var requestPool = Set<MiddlewareStack>(minimumCapacity: 10) // TODO: global option?
    var concurrency: Int {
        return requestPool.count
    }

    // MARK: - Lifecycle

    public init() {
        self.queue = dispatch_queue_create("requestQueue", DISPATCH_QUEUE_CONCURRENT)
        self.socket = ListenerSocket()
        self.socket.delegate = self
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    public func start() {
        self.socket.open()
        Signals.trap(.TERM, action: stop)
        dispatch_main()
    }

    public func stop() {
        self.socket.close()
    }

    // MARK: - Private API

    // MARK: - MiddlewareStackDelegate

    func didCompleteResponse(stack: MiddlewareStack) {
        dispatch_sync(queue) {
            self.requestPool.remove(stack)
        }
    }

    // MARK: - SocketDelegate

    func didAcceptConnection(childSocket: IOSocket) {
        let stack = buildMiddlewareStack(socket: childSocket)
        requestPool.insert(stack)

        dispatch_async(queue) {
            stack.start()
        }
    }

    func buildMiddlewareStack(socket socket: IOSocket) -> MiddlewareStack {
        let io = IOController(socket: socket)
        let stack = MiddlewareStack(io: io)
        stack.delegate = self
        return stack
    }
}
