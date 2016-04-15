	.file	"framebuffer.c"
	.section	.rodata
.LC0:
	.string	"/dev/fb0"
	.align 8
.LC1:
	.string	"Error: cannot open framebuffer device"
	.align 8
.LC2:
	.string	"The framebuffer device was opened successfully."
	.align 8
.LC3:
	.string	"Error reading fixed information"
	.align 8
.LC4:
	.string	"Error reading variable information"
.LC5:
	.string	"%dx%d, %dbpp\n"
	.align 8
.LC6:
	.string	"Error: failed to map framebuffer device to memory"
	.align 8
.LC7:
	.string	"The framebuffer device was mapped to memory successfully."
	.text
	.globl	main
	.type	main, @function
main:
.LFB2:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$304, %rsp
	movl	$0, -12(%rbp)
	movq	$0, -24(%rbp)
	movq	$0, -32(%rbp)
	movl	$0, -4(%rbp)
	movl	$0, -8(%rbp)
	movq	$0, -40(%rbp)
	movl	$2, %esi
	movl	$.LC0, %edi
	movl	$0, %eax
	call	open
	movl	%eax, -12(%rbp)
	cmpl	$-1, -12(%rbp)
	jne	.L2
	movl	$.LC1, %edi
	call	perror
	movl	$1, %edi
	call	exit
.L2:
	movl	$.LC2, %edi
	call	puts
	leaq	-304(%rbp), %rdx
	movl	-12(%rbp), %eax
	movl	$17922, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl
	cmpl	$-1, %eax
	jne	.L3
	movl	$.LC3, %edi
	call	perror
	movl	$2, %edi
	call	exit
.L3:
	leaq	-224(%rbp), %rdx
	movl	-12(%rbp), %eax
	movl	$17920, %esi
	movl	%eax, %edi
	movl	$0, %eax
	call	ioctl
	cmpl	$-1, %eax
	jne	.L4
	movl	$.LC4, %edi
	call	perror
	movl	$3, %edi
	call	exit
.L4:
	movl	-200(%rbp), %ecx
	movl	-220(%rbp), %edx
	movl	-224(%rbp), %eax
	movl	%eax, %esi
	movl	$.LC5, %edi
	movl	$0, %eax
	call	printf
	movl	-224(%rbp), %edx
	movl	-220(%rbp), %eax
	imull	%eax, %edx
	movl	-200(%rbp), %eax
	imull	%edx, %eax
	shrl	$3, %eax
	movl	%eax, %eax
	movq	%rax, -24(%rbp)
	movq	-24(%rbp), %rax
	movl	-12(%rbp), %edx
	movl	$0, %r9d
	movl	%edx, %r8d
	movl	$1, %ecx
	movl	$3, %edx
	movq	%rax, %rsi
	movl	$0, %edi
	call	mmap
	movq	%rax, -32(%rbp)
	movq	-32(%rbp), %rax
	cmpl	$-1, %eax
	jne	.L5
	movl	$.LC6, %edi
	call	perror
	movl	$4, %edi
	call	exit
.L5:
	movl	$.LC7, %edi
	call	puts
	movl	$100, -4(%rbp)
	movl	$100, -8(%rbp)
	movl	$100, -8(%rbp)
	jmp	.L6
.L11:
	movl	$100, -4(%rbp)
	jmp	.L7
.L10:
	movl	-208(%rbp), %edx
	movl	-4(%rbp), %eax
	addl	%eax, %edx
	movl	-200(%rbp), %eax
	shrl	$3, %eax
	imull	%eax, %edx
	movl	-204(%rbp), %ecx
	movl	-8(%rbp), %eax
	addl	%eax, %ecx
	movl	-256(%rbp), %eax
	imull	%ecx, %eax
	addl	%edx, %eax
	movl	%eax, %eax
	movq	%rax, -40(%rbp)
	movl	-200(%rbp), %eax
	cmpl	$32, %eax
	jne	.L8
	movq	-40(%rbp), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	movb	$100, (%rax)
	movq	-40(%rbp), %rax
	leaq	1(%rax), %rdx
	movq	-32(%rbp), %rax
	addq	%rax, %rdx
	movl	-4(%rbp), %eax
	subl	$100, %eax
	movl	%eax, %ecx
	shrl	$31, %ecx
	addl	%ecx, %eax
	sarl	%eax
	addl	$15, %eax
	movb	%al, (%rdx)
	movq	-40(%rbp), %rax
	leaq	2(%rax), %rdx
	movq	-32(%rbp), %rax
	leaq	(%rdx,%rax), %rsi
	movl	-8(%rbp), %eax
	leal	-100(%rax), %ecx
	movl	$1717986919, %edx
	movl	%ecx, %eax
	imull	%edx
	sarl	%edx
	movl	%ecx, %eax
	sarl	$31, %eax
	subl	%eax, %edx
	movl	%edx, %eax
	movl	$-56, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	movb	%al, (%rsi)
	movq	-40(%rbp), %rax
	leaq	3(%rax), %rdx
	movq	-32(%rbp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	jmp	.L9
.L8:
	movl	$10, -44(%rbp)
	movl	-4(%rbp), %eax
	leal	-100(%rax), %ecx
	movl	$715827883, %edx
	movl	%ecx, %eax
	imull	%edx
	movl	%ecx, %eax
	sarl	$31, %eax
	subl	%eax, %edx
	movl	%edx, %eax
	movl	%eax, -48(%rbp)
	movl	-8(%rbp), %eax
	subl	$100, %eax
	leal	15(%rax), %edx
	testl	%eax, %eax
	cmovs	%edx, %eax
	sarl	$4, %eax
	movl	$31, %edx
	subl	%eax, %edx
	movl	%edx, %eax
	movl	%eax, -52(%rbp)
	movl	-52(%rbp), %eax
	sall	$11, %eax
	movl	%eax, %edx
	movl	-48(%rbp), %eax
	sall	$5, %eax
	orl	%eax, %edx
	movl	-44(%rbp), %eax
	orl	%edx, %eax
	movw	%ax, -54(%rbp)
	movq	-40(%rbp), %rdx
	movq	-32(%rbp), %rax
	addq	%rax, %rdx
	movzwl	-54(%rbp), %eax
	movw	%ax, (%rdx)
.L9:
	addl	$1, -4(%rbp)
.L7:
	cmpl	$299, -4(%rbp)
	jle	.L10
	addl	$1, -8(%rbp)
.L6:
	cmpl	$299, -8(%rbp)
	jle	.L11
	movq	-24(%rbp), %rdx
	movq	-32(%rbp), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	munmap
	movl	-12(%rbp), %eax
	movl	%eax, %edi
	call	close
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE2:
	.size	main, .-main
	.ident	"GCC: (GNU) 5.3.0"
	.section	.note.GNU-stack,"",@progbits
