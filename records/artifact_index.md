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
| `mlir/sources/selected_tests/plan_memory_input.mlir` | Ascend 官方 `plan-memory.mlir` 摘录 | 上游 `RUN`/`CHECK` 原样摘录；两种策略均在本地通过 | 是 |
| `mlir/sources/selected_tests/sync_input.mlir` | Ascend 官方 `inject-sync.mlir` 摘录 | 上游 `RUN`/`CHECK` 原样摘录；本地运行通过 | 是 |
| `mlir/outputs/plan_memory_before.mlir`、`plan_memory_after.mlir` | 本机执行 `bishengir-opt` | PlanMemory 真实 Before/After | 是 |
| `mlir/outputs/sync_before.mlir`、`sync_after.mlir` | 本机执行 `bishengir-opt` | InjectSync 真实 Before/After | 是 |
| `mlir/logs/pass_runs.log` | 本机执行 | 上游 RUN 命令与 FileCheck 断言结果 | 是 |
| `mlir/analysis/lowering_chain.md` | LLVM 与 Ascend 官方资料分析 | 多层抽象与 HIVM 硬件映射 | 是 |
| `mlir/analysis/plan_memory_analysis.md` | Ascend 官方文档、Test Case 与本机输出 | PlanMemory 的 alloc 到 pointer_cast 实测变化 | 是 |
| `mlir/references/source_index.md` | LLVM 与 Ascend 官方资料及固定源码提交 | 官方来源和本机验证版本索引 | 是 |
| `mlir/logs/environment.log`, `build.log`, `pass_runs.log` | 环境检查、构建决策与本机执行 | 记录初次分析决策及后续构建、Pass 运行 | 按需引用 |
| `report/report.tex` | Stage 10（按用户修改的文风统一后文） | LaTeX 正式报告源文件，含 TikZ 图表 | 是 |
| `report/report.pdf` | Stage 10（新增共同作者与分工后重编译） | Tectonic 编译的 16 页最终报告 | 是 |
| `scripts/10_build_report.sh` | Stage 10 | 使用隔离的临时引擎/缓存构建 PDF | 是 |
| `logs/10_latex_compile.log` | Stage 10 | Tectonic/LaTeX 编译日志 | 按需引用 |
| `scripts/patches/ascendnpu-ir-hivmc-link-order.patch` | 本实验 | 上游静态库循环的链接补丁 | 是 |
| `scripts/12_ascend_build.sh` | Stage 12 | 编译 `bishengir-opt` 单个 target | 是 |
| `scripts/13_ascend_pass_runs.sh` | Stage 13 | 逐字跑上游 RUN 并 FileCheck；保存 Before/After | 是 |
| `records/12_ascend_build.md` | Stage 12 | 构建过程、三处失败与修复、内存实测 | 是 |
| `records/13_ascend_pass_runs.md` | Stage 13 | Pass 实测结果与两组 Before/After | 是 |
| `records/11_ascend_build_precheck.md` | Stage 11 | Ascend 构建环境预检：条件、坑点、配置结果与风险 | 是 |
| `scripts/11_ascend_configure.sh` | Stage 11 | AscendNPU-IR 的 CMake 配置验证（不编译） | 是 |
| `records/00`–`10` | 各阶段记录 | 过程、结果、验收与限制 | 是 |
| `records/errors_and_fixes.md` | 本实验 | 错误、原因、修改与复验留档 | 按需引用 |
| `scripts/00`–`10` | 本实验脚本 | 重现工具检查、构建和验证 | 是 |
| `logs/00`–`10` | 阶段实际 stdout/stderr | 过程证据 | 按需引用 |
| `logs/11`–`13` | Ascend 配置、构建与 Pass 运行 stdout/stderr | 后续阶段的完整执行记录 | 按需引用 |
| `records/FINAL_HANDOFF.md` | 最终交付记录 | 完成状态、提交和限制汇总 | 是 |
| `docs/` | 课程下发的作业要求与执行方案 | 任务依据与验收口径 | 否 |

## 仓库外资源（不进版本管理）

Stage 11 的构建环境位于 `lab/` 之外，因此不在 Git 中，仅在记录中登记路径以便复现：

| 路径 | 内容 | 说明 |
| --- | --- | --- |
| `../.venv-ascendnpu/` | CMake 4.4.4、Ninja 1.13.2 | pip 安装的用户级隔离环境，未改动系统 |
| `../third_party/ascendnpu-ir/` | AscendNPU-IR 源码（commit `2ac1b376da1d`） | 来自 gitcode.com，含上游 Test Case |
| `../third_party/ascendnpu-ir/third-party/llvm-project/` | LLVM 19.1.7（`06913395…`，2.8 GB） | 按上游固定 SHA 检出 |
| `../third_party/ascendnpu-ir/build/` | 完整构建树 | 含 `bin/bishengir-opt`（180 MB）与 `bin/FileCheck` |
