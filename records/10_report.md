# 阶段 10：以 LaTeX 撰写并编译最终报告

## 目标

按课程科技论文结构整理实验结果，使用 LaTeX 源文件编译 PDF，并保存构建过程与日志。

## 报告内容

`report/report.tex` 包含题目、摘要、关键词、引言、实验对象与环境、预处理/编译/汇编/链接、LLVM IR/CFG 与手写 IR、RV64 ABI/手写汇编、六组运行结果、O0/O2 对照、MLIR/Ascend VecAdd 与 PlanMemory 上游 Test Case 分析、实验可复现性、结论和参考文献。流程图、CFG 图和栈帧图使用 TikZ 绘制为矢量图。

报告共有 13 个表、4 张图。所有引用的数字均与本仓库产物逐项核对：`example.ll` 的基本块编号、`readelf` 的节区/符号/重定位项、O0/O2 的 `alloca/load/store/phi` 计数、两种目标的汇编行数、手写汇编与 Clang 参考汇编的栈帧偏移等。

### 2026-10-08 修订

按用户要求对报告做了深度修订，补充了过程记录中的细节：

- 新增「编译器内部各阶段」小节，把词法/语法/语义/IR 生成/中端/后端与观察到的产物对应起来。
- 预处理、ELF 目标文件两处补充真实文本证据（`.i` 行标记、`readelf -h` 文件头、节区/符号/重定位表）。
- 第 4 节新增「自动生成 IR 与手写 IR 组织方式对比」表，并完整列出 `manual.ll`。
- 第 5 节新增 Clang 参考汇编片段、手写汇编片段与 32 字节栈帧图，并对比两者在取模实现和 `main` 帧大小上的差异。
- 第 7 节改写为四个小节，给出 `-O2` 的 RV64 汇编原文，说明奇偶判断如何退化为变长左移、整个 `if/else` 如何消失。
- 第 8 节新增「观察范围与证据边界」，逐条区分本机运行结果与资料分析。
- 新增第 9 节「实验可复现性」，列出各阶段脚本入口。
- 结论改为按引言四个问题逐条回答，并单列实验边界。
- 新建 `records/errors_and_fixes.md`，补充此前缺失的错误与修复留档。

AscendNPU 部分只报告官方文档和源码分析；本机没有构建/运行 `bishengir-opt`，没有 CANN 或 Ascend 设备，因此没有声称运行 Ascend Pass、编译或设备测试。PlanMemory 用例的 `RUN`/`CHECK` 只作为上游源码证据。

## 编译过程

报告由 Tectonic 0.16.9（x86-64 musl 静态构建）编译。没有安装系统软件、修改 shell 配置或提交编译器二进制。中文字体使用 Tectonic 资源包中的 Fandol 字体。

本次修订构建时 GitHub 直连不可用，脚本内置的临时下载失败。改用 GitHub 加速代理取得同一 release 包并通过内置 SHA-256 校验后，把二进制放在用户缓存目录：

```text
~/.cache/compiler-labs/bin/tectonic            # 二进制，SHA-256 与脚本内置值一致
~/.cache/compiler-labs/tectonic-cache/          # LaTeX 资源缓存，复用后构建明显变快
```

本次构建命令：

```bash
TECTONIC_BIN="$HOME/.cache/compiler-labs/bin/tectonic" \
TECTONIC_CACHE_DIR="$HOME/.cache/compiler-labs/tectonic-cache" \
bash scripts/10_build_report.sh 2>&1 | tee logs/10_report_build.log
```

该用法不需要修改脚本：`scripts/10_build_report.sh` 本来就支持 `TECTONIC_BIN` 与 `TECTONIC_CACHE_DIR`。若两者都不设置，脚本沿用原逻辑——存在系统 Tectonic 时直接使用，否则下载校验固定版本到临时目录并在退出时清理。

## 生成产物

- `report/report.tex`：唯一正式报告源文件。
- `report/report.pdf`：由上述 LaTeX 源文件编译。
- `scripts/10_build_report.sh`：构建脚本。
- `logs/10_report_build.log`：构建命令输出。
- `logs/10_latex_compile.log`：引擎日志。
- `records/10_report.md`、`records/FINAL_HANDOFF.md`、`records/artifact_index.md`。

## 验收结果

PASS — Tectonic 编译成功，最终 LaTeX 日志无编译错误、无排版溢出（Overfull），仅剩少量 CJK 行内松散的 Underfull 提示，不影响版面。PDF 版本 1.5，共 21 页，含 13 个表、4 张矢量图。

构建产物的 SHA-256 每次都会写入 `logs/10_report_build.log`。注意 Tectonic 会把生成时间写入 PDF，因此即使源文件不变，重新构建的哈希也会变化；稳定的验收指标是页数（21）与源文件 `report/report.tex`。正文中引用的每个数字都在 `records/` 与 `outputs/` 中可追溯。
