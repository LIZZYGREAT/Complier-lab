# 阶段 8：MLIR / AscendNPU VecAdd lowering 资料分析

## 目标

围绕 `C[j] = A[j] + B[j]`，说明从张量运算到 Ascend NPU 执行所需的表示如何逐层增加硬件细节，并解释 MLIR 多 dialect 的用途。

## 输入

- LLVM Project 的 MLIR Language Reference、Rationale 和 Target LLVM IR 文档。
- Ascend 官方 AscendNPU-IR Framework Integration、Interface API 和 HIVM VecAdd 集成示例。
- 本阶段未发现本地课程 PDF/PPT；MLIR/Ascend 编译器与 NPU 执行环境也未安装。

## 执行命令

```bash
bash scripts/08_mlir_exploration.sh 2>&1 | tee logs/08_mlir_exploration.log
```

官方 `add.mlir` 示例可读作：

```mlir
func.func @add(
    %a: memref<16xi16, #hivm.address_space<gm>>,
    %b: memref<16xi16, #hivm.address_space<gm>>,
    %c: memref<16xi16, #hivm.address_space<gm>>)
    attributes {hacc.entry, hacc.function_kind = #hacc.function_kind<DEVICE>} {
  %ub_a = memref.alloc() : memref<16xi16, #hivm.address_space<ub>>
  hivm.hir.load ins(%a : memref<16xi16, #hivm.address_space<gm>>)
                outs(%ub_a : memref<16xi16, #hivm.address_space<ub>>)
  %ub_b = memref.alloc() : memref<16xi16, #hivm.address_space<ub>>
  hivm.hir.load ins(%b : memref<16xi16, #hivm.address_space<gm>>)
                outs(%ub_b : memref<16xi16, #hivm.address_space<ub>>)
  %ub_c = memref.alloc() : memref<16xi16, #hivm.address_space<ub>>
  hivm.hir.vadd ins(%ub_a, %ub_b : memref<16xi16, #hivm.address_space<ub>>,
                                  memref<16xi16, #hivm.address_space<ub>>)
                outs(%ub_c : memref<16xi16, #hivm.address_space<ub>>)
  hivm.hir.store ins(%ub_c : memref<16xi16, #hivm.address_space<ub>>)
                 outs(%c : memref<16xi16, #hivm.address_space<gm>>)
  return
}
```

This is transcribed from the official VecAdd example, not compiled locally. Its exact source URL is listed in `mlir/references/README.md`.

## 关键分析

| 表示层 | VecAdd 的关注点 | 新增信息 |
| --- | --- | --- |
| Arith / Tensor | 元素类型、形状和逐元素加法；元素运算可用 `arith.addi`，张量层描述 `tensor<16xi16>` 等值 | 算法语义与形状，不指定 NPU 地址空间或搬运指令 |
| Linalg / HFusion | `linalg.elemwise_binary` 等保留张量级 elementwise 语义；HFusion 对满足条件的算子做融合、tiling 与调度 | 算子组合与执行计划；仍可按 tensor/算子理解 |
| HIVM | 官方例子把 A/B/C 标为 GM，显式分配 UB 暂存区，执行 GM→UB load、`hivm.hir.vadd`、UB→GM store | Ascend 存储层次、向量操作与内存搬运；需要时由编译流程做内存规划和同步插入 |
| HACC | `hacc.entry` 和 `hacc.function_kind<DEVICE>` 标记 kernel 入口与执行侧；配套 host wrapper 初始化 ACL、准备数据、launch、同步并拷回结果 | 主机与设备边界、kernel entry/launch 元数据，不改变加法本身 |
| LLVM IR / 目标代码 | 经过转换后，面向后端的低层操作可表示为 LLVM dialect/LLVM IR 或硬件 intrinsic，再继续目标代码生成 | 更明确的控制流、类型转换、指针与指令/调用约定，较少保留高层张量语义 |

## Lowering 与资料边界

MLIR 的 `Operation`、`Value`、`Block`、`Region` 让不同抽象层可以留在同一个可扩展 IR 框架里；dialect 定义各层自己的操作、类型和属性。Lowering 是一系列保持程序语义的转换：先让通用优化仍能看到张量/算子结构，再逐步确定 tiling、内存空间、数据搬运和硬件操作。若过早降到普通 load/store，后续 pass 很难恢复原有算子边界和张量形状。

课程文档给出的 `Arith/Tensor → HFusion → HIVM → HACC → LLVM IR` 可用作概念路线。按本次查阅的当前公开 AscendNPU-IR 样例，Linalg/Tensor 与 HFusion 组成算子和调度层，HIVM 样例使用 `hivm.hir.vadd`；HACC 以入口/host-device 属性和 host wrapper 体现。官方可运行示例要求 CANN、`bishengir-compile` 和 NPU；示例的明确产物是 kernel `.o`，本资料中没有保存可供复核的 Ascend LLVM IR dump。LLVM IR 是通用 MLIR lowering 机制的后续表示，不应在本记录中伪称为该 VecAdd 示例实测得到的中间文件。

这次只完成文档与源码阅读，没有运行 `bishengir-opt`、`bishengir-compile`，没有安装 CANN，也没有在 Ascend 硬件上执行。因此表中高层 Arith/Tensor 描述是语义示意；只有 HIVM `add.mlir` 片段和 host wrapper 调用流程来自官方项目源文件。

## 生成产物

- `mlir/references/README.md`：官方来源清单及访问日期。
- `scripts/08_mlir_exploration.sh`
- `logs/08_mlir_exploration.log`
- `records/08_mlir_exploration.md`

## 结果解释

LLVM IR 通常更接近目标无关的低层指令表示；MLIR 允许多个具有专门语义的 dialect 并存，按需求渐进 lowering。对 VecAdd 来说，最核心的变化是从“两个形状相同的张量逐元素相加”变成“从 GM 搬到 UB、执行 NPU vector add、再写回 GM”，同时由 HACC/运行时负责把 device kernel 与 host 调用衔接。

## 验收结果

PASS（资料分析）— 已按 Arith/Tensor、HFusion、HIVM、HACC、LLVM IR 逐层解释 lowering，并明确标注未运行编译器/未上板。

## 异常

无。工具缺失和没有本地课程演示材料已如实记入日志；按照阶段方案使用官方文档与官方 VecAdd 源码完成分析。
