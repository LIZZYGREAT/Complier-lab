# 阶段 1：建立源程序 Ground Truth

## 目标

先取得一份可执行的宿主机参考结果，作为后续 LLVM IR 和 RISC-V 实现的比较基准。

## 输入

- `source/example_clang.c`：固定算法的 C 版本，声明 SysY runtime 接口。
- `source/host_runtime.c`：只用于宿主机验证的 `getint` / `putint` 实现。
- `source/test_reference.sh`：六组固定输入的对照脚本。

## 执行命令

```bash
bash scripts/01_reference.sh 2>&1 | tee logs/01_reference.log
```

脚本使用 `clang source/example_clang.c source/host_runtime.c -O0 -o generated/reference` 构建参考程序，并运行 `source/test_reference.sh`。

## 关键输出

六组测试均与文档中的期望值相同：

| 输入 `n` | 期望/实际输出 |
| ---: | ---: |
| 1 | 1 |
| 2 | 5 |
| 3 | 8 |
| 4 | 16 |
| 5 | 21 |
| 10 | 85 |

逐组运行输出保存在 `outputs/reference-test.txt`，编译器命令和完整终端输出保存在 `logs/01_reference.log`。

## 生成产物

- `generated/reference`
- `outputs/reference-test.txt`
- `scripts/01_reference.sh`
- `source/test_reference.sh`
- `logs/01_reference.log`
- `records/01_reference_baseline.md`

## 结果解释

基线程序按 `i=1..n` 累加：偶数项计入 `2*i`，奇数项计入 `i`。`example.sy` 保留 SysY 源码形式；`example_clang.c` 仅补上 Clang 所需的函数原型和 `main(void)` 形式；`host_runtime.c` 提供本机标准输入输出，不属于手写 LLVM IR 或 RISC-V 程序。

## 验收结果

PASS — 六组输入全部得到预期结果。

## 异常

无。
