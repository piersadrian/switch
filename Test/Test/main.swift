//
//  main.swift
//  Test
//
//  Created by Piers Mainwaring on 1/4/16.
//  Copyright © 2016 Playfair, LLC. All rights reserved.
//

import Hyper

// This class is the last item in the global middleware stack, and implements
// its own private middleware stack to wrap Responders

let server = HTTPServer()
server.start()
