    .section .text
    .align 2

    .globl calc
    .type calc, @function
calc:
    addi sp, sp, -32
    sd ra, 24(sp)
    sd s0, 16(sp)
    addi s0, sp, 32
    sw a0, -20(s0)       # n
    li t0, 1
    sw t0, -24(s0)       # i = 1
    sw zero, -28(s0)     # sum = 0

.Lwhile_cond:
    lw t0, -24(s0)       # i
    lw t1, -20(s0)       # n
    blt t1, t0, .Lwhile_end

.Lif_cond:
    li t1, 2
    remw t2, t0, t1
    beqz t2, .Lif_then
    j .Lif_else

.Lif_then:
    lw t0, -28(s0)       # sum
    lw t1, -24(s0)       # i
    slliw t1, t1, 1      # 2 * i
    addw t0, t0, t1
    sw t0, -28(s0)
    j .Lif_end

.Lif_else:
    lw t0, -28(s0)       # sum
    lw t1, -24(s0)       # i
    addw t0, t0, t1
    sw t0, -28(s0)

.Lif_end:
    lw t0, -24(s0)
    addiw t0, t0, 1
    sw t0, -24(s0)
    j .Lwhile_cond

.Lwhile_end:
    lw a0, -28(s0)       # integer return value
    ld s0, 16(sp)
    ld ra, 24(sp)
    addi sp, sp, 32
    ret
    .size calc, .-calc

    .align 2
    .globl main
    .type main, @function
main:
    addi sp, sp, -16
    sd ra, 8(sp)
    call getint          # input/return value in a0
    call calc            # argument and return value in a0
    call putint          # output argument in a0
    li a0, 0
    ld ra, 8(sp)
    addi sp, sp, 16
    ret
    .size main, .-main

    .section .note.GNU-stack,"",@progbits
