//
//  Signals.swift
//  Switch
//
//  Created by Piers Mainwaring on 12/22/15.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Foundation

struct Signals {
    enum Signal: Int32 {
        case HUP    = 1
        case INT    = 2
        case QUIT   = 3
        case ABRT   = 6
        case ALRM   = 14
        case TERM   = 15
    }

    static var sources = [dispatch_source_t]()

    static func trap(signals: Signal..., action: Void -> Void) {
        // From Swift, `sigaction.init()` collides with `Darwin.sigaction()`. This
        // typealias allows us to disambiguate them
        typealias SignalActionContext = sigaction
        typealias SignalHandler = __sigaction_u

        for signal in signals {
            // Pass action block to GCD for signal handling
            let source = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, UInt(signal.rawValue), 0, dispatch_get_global_queue(0, 0))
            dispatch_source_set_event_handler(source, action)
            dispatch_resume(source)

            sources.append(source)

            // Thanks to Adam Sharp for this implementation (gist: https://gist.github.com/sharplet/d640eea5b6c99605ac79)
            // Disable default `sigaction` handling with SIG_IGN
            var actionContext = SignalActionContext(__sigaction_u: SignalHandler(__sa_handler: SIG_IGN), sa_mask: 0, sa_flags: 0)
            sigaction(signal.rawValue, &actionContext, nil)
        }
    }
}
