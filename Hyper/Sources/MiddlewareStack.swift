//
//  Middleware.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

public typealias Middleware = (connection: HTTPConnection, stack: MiddlewareStack) -> HTTPConnection

public class MiddlewareStack: ArrayLiteralConvertible {
    public var stack: [Middleware] = []

    private var index: Int = 0

    public init() {}
    public required init(arrayLiteral elements: Middleware...) {
        self.stack = elements
    }

    func start(connection: Connection) -> Connection {
        guard let conn = connection as? HTTPConnection else {
            fatalError("MiddlewareStack only operates on HTTPConnection instances")
        }

        return next(conn)
    }

    public func next(connection: HTTPConnection) -> Connection {
        var conn = connection

        if index < stack.count {
            let middleware = stack[index]
            index += 1
            conn = middleware(connection: conn, stack: self)
        }

        return conn
    }
}
