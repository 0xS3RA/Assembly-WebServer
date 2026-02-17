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


Here is an example trace:
===== Trace: Parent Process =====
- execve("/proc/self/fd/3", ["/proc/self/fd/3"], 0x7f929f853af0 /* 0 vars */) = 0
- socket(AF_INET, SOCK_STREAM, IPPROTO_IP) = 3
- bind(3, {sa_family=AF_INET, sin_port=htons(80), sin_addr=inet_addr("0.0.0.0")}, 16) = 0
- listen(3, 0)                            = 0
- accept(3, NULL, NULL)                   = 4
- fork()                                  = 7
- close(4)                                = 0
- accept(3, NULL, NULL)                   = ?
- +++ killed by SIGKILL +++

===== Trace: Child Process =====
- close(3)                                = 0
- read(4, "POST /tmp/tmpr1v0w1d4 HTTP/1.1\r\nHost: localhost\r\nUser-Agent: python-requests/2.32.4\r\nAccept-Encoding: gzip, deflate, zstd\r\nAccept: */*\r\nConnection: keep-alive\r\nContent-Length: 167\r\n\r\n4PigVMtor1AODNUWATMX30QAEtV24XYkPPM1ERprVM30ag6vO0SMDEImionB6tU6fDpCBZ1p5TFmHuRVu9Y9xEHXSu5g6ylvyrpFigDLSGFotQawJS8P0ff7LTDkDqOgITnYqXkVxs2u17r1OLeDXeOTnvjKHZo3JgucGJa", 1024) = 350
- open("/tmp/tmpr1v0w1d4", O_WRONLY|O_CREAT, 0777) = 3
- write(3, "4PigVMtor1AODNUWATMX30QAEtV24XYkPPM1ERprVM30ag6vO0SMDEImionB6tU6fDpCBZ1p5TFmHuRVu9Y9xEHXSu5g6ylvyrpFigDLSGFotQawJS8P0ff7LTDkDqOgITnYqXkVxs2u17r1OLeDXeOTnvjKHZo3JgucGJa", 167) = 167
- close(3)                                = 0
- write(4, "HTTP/1.0 200 OK\r\n\r\n", 19) = 19
- exit(0)                                 = ?
- +++ exited with 0 +++
