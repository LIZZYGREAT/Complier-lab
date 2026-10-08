# MLIR / AscendNPU IR 探索

本目录记录 Assignment 1 进阶部分的探索。项目已有实验根目录是 `lab/`，因此本任务按仓库现有布局放在 `lab/mlir/`。

## 完成内容

- 保存 Ascend 官方 16×`i16` HIVM VecAdd 输入，并按 Arith/Tensor → HFusion → HIVM → 后续 HACC/LLVM 表示说明抽象层次变化。
- 解释 GM/UB、load、vadd、store 把内存层次和数据搬运策略显式带入 IR 的作用。
- **构建了上游 `bishengir-opt` 并实跑上游 Pass**，用上游自带的 `RUN` 命令与其 `CHECK` 断言逐条验证。
- 保存 PlanMemory 与 InjectSync 两个具体用例的真实 Before / After。

## 实测结果

工具为本机从源码构建：

```text
bishengir-opt 2.0.0 (gitcode.com/Ascend/ascendnpu-ir 2ac1b376da1d, 2026-10-09)
llvm 19.1.7 06913395ef8a   Release build
```

上游 RUN 命令逐字执行，并交给上游自己的 FileCheck 断言：

| 用例 | 结果 |
| --- | --- |
| `plan-memory.mlir` 默认策略 | PASS |
| `plan-memory.mlir` `largest-first`（`CHECK-REORDER`） | PASS |
| `inject-sync.mlir` | PASS |

两个单用例的实测变化：

- **PlanMemory**（`test_mem_allocate_basic`）：`memref.alloc()` 4 → 0，产出 4 个 `hivm.hir.pointer_cast`；同时注入 `dlti.target_system_spec`，其中含 UB_SIZE 1572864、L1_SIZE 4194304、L0C_SIZE 1048576、UB_ALIGN_SIZE 256、AI_CORE_COUNT 24、VECTOR_CORE_COUNT 48 等具体芯片参数。计算指令未变。
- **InjectSync**（`test_mem_injcet_sync_basic`）：源程序只有 load/vadd/store，无同步；Pass 注入 2 条 `set_flag`、2 条 `wait_flag` 和 1 条 `pipe_barrier`，形态为 `MTE2→V` 与 `V→MTE3` 两组同步。

## 执行边界

系统既有的 CMake 缺失、Ninja 为 1.10.1（官方要求至少 1.12），因此没有用系统工具链。CMake 4.4.4 与 Ninja 1.13.2 由 pip 安装在仓库外的用户级 venv `.venv-ascendnpu`，源码与其 LLVM 19.1.7 子模块检出于 `../third_party/ascendnpu-ir`。构建、配置与 Pass 运行的完整过程见 `../records/11_ascend_build_precheck.md`、`../records/12_ascend_build.md`、`../records/13_ascend_pass_runs.md`。

对上游源码打了一处必要的链接补丁（`../scripts/patches/ascendnpu-ir-hivmc-link-order.patch`），原因是上游 `BiShengIRHIVMCLib` 与 A3/A5 之间存在静态库循环。该补丁只影响 `bishengir-opt` 的链接参数，不改变 Pass 行为。

**没有做**：安装完整 CANN、配置 Ascend 驱动、生成或运行 kernel `.o`、在真实 NPU 上执行。已确认这些不是本任务（观察 IR 层 lowering）的必需项——CANN 只在"编出 kernel 并上板执行"时才需要。

## 文件入口

- [VecAdd 输入](sources/vecadd_hivm.mlir)
- [PlanMemory 官方测试摘录](sources/selected_tests/plan_memory_input.mlir)、[InjectSync 摘录](sources/selected_tests/sync_input.mlir)
- [PlanMemory Before](outputs/plan_memory_before.mlir) / [After](outputs/plan_memory_after.mlir)
- [InjectSync Before](outputs/sync_before.mlir) / [After](outputs/sync_after.mlir)
- [Lowering 主线](analysis/lowering_chain.md)、[PlanMemory 分析](analysis/plan_memory_analysis.md)
- [官方来源索引](references/source_index.md)
- `logs/`：环境检查、构建决策与 Pass 运行留痕

## 状态

| 项目 | 状态 |
| --- | --- |
| VecAdd 主线 | PASS |
| 官方资料和 Test Case 核对 | PASS |
| `bishengir-opt` 构建 | PASS |
| PlanMemory 实验 | PASS（真实运行，含 Before/After） |
| Sync 实验 | PASS（真实运行，含 Before/After） |
| CANN / NPU 上板 | NOT ATTEMPTED（非本任务所需） |
