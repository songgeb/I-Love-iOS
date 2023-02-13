# Compiler error: "initializer element is not a compile-time constant"

## 问题与解析

```
// 下一句编译不过
// 错误为：initializer element is not a compile-time constant
NSMutableDictionary *dict = [NSMutableDictionary dictionary];

@implementation SomeClass
@end
```

我们从这个错误提示本身入手：

- 什么是`initializer element`
- 什么是`compile-time constant`


我们上面这句代码做的事情是初始化一个变量的过程，initializer element就是` [NSMutableDictionary dictionary]`

`compile-time constant`，我第一反应是不知道什么意思


## 参考

- [Initializer element is not a compile-time constant using C](https://stackoverflow.com/questions/65774807/initializer-element-is-not-a-compile-time-constant-using-c)
- [stack overflow-Compiler error: "initializer element is not a compile-time constant"](https://stackoverflow.com/questions/6143107/compiler-error-initializer-element-is-not-a-compile-time-constant)
- [Constant Expressions](https://public.support.unisys.com/aseries/docs/ClearPath-MCP-20.0/86002268-209/section-000066746.html)
- [What is a compile time constant?](https://coderanch.com/t/454384/java/compile-time-constant)