# MLIR / AscendNPU VecAdd references

Stage 8 is a source-based study. These primary references describe the standard MLIR model and the published AscendNPU-IR VecAdd pipeline:

1. LLVM Project, *MLIR Language Reference*: <https://mlir.llvm.org/docs/LangRef/>
2. LLVM Project, *MLIR Rationale*: <https://mlir.llvm.org/docs/Rationale/Rationale/>
3. LLVM Project, *Targeting LLVM IR from MLIR*: <https://mlir.llvm.org/docs/TargetLLVMIR/>
4. Ascend, *AscendNPU-IR Framework Integration*: <https://github.com/Ascend/AscendNPU-IR/blob/master/docs/source/en/developer_guide/conversion/framework_interface.md>
5. Ascend, *AscendNPU-IR Interface API*: <https://github.com/Ascend/AscendNPU-IR/blob/master/docs/source/en/developer_guide/conversion/interface_api.md>
6. Ascend, *HIVM VecAdd `add.mlir`*: <https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/add.mlir>
7. Ascend, *HIVM VecAdd README*: <https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/README.md>
8. Ascend, *HIVM VecAdd host wrapper `main.cpp`*: <https://github.com/Ascend/AscendNPU-IR/blob/master/bishengir/test/Integration/HIVM/VecAdd/main.cpp>

Accessed 2026-10-07. The checked-in notes are an analysis of these sources, not captured output from `bishengir-opt` or an Ascend device.
