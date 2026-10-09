# 官方来源与本地版本索引

官方网页访问日期：2026-10-09。AscendNPU-IR 的上游源码基于公开仓库检出；本机构建与实跑使用的提交为 `2ac1b376da1d`，其 LLVM 子项目固定在 `06913395ef8a`。相关构建过程见 `records/12_ascend_build.md`。

| 来源 | 官方页面/文件 | 用途 |
| --- | --- | --- |
| LLVM MLIR Language Reference | [mlir.llvm.org/docs/LangRef](https://mlir.llvm.org/docs/LangRef/) | Operation、Value、Block、Region 和 Dialect 的 IR 基础 |
| LLVM MLIR Rationale | [llvm-project/mlir/docs/Rationale](https://github.com/llvm/llvm-project/blob/main/mlir/docs/Rationale/Rationale.md) | 多层表示与逐步 lowering 的设计依据 |
| LLVM Targeting LLVM IR from MLIR | [mlir.llvm.org/docs/TargetLLVMIR](https://mlir.llvm.org/docs/TargetLLVMIR/) | MLIR 转换到 LLVM IR 的机制；不是本次 VecAdd 的实测输出 |
| AscendNPU-IR Framework Integration | [framework_interface.md](https://github.com/Ascend/AscendNPU-IR/blob/master/docs/source/en/developer_guide/conversion/framework_interface.md) | Torch、Linalg/HFusion、HIVM 的多层接入与示例 |
| AscendNPU-IR HIVM VecAdd | [add.mlir](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/add.mlir) | 16×`i16` 的 HIVM 输入；副本在 `sources/vecadd_hivm.mlir` |
| AscendNPU-IR VecAdd README | [VecAdd/README.md](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/README.md) | CANN、kernel `.o` 与 host wrapper 的构建要求 |
| AscendNPU-IR Build and Installation | [installing_guide.md](https://github.com/Ascend/AscendNPU-IR/blob/master/docs/source/en/introduction/quick_start/installing_guide.md) | 构建环境要求；阶段 11 的环境判断依据 |
| AscendNPU-IR Plan Memory | [PlanMemory 文档](https://ascendnpu-ir.gitcode.com/en/developer_guide/features/PlanMemory/PlanMemory.html) | 生命周期、地址分配和 alloc 改写机制 |
| AscendNPU-IR HIVM Pass 文档 | [HIVM Passes](https://ascendnpu-ir.gitcode.com/en/developer_guide/passes/hivm_passes.html) | `-hivm-plan-memory` 等 Pass 名称与参数 |
| AscendNPU-IR PlanMemory Test Case | [plan-memory.mlir](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Dialect/HIVM/plan-memory.mlir) | 实测用例、两条 `RUN` 命令及相关 `CHECK` 断言 |
| AscendNPU-IR InjectSync Test Case | [inject-sync.mlir](https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Dialect/HIVM/inject-sync.mlir) | 实测同步插入用例及上游断言 |

Ascend 源码测试链接指向公开上游页面；本机实跑用的是上文记录的固定检出版本。运行命令、FileCheck 结果和输出文件见 [`../logs/pass_runs.log`](../logs/pass_runs.log)、[`../../records/13_ascend_pass_runs.md`](../../records/13_ascend_pass_runs.md) 与 `../outputs/`。
