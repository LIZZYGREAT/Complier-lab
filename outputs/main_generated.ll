define dso_local i32 @main() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 0, i32* %1, align 4
  %4 = call i32 @getint()
  store i32 %4, i32* %2, align 4
  %5 = load i32, i32* %2, align 4
  %6 = call i32 @calc(i32 noundef %5)
  store i32 %6, i32* %3, align 4
  %7 = load i32, i32* %3, align 4
  call void @putint(i32 noundef %7)
  ret i32 0
}
