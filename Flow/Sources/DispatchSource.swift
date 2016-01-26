//
//  DispatchSource.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/24/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

struct DispatchSource {
    enum Status {
        case Running, Paused, Cancelled
    }

    // MARK: - Internal Properties

    let source: dispatch_source_t
    var status: Status

    // MARK: - Lifecycle

    init(fd: CFSocketNativeHandle, type: dispatch_source_type_t, queue: dispatch_queue_t, handler: dispatch_block_t) {
        self.status = .Paused

        guard let source = dispatch_source_create(type, UInt(fd), 0, queue) else {
            fatalError("couldn't create dispatch_source")
        }

        self.source = source

        dispatch_source_set_event_handler(self.source, handler)
    }

    // MARK: - Public API

    func data() -> UInt {
        return dispatch_source_get_data(self.source)
    }

    mutating func run() {
        guard self.status != .Cancelled else {
            fatalError("DispatchSource is cancelled and cannot be run")
        }

        guard self.status != .Running else {
            fatalError("DispatchSource is already running")
        }

        self.status = .Running
        dispatch_resume(self.source)
    }

    mutating func pause() {
        guard self.status != .Cancelled else {
            fatalError("DispatchSource is cancelled and cannot be paused")
        }

        guard self.status != .Paused else {
            fatalError("DispatchSource is already paused")
        }

        self.status = .Paused
        dispatch_suspend(self.source)
    }

    mutating func cancel() {
        guard self.status != .Cancelled else {
            return
//            fatalError("DispatchSource is cancelled and cannot be cancelled again")
        }

        let wasPaused = (status == .Paused)
        self.status = .Cancelled

        dispatch_source_cancel(self.source)

        // A paused dispatch source will never recognize that it's been cancelled
        // so its cancel handler won't run. This resumes the source so it can process
        // its cancellation. Weird but true.
        if wasPaused {
            dispatch_resume(self.source)
        }
    }
}
