# Codex 执行方案：编译原理第一次作业（全过程留痕版）

> 目标：由 Codex 在当前 WSL 编译原理环境中完成第一次作业的实验部分，并对全过程进行可复现记录。  
> 最终不仅要得到“能跑通的结果”，还要保留足够的命令、输出、中间文件、分析记录和验证证据，以便：
>
> 1. 后续撰写正式实验报告；
> 2. 人工复盘每一步编译过程；
> 3. 回答老师可能的过程性提问；
> 4. 明确区分“编译器自动生成结果”和“人工设计/手写结果”。

---

## 一、总体要求

Codex 执行本任务时必须遵守以下原则。

### 1. 不允许只交最终结果

不能只得到：

```text
manual.ll
manual.s
最终可执行文件
```

而跳过过程。

必须保留：

```text
输入源文件
执行命令
命令输出
中间产物
分析过程
验证结果
错误与修复记录
最终结果
```

### 2. 每一个阶段必须可复现

每个正式阶段都应有：

```text
scripts/
    stage_xx_*.sh

logs/
    stage_xx_*.log

records/
    stage_xx_*.md
```

其中：

- `scripts/`：保存实际执行命令；
- `logs/`：保存命令真实 stdout/stderr；
- `records/`：说明该阶段做了什么、为什么、结果是什么。

不要依赖终端历史作为唯一记录。

### 3. 自动生成代码和手写代码必须分开

必须严格区分：

```text
generated/
```

与：

```text
llvm/manual.ll
riscv/manual.s
```

禁止直接复制 Clang 自动生成结果作为“手写结果”。自动生成结果只能用于观察、分析、对照和验证。

### 4. 不擅自修改实验基线

本次贯穿程序固定为：

```c
int calc(int n) {
    int i = 1;
    int sum = 0;

    while (i <= n) {
        if (i % 2 == 0) {
            sum = sum + i * 2;
        } else {
            sum = sum + i;
        }

        i = i + 1;
    }

    return sum;
}

int main() {
    int n;
    n = getint();

    int result;
    result = calc(n);

    putint(result);

    return 0;
}
```

不要为了简单而删除 `while`、`if/else`、函数调用、取模、乘法，也不要擅自增加数组、递归等无关特性。

### 5. 不修改系统环境

当前环境已经配置完成。原则上：

```text
不要重新安装 QEMU
不要重新安装 RISC-V 工具链
不要修改系统 GCC
不要修改 ~/.bashrc
不要改变课程环境配置
```

只有在确认某个必要工具缺失且任务无法继续时，先记录问题并停止相关步骤，不要擅自大规模调整系统环境。

### 6. 不自动提交或推送 Git

允许查看 `git status`、`git diff` 和创建本地实验文件。未经明确要求：

```text
不要 git commit
不要 git push
```

---

## 二、任务目标

第一次作业基本部分要完成：

```text
SysY 源程序
      ↓
成熟编译器完整处理过程
      ↓
预处理文件
      ↓
LLVM IR
      ↓
汇编
      ↓
目标文件
      ↓
链接
      ↓
可执行程序
```

然后完成两次人工实现：

```text
SysY
 ↓
手写 LLVM IR
 ↓
编译 + 链接
 ↓
运行验证
```

以及：

```text
SysY
 ↓
手写 RISC-V 汇编
 ↓
汇编 + 链接 SysY Runtime
 ↓
QEMU
 ↓
运行验证
```

最后完成 `-O0 vs -O2` 优化观察，以及 MLIR / AscendNPU IR VecAdd lowering 进阶探索。

---

## 三、目录结构

工作目录：

```text
~/projects/Compiler-Labs/assignment1
```

最终至少保持：

```text
assignment1/
├── source/
│   ├── example.sy
│   ├── example_clang.c
│   ├── host_runtime.c
│   └── test_reference.sh
├── generated/
│   ├── example.i
│   ├── example.ll
│   ├── example_x86.s
│   ├── example.o
│   ├── host_runtime.o
│   ├── reference
│   └── example_riscv.s
├── llvm/
│   └── manual.ll
├── riscv/
│   └── manual.s
├── exploration/
│   ├── O0.ll
│   ├── O2.ll
│   ├── O0.s
│   └── O2.s
├── scripts/
│   ├── 00_environment_check.sh
│   ├── 01_reference.sh
│   ├── 02_pipeline.sh
│   ├── 03_llvm_validation.sh
│   ├── 04_riscv_reference.sh
│   ├── 05_riscv_validation.sh
│   ├── 06_optimization.sh
│   └── 09_final_validation.sh
├── logs/
│   ├── 00_environment.log
│   ├── 01_reference.log
│   ├── 02_pipeline.log
│   ├── 03_llvm_validation.log
│   ├── 04_riscv_reference.log
│   ├── 05_riscv_validation.log
│   ├── 06_optimization.log
│   └── 09_final_validation.log
├── records/
│   ├── 00_environment.md
│   ├── 01_reference_baseline.md
│   ├── 02_compilation_pipeline.md
│   ├── 03_llvm_analysis.md
│   ├── 04_manual_llvm.md
│   ├── 05_riscv_analysis.md
│   ├── 06_manual_riscv.md
│   ├── 07_optimization_analysis.md
│   ├── 08_mlir_exploration.md
│   ├── 09_final_validation.md
│   ├── errors_and_fixes.md
│   └── artifact_index.md
├── outputs/
│   ├── reference-test.txt
│   ├── manual-llvm-test.txt
│   └── manual-riscv-test.txt
├── mlir/
│   └── references/
└── report/
    └── figures/
```

不要为了形式漂亮继续增加无意义目录。

---

## 四、统一记录规范

### 1. 每个阶段脚本必须使用

```bash
#!/usr/bin/env bash
set -euo pipefail
```

### 2. 正式执行方式

统一使用：

```bash
bash scripts/<script>.sh 2>&1 | tee logs/<log>.log
```

例如：

```bash
bash scripts/00_environment_check.sh 2>&1 | tee logs/00_environment.log
```

### 3. 每份阶段记录必须写

```markdown
# 阶段名称

## 目标
## 输入
## 执行命令
## 关键输出
## 生成产物
## 结果解释
## 验收结果

PASS / FAIL

## 异常

若无：无
若有：问题、原因、修复方式、修复后验证。
```

### 4. 错误不能覆盖

如果发生错误，必须追加到：

```text
records/errors_and_fixes.md
```

格式：

```markdown
## YYYY-MM-DD / 阶段

### 问题
### 原始报错
### 原因
### 修改
### 重新执行
### 最终结果
```

不能只保留修复后的成功结果。

---

## 五、阶段 0：环境快照

### 目标

记录本次实验实际使用环境，不重新安装。

### 执行内容

创建：

```text
scripts/00_environment_check.sh
```

记录：

```bash
uname -a
cat /etc/os-release

gcc --version | head -n 1
clang --version | head -n 1
make --version | head -n 1

flex --version
bison --version | head -n 1

python3 --version

which qemu-riscv64
qemu-riscv64 --version | head -n 1

which riscv64-unknown-elf-gcc
riscv64-unknown-elf-gcc --version | head -n 1

which riscv64-unknown-elf-readelf
```

如果存在课程环境脚本，执行前加载：

```bash
source ~/projects/Compiler-Labs/env.sh
```

### 输出

```text
logs/00_environment.log
records/00_environment.md
```

### 验收

确认 Ubuntu 22.04、Clang、QEMU 7.0.0 和 RISC-V unknown-elf 工具链可用。

---

## 六、阶段 1：建立源程序基线

### 目标

建立 Ground Truth。

### 1. 建立源文件

确保：

```text
source/example.sy
source/example_clang.c
source/host_runtime.c
```

存在。

`example_clang.c` 与 `example.sy` 算法一致，仅补充：

```c
int getint(void);
void putint(int x);
```

`host_runtime.c`：

```c
#include <stdio.h>

int getint(void) {
    int x;
    scanf("%d", &x);
    return x;
}

void putint(int x) {
    printf("%d\n", x);
}
```

### 2. 编译参考版本

```bash
clang \
    source/example_clang.c \
    source/host_runtime.c \
    -O0 \
    -o generated/reference
```

### 3. 固定测试

```text
1  -> 1
2  -> 5
3  -> 8
4  -> 16
5  -> 21
10 -> 85
```

建立自动测试脚本并保存：

```text
outputs/reference-test.txt
```

### 4. 记录

创建：

```text
records/01_reference_baseline.md
```

解释为什么需要 Ground Truth、为什么 `example.sy` 与 `example_clang.c` 分开、为什么 `host_runtime.c` 只是本机测试 Runtime。

### 验收

六组全部 PASS，否则不进入下一阶段。

---

## 七、阶段 2：成熟编译器完整流程

### 目标

实际获得：

```text
源代码
→ 预处理
→ LLVM IR
→ 汇编
→ object
→ executable
```

### 1. 预处理

```bash
clang -E \
    source/example_clang.c \
    -o generated/example.i
```

### 2. LLVM IR

```bash
clang -S -emit-llvm -O0 \
    source/example_clang.c \
    -o generated/example.ll
```

### 3. x86-64 汇编

```bash
clang -S -O0 \
    source/example_clang.c \
    -o generated/example_x86.s
```

明确记录：这是 WSL 主机架构 x86-64 汇编，不是最终手写 RISC-V 汇编。

### 4. 目标文件

```bash
clang -c -O0 \
    source/example_clang.c \
    -o generated/example.o

clang -c \
    source/host_runtime.c \
    -o generated/host_runtime.o
```

检查：

```bash
file generated/example.o
readelf -h generated/example.o
readelf -S generated/example.o
readelf -s generated/example.o
```

### 5. 显式链接

```bash
clang \
    generated/example.o \
    generated/host_runtime.o \
    -o generated/reference_linked
```

运行相同六组测试。

### 6. 分析记录

创建：

```text
records/02_compilation_pipeline.md
```

必须结合本次真实文件回答：

```text
预处理器做了什么？
编译器做了什么？
汇编器做了什么？
链接器做了什么？
example.o 为什么不能独立完成整个程序功能？
getint / putint 是在哪里被解析的？
```

---

## 八、阶段 3：LLVM IR 分析

### 目标

建立：

```text
SysY Source
      ↕
LLVM Basic Blocks / CFG
```

映射。

### 1. 提取函数

保存：

```text
outputs/calc_generated.ll
outputs/main_generated.ll
```

可使用：

```bash
sed -n '/define.*@calc/,/^}/p' generated/example.ll
sed -n '/define.*@main/,/^}/p' generated/example.ll
```

### 2. 分析 `calc` CFG

目标语义结构：

```text
entry
  ↓
while.cond
 ├── false → while.end
 └── true
       ↓
    if.cond
    ├── true → if.then
    └── false → if.else
          \       /
           if.end
              ↓
          while.cond
```

记录：

```text
LLVM block number
→ 人类语义名称
→ 对应源代码
```

### 3. 必须解释的指令

至少：

```text
alloca
load
store
add
mul
srem
icmp sle
icmp eq
br
call
ret
```

不能只写定义。必须写：

```text
本程序哪一行源代码
↓
对应哪条 LLVM IR
↓
为什么需要该指令
```

### 输出

```text
records/03_llvm_analysis.md
```

### 验收

必须能回答：

```text
while 为什么不需要 while 指令？
什么是 Basic Block？
while 的 back edge 在哪里？
if / else 如何形成两个分支？
两个分支在哪里 merge？
```

---

## 九、阶段 4：手写 LLVM IR

### 目标

从源程序和 CFG 独立构造：

```text
llvm/manual.ll
```

### 1. 禁止复制自动生成结果

允许参考指令语法、函数声明和类型写法，但控制流和代码组织必须根据前一阶段分析重新构造。

### 2. 第一版优先清晰

允许使用：

```text
alloca
load
store
```

不要求复杂 SSA + phi。

### 3. 结构

至少包含：

```text
declare @getint
declare @putint
define @calc
define @main
```

`calc` 应明确体现：

```text
entry
while.cond
if.cond
if.then
if.else
if.end
while.end
```

### 4. 语法验证

优先使用现有 `clang` 直接处理 `.ll`。若 LLVM 版本语法存在差异，要记录具体差异，不得静默绕过。

### 5. 运行测试

将 `manual.ll` 与：

```text
source/host_runtime.c
```

链接生成本机程序。

跑六组测试。

保存：

```text
outputs/manual-llvm-test.txt
logs/03_llvm_validation.log
records/04_manual_llvm.md
```

### 验收

六组全部 PASS，且 `manual.ll` 可解释、CFG 与源代码一致、不是自动生成文件复制品。

---

## 十、阶段 5：生成并分析 RISC-V 参考汇编

### 目标

在手写 RISC-V 前先观察成熟工具链如何表达相同逻辑。

### 1. 生成参考汇编

探索当前工具链下合理的 RISC-V 交叉生成方式。

目标文件：

```text
generated/example_riscv.s
```

允许使用 Clang cross target 或现有 RISC-V GCC 工具链，但必须记录实际命令和采用理由。

### 2. 分析 ABI

至少解释：

```text
a0-a7
t0-t6
s0-s11
sp
ra
```

但只深入本程序真实使用的寄存器。

### 3. 对齐源程序

重点找：

```text
calc 参数
calc 返回值
while 比较与跳转
if 奇偶判断
i++
函数调用
栈帧
```

### 输出

```text
records/05_riscv_analysis.md
logs/04_riscv_reference.log
```

---

## 十一、阶段 6：手写 RISC-V 汇编

### 目标

独立编写：

```text
riscv/manual.s
```

### 1. 结构建议

```text
calc:
    prologue
    初始化 i
    初始化 sum

while_cond:
    ...

if_cond:
    ...

if_then:
    ...

if_else:
    ...

if_end:
    ...

while_end:
    epilogue
    ret

main:
    ...
```

### 2. ABI 要求

必须正确处理：

```text
参数传递
返回值
ra
sp
必要的寄存器保存/恢复
```

不要求高度优化。

### 3. Runtime

优先复用已经构建成功的 `SysY_Compiler_2025` 中的 RISC-V runtime / library。

先调查：

```text
课程实际 runtime 文件
链接脚本
已有 asm2bin.sh / buildlib.sh
toolchain.conf
```

不要猜路径。

### 4. 链接与执行

目标：

```text
manual.s
+
SysY runtime
   ↓
RISC-V executable
   ↓
qemu-riscv64
```

### 5. 验证

继续使用：

```text
1
2
3
4
5
10
```

保存：

```text
outputs/manual-riscv-test.txt
logs/05_riscv_validation.log
records/06_manual_riscv.md
```

### 验收

六组全部 PASS。

---

## 十二、阶段 7：优化探索

### 目标

完成一次有真实证据的：

```text
-O0 vs -O2
```

比较。

### 1. LLVM IR

```bash
clang -S -emit-llvm -O0 \
    source/example_clang.c \
    -o exploration/O0.ll

clang -S -emit-llvm -O2 \
    source/example_clang.c \
    -o exploration/O2.ll
```

### 2. 汇编

```bash
clang -S -O0 \
    source/example_clang.c \
    -o exploration/O0.s

clang -S -O2 \
    source/example_clang.c \
    -o exploration/O2.s
```

如果 RISC-V 交叉编译链已稳定，也增加 RISC-V O0/O2 对比。

### 3. 分析原则

必须基于真实 diff：

```bash
diff -u exploration/O0.ll exploration/O2.ll
diff -u exploration/O0.s exploration/O2.s
```

检查：

```text
alloca 是否减少
load/store 是否减少
变量是否寄存器化
控制流是否简化
函数是否内联
表达式是否重写
```

只写本程序真实发生的变化。

### 输出

```text
records/07_optimization_analysis.md
logs/06_optimization.log
```

---

## 十三、阶段 8：MLIR / AscendNPU IR 进阶探索

### 目标

完成进阶部分探索材料。

当前不安装新的 CANN 环境。

### 1. 使用已有课程资料

重点分析 VecAdd：

```text
Arith / Tensor
      ↓
HFusion
      ↓
HIVM
      ↓
HACC
      ↓
LLVM IR
```

### 2. 必须解释

```text
LLVM 单层 IR 与 MLIR 多级 Dialect 的差异
Dialect 是什么
Operation 是什么
Lowering 是什么

为什么 hfusion.vadd
会逐渐下降为 load / vadd / store

为什么 HIVM 开始出现 GM、UB、显式内存搬运和同步
```

### 3. 不伪造实验

如果没有真实运行 `bishengir-opt`，就明确写：

```text
该部分为基于课程资料和官方资料的结构分析
```

禁止伪造“实际运行得到”的输出。

### 输出

```text
records/08_mlir_exploration.md
```

---

## 十四、阶段 9：最终一致性验证

### 目标

正式收口实验部分。

创建：

```text
scripts/09_final_validation.sh
```

统一运行：

```text
reference
manual LLVM executable
manual RISC-V executable
```

固定测试：

```text
1
2
3
4
5
10
```

生成总表：

```text
Input | Reference | LLVM | RISC-V | Result
```

保存：

```text
logs/09_final_validation.log
records/09_final_validation.md
```

---

## 十五、最终产物索引

创建：

```text
records/artifact_index.md
```

列出关键文件，例如：

```markdown
| 文件 | 来源 | 用途 | 是否用于报告 |
|---|---|---|---|
| source/example.sy | 人工确定 | 原始 SysY | 是 |
| generated/example.ll | Clang | 自动 LLVM 参考 | 是 |
| llvm/manual.ll | 手写 | LLVM 实验成果 | 是 |
| generated/example_riscv.s | 工具生成 | 汇编参考 | 是 |
| riscv/manual.s | 手写 | RISC-V 实验成果 | 是 |
```

---

## 十六、报告素材整理

暂时不要正式写完整 PDF。

先整理后续报告素材。

建议 `report/figures/` 只保留真正适合做图的内容，例如：

```text
真实 CFG
O0 / O2 对比
三路结果一致性表
完整编译流程图
```

不要大量截终端图。命令输出优先保存为文本或表格。

---

## 十七、Codex 最终交付内容

任务完成后必须创建：

```text
records/FINAL_HANDOFF.md
```

其中包括：

### 1. 完成情况

逐项标记：

```text
环境记录
Ground Truth
编译流程
LLVM 分析
手写 LLVM
RISC-V 分析
手写 RISC-V
优化实验
MLIR 探索
最终一致性测试
```

状态：

```text
PASS
PARTIAL
FAIL
```

### 2. 关键结果

例如：

```text
Reference 六组测试：PASS
Manual LLVM 六组测试：PASS
Manual RISC-V 六组测试：PASS
```

### 3. 仍存在的问题

如果没有：

```text
无阻塞问题
```

如果有，明确写问题、影响、是否影响提交、建议如何处理。

### 4. 报告可直接使用的材料

列出：

```text
records/02_compilation_pipeline.md
records/03_llvm_analysis.md
records/04_manual_llvm.md
records/05_riscv_analysis.md
records/06_manual_riscv.md
records/07_optimization_analysis.md
records/08_mlir_exploration.md
records/09_final_validation.md
```

### 5. 必须人工复盘的知识点

至少：

```text
预处理 / 编译 / 汇编 / 链接区别

LLVM Basic Block
CFG
while back edge
alloca/load/store
icmp/br
call/ret

RISC-V ABI
a0
ra
sp
函数调用
栈帧
条件分支

-O0 与 -O2 的真实差异

LLVM IR 与 MLIR 的区别
Dialect
Lowering
```

---

## 十八、Codex 执行方式

不要一次性盲跑到最后。

按阶段执行：

```text
Stage 0
↓
记录 + 验收

Stage 1
↓
记录 + 验收

Stage 2
↓
记录 + 验收

...
```

如果某阶段失败：

```text
停止依赖该阶段的后续任务
↓
定位问题
↓
记录原始错误
↓
最小修改
↓
重新验证
↓
继续
```

禁止为了“让测试变绿”而：

```text
删除测试
降低验证标准
跳过失败用例
硬编码输入输出
修改 Ground Truth
```

---

## 十九、最终判定标准

只有同时满足以下条件才算完成：

```text
[ ] 六组 reference 测试 PASS
[ ] 完整编译流程中间文件已保存
[ ] LLVM CFG 与源程序关系已记录
[ ] manual.ll 为独立手写实现
[ ] manual.ll 六组测试 PASS
[ ] RISC-V ABI 与控制流已分析
[ ] manual.s 为独立手写实现
[ ] manual.s 六组 QEMU 测试 PASS
[ ] O0/O2 真实 diff 已分析
[ ] MLIR VecAdd lowering 已完成进阶探索
[ ] 每阶段存在 log
[ ] 每阶段存在 record
[ ] 错误与修复均有留档
[ ] artifact_index.md 完整
[ ] FINAL_HANDOFF.md 完整
```

完成上述内容后，才进入正式实验报告撰写阶段。

---

## 二十、Codex 开始执行时的第一步

先不要立即修改代码。

首先：

1. 查看 `~/projects/Compiler-Labs/assignment1` 当前状态；
2. 查看现有文件；
3. 查看 `~/projects/Compiler-Labs/env.sh`；
4. 查看已经完成的课程 `SysY_Compiler_2025` 环境；
5. 判断本文档中哪些步骤已经人工完成；
6. 保留已经正确的现有成果，不重复覆盖；
7. 建立缺失的 `scripts/`、`logs/`、`records/`；
8. 从 Stage 0 开始补齐全过程记录；
9. 再继续完成尚未完成的任务。

如果已有产物但缺少历史日志：

```text
不要伪造之前执行过的日志。
```

可以重新执行可安全复现的命令，并明确记录：

```text
“为补充可复现实验记录，本步骤于当前阶段重新执行。”
```

这是允许的，也比伪造历史记录可靠。
