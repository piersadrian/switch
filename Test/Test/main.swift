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
        return HTTPConnection(socket: socket)
    }
}

let serverDelegate = HTTPServerDelegate()
let server = Server()
server.delegate = serverDelegate
server.start()
