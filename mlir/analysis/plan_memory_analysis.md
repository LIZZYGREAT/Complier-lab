# PlanMemory：上游 Test Case 结构分析

## 来源和执行命令

选用 AscendNPU-IR 的 `bishengir/test/Dialect/HIVM/plan-memory.mlir` 中 `test_mem_allocate_basic` 用例。上游文件的 `RUN` 是：

```sh
bishengir-opt %s -hacc-append-device-spec=target=Ascend910B1 -hivm-plan-memory -split-input-file -verify-diagnostics | FileCheck %s
```

该文件还有第二条 `RUN`，用 `-hivm-plan-memory=plan-memory-strategy=largest-first` 并以 `CHECK-REORDER` 前缀检查；下面只分析第一条（默认策略）。两条都要求 `-hacc-append-device-spec=target=Ascend910B1`，缺少该参数时 Pass 无法确定目标芯片规格。

本地摘录在 [`sources/selected_tests/plan_memory_input.mlir`](../sources/selected_tests/plan_memory_input.mlir)。摘录保留该用例的 `RUN`、输入 IR 和 `CHECK` 指令。官方文档说明 PlanMemory 会根据 buffer 生命周期和硬件约束规划地址，并把局部 `memref.alloc` 改写为 `hivm.hir.pointer_cast(offset)`。

## Before / After 的结构变化

| 项目 | Test Case 输入（Before） | 上游 `CHECK` 期望（After） |
| --- | --- | --- |
| 临时 UB 缓冲区 | 四个独立的 `memref.alloc()`，shape 都是 `16×16×16×f16` | 检查输出中没有 `memref.alloc()` |
| 地址信息 | 只声明 UB 地址空间和 buffer 大小 | 对应为 `hivm.hir.pointer_cast` |
| 该用例的偏移 | IR 中没有显式地址 | 四处 `pointer_cast` 都引用 `arith.constant 0 : i64` |

每个 buffer 大小为 `16×16×16×2 = 8192` 字节。官方用例展示 PlanMemory 如何给原本只有内存空间和大小的局部 buffer 指定地址。所有地址断言为 0 是该特定用例的上游期望；不能据此推断任意程序的所有 buffer 都会共用一个地址。一般的复用仍须满足生命周期、别名、对齐和硬件规则。

## Pass 前缺少什么

`memref.alloc` 表达了“需要一个 UB 区域”以及区域大小，但用例输入没有数值偏移。编译器仍需确定 buffer 在 UB 中的地址，并避免读写冲突和越界。

## Pass 后增加或改变什么

官方文档说明 Pass 执行生命周期分析，再依据内存范围和复用规则分配地址，并把 `memref.alloc` 改写成带偏移的 `hivm.hir.pointer_cast`。这个测试的 `CHECK-NOT` 与四个 offset-0 检查表达了预期输出形状。我们没有执行 `RUN`，所以以上是对官方测试断言的结构解读，不是本机捕获的 After IR。

## 为什么 Ascend 需要它

UB 属于容量有限、需要满足硬件对齐约束的片上存储。仅把临时 buffer 表达出来，仍不足以形成最终可调度的硬件内存布局。PlanMemory 把内存地址安排显式落入 IR，同时根据存活区间和硬件规则复用空间，连接“需要一个临时缓冲区”与“它在片上内存里放在哪里”。

## 证据边界

- 真实保存：官方 VecAdd 输入、上游测试摘录、上游 `RUN`/`CHECK`、官方 Pass 文档。
- 未运行：`bishengir-opt` 和 `FileCheck`。
- 因此 `mlir/outputs/` 不包含 PlanMemory Before/After 文件；官方 `CHECK` 仅作为 Test Case 的期望输出断言来引用。
