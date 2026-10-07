# 最终交付记录

## 阶段状态

| 阶段 | 状态 | 提交 |
| --- | --- | --- |
| 0 环境与既有成果检查 | PASS | `ec2695c` |
| 1 固定源程序与 Ground Truth | PASS | `93f75d0` |
| 2 Clang 预处理、编译、汇编和链接 | PASS | `3a7e1dd` |
| 3 LLVM IR / CFG 分析 | PASS | `c842c8e` |
| 4 手写 LLVM IR | PASS | `dafed10` |
| 5 RISC-V 参考汇编与 ABI 分析 | PASS | `65bd5ae` |
| 6 手写 RISC-V 并在 QEMU 运行 | PASS | `1e614c5` |
| 7 O0/O2 优化对比 | PASS | `cafe4d4` |
| 8 MLIR / Ascend VecAdd 与 PlanMemory 源码分析 | PASS（ANALYSIS-ONLY；工具条件不足时按 Stage 1B） | `d25b04c`（基础记录） + `2c42438`（本轮分析） |
| 9 三路最终一致性验证 | PASS | `bfd4f20` |
| 10 最终 PDF 报告 | PASS（更新后重编译，7 页） | `a3e2f79` |

## 交付入口

- 正式报告：`report/report.pdf`
- LaTeX 源稿：`report/report.tex`
- 实验结果矩阵：`outputs/final-validation.md`
- 各阶段记录：`records/00_environment.md` 至 `records/10_report.md`
- 日志与脚本索引：`records/artifact_index.md`
- 最终验证日志：`logs/09_final_validation.log`
- 报告构建日志：`logs/10_report_build.log`
- LaTeX 引擎日志：`logs/10_latex_compile.log`

## 全局范围说明

`../SysY_Compiler_2025` 已有的编译器、运行库及其本地修改均未重建或更改；实验复用其中既有 RISC-V runtime。报告忠实标注了 Ascend 阶段只做官方资料和上游源码 Test Case 分析；没有运行 `bishengir-opt`、安装 CANN 或上板。本轮在 `lab1` 分两笔提交 Stage 8 分析和 Stage 10 报告，随后单独更新本交接记录；提交仅保存在本地，没有推送远端。此前 LaTeX 引擎和宏包缓存仅用于临时构建，已清理；按用户要求，PDF 页面检查工具保留在 `/tmp/compiler-labs-pdf-check`。
