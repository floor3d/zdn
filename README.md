# Zig Distribution Network

## Notes

1. Need Origin_Server, Pop_Server, Client
2. Socket library

## Origin Server

1. Serves ... images?
2. Log images asked for
3. Log connections
4. listen on 9000
5. Every so often, bit shift the images (around 1x the ttl? 50% chance?)
6. images are sent with sha hashes so we know when changes occur

## Pop Server

1. Cache garbage collection: LFU
2. Log cache misses & hits, as well as garbage collection
3. Make cache size customizable; do it via JSON or something, and make the
binary sit behind a `main` that takes in commandline args and turns it to
obj or something to pass to actual api
4. Connect to origin on startup, & keep connection alive probably?
5. TTL of cache items before we ask for a new one; send a "check me out"
msg where, if the TTL is expired, send old one and ask "is this sha256 correct"
for image id X, and if it is not, the server will give us the new one

## Client

1. Heavy jitter, randomly asks for 1-100 images at a time
2. Make amt. clients customizable too; need some sort of Initializer that
creates processes for each client
3. Client ID % Num_Pop_Servers = Pop Server Id

## "Socket Library"

1. Abstracted wrapper so I can change it later
2. support ipv4 AND ipv6...? :P
3. Error set for recoverable and nonrecoverable errors
4. Length-prefixed messages
5. Poll between connected friends ... could do a dynamo-db style where I ask
   several pop servers at once
6. SHOULD BE MOCKABLE! FOR TESTING
7. Fit use case: sockets are used on:
  1. CLIENT: Send a request to a pop server, wait for a result asynchronously;
   future/promise would be cool ...
  2. Pop Server: Field requests from client(s) in poll loop, queue requests
   into a worker thread which would find the answers and send them to a sender thread?
   Would need to interact with origin server like how the client interacts with
   us, future/promise style; to receive from client, just essentially need a recvmsgs()
   function of sorts, which only returns complete messages
  3. Origin server: acts like pop server to client
8. Socket library should continually read from all its socket append to buffer;
  once it gets a call to `recvmsg[s]()` it should read the len field and return
  whatever the user asks for (one or multiple); question is, how to make this
  efficient alloc wise ...

9. Future/promise can be a wrapper around this library which primarily does
   `send()` and `recvmsg[s]()`
10. Need an `init()` which binds and an `accept()`; `accept()` returns the socket
    class which you call `send()` and `recvmsg[s]()` on
11. Error handling when the connection is dropped...
12. Don't lose focus of the whole picture: socket libary is for ONE socket at a
    time

## Overall

1. Log to a file: [DEVICE_TYPE]_[ID].log
2. [+], [!], ..., need some sort of logger library
3. Server Port == [INIT_VALUE] + Server Id
4. pop server init value: 9000; server 1 is 9001
5. client asks origin for a pop, origin gives client an ID and pop server's ip/port;
"this is a signup message" or something
