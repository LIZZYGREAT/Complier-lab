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
| `mlir/references/README.md` | LLVM 与 Ascend 官方资料 | MLIR VecAdd 参考来源 | 是 |
| `report/report.md` | Stage 10 | 报告源稿，含图表说明、结果与参考文献 | 是 |
| `report/report.pdf` | Stage 10 | 五页最终 PDF 实验报告 | 是 |
| `scripts/10_build_report.sh`, `scripts/10_render_report.py` | Stage 10 | 可重复构建并结构校验报告 PDF | 是 |
| `records/00`–`10` | 各阶段记录 | 过程、结果、验收与限制 | 是 |
| `scripts/00`–`10` | 本实验脚本 | 重现工具检查、构建和验证 | 是 |
| `logs/00`–`10` | 阶段实际 stdout/stderr | 过程证据 | 按需引用 |
| `records/FINAL_HANDOFF.md` | Stage 10 | 完成状态、提交和限制汇总 | 是 |
