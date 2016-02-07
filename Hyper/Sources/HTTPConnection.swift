//
//  HTTPConnection.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/28/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

public class HTTPConnection: Connection {
    public let socket: IOSocket
    public weak var delegate: ConnectionDelegate?

    public var middlewareStack: MiddlewareStack
    public var request: HTTPRequest
    public var response: HTTPResponse

    // MARK: - Lifecycle

    public init(socket: IOSocket, middlewareStack: MiddlewareStack) {
        self.middlewareStack = middlewareStack
        self.request = HTTPRequest()
        self.response = HTTPResponse(request: request)

        self.socket = socket
        self.socket.delegate = self

        request.connection = self
        response.connection = self
    }

    // MARK: - Internal API

    func handleRequest(data: NSData) {
        do {
            try request.parseFromData(data)
        }
        catch {
            // respond with 400
            closeSocket()
        }

        middlewareStack.start(self)
    }

    func closeSocket() {
        socket.detach()
    }

    // MARK: - Public API

    public func start() {
        // set status to running
        socket.readData(completion: handleRequest)
    }

    public func finish() {
        closeSocket()
    }

    // MARK: - IOSocketDelegate

    public func socketDidDetach(socket: IOSocket) {
//        Log.event(socket.socketFD, uuid: socket.uuid, eventName: "socket detached; called delegate")

        // FIXME: this is not realistic - connections can continue after they close their sockets
        //      will need separate request and socket pools to make this efficient
        delegate?.didCompleteConnection(self)
    }
}
