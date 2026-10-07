	.text
	.file	"example_clang.c"
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4                               # -- Begin function calc
.LCPI0_0:
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
	.long	4                               # 0x4
.LCPI0_1:
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
.LCPI0_2:
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	1                               # 0x1
.LCPI0_3:
	.long	1065353216                      # 0x3f800000
	.long	1065353216                      # 0x3f800000
	.long	1065353216                      # 0x3f800000
	.long	1065353216                      # 0x3f800000
.LCPI0_4:
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
.LCPI0_5:
	.long	12                              # 0xc
	.long	12                              # 0xc
	.long	12                              # 0xc
	.long	12                              # 0xc
.LCPI0_6:
	.long	16                              # 0x10
	.long	16                              # 0x10
	.long	16                              # 0x10
	.long	16                              # 0x10
	.text
	.globl	calc
	.p2align	4, 0x90
	.type	calc,@function
calc:                                   # @calc
	.cfi_startproc
# %bb.0:
	testl	%edi, %edi
	jle	.LBB0_1
# %bb.2:
	cmpl	$8, %edi
	jae	.LBB0_4
# %bb.3:
	movl	$1, %edx
	xorl	%eax, %eax
	jmp	.LBB0_12
.LBB0_1:
	xorl	%eax, %eax
	retq
.LBB0_4:
	movl	%edi, %edx
	andl	$-8, %edx
	leal	-8(%rdx), %ecx
	movl	%ecx, %eax
	shrl	$3, %eax
	addl	$1, %eax
	testl	%ecx, %ecx
	je	.LBB0_5
# %bb.6:
	movl	%eax, %ecx
	andl	$-2, %ecx
	movdqa	.LCPI0_0(%rip), %xmm1           # xmm1 = [1,2,3,4]
	pxor	%xmm0, %xmm0
	movdqa	.LCPI0_1(%rip), %xmm8           # xmm8 = [4,4,4,4]
	movdqa	.LCPI0_2(%rip), %xmm9           # xmm9 = [1,1,1,1]
	movdqa	.LCPI0_3(%rip), %xmm10          # xmm10 = [1065353216,1065353216,1065353216,1065353216]
	movdqa	.LCPI0_4(%rip), %xmm11          # xmm11 = [8,8,8,8]
	movdqa	.LCPI0_5(%rip), %xmm12          # xmm12 = [12,12,12,12]
	movdqa	.LCPI0_6(%rip), %xmm13          # xmm13 = [16,16,16,16]
	pxor	%xmm2, %xmm2
	.p2align	4, 0x90
.LBB0_7:                                # =>This Inner Loop Header: Depth=1
	movdqa	%xmm1, %xmm7
	paddd	%xmm8, %xmm7
	movdqa	%xmm1, %xmm4
	pandn	%xmm9, %xmm4
	pslld	$23, %xmm4
	paddd	%xmm10, %xmm4
	cvttps2dq	%xmm4, %xmm4
	movdqa	%xmm1, %xmm5
	pmuludq	%xmm4, %xmm5
	pshufd	$232, %xmm5, %xmm6              # xmm6 = xmm5[0,2,2,3]
	pshufd	$245, %xmm1, %xmm3              # xmm3 = xmm1[1,1,3,3]
	pshufd	$245, %xmm4, %xmm5              # xmm5 = xmm4[1,1,3,3]
	pmuludq	%xmm5, %xmm3
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm6            # xmm6 = xmm6[0],xmm3[0],xmm6[1],xmm3[1]
	paddd	%xmm0, %xmm6
	pshufd	$245, %xmm7, %xmm0              # xmm0 = xmm7[1,1,3,3]
	pmuludq	%xmm4, %xmm7
	pshufd	$232, %xmm7, %xmm7              # xmm7 = xmm7[0,2,2,3]
	pmuludq	%xmm5, %xmm0
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	paddd	%xmm2, %xmm7
	movdqa	%xmm1, %xmm0
	paddd	%xmm11, %xmm0
	movdqa	%xmm1, %xmm3
	paddd	%xmm12, %xmm3
	pshufd	$245, %xmm0, %xmm2              # xmm2 = xmm0[1,1,3,3]
	pmuludq	%xmm4, %xmm0
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	pmuludq	%xmm5, %xmm2
	pshufd	$232, %xmm2, %xmm2              # xmm2 = xmm2[0,2,2,3]
	punpckldq	%xmm2, %xmm0            # xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1]
	paddd	%xmm6, %xmm0
	pmuludq	%xmm3, %xmm4
	pshufd	$232, %xmm4, %xmm2              # xmm2 = xmm4[0,2,2,3]
	pshufd	$245, %xmm3, %xmm3              # xmm3 = xmm3[1,1,3,3]
	pmuludq	%xmm5, %xmm3
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm2            # xmm2 = xmm2[0],xmm3[0],xmm2[1],xmm3[1]
	paddd	%xmm7, %xmm2
	paddd	%xmm13, %xmm1
	addl	$-2, %ecx
	jne	.LBB0_7
# %bb.8:
	testb	$1, %al
	je	.LBB0_10
.LBB0_9:
	movdqa	.LCPI0_1(%rip), %xmm3           # xmm3 = [4,4,4,4]
	movdqa	%xmm1, %xmm4
	pandn	.LCPI0_2(%rip), %xmm4
	paddd	%xmm1, %xmm3
	pslld	$23, %xmm4
	paddd	.LCPI0_3(%rip), %xmm4
	cvttps2dq	%xmm4, %xmm4
	pshufd	$245, %xmm1, %xmm5              # xmm5 = xmm1[1,1,3,3]
	pmuludq	%xmm4, %xmm1
	pshufd	$232, %xmm1, %xmm1              # xmm1 = xmm1[0,2,2,3]
	pshufd	$245, %xmm4, %xmm6              # xmm6 = xmm4[1,1,3,3]
	pmuludq	%xmm6, %xmm5
	pshufd	$232, %xmm5, %xmm5              # xmm5 = xmm5[0,2,2,3]
	punpckldq	%xmm5, %xmm1            # xmm1 = xmm1[0],xmm5[0],xmm1[1],xmm5[1]
	paddd	%xmm1, %xmm0
	pmuludq	%xmm3, %xmm4
	pshufd	$232, %xmm4, %xmm1              # xmm1 = xmm4[0,2,2,3]
	pshufd	$245, %xmm3, %xmm3              # xmm3 = xmm3[1,1,3,3]
	pmuludq	%xmm6, %xmm3
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm1            # xmm1 = xmm1[0],xmm3[0],xmm1[1],xmm3[1]
	paddd	%xmm1, %xmm2
.LBB0_10:
	paddd	%xmm2, %xmm0
	pshufd	$238, %xmm0, %xmm1              # xmm1 = xmm0[2,3,2,3]
	paddd	%xmm0, %xmm1
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	paddd	%xmm1, %xmm0
	movd	%xmm0, %eax
	cmpl	%edi, %edx
	je	.LBB0_14
# %bb.11:
	orl	$1, %edx
.LBB0_12:
	addl	$1, %edi
	.p2align	4, 0x90
.LBB0_13:                               # =>This Inner Loop Header: Depth=1
	movl	%edx, %ecx
	notb	%cl
	andb	$1, %cl
	movl	%edx, %esi
	shll	%cl, %esi
	addl	%esi, %eax
	addl	$1, %edx
	cmpl	%edx, %edi
	jne	.LBB0_13
.LBB0_14:
	retq
.LBB0_5:
	movdqa	.LCPI0_0(%rip), %xmm1           # xmm1 = [1,2,3,4]
	pxor	%xmm0, %xmm0
	pxor	%xmm2, %xmm2
	testb	$1, %al
	jne	.LBB0_9
	jmp	.LBB0_10
.Lfunc_end0:
	.size	calc, .Lfunc_end0-calc
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4                               # -- Begin function main
.LCPI1_0:
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
	.long	4                               # 0x4
.LCPI1_1:
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
.LCPI1_2:
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	1                               # 0x1
.LCPI1_3:
	.long	1065353216                      # 0x3f800000
	.long	1065353216                      # 0x3f800000
	.long	1065353216                      # 0x3f800000
	.long	1065353216                      # 0x3f800000
.LCPI1_4:
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
.LCPI1_5:
	.long	12                              # 0xc
	.long	12                              # 0xc
	.long	12                              # 0xc
	.long	12                              # 0xc
.LCPI1_6:
	.long	16                              # 0x10
	.long	16                              # 0x10
	.long	16                              # 0x10
	.long	16                              # 0x10
	.text
	.globl	main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:
	pushq	%rax
	.cfi_def_cfa_offset 16
	callq	getint@PLT
	testl	%eax, %eax
	jle	.LBB1_1
# %bb.2:
	cmpl	$8, %eax
	jae	.LBB1_4
# %bb.3:
	movl	$1, %edx
	xorl	%edi, %edi
	jmp	.LBB1_12
.LBB1_1:
	xorl	%edi, %edi
	jmp	.LBB1_14
.LBB1_4:
	movl	%eax, %edx
	andl	$-8, %edx
	leal	-8(%rdx), %esi
	movl	%esi, %ecx
	shrl	$3, %ecx
	addl	$1, %ecx
	testl	%esi, %esi
	je	.LBB1_5
# %bb.6:
	movl	%ecx, %esi
	andl	$-2, %esi
	movdqa	.LCPI1_0(%rip), %xmm1           # xmm1 = [1,2,3,4]
	pxor	%xmm0, %xmm0
	movdqa	.LCPI1_1(%rip), %xmm8           # xmm8 = [4,4,4,4]
	movdqa	.LCPI1_2(%rip), %xmm9           # xmm9 = [1,1,1,1]
	movdqa	.LCPI1_3(%rip), %xmm10          # xmm10 = [1065353216,1065353216,1065353216,1065353216]
	movdqa	.LCPI1_4(%rip), %xmm11          # xmm11 = [8,8,8,8]
	movdqa	.LCPI1_5(%rip), %xmm12          # xmm12 = [12,12,12,12]
	movdqa	.LCPI1_6(%rip), %xmm13          # xmm13 = [16,16,16,16]
	pxor	%xmm2, %xmm2
	.p2align	4, 0x90
.LBB1_7:                                # =>This Inner Loop Header: Depth=1
	movdqa	%xmm1, %xmm7
	paddd	%xmm8, %xmm7
	movdqa	%xmm1, %xmm4
	pandn	%xmm9, %xmm4
	pslld	$23, %xmm4
	paddd	%xmm10, %xmm4
	cvttps2dq	%xmm4, %xmm4
	movdqa	%xmm1, %xmm5
	pmuludq	%xmm4, %xmm5
	pshufd	$232, %xmm5, %xmm6              # xmm6 = xmm5[0,2,2,3]
	pshufd	$245, %xmm1, %xmm3              # xmm3 = xmm1[1,1,3,3]
	pshufd	$245, %xmm4, %xmm5              # xmm5 = xmm4[1,1,3,3]
	pmuludq	%xmm5, %xmm3
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm6            # xmm6 = xmm6[0],xmm3[0],xmm6[1],xmm3[1]
	paddd	%xmm0, %xmm6
	pshufd	$245, %xmm7, %xmm0              # xmm0 = xmm7[1,1,3,3]
	pmuludq	%xmm4, %xmm7
	pshufd	$232, %xmm7, %xmm7              # xmm7 = xmm7[0,2,2,3]
	pmuludq	%xmm5, %xmm0
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	punpckldq	%xmm0, %xmm7            # xmm7 = xmm7[0],xmm0[0],xmm7[1],xmm0[1]
	paddd	%xmm2, %xmm7
	movdqa	%xmm1, %xmm0
	paddd	%xmm11, %xmm0
	movdqa	%xmm1, %xmm3
	paddd	%xmm12, %xmm3
	pshufd	$245, %xmm0, %xmm2              # xmm2 = xmm0[1,1,3,3]
	pmuludq	%xmm4, %xmm0
	pshufd	$232, %xmm0, %xmm0              # xmm0 = xmm0[0,2,2,3]
	pmuludq	%xmm5, %xmm2
	pshufd	$232, %xmm2, %xmm2              # xmm2 = xmm2[0,2,2,3]
	punpckldq	%xmm2, %xmm0            # xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1]
	paddd	%xmm6, %xmm0
	pmuludq	%xmm3, %xmm4
	pshufd	$232, %xmm4, %xmm2              # xmm2 = xmm4[0,2,2,3]
	pshufd	$245, %xmm3, %xmm3              # xmm3 = xmm3[1,1,3,3]
	pmuludq	%xmm5, %xmm3
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm2            # xmm2 = xmm2[0],xmm3[0],xmm2[1],xmm3[1]
	paddd	%xmm7, %xmm2
	paddd	%xmm13, %xmm1
	addl	$-2, %esi
	jne	.LBB1_7
# %bb.8:
	testb	$1, %cl
	je	.LBB1_10
.LBB1_9:
	movdqa	.LCPI1_1(%rip), %xmm3           # xmm3 = [4,4,4,4]
	movdqa	%xmm1, %xmm4
	pandn	.LCPI1_2(%rip), %xmm4
	paddd	%xmm1, %xmm3
	pslld	$23, %xmm4
	paddd	.LCPI1_3(%rip), %xmm4
	cvttps2dq	%xmm4, %xmm4
	pshufd	$245, %xmm1, %xmm5              # xmm5 = xmm1[1,1,3,3]
	pmuludq	%xmm4, %xmm1
	pshufd	$232, %xmm1, %xmm1              # xmm1 = xmm1[0,2,2,3]
	pshufd	$245, %xmm4, %xmm6              # xmm6 = xmm4[1,1,3,3]
	pmuludq	%xmm6, %xmm5
	pshufd	$232, %xmm5, %xmm5              # xmm5 = xmm5[0,2,2,3]
	punpckldq	%xmm5, %xmm1            # xmm1 = xmm1[0],xmm5[0],xmm1[1],xmm5[1]
	paddd	%xmm1, %xmm0
	pmuludq	%xmm3, %xmm4
	pshufd	$232, %xmm4, %xmm1              # xmm1 = xmm4[0,2,2,3]
	pshufd	$245, %xmm3, %xmm3              # xmm3 = xmm3[1,1,3,3]
	pmuludq	%xmm6, %xmm3
	pshufd	$232, %xmm3, %xmm3              # xmm3 = xmm3[0,2,2,3]
	punpckldq	%xmm3, %xmm1            # xmm1 = xmm1[0],xmm3[0],xmm1[1],xmm3[1]
	paddd	%xmm1, %xmm2
.LBB1_10:
	paddd	%xmm2, %xmm0
	pshufd	$238, %xmm0, %xmm1              # xmm1 = xmm0[2,3,2,3]
	paddd	%xmm0, %xmm1
	pshufd	$85, %xmm1, %xmm0               # xmm0 = xmm1[1,1,1,1]
	paddd	%xmm1, %xmm0
	movd	%xmm0, %edi
	cmpl	%edx, %eax
	je	.LBB1_14
# %bb.11:
	orl	$1, %edx
.LBB1_12:
	addl	$1, %eax
	.p2align	4, 0x90
.LBB1_13:                               # =>This Inner Loop Header: Depth=1
	movl	%edx, %ecx
	notb	%cl
	andb	$1, %cl
	movl	%edx, %esi
	shll	%cl, %esi
	addl	%esi, %edi
	addl	$1, %edx
	cmpl	%edx, %eax
	jne	.LBB1_13
.LBB1_14:
	callq	putint@PLT
	xorl	%eax, %eax
	popq	%rcx
	.cfi_def_cfa_offset 8
	retq
.LBB1_5:
	.cfi_def_cfa_offset 16
	movdqa	.LCPI1_0(%rip), %xmm1           # xmm1 = [1,2,3,4]
	pxor	%xmm0, %xmm0
	pxor	%xmm2, %xmm2
	testb	$1, %cl
	jne	.LBB1_9
	jmp	.LBB1_10
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function
	.ident	"Ubuntu clang version 14.0.0-1ubuntu1.1"
	.section	".note.GNU-stack","",@progbits
	.addrsig
