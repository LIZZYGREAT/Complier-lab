# 阶段 13：实跑 AscendNPU-IR 上游 Pass

## 目标

用本地构建的 `bishengir-opt` 真实执行上游 Pass，把第 8 节从"官方资料与源码分析"升级为有运行证据的实测。要回答两件事：

1. 本地构建能否复现上游测试所期望的行为（而不只是"跑起来不报错"）；
2. 对报告具体讨论的两个用例，Pass 到底把 IR 改成了什么。

## 输入

- `../third_party/ascendnpu-ir/build/bin/bishengir-opt`（阶段 12 产出）
- `../third_party/ascendnpu-ir/build/bin/FileCheck`
- 上游测试文件：`bishengir/test/Dialect/HIVM/plan-memory.mlir`、`inject-sync.mlir`

## 执行命令

```bash
bash scripts/13_ascend_pass_runs.sh 2>&1 | tee logs/13_ascend_pass_runs.log
```

脚本第 1 部分**逐字执行上游文件自带的 `RUN` 命令**，并把输出交给**上游自己的 `CHECK` 断言**做 FileCheck；第 2 部分保存两个单用例的 Before / After。

## 关键输出

### 上游 RUN 命令逐字执行（含 FileCheck 断言）

| 用例 | 命令要点 | 结果 |
| --- | --- | --- |
| `plan-memory.mlir` 默认策略 | `-hacc-append-device-spec=target=Ascend910B1 -hivm-plan-memory` | **PASS** |
| `plan-memory.mlir` `largest-first` | 同上加 `=plan-memory-strategy=largest-first`，`CHECK-REORDER` | **PASS** |
| `inject-sync.mlir` | `-hivm-inject-sync -hivm-lower-multi-buffer-counter` | **PASS** |

三条全部通过，说明本地构建不仅"能跑"，而且逐条满足了上游断言的 IR 形状。

### PlanMemory 单用例 Before / After

用例 `test_mem_allocate_basic`（16×16×16×f16，四个 UB 临时 buffer）：

| 指标 | Before | After |
| --- | ---: | ---: |
| `memref.alloc()` | 4 | **0** |
| `hivm.hir.pointer_cast` | 0 | **4** |

Before 的四个 `memref.alloc()` 被逐个改写为引用同一常量 `%c0_i64 = arith.constant 0 : i64` 的 `pointer_cast`，偏移均为 0——与上游 `CHECK-NOT: memref.alloc()` 加四处 `pointer_cast` 断言一致。

同时，注入的模块属性给出了**具体芯片参数**，这是"硬件信息何时进入 IR"的直接证据：

```mlir
module attributes {
  dlti.target_system_spec = #dlti.target_system_spec<"NPU" :
    #hacc.target_device_spec<
      #dlti.dl_entry<"UB_SIZE", 1572864 : i32>,
      #dlti.dl_entry<"L1_SIZE", 4194304 : i32>,
      #dlti.dl_entry<"L0C_SIZE", 1048576 : i32>,
      #dlti.dl_entry<"UB_ALIGN_SIZE", 256 : i32>,
      #dlti.dl_entry<"AI_CORE_COUNT", 24 : i32>,
      #dlti.dl_entry<"VECTOR_CORE_COUNT", 48 : i32>, ...>>,
  hacc.target = #hacc.target<"Ascend910B1">
}
```

Pass 前的计算部分（`hivm.hir.load` / `vadd` / `store`）**一字未改**：PlanMemory 只改变内存的表示方式，不改变计算语义。这一点过去只能引用官方文档断言，现在是实测结果。

### InjectSync 单用例 Before / After

用例 `test_mem_injcet_sync_basic`，源程序只有 `load → vadd → store` 三条计算指令，**没有任何同步指令**。

| 指令 | Before（代码行） | After |
| --- | ---: | ---: |
| `hivm.hir.set_flag` | 0 | 2 |
| `hivm.hir.wait_flag` | 0 | 2 |
| `hivm.hir.pipe_barrier` | 0 | 1 |

After 的实际形态：

```mlir
hivm.hir.load ins(%arg0 : ...<gm>) outs(%0 : ...<ub>)
hivm.hir.set_flag[<PIPE_MTE2>, <PIPE_V>, <EVENT_ID0>]
hivm.hir.wait_flag[<PIPE_MTE2>, <PIPE_V>, <EVENT_ID0>]
hivm.hir.vadd ins(%0, %2 : ...) outs(%0 : ...)
hivm.hir.set_flag[<PIPE_V>, <PIPE_MTE3>, <EVENT_ID0>]
hivm.hir.wait_flag[<PIPE_V>, <PIPE_MTE3>, <EVENT_ID0>]
hivm.hir.store ins(%0 : ...<ub>) outs(%arg1 : ...<gm>)
hivm.hir.pipe_barrier[<PIPE_ALL>]
```

这段输出把"为什么 NPU 需要显式同步"讲得很具体：数据搬运走 MTE2/MTE3 流水，计算走 V（向量）流水，二者是**不同的硬件流水线**，源代码里的先后顺序并不能保证执行完成。Pass 因此插入 MTE2→V（搬入后才能算）与 V→MTE3（算完才能写回）两组 flag，并在函数结尾加一条 `PIPE_ALL` barrier。

注意统计口径：Before 文件中含 `// CHECK:` 断言文本，直接 `grep set_flag` 会得到非零值，从而误判"Before 也有同步"。脚本已限定只统计非注释行，Before 的真实计数为 0。

## 生成产物

- `mlir/outputs/plan_memory_before.mlir`、`plan_memory_after.mlir`
- `mlir/outputs/sync_before.mlir`、`sync_after.mlir`
- `mlir/sources/selected_tests/plan_memory_input.mlir`、`sync_input.mlir`：上游用例的原样摘录（含原始 RUN 行）
- `mlir/logs/pass_runs.log`：上游 RUN 命令的执行记录
- `scripts/13_ascend_pass_runs.sh`
- `logs/13_ascend_pass_runs.log`
- `records/13_ascend_pass_runs.md`：本记录

## 结果解释

本阶段把第 8 节从概念分析推进到可复现的实测，得到三点以前无法声称的结论：

1. **PlanMemory 的作用被实测确认**：它把抽象的 UB 分配请求（`memref.alloc`）落实为带显式偏移的 `pointer_cast`，同时不触碰计算指令。
2. **"硬件信息进入 IR"有了具体形态**：目标芯片的 UB/L1/L0C 容量与对齐、AI/Vector 核数量，是以 `dlti.target_system_spec` 属性写入模块的，而不是含糊的"带上了硬件信息"。
3. **InjectSync 展示了流水线同步的必要性**：源程序只有三条计算指令，Pass 注入了 5 条同步指令（2 flag 对 + 1 barrier），因为这些指令运行在 MTE2/V/MTE3 三个不同流水线上。

关于偏移为 0：该用例四个 buffer 各 8192 字节、名义容量合计 32 KiB，目标规格中的 UB 容量为 1572864 字节。容量对比本身不足以说明四个地址为何均为 0；地址规划还涉及生命周期、别名关系和硬件约束。本记录只依据 After 输出和上游断言确认这一用例的结果，不把它推广到其他程序。

## 验收结果

PASS — 三个上游 RUN 命令连同其 FileCheck 断言全部通过；两个用例的 Before / After 已保存；`mlir/outputs/` 不再为空。

## 异常

无。唯一的坑是包了一层"上游 RUN 命令"的统计口径问题（CHECK 注释污染计数），已在脚本中修正并记录于上。
