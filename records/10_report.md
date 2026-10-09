# 阶段 10：报告全篇修订与 PDF 构建

## 修订目标

2026-10-09 在用户调整前半部分用语后，继续统一后半部分的表达方式：采用简洁的陈述句说明操作和观察结果，不以“我”起句，并保持技术术语和必要边界。正文围绕本次实际产物说明处理过程；长代码清单改为关键片段，完整实现仍保留在 `llvm/`、`riscv/` 等实验目录。调整表格、代码块和段落安排，方便读者区分观察结果、解释和实验边界。

报告内容包括 SysY 示例、Clang 各阶段及 ELF 产物、手写 LLVM IR 与 RV64 汇编、六组运行核对、O0/O2 观察，以及 AscendNPU IR 的 PlanMemory 和 InjectSync 实测。Ascend 部分以 Stage 13 的真实输出为准，并明确说明 Arith/Tensor 与 HFusion 路线属于资料整理，未安装 CANN 或运行真实 NPU。

## 编译过程

使用 Tectonic 0.16.9 编译 `report/report.tex`。本次复用了用户级 Tectonic 二进制，将已有的宏包缓存复制到 `/tmp/compiler-labs-tectonic-cache-review` 后完成构建，没有改动系统工具。执行命令：

```bash
TECTONIC_BIN=/home/lenovo/.cache/compiler-labs/bin/tectonic \
TECTONIC_CACHE_DIR=/tmp/compiler-labs-tectonic-cache-review \
bash scripts/10_build_report.sh 2>&1 | tee logs/10_report_build.log
```

构建脚本将 PDF 写回 `report/report.pdf`，详细引擎输出记录在 `logs/10_latex_compile.log`。Tectonic 报告生成 15 页。此次编译没有 Overfull、Underfull、未定义引用或编译错误。

## 生成产物与验收

- `report/report.tex`：修订后的正式报告源文件。
- `report/report.pdf`：Tectonic 生成的 15 页 PDF。
- `logs/10_report_build.log`：构建命令和产物摘要。
- `logs/10_latex_compile.log`：LaTeX 引擎日志。

报告含 10 个表格和 4 张 TikZ 矢量图。最终 PDF SHA-256：

```text
434721c22b0ef7f6b7ed2a035adf84207908d81ca34ffcdf205f9965d1e36e6a
```

**验收：PASS。** PDF 已成功重编译；编译无错误、无排版警告或未定义引用。数字和结论只在本实验实际覆盖的范围内使用，未据此声称性能提升或真实 NPU 执行结果。
