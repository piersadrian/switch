//
//  HTTPIOAdapter.swift
//  Switch
//
//  Created by Piers Mainwaring on 1/2/16.
//  Copyright © 2016 piersadrian. All rights reserved.
//

import Foundation

private enum HTTPConstants: CustomStringConvertible {
    case CRLF
    case Separator
    case ChunkTerminator

    // MARK: - CustomStringConvertible

    var description: String {
        switch self {
        case .CRLF:                 return "\r\n"
        case .Separator:            return "\r\n\r\n"
        case .ChunkTerminator:      return "0\r\n\r\n"
        }
    }
}

class HTTPIOAdapter: Middleware {
    var stack: MiddlewareStack

    required init(stack: MiddlewareStack) {
        self.stack = stack
    }

    func call(env: Environment) {
        stack.io.readRequest { requestData in
            // The raw request data will be parsed within the middleware stack
            env.request.rawData = requestData

            // Parse HTTP request data
            self.parseRequest(env)

            self.stack.call(env)

            // Marshal HTTP response data
            self.serializeResponse(env)

            // Retrieve raw response data and write it back over the network
            self.stack.io.writeResponse(env.response.rawData) {
                self.stack.finish()
            }
        }
    }

    func parseRequest(env: Environment) {
        if let string = String(data: env.request.rawData, encoding: NSUTF8StringEncoding) {
            env.request.body = string
        }
        else {
            // FIXME: this should return a middleware 400. throw?
            fatalError("couldn't parse request")
        }
    }

    func serializeResponse(env: Environment) {
        // HTTP/1.0 responses
        env.response.headers[.ContentLength] = String(env.response.body.utf8.count)

        // TODO: implement HTTP/1.1 chunked responses
//        env.response.headers[.TransferEncoding] = "chunked"

        var responseString = [String(env.response.headers), env.response.body].joinWithSeparator(String(HTTPConstants.Separator))

//        responseString += String(HTTPConstants.ChunkTerminator)

        env.response.rawData = responseString.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}
