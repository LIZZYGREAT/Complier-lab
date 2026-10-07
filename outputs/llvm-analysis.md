# LLVM IR 与源程序的对应关系

分析对象是 Clang 14 在 `-O0` 下生成的 `generated/example.ll`。抽取的原始函数保存在 `calc_generated.ll` 和 `main_generated.ll`。

## `calc` 控制流

```text
entry (%1)
  └─→ %5 while 条件
       ├─ false → %25 循环结束并返回 sum
       └─ true  → %9 if 条件
                    ├─ true  → %13 偶数分支 ─┐
                    └─ false → %18 奇数分支 ─┴→ %22 分支合流、递增 i
                                                    └─→ %5（循环回边）
```

| LLVM 基本块 | 源程序含义 | 关键操作 |
| --- | --- | --- |
| 函数入口 `%1` | 建立 `n`、`i`、`sum` 的栈槽并初始化 `i=1`、`sum=0` | `alloca`、`store`，跳转到 `%5` |
| `%5` | `while (i <= n)` 条件 | `load i/n`、`icmp sle`、条件 `br`；真到 `%9`，假到 `%25` |
| `%9` | `if (i % 2 == 0)` 条件 | `srem` 求余，`icmp eq` 比较余数是否为零，条件 `br` |
| `%13` | 偶数分支 `sum = sum + i * 2` | `mul`、`add`、`store sum`，跳到 `%22` |
| `%18` | 奇数分支 `sum = sum + i` | `add`、`store sum`，跳到 `%22` |
| `%22` | 两个 if 分支的合流及 `i = i + 1` | `load`、`add`、`store i`；无条件跳回 `%5`，这条边是 while 的 back edge |
| `%25` | while 结束后的 `return sum` | `load sum`、`ret` |

## 指令如何表达源语句

| 源程序结构 | LLVM IR 表达 | 本程序中的作用 |
| --- | --- | --- |
| 局部整型变量 | `alloca i32` | 在入口块给 `n`、`i`、`sum` 分配栈槽；Clang `-O0` 保留这些内存读写 |
| 读取变量 / 赋值 | `load` / `store` | 取 `i` 和 `n` 做比较、读写 `sum`，并更新 `i` |
| `i + 1`、累加 | `add nsw i32` | 更新循环计数器，以及奇偶分支的求和 |
| `i * 2` | `mul nsw i32` | 偶数分支的加权项 |
| `i % 2` | `srem i32` | 有符号整数余数，用于判断奇偶 |
| `i <= n` / `余数 == 0` | `icmp sle` / `icmp eq` | 产生 i1 条件值 |
| while / if 控制转移 | `br label` / `br i1` | 无条件跳转或按条件选择后继基本块 |
| 函数定义 / 调用 / 返回 | `define` / `call` / `ret` | 定义 `calc`、调用 runtime 与 `calc`、返回整数 |

`while` 和 `if` 没有各自专用的 LLVM 指令。它们由基本块、条件计算和 `br` 组成。基本块是一段只有入口处可进入、末尾由一个 terminator（此处为 `br` 或 `ret`）结束的连续指令序列。`%13` 与 `%18` 汇入 `%22`，因此两个分支的求和更新完成后都执行同一个循环递增。

## `main` 与调用关系

`main` 中 `call @getint()` 取得输入，`store` 保存到 `n`；随后 `load n` 并 `call @calc(...)`；结果被保存、重新载入后传给 `call @putint(...)`，最后 `ret i32 0`。因此外部 I/O 符号由 runtime 提供，而 `calc` 是同一 LLVM module 中的函数定义。

## 输出文件

- `calc_generated.ll`：自动生成的 `calc` 原始 IR。
- `main_generated.ll`：自动生成的 `main` 原始 IR。
- 完整模块：`../generated/example.ll`。
