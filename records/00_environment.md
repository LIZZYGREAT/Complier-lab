# 阶段 0：环境快照与实验目录

## 目标

记录当前课程环境和工具版本，建立 `lab/` 下统一的实验目录骨架，并检查已有课程编译器成果；本阶段不安装或重新配置工具链。

## 输入

- 工作区脚本：`../env.sh`
- 已有课程项目：`../SysY_Compiler_2025`
- 固定贯穿程序：`source/example.sy`

## 执行命令

```bash
bash scripts/00_environment_check.sh 2>&1 | tee logs/00_environment.log
```

## 关键输出

- `env.sh` 成功加载，`COMPILER_HOME=/home/lenovo/opt/compiler`。
- Clang 14.0.0、QEMU 7.0.0、`riscv64-unknown-elf-gcc` 15.1.0 可用；GCC、Make、Flex、Bison、Python 3 及 RISC-V readelf 也均可找到。实际完整版本和可执行文件路径见 `logs/00_environment.log`。
- Ubuntu 22.04 环境信息已写入日志。
- `SysY_Compiler_2025/bin/compiler`、`lib/libsysy_riscv.a` 和 `lib/libsysy_x86.a` 已存在，说明课程编译器与 SysY 运行库已有构建结果。本实验会复用并只读检查这些成果，不重复构建或修改该目录。
- 课程项目当前有本地未提交修改：parser 生成文件和两个运行库文件处于 modified 状态。该状态已记入日志；实验不在该项目中写入任何文件。
- `lab/` 中的 `source/`、`generated/`、`llvm/`、`riscv/`、`outputs/`、`exploration/`、`mlir/references/`、`report/figures/`、`scripts/`、`logs/`、`records/` 已按计划准备。

## 生成产物

- `scripts/00_environment_check.sh`
- `logs/00_environment.log`
- `records/00_environment.md`
- `source/example.sy`
- `source/example_clang.c`
- `source/host_runtime.c`

## 结果解释

`env.sh` 只为当前脚本进程加入课程工具链路径，没有修改 shell 启动文件或系统安装。SysY 原始版本与 Clang 可处理版本保持同一算法；C 版本仅声明 `getint` / `putint`，本机 runtime 提供输入输出实现。

## 验收结果

PASS — 环境脚本可加载，必需命令存在，阶段目录与三份源文件已就位。

## 异常

最初尝试写入全局 Git 配置时遇到家目录只读限制；按用户明确要求授权后，已成功设为 `LIZZYGREAT <2660550447@qq.com>`。未触碰 `SysY_Compiler_2025` 中的现有修改。
