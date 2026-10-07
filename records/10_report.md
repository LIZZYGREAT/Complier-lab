# 阶段 10：撰写并生成最终报告

## 目标

根据课程要求汇总真实实验过程与结果，生成科技论文结构的 PDF 报告，并留下可复现构建命令及阶段证据。

## 执行命令

```bash
bash scripts/10_build_report.sh 2>&1 | tee logs/10_report_build.log
```

## 报告内容

`report/report.md` 覆盖题目、摘要、关键词、引言、实验程序和工具环境、预处理/编译/汇编/链接、LLVM IR/CFG 与手写 IR、RV64 ABI/手写汇编、六组运行结果、O0/O2 差异、MLIR/Ascend VecAdd 资料分析、结论和参考文献。流程图和 CFG 图由生成器按前序实验产物绘制为矢量图形。

AscendNPU 部分只报告查阅的官方文档和源码分析；本机没有 CANN、`bishengir-compile` 或 Ascend 设备，因此没有声称运行了 Ascend 编译或设备测试。

## 生成产物

- `report/report.md`
- `report/report.pdf`（PDF 1.7，5 页）
- `scripts/10_build_report.sh`
- `scripts/10_render_report.py`
- `logs/10_report_build.log`
- `records/10_report.md`
- `records/FINAL_HANDOFF.md`
- 更新后的 `records/artifact_index.md`

PDF 由 Python 标准库实现的矢量 PDF writer 生成，使用标准 STSong-Light CID 字体引用及 ToUnicode 映射。环境中没有 PDF 预览/渲染工具，所以完成了 PDF 头尾、页树、xref 偏移、字体引用和 Unicode 映射的结构校验，但没有做逐页视觉检查。不同阅读器对标准 CJK CID 字体的替代方式可能不同。

## 验收结果

PASS — 报告结构覆盖课程要求；PDF 生成成功，识别为 5 页，结构校验通过。SHA-256：`90b05102ef052be0ba753fc7e7f95350adb0b7d34ef8a48e69c4d1fa0a387982`。

## 限制

- 本机没有可用于视觉预览 PDF 的工具，故未检查实际页面渲染效果。
- MLIR/Ascend 仍属于官方资料分析，未做本机 CANN 编译或 NPU 运行。
