//
//  Middleware.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

protocol Middleware {
    init(stack: MiddlewareStack)
    func call(env: Environment)
}

protocol MiddlewareStackDelegate {
    func didCompleteResponse(stack: MiddlewareStack)
}

class MiddlewareStack {
    static var stack: [Middleware.Type] = []

    var io: SocketDriver
    var delegate: MiddlewareStackDelegate?

    private var index: Int = 0
    private var env: Environment

    init(io: SocketDriver) {
        self.io = io
        self.env = Environment()
//        self.env = Environment(request: Request(), response: Response())
    }

    func start() {
        guard MiddlewareStack.stack.count > 0 else {
            fatalError("the middleware stack is empty. Set with MiddlewareStack.stack = [MyMiddleware.self...]")
        }

        io.open() // FIXME: will throw
        call(env)
    }

    func finish() {
        io.close()
        delegate?.didCompleteResponse(self)
    }

    func call(env: Environment) -> Environment {
        if index < MiddlewareStack.stack.count {
            let middleware = MiddlewareStack.stack[index].init(stack: self)
            index = index.advancedBy(1)

            middleware.call(env)
        }
        
        return env
    }

    // MARK: - Hashable

//    var hashValue: Int {
//        return Int(io.socket.socketFD)
//    }
}

//func ==(lhs: MiddlewareStack, rhs: MiddlewareStack) -> Bool {
//    return lhs.hashValue == rhs.hashValue
//}
