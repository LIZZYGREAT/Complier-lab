# 实验资产索引

| 文件 | 来源 | 用途 | 报告使用 |
| --- | --- | --- | :---: |
| `source/example.sy` | 人工固定 | 贯穿整个实验的 SysY 源程序 | 是 |
| `source/example_clang.c` | SysY 程序的 Clang 包装版本 | 生成成熟编译器各阶段产物 | 是 |
| `source/host_runtime.c` | 本实验宿主机适配 | 为本机程序提供 `getint`/`putint` | 是 |
| `source/test_reference.sh` | 本实验 | 固定六组输出比较 | 是 |
| `generated/example.i` | Clang `-E` | 预处理结果 | 是 |
| `generated/example.ll` | Clang `-O0 -emit-llvm` | 自动 LLVM IR 参考 | 是 |
| `generated/example_x86.s` | Clang `-O0 -S` | 自动宿主机汇编参考 | 是 |
| `generated/example.o`, `generated/host_runtime.o` | Clang `-c` | ELF relocatable object 分析（由脚本重建） | 是 |
| `generated/reference` | Clang + host runtime | Ground Truth 可执行文件 | 是 |
| `generated/reference_linked` | 显式链接两个 object | 链接步骤验证 | 是 |
| `generated/example_riscv.s` | Clang RISC-V target | 自动 RISC-V 汇编参考 | 是 |
| `llvm/manual.ll` | 手写 | LLVM IR 等价实现 | 是 |
| `riscv/manual.s` | 手写 | RV64 汇编等价实现 | 是 |
| `generated/manual_riscv` | RISC-V 工具链 + 课程 SysY runtime | QEMU 运行文件 | 是 |
| `outputs/reference-test.txt` | Stage 1 测试 | Ground Truth 结果 | 是 |
| `outputs/manual-llvm-test.txt` | Stage 4 测试 | 手写 LLVM 结果 | 是 |
| `outputs/manual-riscv-test.txt` | Stage 6 QEMU 测试 | 手写 RISC-V 结果 | 是 |
| `outputs/final-validation.md` | Stage 9 脚本 | 三路最终结果总表 | 是 |
| `outputs/llvm-analysis.md` | IR 分析 | CFG、源代码和 IR 指令映射 | 是 |
| `exploration/O0.ll`, `exploration/O2.ll` | Clang | 优化级别对照 | 是 |
| `exploration/O0.s`, `exploration/O2.s` | Clang | x86-64 汇编对照 | 是 |
| `exploration/O0_riscv.s`, `exploration/O2_riscv.s` | Clang | RV64 汇编对照 | 是 |
| `outputs/optimization-*.diff` | Stage 7 脚本 | 真实 O0/O2 unified diff | 是 |
| `outputs/optimization-analysis.md` | 实验分析 | 实际优化变化说明 | 是 |
| `mlir/README.md` | 本轮进阶任务记录 | MLIR / AscendNPU IR 入口、范围、结果状态 | 是 |
| `mlir/sources/vecadd_hivm.mlir` | Ascend 官方 HIVM VecAdd | 16×`i16` 的 GM/UB/load/vadd/store 源样例 | 是 |
| `mlir/sources/selected_tests/plan_memory_input.mlir` | Ascend 官方 `plan-memory.mlir` 摘录 | 真实上游 `RUN` 和 `CHECK`，未本地执行 | 是 |
| `mlir/analysis/lowering_chain.md` | LLVM 与 Ascend 官方资料分析 | 多层抽象与 HIVM 硬件映射 | 是 |
| `mlir/analysis/plan_memory_analysis.md` | Ascend 官方 PlanMemory 文档和 Test Case | 分析 alloc 到 pointer_cast 的预期变化 | 是 |
| `mlir/references/source_index.md` | LLVM 与 Ascend 官方资料 | 官方文档和源码索引 | 是 |
| `mlir/logs/environment.log`, `build.log`, `pass_runs.log` | 本轮只读环境检查与执行留痕 | 构建决策及 analysis-only 证据边界 | 按需引用 |
| `report/report.tex` | Stage 10 | LaTeX 正式报告源文件，含 TikZ 图表 | 是 |
| `report/report.pdf` | Stage 10 | Tectonic 从 LaTeX 编译的最终 PDF | 是 |
| `scripts/10_build_report.sh` | Stage 10 | 使用隔离的临时引擎/缓存构建 PDF | 是 |
| `logs/10_latex_compile.log` | Stage 10 | Tectonic/LaTeX 编译日志 | 按需引用 |
| `records/00`–`10` | 各阶段记录 | 过程、结果、验收与限制 | 是 |
| `records/errors_and_fixes.md` | 本实验 | 错误、原因、修改与复验留档 | 按需引用 |
| `scripts/00`–`10` | 本实验脚本 | 重现工具检查、构建和验证 | 是 |
| `logs/00`–`10` | 阶段实际 stdout/stderr | 过程证据 | 按需引用 |
| `records/FINAL_HANDOFF.md` | Stage 10 | 完成状态、提交和限制汇总 | 是 |
| `docs/` | 课程下发的作业要求与执行方案 | 任务依据与验收口径 | 否 |
