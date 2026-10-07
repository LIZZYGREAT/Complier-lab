# Clang `-O0` 与 `-O2` 真实差异

比较文件由 `scripts/06_optimization.sh` 重新生成；完整 unified diff 保存在 `optimization-ir.diff`、`optimization-x86.diff`、`optimization-riscv.diff`。以下结论只描述 Clang 14 对当前程序和目标的实际结果。

## LLVM IR

| 指标 / 变化 | `-O0` | `-O2` |
| --- | --- | --- |
| `alloca` | 6 | 0 |
| `load` | 11 | 0 |
| `store` | 9 | 0 |
| `calc` 中的求余与分支 | `srem` 后接 `icmp eq` 和条件分支 | 改为 parity 的 `and/xor/shl` 运算 |
| 局部变量表示 | 栈槽与内存读写 | SSA 临时值和循环 `phi` |
| `main` 对 `calc` 的调用 | 存在 `call @calc` | 函数体被内联到 `main`；因 `calc` 外部可见，单独的 `@calc` 定义仍保留 |
| 循环主体 | 直接逐项循环 | x86-64 通用 IR 中出现四 lane `<4 x i32>` 运算和 `llvm.vector.reduce.add`，并保留边界/尾部路径 |

## 目标汇编

- x86-64 汇编从 87 行变为 385 行。`-O2` 的 `calc`/`main` 中有 SSE `xmm` 与 `paddd` 等向量指令，也有向量归约；文本更长是因为 vectorized/unrolled 主体和函数内联，行数不能直接当作运行速度指标。
- RV64 汇编从 91 行变为 56 行。`-O2` 去掉 `calc` 的局部栈槽和独立调用，将调用体内联进 `main`；奇偶判断变成位运算和移位累加。目标为 `rv64gc`，未启用 RVV，所以输出仍是标量循环，没有向量寄存器指令。
- 两种目标都在 `-O2` 下去掉了 `main` 到 `calc` 的调用。x86-64 做了 SIMD 向量化；RV64 则保持标量循环，并用算术表达式简化分支。

## 结论边界

`-O2` 明显减少抽象内存读写并重写控制/算术，但本节只观察 IR/汇编，没有测量耗时、代码体积或硬件性能，因而不据此声称量化的速度提升。
