        global main

        section .text

        ;; program setup
main:
        ;; push main sc onto the stack
        pushglobal main
        ;; set up base pointer
        mov rbp, rsp
        ;; begin evaluating supercombinator code
        unwind

main.sc:
        pushglobal id
        pushint 52
        mkap
        slide 1
        unwind

        ;; pushglobal f
        ;; pushglobal id
        ;; mkap
        ;; pushint 5
        ;; mkap
        ;; slide 1
        ;; unwind

id.sc:
        pusharg 0
        slide 2
        unwind

K.sc:
        pusharg 0
        slide 3
        unwind

f.sc:
        pusharg 1
        pusharg 1
        mkap
        pushglobal K
        mkap
        slide 3
        unwind

        ;; create supercombinators in the .data region
        section .data
main.node:
        dq TAG_GLOBAL
        dq 0
        dq main.sc
id.node:
        dq TAG_GLOBAL
        dq 1
        dq id.sc
K.node:
        dq TAG_GLOBAL
        dq 2
        dq K.sc
f.node:
        dq TAG_GLOBAL
        dq 1
        dq f.sc
