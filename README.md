# Assembly-WebServer
A simple yet functional webserver written in Assembly x64 (Intel syntax).

It accepts both GET and POST request.

## It works this way:

1. create socket, and wait for requests.
2. Fork when receiving a request
3. Read and parse a request to then find out wich type it is
4. Following the type of request it:
   POST -> parse the file path and the request content to then open/create the file and write the request content in it
   GET -> parse the file path to then open the file, read it's content, and write it back to the client via the socket

5. prints a simple HTTP 200 OK
6. exit
