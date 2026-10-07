# 阶段 5：生成并分析 RISC-V 参考汇编

## 目标

先观察成熟 Clang 后端如何把同一 C/SysY 逻辑变成 RISC-V 汇编，并读取已有课程工具链配置，为手写汇编选择可复现的汇编与链接方式。

## 输入

- `source/example_clang.c`
- `../env.sh` 提供的 RISC-V 工具链路径。
- `../SysY_Compiler_2025/toolchain.conf`、`asm2bin.sh` 和已有 `lib/libsysy_riscv.a`。

## 执行命令

```bash
bash scripts/04_riscv_reference.sh 2>&1 | tee logs/04_riscv_reference.log
```

生成参考代码的核心命令：

```bash
clang --target=riscv64-unknown-elf -march=rv64gc -mabi=lp64d \
    -S -O0 source/example_clang.c -o generated/example_riscv.s
```

## 关键输出

- 参考汇编目标为 `rv64gc/lp64d`，与 `libsysy_riscv.a` 的 ELF `RISC-V`、`RVC`、double-float ABI 标志匹配。
- `calc` 入参 `n` 从 `a0` 传入；返回值在退出时放入 `a0`。`main` 调用 `getint` 后从 `a0` 取得输入，把 `n` 放回 `a0` 调用 `calc`，再把结果放在 `a0` 调用 `putint`。
- 自动生成代码使用 `sp` 建立 32/48 字节栈帧、以 `s0` 为 frame pointer；局部 `i`、`sum` 等整型值由 `lw/sw` 访问。32/48 都是 16 的倍数，保持栈对齐。`main` 需要跨函数调用保存/恢复 `ra`；`s0` 属于被调用者保存寄存器，序言与尾声成对保存/恢复。`calc` 在 `-O0` 下也保存了 `ra`。
- `.LBB0_1` 承载 while 条件：`blt n, i, exit` 在 `i > n` 时离开循环，其他情况继续。奇偶判断分支到 `.LBB0_3`/`.LBB0_4`，两个分支在 `.LBB0_5` 合流，递增 `i` 后 `j .LBB0_1` 构成回边。`slliw i, 1` 实现偶数分支的乘 2；`addw` 做 32 位累加。
- 使用到的 ABI 寄存器是 `a0`、`a1`、`s0`、`sp`、`ra`。通用规则：`a0-a7` 传参/返回（返回值主要在 `a0`），`t0-t6` 为 caller-saved 临时寄存器，`s0-s11` 为 callee-saved；本次 Clang 输出未用到 `t*`。
- `toolchain.conf` 选择 `riscv64-unknown-elf-gcc`，文本地址为 `0x90000000`。`asm2bin.sh` 的实际链接参数包括 `-L./lib -lsysy_riscv -static -mcmodel=medany -Wl,--no-relax,-Ttext=0x90000000`；项目没有独立 `.ld/.lds` 文件。
- 现有 runtime archive 可读到，但 `ar t` 显示含 `sylib.o` 与 `libsysy_riscv.o` 两个成员，且 sibling 项目状态已标为修改。为保留已有成果，本实验不运行 `buildlib.sh`，也不改写该目录。

## 生成产物

- `generated/example_riscv.s`：Clang 自动生成的参考汇编，只用于分析。
- `scripts/04_riscv_reference.sh`
- `logs/04_riscv_reference.log`
- `records/05_riscv_analysis.md`

## 结果解释

`a0` 同时承担第一个整数参数和整数返回值，解释了 `getint`、`calc` 与 `putint` 之间的值传递。`sp/s0` 和偏移量表达局部变量存储；条件分支与跳转标签表达 if 和 while。自动汇编用于观察与对照，后续 `riscv/manual.s` 将按 ABI 规则独立编写。

## 验收结果

PASS — 参考 RISC-V 汇编已生成，寄存器、栈帧、比较、奇偶分支、回边和调用关系均已映射到源程序。

## 异常

无。
