# PlanMemory：上游 Test Case 与本机实测

## 用例和命令

本分析对应 AscendNPU-IR 上游 `bishengir/test/Dialect/HIVM/plan-memory.mlir` 中的 `test_mem_allocate_basic`。摘录保存在 [`sources/selected_tests/plan_memory_input.mlir`](../sources/selected_tests/plan_memory_input.mlir)，保留输入、`RUN` 和 `CHECK`。

上游文件的两条命令分别验证默认策略和 `largest-first` 策略；两条都先用 `-hacc-append-device-spec=target=Ascend910B1` 把目标规格写入模块，再执行 `-hivm-plan-memory`。阶段 13 用本地构建的 `bishengir-opt` 原样执行这两条命令，并把输出交给上游 FileCheck 断言；两条均通过。单用例 Before/After 文件对应默认策略。

## 实测变化

输入包含四个 UB `memref.alloc()`，每个类型为 `16×16×16×f16`，名义容量为 8192 字节。实测结果如下：

| 项目 | Before | After |
| --- | --- | --- |
| UB `memref.alloc()` | 4 | 0 |
| `hivm.hir.pointer_cast` | 0 | 4 |
| `load`、`vadd`、`store` 合计 | 5 | 5 |
| pointer offset | 未显式给出 | 四处均为 0 |

四个 `pointer_cast` 都引用 `%c0_i64 = arith.constant 0 : i64`。原有的 load、三条 vadd 和 store 保持不变。实测 After 还包含 `dlti.target_system_spec` 和 `hacc.target`；这些设备属性由前置的 `-hacc-append-device-spec` 加入，而非 PlanMemory 单独产生。

四个 buffer 的名义容量合计 32 KiB，小于目标规格中的 UB 容量。不过仅凭容量大小不能解释它们为何都映射到偏移 0；地址规划还涉及生命周期、别名和硬件约束。本记录只确认上游断言与本机输出中的结果，不把这一例推广到其他 IR。

## 作用与证据范围

`memref.alloc` 表示需要一个 UB buffer，但没有给出具体地址。该用例的实测表明，PlanMemory 将这些分配转换为带偏移的 `hivm.hir.pointer_cast`。因此可以直接观察到 IR 中内存表示的变化；此处的输出并不单独证明所有程序中的完整分配算法或最终设备执行结果。

- 上游测试与 Pass 文档：见 [`references/source_index.md`](../references/source_index.md)。
- 本机 Before/After：`../outputs/plan_memory_before.mlir`、`../outputs/plan_memory_after.mlir`。
- 完整命令与 FileCheck 结果：`../logs/pass_runs.log`、`../../records/13_ascend_pass_runs.md`。
- 没有执行 CANN 编译、驱动配置、kernel `.o` 生成或 NPU 运行。
