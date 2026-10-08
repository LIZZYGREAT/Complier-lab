# 阶段 8：MLIR / AscendNPU IR VecAdd 与 PlanMemory

## 目标与边界

本轮进阶任务围绕 16 个 `int16` 元素的 VecAdd，解释 MLIR 为何保留多层抽象，以及 HIVM 如何把 GM / UB、显式数据搬运和 NPU 向量运算带入 IR。环境不满足低成本构建条件，因此按任务方案使用官方资料和真实上游 Test Case 做源码分析，没有声称运行本地 Ascend Pass。

项目已存在的实验目录为 `lab/`，故本轮文件按当前仓库结构放在 `lab/mlir/`，而不是另建 `assignment1/mlir/`。

## Stage 0：环境检查和构建决策

只读检查结果见 `mlir/logs/environment.log`：Ubuntu 22.04.5 x86_64，CMake 不存在，Ninja 为 1.10.1，Clang 为 14.0.0。AscendNPU-IR 官方构建要求 CMake ≥ 3.28、Ninja ≥ 1.12；当前至少两个关键构建条件不满足，且检查路径未发现用户级 `cmake`、`ninja` 或 `bishengir-opt`。按任务停止条件，没有安装/升级系统工具，也没有克隆源码，选择 Stage 1B。

## VecAdd 主线

固定语义为 `c[i] = a[i] + b[i]`，`0 ≤ i < 16`。官方 [HIVM VecAdd `add.mlir`](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/add.mlir) 的输入已保存到 `mlir/sources/vecadd_hivm.mlir`。三个参数均属于 GM；A、B 通过 `hivm.hir.load` 搬到 UB；`hivm.hir.vadd` 在 UB 计算；`hivm.hir.store` 把结果写回 GM。`hacc.entry` 与 `hacc.function_kind<DEVICE>` 标记设备侧入口。

概念主线为：

```text
Arith / Tensor
    ↓ 元素类型、shape、逐元素加语义
Linalg / HFusion
    ↓ 算子融合、tiling、调度
HIVM
    ↓ GM / UB、load / vadd / store、内存规划与同步
HACC / LLVM 后续表示
```

MLIR 的价值不只是拥有多个 IR 层级，而是让不同阶段在合适的抽象上优化：张量形状和算子边界尚在时可以分析 fusion 和 tiling；进入 HIVM 后再显式安排存储层次、搬运路径和 NPU 计算。若过早摊平成低层 load/store，后续 pass 就难直接利用算子与张量语义。LLVM IR 可作为后续低层通用表示；此次没有观察到该 VecAdd 的 LLVM IR dump。

HFusion 到 HIVM 的图是依官方多层接入文档和作业要求建立的概念路线。本地真实保存并逐行分析的是官方 HIVM VecAdd；没有声称本机执行了从 HFusion 到 HIVM 的转换。

## PlanMemory：官方源码 Test Case 分析

在官方 [PlanMemory 文档](https://ascendnpu-ir.gitcode.com/en/developer_guide/features/PlanMemory/PlanMemory.html) 中，`memref.alloc` 具有 buffer 大小和地址空间，但没有具体地址。PlanMemory 根据生命周期、别名及硬件规则分配片上地址，并将局部 `memref.alloc` 改写为 `hivm.hir.pointer_cast(offset)`。

使用的真实上游文件是 [官方 `plan-memory.mlir`](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Dialect/HIVM/plan-memory.mlir) 中的 `test_mem_allocate_basic`。其上游 `RUN` 为：

```sh
bishengir-opt %s -hacc-append-device-spec=target=Ascend910B1 -hivm-plan-memory -split-input-file -verify-diagnostics | FileCheck %s
```

该用例输入有四个独立 UB `memref.alloc()`，类型均为 `16×16×16×f16`，每块 8192 字节。上游 `CHECK` 要求变换结果中不再有 `memref.alloc()`，并检查四个分配位置都对应偏移 0 的 `hivm.hir.pointer_cast`。这展示了 pass 把“申请 UB 临时区”转成显式地址表达的结果形状。

这里的 `CHECK` 是官方测试源中的期望，不是我们运行产生的输出。由于本机没有 `bishengir-opt` 和 `FileCheck`，没有生成 `plan_memory_before.mlir` 或 `plan_memory_after.mlir`；具体运行状态见 `mlir/logs/pass_runs.log`，结构解释见 `mlir/analysis/plan_memory_analysis.md`。不把该单一用例的 offset-0 期望推广到所有程序。

## 资料理解与真实运行的区分

| 内容 | 证据类型 | 本轮结果 |
| --- | --- | --- |
| 16×`i16` VecAdd 的 GM/UB/load/vadd/store | 官方上游源文件摘录 | 已保存并结构分析，未编译 |
| PlanMemory 的功能和地址规划机制 | 官方 Pass 文档 | 已阅读 |
| PlanMemory 输入、`RUN` 和 `CHECK` | 官方上游 `plan-memory.mlir` Test Case | 已保存摘录和链接，未在本机执行 |
| 本机 Ascend Pass Before / After | 真实运行结果 | 未产生 |
| Sync 独立用例 | 可选实验 | 本轮跳过 |
| CANN、kernel `.o`、NPU Runtime | 硬件端到端 | 未尝试 |

因此本部分是基于官方文档和真实源码 Test Case 的结构分析，未声称完成真实 Ascend Pass 运行或 NPU 上板。

## 生成产物

- `mlir/README.md`：本轮范围和状态。
- `mlir/sources/vecadd_hivm.mlir`：官方 16×`i16` HIVM VecAdd。
- `mlir/sources/selected_tests/plan_memory_input.mlir`：上游 PlanMemory 用例摘录，含原始 RUN/CHECK。
- `mlir/analysis/lowering_chain.md`：多层 IR 与 VecAdd 硬件映射分析。
- `mlir/analysis/plan_memory_analysis.md`：PlanMemory Test Case 分析。
- `mlir/references/source_index.md`：官方文档和源码索引。
- `mlir/logs/environment.log`、`build.log`、`pass_runs.log`：检查、停止决策和运行范围记录。
- 未创建 `mlir/outputs/` Before/After 文件，因为本机没有运行 Pass。

## 完成状态

- VecAdd 主线：PASS
- 官方资料核对：PASS
- bishengir-opt 构建：SKIPPED（CMake 缺失、Ninja 版本低于最低要求）
- PlanMemory 实验：ANALYSIS-ONLY
- Sync 实验：SKIPPED
- CANN：NOT ATTEMPTED
- NPU 上板：NOT ATTEMPTED
