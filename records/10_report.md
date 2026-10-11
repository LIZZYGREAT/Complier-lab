# 阶段 10：报告全篇修订与 PDF 构建

## 修订目标

2026-10-09 在用户调整前半部分用语后，继续统一后半部分的表达方式：采用简洁的陈述句说明操作和观察结果，不以“我”起句，并保持技术术语和必要边界。正文围绕本次实际产物说明处理过程；长代码清单改为关键片段，完整实现仍保留在 `llvm/`、`riscv/` 等实验目录。调整表格、代码块和段落安排，方便读者区分观察结果、解释和实验边界。

随后按用户要求将甘文杰、向宇航列为共同作者，补充双方的学号与分工说明。

报告内容包括 SysY 示例、Clang 各阶段及 ELF 产物、手写 LLVM IR 与 RV64 汇编、六组运行核对、O0/O2 观察，以及 AscendNPU IR 的 PlanMemory 和 InjectSync 实测。Ascend 部分以 Stage 13 的真实输出为准，并明确说明 Arith/Tensor 与 HFusion 路线属于资料整理，未安装 CANN 或运行真实 NPU。

## 编译过程

使用 Tectonic 0.16.9 编译 `report/report.tex`。本次复用了用户级 Tectonic 二进制，将已有的宏包缓存复制到 `/tmp/compiler-labs-tectonic-cache-review` 后完成构建，没有改动系统工具。执行命令：

```bash
TECTONIC_BIN=/home/lenovo/.cache/compiler-labs/bin/tectonic \
TECTONIC_CACHE_DIR=/tmp/compiler-labs-tectonic-cache-review \
bash scripts/10_build_report.sh 2>&1 | tee logs/10_report_build.log
```

构建脚本将 PDF 写回 `report/report.pdf`，详细引擎输出记录在 `logs/10_latex_compile.log`。Tectonic 报告生成 16 页。此次编译没有 Overfull、Underfull、未定义引用或编译错误。

## 生成产物与验收

- `report/report.tex`：修订后的正式报告源文件。
- `report/report.pdf`：Tectonic 生成的 16 页 PDF。
- `logs/10_report_build.log`：构建命令和产物摘要。
- `logs/10_latex_compile.log`：LaTeX 引擎日志。

报告含 10 个表格和 4 张 TikZ 矢量图。最终 PDF SHA-256：

```text
fdcfa9d104259f579def1fe97949df613781fd789898a5f4f4ad4bc33dc2efd4
```

**验收：PASS。** PDF 已成功重编译；编译无错误、无排版警告或未定义引用。数字和结论只在本实验实际覆盖的范围内使用，未据此声称性能提升或真实 NPU 执行结果。


## 2026-10-11：结构重组与独立报告提交

按课件和确认计划重组正文，完整保留既有内容；将仓库文件检索指引替换为附录交叉引用，附录 A--E 嵌入完整手写实现、基础生成结果、必要命令与运行记录、优化摘录、Ascend 构建补丁和两个 Pass 完整 Before/After。原实验脚本总表保留于附录 A。本次仅整理报告，未重新执行历史编译器实验。

使用 WSL 中的 XeLaTeX/latexmk 编译并在临时目录检查，成功后更新正式 PDF。报告为 **45 页、11 表、4 图、50 个代码块**；原有 10 表、4 图、13 个正文代码块及 11 条参考文献完整保留。全 45 页渲染检查通过，无编译错误、未定义引用、缺字或 Overfull/Underfull。Fandol 字体有三条 Script CJK 元数据提示，不影响中文显示。

SHA-256：2f4d654cce4224122c6e47ace435963f8b5466e0ca89bdbe6bfec1ada9b6ee8f。

完整新旧结构对照及验收记录：[修订记录](14_report_restructure.md)。
