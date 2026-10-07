# 阶段 3：分析 Clang 生成的 LLVM IR

## 目标

把 `example.sy` 中的变量、运算、while、if/else 和函数调用映射到 LLVM 基本块与指令，为下一阶段独立设计手写 IR 做准备。

## 输入

- `generated/example.ll`：Stage 2 由 Clang 14、`-O0` 生成的模块。
- SysY 基线：`source/example.sy`。

## 执行命令

```bash
bash scripts/03_llvm_analysis.sh 2>&1 | tee logs/03_llvm_analysis.log
```

## 关键输出

- `%5` 为 while 条件块：`icmp sle` 计算 `i <= n`，`br i1` 在循环体 `%9` 与退出块 `%25` 间选择。
- `%9` 为 if 条件块：`srem i32 i, 2` 与 `icmp eq` 判断偶数，并分流到 `%13` 或 `%18`。
- `%13` 和 `%18` 分别实现偶数、奇数求和，两者汇入 `%22`；`%22` 递增 `i` 并无条件跳回 `%5`，构成回边。
- `%25` 读取 `sum` 并返回。`main` 使用 `call` 顺序调用 `getint`、`calc`、`putint`。
- `-O0` IR 使用 `alloca/load/store` 表达局部变量的栈内存访问；控制流由基本块与 `br` 表达，不存在专门的 while/if 指令。

详细 CFG、块到源代码映射和指令解释见 `outputs/llvm-analysis.md`；本阶段实际抽取结果保存在 `outputs/calc_generated.ll`、`outputs/main_generated.ll`。

## 生成产物

- `outputs/calc_generated.ll`
- `outputs/main_generated.ll`
- `outputs/llvm-analysis.md`
- `scripts/03_llvm_analysis.sh`
- `logs/03_llvm_analysis.log`
- `records/03_llvm_analysis.md`

## 结果解释

LLVM 基本块末尾的分支指令编码源程序控制结构。if 的两个路径在 `%22` 汇合，while 的循环体执行完后由 `%22` 回到 `%5`；局部可变变量在此未转换成 SSA phi 节点，而是通过入口处分配的栈槽和加载/存储实现。

## 验收结果

PASS — 已识别 while 条件、if 分支、merge、back edge，并解释内存、算术、比较、跳转和函数指令。

## 异常

无。
