    .file    "test_stdin.c"
    .section    .rodata.str1.1,"aMS",@progbits,1
.LC0:
    .string    "%d\n"
    .section    .text.unlikely,"ax",@progbits
.LCOLDB1:
    .section    .text.startup,"ax",@progbits
.LHOTB1:
    .p2align 4,,15
    .globl    main
    .type    main, @function
main:
.LFB25:
    .cfi_startproc
    subq    $152, %rsp
    .cfi_def_cfa_offset 160
    movl    $sta, %esi
    xorl    %edi, %edi
    call    tcgetattr
    movl    $sta, %edx
    xorl    %esi, %esi
    xorl    %edi, %edi
    andl    $-11, sta+12(%rip)
    call    tcsetattr
    movl    $1, %edi
    movq    $0, (%rsp)
    movq    $0, 8(%rsp)
    call    sleep
    leaq    16(%rsp), %rsi
    xorl    %eax, %eax
    movl    $16, %ecx
    movq    %rsp, %r8
    xorl    %edx, %edx
    movq    %rsi, %rdi
    rep stosq
    movl    $1, %edi
    movb    $1, 16(%rsp)
    call    select
    movl    $.LC0, %edi
    movl    %eax, %esi
    xorl    %eax, %eax
    call    printf
    xorl    %eax, %eax
    addq    $152, %rsp
    .cfi_def_cfa_offset 8
    ret
    .cfi_endproc
.LFE25:
    .size    main, .-main
    .section    .text.unlikely
.LCOLDE1:
    .section    .text.startup
.LHOTE1:
    .local    sta
    .comm    sta,60,32
    .ident    "GCC: (GNU) 5.3.0"
    .section    .note.GNU-stack,"",@progbits
