; Hand-written LLVM IR for source/example.sy.
; The control-flow graph is expressed with named basic blocks and memory slots.

source_filename = "manual.ll"
target triple = "x86_64-pc-linux-gnu"

declare i32 @getint()
declare void @putint(i32)

define i32 @calc(i32 %n) {
entry:
  %i.addr = alloca i32, align 4
  %sum.addr = alloca i32, align 4
  store i32 1, i32* %i.addr, align 4
  store i32 0, i32* %sum.addr, align 4
  br label %while.cond

while.cond:
  %i.cond = load i32, i32* %i.addr, align 4
  %continue = icmp sle i32 %i.cond, %n
  br i1 %continue, label %if.cond, label %while.end

if.cond:
  %i.parity = load i32, i32* %i.addr, align 4
  %remainder = srem i32 %i.parity, 2
  %is.even = icmp eq i32 %remainder, 0
  br i1 %is.even, label %if.then, label %if.else

if.then:
  %sum.even = load i32, i32* %sum.addr, align 4
  %i.even = load i32, i32* %i.addr, align 4
  %twice.i = mul nsw i32 %i.even, 2
  %sum.even.next = add nsw i32 %sum.even, %twice.i
  store i32 %sum.even.next, i32* %sum.addr, align 4
  br label %if.end

if.else:
  %sum.odd = load i32, i32* %sum.addr, align 4
  %i.odd = load i32, i32* %i.addr, align 4
  %sum.odd.next = add nsw i32 %sum.odd, %i.odd
  store i32 %sum.odd.next, i32* %sum.addr, align 4
  br label %if.end

if.end:
  %i.current = load i32, i32* %i.addr, align 4
  %i.next = add nsw i32 %i.current, 1
  store i32 %i.next, i32* %i.addr, align 4
  br label %while.cond

while.end:
  %sum.result = load i32, i32* %sum.addr, align 4
  ret i32 %sum.result
}

define i32 @main() {
entry:
  %n = call i32 @getint()
  %result = call i32 @calc(i32 %n)
  call void @putint(i32 %result)
  ret i32 0
}
