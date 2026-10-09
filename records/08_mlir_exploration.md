# 阶段 8：MLIR / AscendNPU IR VecAdd 与 Pass 实验

## 过程与范围

进阶部分围绕 16 个 `int16` 元素的 VecAdd，观察 MLIR 如何保留张量、内存空间和 NPU 操作信息。工作按两个阶段推进：最初检查环境时发现系统没有 CMake，Ninja 版本也低于上游要求，于是先基于官方资料和 Test Case 做结构分析；后续阶段 11–13 在仓库外准备了用户级构建环境，构建 `bishengir-opt` 并实际运行上游 Pass。当前结论以阶段 13 的运行结果为准，以下同时保留最初的决策过程。

最初的环境快照见 `mlir/logs/environment.log`：Ubuntu 22.04.5 x86_64、系统 Ninja 1.10.1，未发现可用的 `cmake`、`ninja` 或 `bishengir-opt`。阶段 11 后来用仓库外的用户级 venv 补齐工具，阶段 12 从 AscendNPU-IR 源码构建成功，阶段 13 的三条上游 `RUN` 命令及 FileCheck 断言全部通过。过程详见 `records/11_ascend_build_precheck.md` 至 `records/13_ascend_pass_runs.md`。

## VecAdd 主线

固定语义为 `c[i] = a[i] + b[i]`，`0 ≤ i < 16`。官方 [HIVM VecAdd `add.mlir`](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/add.mlir) 已保存到 `mlir/sources/vecadd_hivm.mlir`。A、B、C 位于 GM；输入通过 `hivm.hir.load` 搬到 UB，在 UB 上执行 `hivm.hir.vadd`，再通过 `hivm.hir.store` 写回 GM。`hacc.entry` 与 `hacc.function_kind<DEVICE>` 标记设备侧入口。

```text
Arith / Tensor
    ↓ 元素类型、shape、逐元素加语义
Linalg / HFusion
    ↓ 算子融合、tiling、调度
HIVM
    ↓ GM / UB、load / vadd / store、内存规划与同步
HACC / LLVM 后续表示
```

这是一条根据官方框架文档和作业要求整理的概念主线。实际保存并逐行分析的 VecAdd 文件处于 HIVM 层；本次没有得到 Arith/Tensor 或 HFusion 到 HIVM 的本地 lowering 转储。

## PlanMemory：实测结果

阶段 13 从上游 `bishengir/test/Dialect/HIVM/plan-memory.mlir` 执行默认策略和 `largest-first` 两条 `RUN`。两条都包含 `-hacc-append-device-spec=target=Ascend910B1`，并都通过上游 FileCheck 断言。Before/After 单文件保存的是默认策略用例 `test_mem_allocate_basic`。

该用例有四个 UB `memref.alloc()`，每个 shape 为 `16×16×16×f16`，占 8192 字节。实测后四个分配均变为 `hivm.hir.pointer_cast`，偏移均为 0；五条 `load`、`vadd`、`store` 计算操作保持不变。模块中的 `dlti.target_system_spec` 和 `hacc.target` 属性由前置的 `-hacc-append-device-spec` 加入，不能归因于 PlanMemory 单独产生。该用例展示了具体输入上的结果，偏移为 0 的现象不应推广到其他程序；地址安排还取决于 buffer 生命周期、别名关系和目标约束。

四个 buffer 的名义容量合计为 32 KiB，小于该目标规格中的 UB 容量，但容量比较本身不足以解释它们为何都得到偏移 0。这里以实测输出和上游断言为证据，不进一步推断地址复用决策的全部原因。

## InjectSync：实测结果

阶段 13 还执行了 `inject-sync.mlir` 中的 `test_mem_injcet_sync_basic`。输入的关键操作为 `load → vadd → store`，没有同步指令。Pass 输出增加了 2 条 `set_flag`、2 条 `wait_flag` 和 1 条 `pipe_barrier`：load 与向量计算之间为 MTE2→V 依赖，向量计算与 store 之间为 V→MTE3 依赖，函数末尾出现 `PIPE_ALL` barrier。Before/After 均保存在 `mlir/outputs/`。

## 当前状态与边界

| 内容 | 结果 |
| --- | --- |
| HIVM VecAdd 输入与 GM/UB 操作分析 | PASS |
| PlanMemory 默认策略 | PASS（上游 FileCheck；Before/After 已保存） |
| PlanMemory `largest-first` 策略 | PASS（上游 `CHECK-REORDER`） |
| InjectSync | PASS（上游 FileCheck；Before/After 已保存） |
| Arith/Tensor、HFusion 到 HIVM 的本地转换 | 未运行，按官方资料说明概念路线 |
| CANN、驱动、kernel `.o`、真实 NPU 执行 | 未尝试；本次验证范围止于 IR Pass |

## 主要产物

- `mlir/README.md`：当前状态和入口。
- `mlir/sources/vecadd_hivm.mlir`：官方 HIVM VecAdd 输入。
- `mlir/sources/selected_tests/plan_memory_input.mlir`、`sync_input.mlir`：上游测试摘录。
- `mlir/outputs/plan_memory_before.mlir`、`plan_memory_after.mlir`：PlanMemory 默认策略实测。
- `mlir/outputs/sync_before.mlir`、`sync_after.mlir`：InjectSync 实测。
- `mlir/analysis/lowering_chain.md`、`plan_memory_analysis.md`：结构说明与结果分析。
- `mlir/references/source_index.md`：官方文档、测试与本地检出版本索引。
- `mlir/logs/`、`logs/11`–`13` 与 `records/11`–`13`：环境、构建和运行留痕。
