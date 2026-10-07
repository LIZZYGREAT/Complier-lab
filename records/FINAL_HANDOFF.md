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
| 8 MLIR / Ascend VecAdd 资料分析 | PASS（资料分析） | `d25b04c` |
| 9 三路最终一致性验证 | PASS | `bfd4f20` |
| 10 最终 PDF 报告 | PASS（结构校验） | 本次提交 |

## 交付入口

- 正式报告：`report/report.pdf`
- 报告源稿：`report/report.md`
- 实验结果矩阵：`outputs/final-validation.md`
- 各阶段记录：`records/00_environment.md` 至 `records/10_report.md`
- 日志与脚本索引：`records/artifact_index.md`
- 最终验证日志：`logs/09_final_validation.log`
- 报告构建日志：`logs/10_report_build.log`

## 全局范围说明

`../SysY_Compiler_2025` 已有的编译器、运行库及其本地修改均未重建或更改；实验复用其中既有 RISC-V runtime。报告忠实标注了 Ascend 阶段仅做资料分析，以及 PDF 未能在本机预览渲染的限制。

所有阶段提交使用全局 Git 身份 `LIZZYGREAT <2660550447@qq.com>`。Stage 10 完成后，`lab/` 工作树应保持干净。
