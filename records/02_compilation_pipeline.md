# 阶段 2：观察 Clang 的完整处理流程

## 目标

用 Clang/LLVM 实际生成预处理源文件、LLVM IR、宿主机汇编、ELF 可重定位目标文件，并显式链接运行，观察每个产物与输入程序的关系。

## 输入

- `source/example_clang.c`
- `source/host_runtime.c`
- `source/test_reference.sh`

## 执行命令

```bash
bash scripts/02_pipeline.sh 2>&1 | tee logs/02_pipeline.log
```

主要子命令和真实输出见 `logs/02_pipeline.log`。

## 关键输出

- `clang -E` 生成 `generated/example.i`。该示例没有宏或头文件引用，因此文件主要保留原 C 程序并带有源文件行标记，没有展开大量库头文件。
- `clang -S -emit-llvm -O0` 生成 `generated/example.ll`。函数、栈变量、读写、比较和控制转移分别体现为 `define/call/ret`、`alloca`、`load/store`、`icmp` 与 `br` 等 IR 指令。
- `clang -S -O0` 生成 `generated/example_x86.s`。它是 WSL x86-64 宿主机汇编，只作自动生成结果分析，不是手写 RISC-V 实验成果。
- Clang 驱动从 C 文件生成 `generated/example.o` 和 `generated/host_runtime.o`；`file` 与 `readelf` 展示其 ELF 类型、节区、符号和重定位信息。`example.o` 是 `ET_REL` 可重定位目标文件，入口地址为 0 且没有程序头；它定义 `calc`、`main`，并保留对 `getint`、`putint` 的外部引用。
- `host_runtime.o` 定义 `getint`、`putint`，并保留 `__isoc99_scanf`、`printf` 引用。显式链接得到 `generated/reference_linked`；Clang `-v` 日志显示驱动调用 `/usr/bin/ld`，加入 CRT 启动对象和 `-lc`。链接器由此解析 runtime 与系统库符号、处理重定位并生成可执行 ELF。
- `reference_linked` 的六组输入输出全部通过，结果保存在 `outputs/reference-linked-test.txt`。

## 生成产物

- `generated/example.i`
- `generated/example.ll`
- `generated/example_x86.s`
- `generated/example.o`、`generated/host_runtime.o`
- `generated/reference_linked`
- `outputs/reference-linked-test.txt`
- `scripts/02_pipeline.sh`
- `logs/02_pipeline.log`
- `records/02_compilation_pipeline.md`

`.o` 文件匹配仓库忽略规则，不纳入 Git；可从脚本复现。其他文本产物、最终可执行文件、日志和记录保存在本阶段提交中。

## 结果解释

预处理器处理 `#include`、宏定义和条件编译等预处理指令，输出仍是 C 源文本；它不负责判断 `while` 的运行语义。本例没有使用这些指令，所以 `.i` 与输入在语句内容上几乎相同。

Clang 前端对字符流做词法分析、语法分析和语义检查，生成 LLVM IR；LLVM 中端可在 IR 上执行优化；后端根据目标架构把 IR 降为汇编/机器指令。`clang -S` 展示 IR 或汇编边界，`clang -c` 继续调用集成汇编器，将指令编码为机器码并产生 ELF 节区、符号和重定位项。

链接器处理多个目标文件和运行库：布局输入节区、解析符号引用、应用重定位，并结合启动文件生成可执行文件。单独的 `example.o` 仍含外部符号引用，且 ELF 类型为可重定位文件，不能直接作为完整进程执行。

## 验收结果

PASS — 各级产物均由本阶段命令生成，显式链接后的六组测试全部通过。

## 异常

无。
