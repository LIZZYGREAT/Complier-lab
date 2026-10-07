# 阶段 7：观察 `-O0` 与 `-O2`

## 目标

基于实际生成的 LLVM IR 和汇编 diff，观察优化级别变化在当前贯穿程序中产生的效果。

## 输入

- `source/example_clang.c`
- Clang 14。
- 已完成的 RISC-V cross target 参考生成。

## 执行命令

```bash
bash scripts/06_optimization.sh 2>&1 | tee logs/06_optimization.log
```

## 关键输出

完整 unified diff 见 `outputs/optimization-ir.diff`、`outputs/optimization-x86.diff`、`outputs/optimization-riscv.diff` 和 `logs/06_optimization.log`。计数为：LLVM IR 的 `alloca` 6→0、`load` 11→0、`store` 9→0。

## 生成产物

- `exploration/O0.ll`、`exploration/O2.ll`
- `exploration/O0.s`、`exploration/O2.s`
- `exploration/O0_riscv.s`、`exploration/O2_riscv.s`
- `outputs/optimization-ir.diff`
- `outputs/optimization-x86.diff`
- `outputs/optimization-riscv.diff`
- `outputs/optimization-analysis.md`
- `scripts/06_optimization.sh`
- `logs/06_optimization.log`
- `records/07_optimization_analysis.md`

## 结果解释

`-O2` 把内存槽变量转成 SSA 值和循环 `phi`；本程序的奇偶计算由求余和 if 分支改写为位运算/移位。LLVM IR 的 `calc` 在 x86-64 主机目标上被 loop vectorizer 改写为四 lane `<4 x i32>` 运算并用 vector reduce 累加；x86 汇编出现 SSE `xmm`/`paddd`。RV64 `rv64gc` 汇编没有 RVV 向量指令，保留标量循环，但把 `calc` 内联到 `main` 并化简奇偶算术。两种 `-O2` 汇编中 `main` 都不再调用 `calc`；`calc` 的对外定义仍保留。主机汇编行数从 87 增至 385，说明优化后文件行数并不必然更短；本实验没有测量运行耗时，不推断速度提升。

## 验收结果

PASS — LLVM IR、x86-64 与 RV64 的 `-O0/-O2` 产物及真实 diff 已保存并分析。

## 异常

无。
