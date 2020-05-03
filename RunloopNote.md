
## Mode
大致结构如下
```
struct __CFRunLoopMode {
    CFStringRef _name;            // Mode Name, 例如 @"kCFRunLoopDefaultMode"
    CFMutableSetRef _sources0;    // Set
    CFMutableSetRef _sources1;    // Set
    CFMutableArrayRef _observers; // Array
    CFMutableArrayRef _timers;    // Array
    ...
};
 
struct __CFRunLoop {
    CFMutableSetRef _commonModes;     // Set
    CFMutableSetRef _commonModeItems; // Set<Source/Observer/Timer>
    CFRunLoopModeRef _currentMode;    // Current Runloop Mode
    CFMutableSetRef _modes;           // Set
    ...
};
```

## 疑问
1. source0和source1的区别
    - 两个都是runloop可以处理的事件源
    - source0事件源无法唤醒runloop工作，需要主动执行wakeup相关方法进行唤醒
    - source1是系统底层基于端口消息传递模型的事件源，可以主动唤醒runloop进行工作
2. 有说runloop循环中，`__CFRunLoopDoBlocks()`方法是**处理非延迟的主线程调用**，是否可以理解为，didfinish中那些同步代码就是在这一步执行的
    - 不可以这样理解
    - 根据目前看的资料，`__CFRunLoopDoBlocks()`处理的是**非延迟的NSObject PerformSelector立即调用，dispatch_after立即调用，block回调**
    - 那像`AppDelegate`的`didFinishxxx`方法中的逻辑，通过断点可以看出其实是底层由`source0`的事件源触发的，所以大胆猜测，开发者写的这些同步代码，都是通过source0、source1触发runloop执行的
   - 而为什么单单有个`__CFRunLoopDoBlocks()`方法呢？我想是因为OC中的Block结构上可能比较特殊，内存上大多数情况下要拷贝到堆上，由系统管理它的内存，所以在runloop里，对于同步的block，也基于了特殊处理逻辑

3. 怎样理解kCFRunLoopCommonModes与其他Mode的不同
    - Runlop必须且仅能运行在一个mode下
    - 一个mode下可以接收多个source、observer、timer事件源
    - 一个Runloop有一个commonModels数组，存放被标记为"common"的Mode，放到这个数组中的mode都是"common"了
    - 一个Runloop还有一个commonModeItems数组，用于存放哪些被标记为"common"的事件源
    - 通过源码可知，当给kCFRunLoopCommonModes添加事件源时，事件源被加入到commonModeItems中，同时，所有不被标记为"common"的mode的事件源中也会加入commonModeItems中所有的事件源
    - 同样，当通过CFRunLoopAddCommonMode添加common mode时，刚加入的mode的事件源也不加入commonModeItems
    - 所以本质上，kCFRunLoopCommonModes并非某个具体mode，而是为了更容易实现common mode的逻辑而添加的

## 参考

- [iOS 事件处理机制与图像渲染过程](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ==&mid=400417748&idx=1&sn=0c5f6747dd192c5a0eea32bb4650c160&3rd=MzA3MDU4NTYzMw==&scene=6#rd)
- [深入理解RunLoop](https://blog.ibireme.com/2015/05/18/runloop/)
- [源码学习笔记](https://github.com/hawk0620/blog/blob/master/posts/runloop-study-note.md)
- [CFRunloop源码](https://opensource.apple.com/source/CF/CF-855.17/CFRunLoop.c)
- [深入浅出 RunLoop（一）：初识](https://juejin.im/post/5e579f2c518825493c7b5a04)
- [RunLoop的前世今生](https://juejin.im/post/5a3095435188250a5719b7b2)
- [Runloop与performSelector](https://juejin.im/post/5c70b391e51d451646267db1)
