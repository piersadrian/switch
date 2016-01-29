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

    required public init(socket: IOSocket) {
        self.socket = socket
        self.socket.delegate = self
    }

    public func start() {
        socket.readRequest(0.5, completion: handleRequest)
    }

    func handleRequest(data: NSData) {
        let responseData = "HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
        socket.writeResponse(responseData, timeout: 0.5, completion: finish)
    }

    func finish() {
        socket.detach()
    }

    // MARK: - IOSocketDelegate

    public func socketDidDetach(socket: IOSocket) {
        delegate?.didCompleteConnection(self)
    }
}
