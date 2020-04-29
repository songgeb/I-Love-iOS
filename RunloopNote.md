## 疑问
1. source0和source1的区别
2. 有说runloop循环中，`__CFRunLoopDoBlocks()`方法是**处理非延迟的主线程调用**，是否可以理解为，didfinish中那些同步代码就是在这一步执行的
## 参考

- [CFRunloop源码](https://opensource.apple.com/source/CF/CF-855.17/CFRunLoop.c)
- [深入浅出 RunLoop（一）：初识](https://juejin.im/post/5e579f2c518825493c7b5a04)
