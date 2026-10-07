# 官方来源索引

访问日期：2026-10-07。AscendNPU-IR 源码链接指向公开 GitHub `master` 镜像；本轮未克隆源码，因此没有本地 commit id。

| 来源 | 官方页面/文件 | 用途 |
| --- | --- | --- |
| LLVM MLIR Language Reference | [mlir.llvm.org/docs/LangRef](https://mlir.llvm.org/docs/LangRef/) | Operation、Value、Block、Region 和 dialect 的 IR 基础 |
| LLVM MLIR Rationale | [llvm-project/mlir/docs/Rationale](https://github.com/llvm/llvm-project/blob/main/mlir/docs/Rationale/Rationale.md) | 多层表示如何从高层数据流表达逐步下降到目标代码 |
| LLVM Targeting LLVM IR from MLIR | [mlir.llvm.org/docs/TargetLLVMIR](https://mlir.llvm.org/docs/TargetLLVMIR/) | MLIR 向 LLVM IR lowering 的后续机制；不是 Ascend VecAdd 实测输出 |
| AscendNPU-IR Framework Integration | [framework_interface.md](https://github.com/Ascend/AscendNPU-IR/blob/master/docs/source/en/developer_guide/conversion/framework_interface.md) | Torch、Linalg/HFusion、HIVM 的多层接入；GM/UB/load/vadd/store 示例 |
| AscendNPU-IR HIVM VecAdd | [add.mlir](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/add.mlir) | 16×`i16` 官方输入；保存到 `sources/vecadd_hivm.mlir` |
| AscendNPU-IR VecAdd README | [VecAdd/README.md](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/README.md) | CANN、编译选项、kernel `.o`、host wrapper 要求；解释未执行范围 |
| AscendNPU-IR Build and Installation | [installing_guide.md](https://github.com/Ascend/AscendNPU-IR/blob/master/docs/source/en/introduction/quick_start/installing_guide.md) | 官方最低构建要求：CMake 3.28、Ninja 1.12；Stage 0 停止依据 |
| AscendNPU-IR Plan Memory | [PlanMemory 文档](https://ascendnpu-ir.gitcode.com/en/developer_guide/features/PlanMemory/PlanMemory.html) | 生命周期、内存复用、地址分配和 alloc 改写机制 |
| AscendNPU-IR HIVM Pass 文档 | [HIVM Passes](https://ascendnpu-ir.gitcode.com/en/developer_guide/passes/hivm_passes.html) | `-hivm-plan-memory` Pass 名称和参数 |
| AscendNPU-IR PlanMemory Test Case | [plan-memory.mlir](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Dialect/HIVM/plan-memory.mlir) | `test_mem_allocate_basic`、`RUN` 命令和 pointer_cast `CHECK`；只做源码分析 |

本轮不把网页摘录或 `CHECK` 断言称作本机 Pass 输出。完整环境命令、构建决策和 Pass 执行状态分别见 [`logs/environment.log`](../logs/environment.log)、[`logs/build.log`](../logs/build.log)、[`logs/pass_runs.log`](../logs/pass_runs.log)。
