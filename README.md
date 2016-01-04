[![Stories in Ready](https://badge.waffle.io/piersadrian/switch.png?label=ready&title=Ready)](https://waffle.io/piersadrian/switch)
# Switch

Switch is a pure-Swift HTTP server framework, including network IO, an HTTP server, and a simple structure for building apps.

### Current status

Don't use this. The scaffolding is still going up, so it's not safe to walk around even with a hard hat.

### Architecture

Switch consists of two main parts: [Flow](#Flow), a flexible, asynchronous network IO library, and [Hyper](#Hyper), a full-featured, multithreaded HTTP server. Switch is designed to help you build simple, performant HTTP-based apps out of the box, but you can also swap out Hyper for a custom protocol server to support alternative wire protocols or other specialized needs.

The final piece of Switch is Port, its set of Swift protocols. Switch apps, protocol servers, including Hyper, and even its IO library are built according to the Port architecture. Port-compliant apps and protocol servers are implemented as middleware stacks, which enable a simple architecture and high performance, and let you take advantage of some really nice aspects of Swift. Port-compliant IO libraries, like Flow,

#### Hyper

Hyper is Switch's HTTP server. It's Port-compliant, so it's built around a middleware stack, and it handles all aspects of the HTTP request/response cycle. It provides you a fully-populated Request object and only requires you to construct a response body and set any appropriate response headers. Then simply return from your app and Hyper will serialize the response and send it back over the wire.

Each incoming request is run within a thread pool of configurable size. Once the pool is full, new requests wait until pool space opens up.

Here's the current high-level status of Hyper:

*HTTP Requests*

- [x] Deserialization
- [ ] Header parsing
- [ ] Multipart support
- [ ] Parameter parsing

*HTTP Responses*

- [x] Content-Length serialization
- [ ] Chunked serialization

*Bundled middleware*

- [ ] CORS
- [ ] sendfile
- [ ] Response timing
- [ ] Cookies

*Routing*

- [ ] Route parameter extraction
- [ ] Fast route matching

*App structure*

- [ ] RESTful responders
- [ ] Function responders
- [ ] Responder callbacks

*Utilities*

- [ ] Logging
- [ ] JSON

#### Flow

Flow is Switch's network IO library. It's designed as a library intended to be used only by the protocol server (Hyper, by default). That allows the protocol server to have complete control over network IO from the socket up.

Here's the current high-level status of Flow:

*Sockets*

- [x] Lifecycle management

*IO management*

- [x] GCD-based async status monitoring
- [x] Configurable operation queues
- [x] In-memory read/write buffers
- [ ] Status monitoring

### Dependencies

* Foundation
* libdispatch
* any supported Swift platform

### Contributing

Please file issues and submit PRs. I'd love to merge some patches!
