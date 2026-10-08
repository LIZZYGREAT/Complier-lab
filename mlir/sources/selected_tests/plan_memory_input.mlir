// RUN: bishengir-opt %s -hacc-append-device-spec=target=Ascend910B1 -hivm-plan-memory -split-input-file -verify-diagnostics | FileCheck %s
// RUN: bishengir-opt %s -hacc-append-device-spec=target=Ascend910B1 -hivm-plan-memory=plan-memory-strategy=largest-first -split-input-file -verify-diagnostics | FileCheck %s --check-prefix=CHECK-REORDER

module {
  // CHECK-LABEL: func.func @test_mem_allocate_basic
  func.func @test_mem_allocate_basic(%src : memref<16x16x16xf16, #hivm.address_space<gm>>,
                                    %dst3 : memref<16x16x16xf16, #hivm.address_space<gm>>) {
    // CHECK-NOT: memref.alloc()
    // CHECK: %[[CONST0:.*]] = arith.constant 0 : i64
    // CHECK: {{.*}} = hivm.hir.pointer_cast(%[[CONST0]])
    %copy_in_ub = memref.alloc() : memref<16x16x16xf16, #hivm.address_space<ub>>
    // CHECK: {{.*}} = hivm.hir.pointer_cast(%[[CONST0]])
    %dst1 = memref.alloc() : memref<16x16x16xf16, #hivm.address_space<ub>>
    // CHECK: {{.*}} = hivm.hir.pointer_cast(%[[CONST0]])
    %dst2 = memref.alloc() : memref<16x16x16xf16, #hivm.address_space<ub>>
    // CHECK: {{.*}} = hivm.hir.pointer_cast(%[[CONST0]])
    %copy_out_ub = memref.alloc() : memref<16x16x16xf16, #hivm.address_space<ub>>
    hivm.hir.load ins(%src : memref<16x16x16xf16, #hivm.address_space<gm>>)
                  outs(%copy_in_ub : memref<16x16x16xf16, #hivm.address_space<ub>>)
    hivm.hir.vadd ins(%copy_in_ub, %copy_in_ub : memref<16x16x16xf16, #hivm.address_space<ub>>,
                      memref<16x16x16xf16, #hivm.address_space<ub>>)
                  outs(%dst1 : memref<16x16x16xf16, #hivm.address_space<ub>>)
    hivm.hir.vadd ins(%dst1, %dst1 : memref<16x16x16xf16, #hivm.address_space<ub>>,
                      memref<16x16x16xf16, #hivm.address_space<ub>>)
                  outs(%dst2 : memref<16x16x16xf16, #hivm.address_space<ub>>)
    hivm.hir.vadd ins(%dst2, %dst2 : memref<16x16x16xf16, #hivm.address_space<ub>>,
                      memref<16x16x16xf16, #hivm.address_space<ub>>)
                  outs(%copy_out_ub : memref<16x16x16xf16, #hivm.address_space<ub>>)
    hivm.hir.store ins(%copy_out_ub : memref<16x16x16xf16,#hivm.address_space<ub>>)
                   outs(%dst3: memref<16x16x16xf16,#hivm.address_space<gm>>)
    return
  }
}

