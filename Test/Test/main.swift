//
//  main.swift
//  Test
//
//  Created by Piers Mainwaring on 1/4/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Hyper

class HTTPServerDelegate: ServerDelegate {
    func connectionForSocket(socket: IOSocket) -> Connection {
        let connection = HTTPConnection(socket: socket, middlewareStack: [
            Compressor.compress
        ])

        return connection
    }
}

class Compressor {
    static func compress(connection: HTTPConnection, stack: MiddlewareStack) -> HTTPConnection {
        if let expect = connection.request.headers[.Expect] where expect == "100-continue" {
            connection.response.sendContinue()
            return connection
        }

        connection.response.status = .Created
        connection.response.headers[.Connection] = "close"
//        connection.response.sendBodyChunk("some body chunk")
        connection.response.finish()

        return connection
    }
}

let serverDelegate = HTTPServerDelegate()
let server = Server()
server.delegate = serverDelegate
server.start()
