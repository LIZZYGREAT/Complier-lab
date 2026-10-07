# 阶段 9：最终一致性验证

## 目标

用相同六组输入并排运行宿主机 reference、手写 LLVM IR 可执行文件和手写 RISC-V QEMU 程序，确认三种实现与固定 Ground Truth 一致。

## 输入

- `generated/reference`
- `generated/manual_llvm`
- `generated/manual_riscv`（通过 `qemu-riscv64`）
- 固定输入/期望值：`1→1, 2→5, 3→8, 4→16, 5→21, 10→85`

## 执行命令

```bash
bash scripts/09_final_validation.sh 2>&1 | tee logs/09_final_validation.log
```

## 关键输出

三种实现的完整输出矩阵见 `outputs/final-validation.md`。六行结果均为 `PASS`，且三路值分别等于 `1, 5, 8, 16, 21, 85`。

## 生成产物

- `outputs/final-validation.md`
- `scripts/09_final_validation.sh`
- `logs/09_final_validation.log`
- `records/09_final_validation.md`
- `records/artifact_index.md`

## 结果解释

该表将执行结果与 Stage 1 固定的期望输出逐项比较，而不是仅检查三种实现彼此相同。RISC-V runtime 额外写入 stderr 的计时摘要仍保留在完整日志中，不进入数值比较。

## 验收结果

PASS — 六组结果全部一致。

## 异常

无。
