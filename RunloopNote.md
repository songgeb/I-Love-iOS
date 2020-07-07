# Runloop笔记
> 深入理解代替单纯记忆

- 它是一种事件机制，通过一种while循环的结构，实现有工作时线程就工作，没工作时线程就进入休眠，等待被事件触发的状态的机制
- 每个线程都有一个Runloop
- 主线程的Runloop会随iOS程序启动时自动启动，其他线程则不会启动Runloop
- **事件源**会唤醒线程的休眠状态从而,继续工作
- **事件源**有`Input Source`、`Timer`两类
- 所以一个RunLoop只有在有事件源的情况下才有意义
- 事件源的管理在RunLoop Mode中
- 还可以给RunLoop添加观察者，用于监听事件循环的不同阶段

> Thread和RunLoop的关系要搞清楚，RunLoop是由`RunLoop`等一些列对象组成的一种让线程处理任务更灵活的机制。Thread不是一定要有RunLoop才行，没有也能执行任务

## Runloop Mode

- RunLoop必须且仅能运行在一个Mode上
- Mode信息中包含了当前RunLoop能够处理的事件源和观察者
- 有不同的Mode，用于不同的任务场景

根据`CFRunLoop.c`源码，RunLoop Mode和RunLoop对象大致结构如下

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

### CommonMode

- 一个mode下可以接收多个source、observer、timer事件源
- 一个Runloop有一个commonModels数组，存放被标记为"common"的Mode，放到这个数组中的mode都是"common"了
- 一个Runloop还有一个commonModeItems数组，用于存放那些被标记为"common"的Model关联的事件源
- 通过源码可知，当给common models添加事件源时，事件源被加入到commonModeItems中，同时，所有被标记为"common"的mode的事件源中也会加入该事件源
  
    	```
    	RunLoop.current.add(timer, forMode: .common)
    	// 当执行上面面这句话时，等同于下面的伪代码
    	// runloop.commonModeItems.add(timer)
    	// for model in runloop.commonModes { model._timers.add(timer) }
    	```	
  
- 同样，当通过CFRunLoopAddCommonMode将一个model标记为common mode时，runloop的commonModes数组中会加入该model，commonModeItems中所有的事件源也会同步到新加入的model中
- 所以本质上，kCFRunLoopCommonModes并非某个具体mode，而是为了更容易实现common mode的逻辑而添加的

### 其他Mode
- `Default`、`Tracking`
- iOS应用默认运行在`Default`模式下
- tableview、collectionview滚动时处于`Tracking`模式

## Input Source

以下三种类型的事件源都属于Input Source

### Port-Based Sources

### Custom Input Sources
### Perform Selector Sources

## Timer Source

- `Timer`对象的使用表示该事件源
- `CFRunLoopTimer`是`CoreFoundation`框架下对应的对象
- `Timer`本质上是`CFRunLoopTimer`的扩展
- 由于`Timer`是基于RunLoop，添加`Timer`后，RunLoop会持有`Timer`
- 非重复的`Timer`在执行完一次事件后，就被从RunLoop中remove掉了
	- 所以在自定义子线程的RunLoop中只添加一个非重复`Timer`事件源，`Timer`任务结束后RunLoop就自动退出了，线程也就随之结束了

### Schedule
- `Timer`工作的实质是，在为预定义的时间点注册事件源，据此触发RunLoop执行`Timer`的任务
- 重复的`Timer`就是自动进行重复的注册
- `Timer`无法做到完全精确，因为RunLoop循环中可能处理一些比较耗时的任务，会使得无法再预先`schedule`的时间点执行，而导致延后
- `schedule`既然是预先定义好要触发的时间点，比如从A时间点开始触发，每5秒执行一次，即使因为其他耗时任务，在A时间点到来时任务未执行完（来到了时间点B），当任务执行完后`Timer`事件会被触发第一次，而下一次回调的触发时间点仍是A+5，而不是B+5
- 但是，当重复执行的`Timer`的时间点错过一次或多次后，`Timer`会在下次RunLoop执行到`Timer`事件时进行一次调用，更重要的是，后面再进行时间点注册时则按照该次补偿时间点，配合相同的时间间隔进行调度，即`reschedule`
	- 用上面的例子就是，当耗时任务太耗时以至于到了A+5的时间点时还没有执行第一次`Timer`事件回调
	- 那耗时任务结束后，执行`Timer`事件回调，此时为时间点C，那下次再执行`Timer`事件就是C+5时间点了

### Timer Tolerance

`Timer`可以设置一个`tolerance`容差，表示允许真正的`firetime`落在`scheduled firetime`到`scheduled firetime + tlerance`之间

- 设置该属性有助于系统节省性能
- 官方建议对于重复`Timer`，该值可以设置为`interval`的`%10`
- 系统也可能会根据需要修改实际的容差值

### Timer 与 Dispatch Source Timer

- Timer依赖于RunLoop运行，而DispatchSourceTimer不是
- 两者都无法做到完全精确

## Observer

RunLoop提供了API用以监听RunLoop的不同阶段

```
switch activity {
case .entry:
	print("即将进入RunLoop循环")
case .beforeTimers:
	print("处理timer事件之前")
case .beforeSources:
  	print("处理input source事件之前")
case .beforeWaiting:
	print("马上进入休眠状态")
case .afterWaiting:
	print("被事件唤醒，还未处理事件")
case .exit:
	print("退出RunLoop循环")
``` 

## RunLoop应用

什么情况下可以使用RunLoop？官方的建议是：

- 当需要开辟子线程来处理**互动性(interactivity)**比较强的任务时
- 任务不一定耗时长，如果只是一个耗时长的一次性任务，完全不需要开启RunLoop，线程里执行一遍就ok了
- 哪些算互动性强呢？比如线程中用到了timer、inputsource或者要处理一些周期性的任务

### `RunLoop`配置

#### 启动
- `run(mode:before:)`，给定一个mode和超时时间点，运行到时即结束
- `run()`方法本质上是做了一个无限循环，循环执行`run(mode:before:)`

官方的例子中看到了这样的代码

```
// in secondary thread
// add a repeat timer
do {
	runloop.run(mode:before:)
} while !shouldExit

// clear data
// balabala
```

- 当时有一个疑问，如果执行该句话，那当前线程不就在疯狂执行while循环了吗，哪里还有机会处理timer事件？
- 经过测试，其实不是的，while循环第一次执行，runloop开启之后，此时有重复timer事件源，runloop所在的线程就会进入`执行timer->休眠->执行timer`的RunLoop循环。线程根本不会执行到`while !shouldExit`位置
- 如果不是重复timer会怎样？RunLoop会执行一次timer回调，然后RunLoop没有其他事件源，退出。再执行`while !shouldExit`语句

#### 停止

1. 使用指定超时时间的run方法，超时后自动停止
2. 如果是`CoreFoundation`语境下用`CFRunLoopStop`来停止RunLoop

> 还有一种方法，remove掉InputSource和timer。官方不太建议，主要是因为担心有些情况RunLoop中被第三方添加未知的InputSource、timer。经过测试，如果完全自己添加删除事件源的话，可以停止RunLoop   

## CFRunLoop.c

关于RunLoop的中文文章挺多的，多数是参考了[深入理解RunLoop](https://blog.ibireme.com/2015/05/18/runloop/)

由于这些源码并非公开给开发者的API，将来可能有变化。所以根据源码习得的内容写在该小节，不能保证未来的正确性

1. iOS界面的刷新底层依赖`CAAnimation`，同时刷新的工作也是在RunLoop中执行的。具体的时机是在**RunLoop进入休眠之前，对应通知的`beforeWaiting`**
2. source0和source1的区别
    - 两个都是runloop可以处理的事件源
    - source0事件源无法唤醒runloop工作，需要主动执行wakeup相关方法进行唤醒
    - source1是系统底层基于端口消息传递模型的事件源，可以主动唤醒runloop进行工作
3. 有说runloop循环中，`__CFRunLoopDoBlocks()`方法是**处理非延迟的主线程调用**，是否可以理解为，didfinish中那些同步代码就是在这一步执行的
    - 不可以这样理解
    - 根据目前看的资料，`__CFRunLoopDoBlocks()`处理的是**非延迟的NSObject PerformSelector立即调用，dispatch_after立即调用，block回调**
    - 那像`AppDelegate`的`didFinishxxx`方法中的逻辑，通过断点可以看出其实是底层由`source0`的事件源触发的，所以大胆猜测，开发者写的这些同步代码，都是通过source0、source1触发runloop执行的
   - 而为什么单单有个`__CFRunLoopDoBlocks()`方法呢？我想是因为OC中的Block结构上可能比较特殊，内存上大多数情况下要拷贝到堆上，由系统管理它的内存，所以在runloop里，对于同步的block，也基于了特殊处理逻辑

## 参考

- [Run Loops](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html)
- [iOS 事件处理机制与图像渲染过程](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ==&mid=400417748&idx=1&sn=0c5f6747dd192c5a0eea32bb4650c160&3rd=MzA3MDU4NTYzMw==&scene=6#rd)
- [深入理解RunLoop](https://blog.ibireme.com/2015/05/18/runloop/)
- [源码学习笔记](https://github.com/hawk0620/blog/blob/master/posts/runloop-study-note.md)
- [CFRunloop源码](https://opensource.apple.com/source/CF/CF-855.17/CFRunLoop.c)
- [深入浅出 RunLoop（一）：初识](https://juejin.im/post/5e579f2c518825493c7b5a04)
- [RunLoop的前世今生](https://juejin.im/post/5a3095435188250a5719b7b2)
- [Runloop与performSelector](https://juejin.im/post/5c70b391e51d451646267db1)
