.intel_syntax noprefix
.global _start

.section .data
        response:
                .ascii "HTTP/1.0 200 OK\r\n\r\n"
        response_len = . - response # auto str length calculation

.section .bss
        destination:
                .space 64
        post_content:
                .space 1024


.section .text
_start:


# --- CREATING A SOCKET ---
mov rax, 41 # syscall socket x64
mov rdi, 2 # int for AF_INET
mov rsi, 1 # int for SOCK_STREAM (TCP connexion)
mov rdx, 0 # 0 lets the OS choose the protocol (here IP for TCP)
syscall


# --- PREPARING AND BINDING A SOCKET bind(fd, sockaddr, sizeof(sockaddr)) ---
mov r15, rax
mov rdi, r15 # file descriptor of the socket
push 0
# Preparing the firt 8 bytes:
# IP (4 Bytes of 0 (so 0.0.0.0 which means all networkd interfaces)) + Port (80 = 0x50 -> exemple for a long port: 8080 -> inverted 0x901f (because of endian)) + Family (AF_INET: 0x0002 -> Protocole internet IPV4, would be 0x000a for IPV6 -> 10)
mov rbx, 0x0000000050000002
push rbx
mov rsi, rsp # points to the beginning of the 16 bytes structure sockaddr (rdx)
mov rax, 49 # syscall bind x64
mov rdx, 16 # size of the struct sockaddr_in
syscall


# --- LISTEN ON THE BINDED SOCKET ---
mov rax, 50 # syscall for listen x64
# rdi still contains the file descriptor of the socket
mov rsi, 0 # backlog amout (0 is the smallest amount so 1 in this case)
syscall

request_loop:
# --- ACCEPT REQUESTS ON THE LISTENED SOCKET ---
mov rax, 43 # syscall for accept x64
mov rdi, r15
mov rsi, 0
mov rdx, 0
syscall

# --- FORK WHEN CONNEXION RECEIVED ---
mov r14, rax
mov rax, 57 # fork
syscall
cmp rax, 0
je process_request # If return == 0 -> child process
# close the accepted socket in the parent process
mov rax, 3
mov rdi, r14
syscall

jmp request_loop # else loop accept


process_request:
# --- CLOSE SOCKET FOR THIS CHILD PROCESS ---
mov r12, rax # KEEP THE FUCKING CLIENT'S FD
mov rax, 3
mov rdi, r15
syscall


# --- READ THE CLIENT'S REQUEST ---
mov rdi, r14 # the client's fd for read syscall
mov rax, 0 # read
sub rsp, 1024 # digging the stack to make some space for the read buffer
mov rsi, rsp
mov rdx, 1024
syscall

# --- PREPARE FOR THE REQUEST PARSING LOOP --
xor rbx, rbx


# --- SEE IF GET OR POST ---
get_or_post:
mov al, [rsp + rbx]
cmp al, 0x20
je go_to_request_process
cmp al, 0x0
je exit
inc rbx
jmp get_or_post

go_to_request_process:
cmp rbx, 3
je copy_get_path
cmp rbx, 4
je copy_post_path
jmp exit


copy_get_path:
add rsp, 4
mov r8, 0 # value if dealing with get
xor rbx, rbx
jmp copy_path


copy_post_path:
add rsp, 5
mov r8, 1 # value if dealing with post
xor rbx, rbx
jmp copy_path



# --- LOOP TO ITERATE AND COPY THE FILE_PATH FROM THE READ CLIENT'S REQUEST ---
copy_path:
mov al, [rsp + rbx]
cmp al, 0x20 # compare the byte with 32 (space)
je end_copy
cmp al, 0x0 # security to see if it's the end of the string
je end_copy
mov [destination + rbx], al # put the byte in destination
inc rbx
jmp copy_path

end_copy:
mov byte ptr [destination + rbx], 0


# --- SEE IF GET OR POST TO READ OR WRITE ---
cmp r8, 0
je get_process
cmp r8, 1
je post_process
jmp exit



get_process:
# --- OPEN THE FILE ---
mov rax, 2 # open
lea rdi, [rip + destination]
xor rsi, rsi # 0 for O_RDONLY
syscall

# --- READ THE FILE ---
mov rdi, rax # open fd
xor rax, rax # 0 for read
mov rsi, rsp
mov rdx, 1024
syscall

mov r13, rax # keep the size of the content read


# --- CLOSE THE FD ---
mov rax, 3 # close
# rdi still contains the opened file's fd
syscall


# --- WRITE THE 200 OK RESPONSE FIRST ---
mov rdi, r14
mov rax, 1 # write
lea rsi, [rip + response] # puts the adress of the string (dereference from the adress rip + response) in rsi
mov rdx, response_len # the length in bytes, directly the value, not the adress
syscall


# --- WRITE THE FILE'S CONTENT TO THE CLIENT FD ---
mov rdi, r14 # ARG 1: get back the client's fd
mov rdx, r13 # ARG 3: the size read
mov rax, 1 # write
mov rsi, rsp # ARG 2: buffer
syscall


# --- CLOSE THE CLIENT'S FD ---
mov rax, 3 # syscall for close
# rdi still contains the client's fd to close
syscall

jmp exit


post_process:
# --- OPEN THE FILE ---
mov rax, 2 # open
lea rdi, [rip + destination]
mov rsi, 65 # 1 for O_WRONLY and 64 for O_CREAT so 65
mov rdx, 0777
syscall
mov r9, rax # keep the opened file's fd



# --- PREPARE THE LOOP ---
xor rbx, rbx
xor rcx, rcx

loop_until_content:
cmp byte ptr [rsp + rbx], 0x0d # compare with \r
je first_found
cmp byte ptr [rsp + rbx], 0x0 # security
je exit
inc rbx
jmp loop_until_content


first_found:
inc rbx
cmp byte ptr [rsp + rbx], 0x0a # compare with \n
je second_found
cmp byte ptr [rsp + rbx], 0x0
je exit
inc rbx
jmp loop_until_content


second_found:
inc rbx
cmp byte ptr [rsp + rbx], 0x0d # again \r
je third_found
cmp byte ptr [rsp + rbx], 0x0
je exit
inc rbx
jmp loop_until_content


third_found:
inc rbx
cmp byte ptr [rsp + rbx], 0x0a # again \n
je fourth_found
cmp byte ptr [rsp + rbx], 0x0
je exit
inc rbx
jmp loop_until_content


fourth_found:
inc rbx
cmp byte ptr [rsp + rbx], 0x0
je exit
add rsp, rbx
jmp loop_copy_content

xor rcx, rcx

loop_copy_content:
mov al, [rsp + rcx]
cmp al, 0x0
je end_copy_content
mov [post_content + rcx], al
inc rcx
jmp loop_copy_content

end_copy_content:
mov byte ptr [post_content + rcx], 0


# --- WRITE TO THE FILE ---
mov rdi, r9
mov rax, 1 # write
lea rsi, [rip + post_content]
mov rdx, rcx
syscall

# --- CLOSE THE FD ---
mov rax, 3 # close
# rdi still contains the opened file's fd
syscall


# --- WRITE THE 200 OK RESPONSE FIRST ---
mov rdi, r14
mov rax, 1 # write
lea rsi, [rip + response] # puts the adress of the string (dereference from the adress rip + response) in rsi
mov rdx, response_len # the length in bytes, directly the value, not the adress
syscall

jmp exit

exit:
# -- EXIT ---
mov rax, 60
mov rdi, 0
syscall
