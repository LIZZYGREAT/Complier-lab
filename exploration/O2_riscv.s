	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p0_m2p0_a2p0_f2p0_d2p0_c2p0"
	.file	"example_clang.c"
	.globl	calc
	.p2align	1
	.type	calc,@function
calc:
	li	a1, 0
	blez	a0, .LBB0_3
	li	a2, 1
.LBB0_2:
	mv	a3, a2
	not	a2, a2
	andi	a2, a2, 1
	sllw	a2, a3, a2
	addw	a1, a1, a2
	addiw	a2, a3, 1
	blt	a3, a0, .LBB0_2
.LBB0_3:
	mv	a0, a1
	ret
.Lfunc_end0:
	.size	calc, .Lfunc_end0-calc

	.globl	main
	.p2align	1
	.type	main,@function
main:
	addi	sp, sp, -16
	sd	ra, 8(sp)
	call	getint
	li	a1, 0
	blez	a0, .LBB1_3
	li	a2, 1
.LBB1_2:
	mv	a3, a2
	not	a2, a2
	andi	a2, a2, 1
	sllw	a2, a3, a2
	addw	a1, a1, a2
	addiw	a2, a3, 1
	blt	a3, a0, .LBB1_2
.LBB1_3:
	mv	a0, a1
	call	putint
	li	a0, 0
	ld	ra, 8(sp)
	addi	sp, sp, 16
	ret
.Lfunc_end1:
	.size	main, .Lfunc_end1-main

	.ident	"Ubuntu clang version 14.0.0-1ubuntu1.1"
	.section	".note.GNU-stack","",@progbits
	.addrsig
