# 阶段 10：以 LaTeX 撰写并编译最终报告

## 目标

按课程科技论文结构整理实验结果，使用 LaTeX 源文件编译 PDF，并保存构建过程与日志。

## 报告内容

`report/report.tex` 包含题目、摘要、关键词、引言、实验对象与环境、预处理/编译/汇编/链接、LLVM IR/CFG 与手写 IR、RV64 ABI/手写汇编、六组运行结果、O0/O2 对照、MLIR/Ascend VecAdd 分析、结论和参考文献。流程图和 CFG 图使用 TikZ 绘制为矢量图。

AscendNPU 部分只报告官方文档和源码分析；本机没有 CANN、`bishengir-compile` 或 Ascend 设备，因此没有声称运行了 Ascend 编译或设备测试。

## 编译过程

报告由 Tectonic 0.16.9（x86-64 musl 静态构建）编译。Tectonic 和 LaTeX 资源缓存都放在 `/tmp`，没有安装系统软件、修改 shell 配置或提交编译器二进制。中文字体使用 Tectonic 资源包中的 Fandol 字体。

本次构建命令：

```bash
bash scripts/10_build_report.sh 2>&1 | tee logs/10_report_build.log
```

用户再次构建时可直接运行 `bash scripts/10_build_report.sh`：存在系统 Tectonic 时使用该程序；否则下载校验固定版本到临时目录。默认情况下临时下载、输出和缓存由脚本退出清理。

## 生成产物

- `report/report.tex`：唯一正式报告源文件。
- `report/report.pdf`：由上述 LaTeX 源文件编译。
- `scripts/10_build_report.sh`：构建脚本。
- `logs/10_report_build.log`：构建命令输出。
- `logs/10_latex_compile.log`：引擎日志。
- `records/10_report.md`、`records/FINAL_HANDOFF.md`、`records/artifact_index.md`。

## 验收结果

PASS — Tectonic 编译成功，最终 LaTeX 日志无排版溢出、缺字或编译错误。PDF 版本 1.5，共 6 页，SHA-256：`d01e6d52ebccd00e09d18982565ba810f45cedb429f96ba13662b5aa96dd6ef1`。

使用隔离在 `/tmp/compiler-labs-pdf-check` 的 pypdfium2 和 Pillow 逐页渲染检查了 PDF：六页内容完整，图表、表格和参考文献未见裁切、重叠或孤行空白页。用户要求保留该检查工具，因此保留渲染工具本身；检查用的临时页面图片已清理。
