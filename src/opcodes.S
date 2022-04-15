        extern malloc

        ;; runtime error codes
%define ERR_UNWIND_TYP  0x1
%define ERR_UNWIND_ARGS 0x2

        ;; used to tag nodes with data; the first 8 bytes of each node
        ;; is the node tag
%define TAG_NUM         0x0
%define TAG_AP          0x1
%define TAG_GLOBAL      0x2

        ;; node formats:
        ;; NUM:    | tag (8) | (4) | int (4) |
        ;; AP:     | tag (8) | fn addr (8) | tag addr (8) |
        ;; GLOBAL: | tag (8) | arity (8) | fn addr (8) |

        ;; calling conventions reminders (for myself):
        ;; caller-save (volatile): rax, rcx, rdx, rdi, rsi, rsp, r8-r11
        ;; callee-save (non-volatile): rbx, rbp, r12-r15
        ;; argument passing: rdi, rsi, rdx, rcx, r8, r9
        ;; special: rsp, rbp

        ;; allocate and push an integer onto the stack
%macro  pushint 1
        mov rdi, 16
        ;; pie: see https://reddit.com/r/asm/comments/gxt3mw/
        call malloc wrt ..plt
        ;; move the int into the int pointer
        mov qword [rax], TAG_NUM
        mov qword [rax+8], %1
	;; push the addr of the into onto the stack
        push rax
%endmacro

        ;; argument is expected to already be an address
        ;; to a global; globals should be resolved to
        ;; addresses at transpile time
%macro  pushglobal 1
        ;; rel necessary for pie
        lea rax, [rel %1.node]
        push rax
%endmacro

        ;; traverse up the stack n times
        ;; and get item in argument position
        ;; TODO: check that the element is an arg node
%macro  pusharg 1
        ;; get address of node
        mov rax, rsp[%1*4]
        ;; push address of argument
        push qword [rax+16]
%endmacro

        ;; alloc a new ap node from the top two nodes,
        ;; replace the top two nodes on the stack with
        ;; this new node
%macro  mkap 0
        ;; allocate new node
        mov rdi, 24
        call malloc wrt ..plt
        ;; pop arg addr from stack
        pop rcx
	;; pop fn addr from stack
        pop rdx
        ;; set the new node's contents
        mov qword [rax], TAG_AP
        mov [rax+8], rdx
        mov [rax+16], rcx
	;; push the new node onto the stack
        push rax
%endmacro

        ;; move the top node up n elements on the stack
%macro  slide 1
        ;; rax is the new top of the stack, rcx is the
        ;; value at the top of the stack
        lea rax, rsp[%1*8]
        mov rcx, [rsp]
        mov [rax], rcx
        mov rsp, rax
%endmacro

        ;; perform unwinding action described by the text
%macro  unwind 0
.unwind_loop:
        ;; get the tag of the element at the top of the stack
        mov qword rax, [rsp]

        ;; if it's an int, end the program
        ;; TODO: do we also need to check if the stack is empty?
        cmp qword [rax], TAG_NUM
        jz .done

        ;; if it's an ap, push the arg onto the stack and
        ;; continue unwinding
        cmp qword [rax], TAG_AP
        jz .continue_unwind

        ;; if it's a supercombinator, then run the supercomb code
        cmp qword [rax], TAG_GLOBAL
        jz .supercombinator

        ;; error: not a valid tagged node
        mov rdi, ERR_UNWIND_TYP
        jmp quit
.done:
        ;; TODO: do something with the output (in rax)
        ;; for now, simply return value in rdi, later should
        ;; set rdi to zero to indicate no error
        ;; xor rdi, rdi
        mov rdi, [rax+8]
        jmp quit

.continue_unwind:
        push qword [rax+8]
        jmp .unwind_loop

.supercombinator:
        ;; get the arity
        mov rdx, qword [rax+8]
        ;; get the length of the stack
        mov rcx, rbp
        sub rcx, rsp
        ;; check that there are enough args on the stack
        ;; TODO: check the order of operands
        cmp rcx, rdx
        jl .too_few_arguments
        ;; run the code in the supercombinator
        jmp [rax+16]

.too_few_arguments:
        mov rdi, ERR_UNWIND_ARGS
        jmp quit
%endmacro

        ;; quit a program (assume that the exit code is in rdi)
quit:
        mov eax, 60
        syscall
