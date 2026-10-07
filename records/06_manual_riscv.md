# 阶段 6：手写 RISC-V 汇编并在 QEMU 上验证

## 目标

独立实现 `calc` 与 `main`，遵守 RV64 调用约定，链接已经存在的 SysY RISC-V runtime，并在 QEMU 上与同一组 Ground Truth 输入对照。

## 输入

- `riscv/manual.s`：手写汇编。
- `../SysY_Compiler_2025/toolchain.conf`：工具链、文本地址配置。
- `../SysY_Compiler_2025/lib/libsysy_riscv.a`：已有 SysY runtime archive。
- `source/test_reference.sh`：固定输入/期望值。

## 执行命令

```bash
bash scripts/05_riscv_validation.sh 2>&1 | tee logs/05_riscv_validation.log
```

脚本用配置中的 `riscv64-unknown-elf-gcc` 汇编和静态链接，参数遵循课程 `asm2bin.sh` 的 runtime、`medany` 与 `TEXT_ADDR=0x90000000` 设定；随后由 `qemu-riscv64` 运行。

## 关键输出

- `generated/manual_riscv` 是静态链接的 RISC-V ELF `EXEC`，架构为 RV64、RVC、double-float ABI；ELF 入口地址为 `0x90000044`。
- 六组输入 `1, 2, 3, 4, 5, 10` 分别输出 `1, 5, 8, 16, 21, 85`，均与宿主机 reference 和手写 LLVM IR 一致。逐组结果在 `outputs/manual-riscv-test.txt`。
- SysY runtime 带有析构计时输出，因此 QEMU 运行时每次还会向 stderr 打印 `TOTAL: 0H-0M-0S-0us`；程序的 `putint` 标准输出值保持正确，测试脚本只对标准输出进行比较。
- 课程 archive 当前包含 `sylib.o` 与 `libsysy_riscv.o` 两个成员；本次按已有配置直接链接成功，没有运行 `buildlib.sh`，也没有改动 sibling 项目文件。

## 生成产物

- `riscv/manual.s`
- `source/run_manual_riscv.sh`：将固定测试调用转发给 `qemu-riscv64`。
- `generated/manual_riscv`
- `outputs/manual-riscv-test.txt`
- `scripts/05_riscv_validation.sh`
- `logs/05_riscv_validation.log`
- `records/06_manual_riscv.md`

中间对象 `generated/manual_riscv.o` 匹配 `.gitignore` 的 `*.o` 规则，可由阶段脚本重建。

## 结果解释

`calc` 在栈帧中保存 `n`、`i`、`sum`，使用 `s0` 作为 frame pointer，并在返回前恢复 `s0`、`ra` 和 `sp`；栈帧大小为 32 字节，符合 16 字节对齐。while 条件用 `blt n,i,while_end` 表达 `i>n` 时退出；`remw` 与 `beqz` 进行奇偶选择；两个分支将结果写回 `sum` 后合流，`i++` 后跳回 while 条件块。`main` 保存返回地址，连续调用 runtime 的 `getint`、`putint` 和本文件的 `calc`，整数实参/返回值通过 `a0` 传递。

所有临时计算仅使用 caller-saved 的 `t0-t2`；被调用者保存的 `s0` 在 `calc` 中成对保存/恢复。`main` 和 `calc` 都在调用或返回边界保持栈对齐。

## 验收结果

PASS — 手写汇编完成汇编、链接 SysY runtime，并在 QEMU 上通过六组测试。

## 异常

无。
