	.text
	.attribute	4, 16
	.attribute	5, "rv64i2p0_m2p0_a2p0_f2p0_d2p0_c2p0"
	.file	"example_clang.c"
	.globl	calc
	.p2align	1
	.type	calc,@function
calc:
	addi	sp, sp, -32
	sd	ra, 24(sp)
	sd	s0, 16(sp)
	addi	s0, sp, 32
	sw	a0, -20(s0)
	li	a0, 1
	sw	a0, -24(s0)
	li	a0, 0
	sw	a0, -28(s0)
	j	.LBB0_1
.LBB0_1:
	lw	a1, -24(s0)
	lw	a0, -20(s0)
	blt	a0, a1, .LBB0_6
	j	.LBB0_2
.LBB0_2:
	lwu	a0, -24(s0)
	srli	a1, a0, 31
	add	a1, a1, a0
	andi	a1, a1, -2
	subw	a0, a0, a1
	li	a1, 0
	bne	a0, a1, .LBB0_4
	j	.LBB0_3
.LBB0_3:
	lw	a0, -28(s0)
	lw	a1, -24(s0)
	slliw	a1, a1, 1
	addw	a0, a0, a1
	sw	a0, -28(s0)
	j	.LBB0_5
.LBB0_4:
	lw	a0, -28(s0)
	lw	a1, -24(s0)
	addw	a0, a0, a1
	sw	a0, -28(s0)
	j	.LBB0_5
.LBB0_5:
	lw	a0, -24(s0)
	addiw	a0, a0, 1
	sw	a0, -24(s0)
	j	.LBB0_1
.LBB0_6:
	lw	a0, -28(s0)
	ld	ra, 24(sp)
	ld	s0, 16(sp)
	addi	sp, sp, 32
	ret
.Lfunc_end0:
	.size	calc, .Lfunc_end0-calc

	.globl	main
	.p2align	1
	.type	main,@function
main:
	addi	sp, sp, -48
	sd	ra, 40(sp)
	sd	s0, 32(sp)
	addi	s0, sp, 48
	li	a0, 0
	sd	a0, -40(s0)
	sw	a0, -20(s0)
	call	getint
	sw	a0, -24(s0)
	lw	a0, -24(s0)
	call	calc
	sw	a0, -28(s0)
	lw	a0, -28(s0)
	call	putint
	ld	a0, -40(s0)
	ld	ra, 40(sp)
	ld	s0, 32(sp)
	addi	sp, sp, 48
	ret
.Lfunc_end1:
	.size	main, .Lfunc_end1-main

	.ident	"Ubuntu clang version 14.0.0-1ubuntu1.1"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym calc
	.addrsig_sym getint
	.addrsig_sym putint
