# Zig Distribution Network

## Notes

1. Need Origin_Server, Pop_Server, Client

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

## Overall

1. Log to a file: [DEVICE_TYPE]_[ID].log
2. [+], [!], ..., need some sort of logger library
3. Server Port == [INIT_VALUE] + Server Id
3a. pop server init value: 9000; server 1 is 9001
4. client asks origin for a pop, origin gives client an ID and pop server's ip/port;
this is a signup message or something
