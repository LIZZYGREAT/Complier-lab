# 阶段 4：手写 LLVM IR 并验证

## 目标

根据 SysY 源程序和已分析的控制流图，独立构造清晰的 LLVM IR，链接宿主机 runtime 并验证输出。

## 输入

- `source/example.sy`
- `source/host_runtime.c`
- `outputs/llvm-analysis.md` 中的控制流分析

## 执行命令

```bash
bash scripts/03_llvm_validation.sh 2>&1 | tee logs/03_llvm_validation.log
```

脚本使用：

```bash
clang -O0 llvm/manual.ll source/host_runtime.c -o generated/manual_llvm
```

## 关键输出

`llvm/manual.ll` 是根据源程序重新构造的实现：`calc` 显式使用 `entry`、`while.cond`、`if.cond`、`if.then`、`if.else`、`if.end`、`while.end` 七个命名块。整数局部变量通过 `alloca/load/store` 表达；算术和分支分别使用 `add`、`mul`、`srem`、`icmp`、`br`。`main` 调用 `getint`、`calc`、`putint`。

本实现未复制生成的 IR。它从源码 CFG 直接组织命名块，没有 Clang 自动生成的 `%N` 临时值编号、函数属性和额外元数据，语义操作仍逐项覆盖原程序。

六组输入全部得到预期输出；实际输出在 `outputs/manual-llvm-test.txt`，完整命令日志在 `logs/03_llvm_validation.log`。

## 生成产物

- `llvm/manual.ll`
- `generated/manual_llvm`
- `outputs/manual-llvm-test.txt`
- `scripts/03_llvm_validation.sh`
- `logs/03_llvm_validation.log`
- `records/04_manual_llvm.md`

## 结果解释

`while.cond` 用 `icmp sle` 判断循环条件；真分支进入 `if.cond`，假分支到 `while.end`。`if.cond` 根据 `i % 2` 进入两个分支，分支都更新 `sum` 后到 `if.end`；该块只递增 `i` 并回跳到 `while.cond`。这直接实现了源程序的循环与分支语义。

## 验收结果

PASS — Clang 接受手写 IR，完成与 host runtime 的链接，六组固定测试全部通过。

## 异常

无。
