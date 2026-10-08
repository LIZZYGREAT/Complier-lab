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
| 8 MLIR / Ascend VecAdd 与 PlanMemory | PASS（初期按 Stage 1B 做源码分析；后由 Stage 12/13 升级为实测） | `d25b04c` + `2c42438` |
| 9 三路最终一致性验证 | PASS | `bfd4f20` |
| 10 最终 PDF 报告 | PASS（深度修订并纳入 Ascend 实测后重编译，21 页） | `a3e2f79`、本轮修订 |
| 11 Ascend 构建环境预检 | PASS | 本轮 |
| 12 编译 bishengir-opt | PASS（三轮失败后成功） | 本轮 |
| 13 实跑上游 Pass | PASS（3 个上游 RUN 全部通过 FileCheck） | 本轮 |

## 交付入口

- 正式报告：`report/report.pdf`（21 页；哈希随构建时间变化，见 `logs/10_report_build.log`）
- LaTeX 源稿：`report/report.tex`（报告唯一正式源文件）
- 实验结果矩阵：`outputs/final-validation.md`
- 各阶段记录：`records/00_environment.md` 至 `records/13_ascend_pass_runs.md`
- 错误与修复留档：`records/errors_and_fixes.md`
- 日志与脚本索引：`records/artifact_index.md`
- 最终验证日志：`logs/09_final_validation.log`
- 报告构建日志：`logs/10_report_build.log`
- LaTeX 引擎日志：`logs/10_latex_compile.log`

## 本轮修订（2026-10-08）

报告从 7 页扩写到 18 页（随后因纳入 Ascend 实测再增至 21 页），主要补充真实过程证据而非教材内容：编译器内部阶段与产物对应表、`.i` 行标记与 `readelf` 文件头/节区/符号/重定位证据、手写 `manual.ll` 与 `manual.s` 完整清单、自动生成与手写 IR 的组织方式对比、`calc` 的 32 字节栈帧图、Clang 参考汇编与手写汇编在取模实现与 `main` 帧大小上的差异、`-O2` 下奇偶判断退化为变长左移的分析、MLIR 部分的证据边界声明，以及各阶段复现入口。报告内的每个数字都与仓库产物核对过。

同时新建了此前缺失的 `records/errors_and_fixes.md`，并把课程文档目录 `docs/` 纳入版本管理。`report/figures/` 保持为空目录：所有图均为内联 TikZ 矢量图，不依赖位图素材。

## Stage 11：Ascend 构建环境预检

第 8 节此前因本机缺少 CMake、Ninja 版本偏低而退化为资料分析。经确认这两个缺口都能用 pip 在用户级 venv 内补齐、无需改动系统，于是恢复了源码构建路线并做了低成本预检（`records/11_ascend_build_precheck.md`）。

预检结论：CANN、驱动与 NPU 硬件都不是必需项；源码全在 gitcode，不受 github 不稳定影响；CMake 配置已通过，`bishengir-opt` target 确认生成；编译规模量化为 3123 个编译单元，预计 1.5–3 小时。**唯一未验证的风险是 10 GiB 内存能否撑住编译与静态链接。**

该预检当时**没有产出 Ascend 运行证据**；`mlir/outputs/` 为空、报告第 8 节保持 ANALYSIS-ONLY。后续 Stage 12/13 已补齐这一缺口（见下）。

另：核对本地真实检出时发现报告引用的 PlanMemory `RUN` 命令丢失了必需参数 `-hacc-append-device-spec=target=Ascend910B1`（缺少时该命令无法执行），已在提交 `769473f` 中连同另外三处一并修正。

## 全局范围说明

`../SysY_Compiler_2025` 已有的编译器、运行库及其本地修改均未重建或更改；实验复用其中既有 RISC-V runtime。报告初期如实标注 Ascend 阶段只做官方资料与上游源码分析；后由 Stage 12/13 补上真实运行证据，第 8 节已改为以实测为准。始终没有安装 CANN、配置驱动或上板。本轮在 `lab1` 分两笔提交 Stage 8 分析和 Stage 10 报告，随后单独更新本交接记录；提交仅保存在本地，没有推送远端。此前 LaTeX 引擎和宏包缓存仅用于临时构建，已清理；按用户要求，PDF 页面检查工具保留在 `/tmp/compiler-labs-pdf-check`。

## Stage 12–13：真正跑通 Ascend

第 8 节此后完成了从"资料分析"到"实测"的升级。

**Stage 12**（`records/12_ascend_build.md`）从源码构建出 `bishengir-opt`。过程并不顺利，四次尝试中失败三次，且三次都不是环境问题，而是上游构建配置缺陷在本机组合下的暴露：生成头文件与编译步骤之间缺依赖边；`BISHENGIR_BUILD_HIVMC=OFF` 会让编译库的 hivmc 符号无处解析；`BiShengIRHIVMCLib` 与 A3/A5 之间存在真实的静态库循环。最后一处用 CMake 的 `LINK_GROUP:RESCAN` 解决，补丁存于 `scripts/patches/`。内存方面，阶段 11 列为"唯一未验证风险"的 10 GiB 约束实测不成立：峰值约 4.8 GiB，3 GiB swap 全程未触发。

**Stage 13**（`records/13_ascend_pass_runs.md`）逐字执行上游测试文件自带的 `RUN` 命令，并用**上游自己的 `CHECK` 断言**做 FileCheck——即用上游的验收标准检验本机构建。三个用例（PlanMemory 默认策略、PlanMemory `largest-first`、InjectSync）全部 PASS。同时保存了两组真实 Before/After：

- PlanMemory：四个 `memref.alloc()` → 四个带偏移的 `hivm.hir.pointer_cast`，计算指令一条未改；并注入含 UB_SIZE/L1_SIZE/UB_ALIGN_SIZE/核数量等具体参数的 `dlti.target_system_spec`。
- InjectSync：源程序只有 load/vadd/store，Pass 注入 MTE2→V 与 V→MTE3 两组 `set_flag`/`wait_flag` 及一条 `PIPE_ALL` barrier。

边界不变：没有安装 CANN、没有驱动、没有生成或运行 kernel `.o`、没有上板——这些经确认不是观察 MLIR 中端 lowering 的必需项。lowering 主线中 Arith/Tensor 与 HFusion 两层仍属官方资料整理的概念说明，实物只到 HIVM 层。

报告因此从 18 页扩到 21 页（13 表 4 图），第 8 节改为以实测结果为准。
