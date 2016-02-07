//
//  Response.swift
//  Hyper
//
//  Created by Piers Mainwaring on 1/5/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Flow

enum HTTPResponseStatus {
    case SentNothing, SentHeaders, SentPartialChunkedBody, SentCompleteBody, SentTrailers, Complete
}

public class HTTPResponse {
    // MARK: - Private Properties

    private var chunked: Bool {
        return request.version == .OnePointOne && headers[.ContentLength] == nil
    }

    // MARK: - Internal Properties

    var sendStatus: HTTPResponseStatus = .SentNothing
    weak var connection: HTTPConnection? // replace with protocol for better testing

    // MARK: - Public Properties

    public let request: HTTPRequest
    public var version: HTTPVersion { return request.version }

    public var status: HTTPStatus = .OK
    public var body: NSData?

    public var headers = ResponseHeaders()
    public var trailers = ResponseHeaders()

    init(request: HTTPRequest) {
        self.request = request
    }

    // MARK: - Public API

    public func finish() {
        if sendStatus == .SentNothing {
            sendHeaders()
        }

        if chunked {
            if sendStatus == .SentHeaders || sendStatus == .SentPartialChunkedBody {
                sendFinalChunk()
                sendTrailers()
            }
        }
        else if headers[.ContentLength] != nil {
            sendStatus = .SentCompleteBody
        }

        connection?.finish()
        sendStatus = .Complete
    }

    public func sendContinue() {
        guard let length = request.headers[.ContentLength], contentLength = Int(length) else {
            // 400, missing or malformed Content-Length header
            return
        }

        connection?.socket.writeData("HTTP/1.1 100 Continue\r\n\r\n".dataUsingEncoding(NSISOLatin1StringEncoding)!) {}
        connection?.socket.readData(contentLength) { data in
//            print("got more data: \(data.length) bytes")
//            Log.printMessage("")
//            Log.printMessage("")
//            Log.printMessage(String(data: data, encoding: NSISOLatin1StringEncoding)!)
            if let str = String(data: data, encoding: NSISOLatin1StringEncoding) {
                let chars = str.characters[str.characters.startIndex..<str.characters.startIndex.advancedBy(10)]

                if String(chars) != "----------" {
                    print("failed")
                }
            }
        }
    }

    public func sendHeaders() {
        guard sendStatus == .SentNothing else { return }

        if chunked {
            headers[.TransferEncoding] = "chunked"
        }

        // send headers + CRLFCRLF
        let headersString = "\(String(version)) \(String(status))\(HTTPToken.CRLF)\(String(headers))\(HTTPToken.CRLF)"
        connection?.socket.writeData(headersString.dataUsingEncoding(NSISOLatin1StringEncoding)!) {}

        sendStatus = .SentHeaders
    }

    public func sendBodyChunk(chunk: String) {
        if sendStatus == .SentNothing {
            // send calculated headers
            sendHeaders()
        }

        guard sendStatus == .SentHeaders || sendStatus == .SentPartialChunkedBody else { return }

        // send chunk
        connection?.socket.writeData("\(String(chunk.utf8.count, radix: 16))\(HTTPToken.CRLF)\(chunk)\(HTTPToken.CRLF)".dataUsingEncoding(NSISOLatin1StringEncoding)!) {}

        sendStatus = .SentPartialChunkedBody
    }

    private func sendFinalChunk() {
        guard sendStatus == .SentHeaders || sendStatus == .SentPartialChunkedBody else { return }

        // send terminator ("0\r\n")
        connection?.socket.writeData(HTTPToken.chunkTerminator.dataUsingEncoding(NSISOLatin1StringEncoding)!) {}

        sendStatus = .SentCompleteBody
    }

    private func sendTrailers() {
        guard sendStatus == .SentCompleteBody else { return }
        guard version == .OnePointOne else { return }

        var trailersStr = String(trailers)
        trailersStr.appendContentsOf(HTTPToken.CRLF)

        connection?.socket.writeData(trailersStr.dataUsingEncoding(NSISOLatin1StringEncoding)!) {}

        sendStatus = .SentTrailers
    }
}
