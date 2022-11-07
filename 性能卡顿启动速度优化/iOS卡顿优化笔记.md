# iOS卡顿优化笔记

## 导致卡顿的原因

> 关于显示器渲染、VSync信号，以及与runloop的关系等问题，鉴于大佬讲的已然很清楚了，我就不废话了，直接将原文贴到此处

首先从过去的 CRT 显示器原理说起。CRT 的电子枪按照上面方式，从上到下一行行扫描，扫描完成后显示器就呈现一帧画面，随后电子枪回到初始位置继续下一次扫描。为了把显示器的显示过程和系统的视频控制器进行同步，显示器（或者其他硬件）会用硬件时钟产生一系列的定时信号。当电子枪换到新的一行，准备进行扫描时，显示器会发出一个水平同步信号（horizonal synchronization），简称 HSync；而当一帧画面绘制完成后，电子枪回复到原位，准备画下一帧前，显示器会发出一个垂直同步信号（vertical synchronization），简称 VSync。显示器通常以固定频率进行刷新，这个刷新率就是 VSync 信号产生的频率。尽管现在的设备大都是液晶显示屏了，但原理仍然没有变。

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios_screen_display_cpu_gpu.png?raw=true)

通常来说，计算机系统中 CPU、GPU、显示器是以上面这种方式协同工作的。CPU 计算好显示内容提交到 GPU，GPU 渲染完成后将渲染结果放入帧缓冲区，随后视频控制器会按照 VSync 信号逐行读取帧缓冲区的数据，经过可能的数模转换传递给显示器显示。

在最简单的情况下，帧缓冲区只有一个，这时帧缓冲区的读取和刷新都都会有比较大的效率问题。为了解决效率问题，显示系统通常会引入两个缓冲区，即双缓冲机制。在这种情况下，GPU 会预先渲染好一帧放入一个缓冲区内，让视频控制器读取，当下一帧渲染好后，GPU 会直接把视频控制器的指针指向第二个缓冲器。如此一来效率会有很大的提升。

双缓冲虽然能解决效率问题，但会引入一个新的问题。当视频控制器还未读取完成时，即屏幕内容刚显示一半时，GPU 将新的一帧内容提交到帧缓冲区并把两个缓冲区进行交换后，视频控制器就会把新的一帧数据的下半段显示到屏幕上，造成画面撕裂现象

为了解决这个问题，GPU 通常有一个机制叫做垂直同步（简写也是 V-Sync），当开启垂直同步后，GPU 会等待显示器的 VSync 信号发出后，才进行新的一帧渲染和缓冲区更新。这样能解决画面撕裂现象，也增加了画面流畅度，但需要消费更多的计算资源，也会带来部分延迟。

那么目前主流的移动设备是什么情况呢？从网上查到的资料可以知道，iOS 设备会始终使用双缓存，并开启垂直同步。而安卓设备直到 4.1 版本，Google 才开始引入这种机制，目前安卓系统是三缓存+垂直同步。

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios_frame_drop.png?raw=true)

在 VSync 信号到来后，系统图形服务会通过 CADisplayLink 等机制通知 App，App 主线程开始在 CPU 中计算显示内容，比如视图的创建、布局计算、图片解码、文本绘制等。随后 CPU 会将计算好的内容提交到 GPU 去，由 GPU 进行变换、合成、渲染。随后 GPU 会把渲染结果提交到帧缓冲区去，等待下一次 VSync 信号到来时显示到屏幕上。由于垂直同步的机制，如果在一个 VSync 时间内，CPU 或者 GPU 没有完成内容提交，则那一帧就会被丢弃，等待下一次机会再显示，而这时显示屏会保留之前的内容不变。这就是界面卡顿的原因。

### VSync与runloop如何协同

> 该部分理论很重要，仍然贴出大佬的原文

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios_vsync_runloop.png?raw=true)

iOS 的显示系统是由 VSync 信号驱动的，VSync 信号由硬件时钟生成，每秒钟发出 60 次（这个值取决设备硬件，比如 iPhone 真机上通常是 59.97）。iOS 图形服务接收到 VSync 信号后，会通过 IPC 通知到 App 内。App 的 Runloop 在启动后会注册对应的 CFRunLoopSource 通过 mach_port 接收传过来的时钟信号通知，随后 Source 的回调会驱动整个 App 的动画与显示。

Core Animation 在 RunLoop 中注册了一个 Observer，监听了 BeforeWaiting 和 Exit 事件。这个 Observer 的优先级是 2000000，低于常见的其他 Observer。当一个触摸事件到来时，RunLoop 被唤醒，App 中的代码会执行一些操作，比如创建和调整视图层级、设置 UIView 的 frame、修改 CALayer 的透明度、为视图添加一个动画；这些操作最终都会被 CALayer 捕获，并通过 CATransaction 提交到一个中间状态去（CATransaction 的文档略有提到这些内容，但并不完整）。当上面所有操作结束后，RunLoop 即将进入休眠（或者退出）时，关注该事件的 Observer 都会得到通知。这时 CA 注册的那个 Observer 就会在回调中，把所有的中间状态合并提交到 GPU 去显示；如果此处有动画，CA 会通过 DisplayLink 等机制多次触发相关流程。

### CPU卡顿 vs GPU卡顿

从上面的VSync号和CPU、GPU任务的图中能看出来，以下三种情况都会导致掉帧：

- CPU任务时间超过两个VSync时间间隔
- GPU任务超过时间间隔
- CPU+GPU任务超过时间间隔

前两种情况就是此处要说的CPU卡顿和GPU卡顿

下图是京东卡顿治理中的例子，CPU的fps很正常，GPU的fps却很低，所以整体仍是掉帧甚至是卡顿明显的

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/jd_cpustuck_gpustuck.gif?raw=true)

为啥分开统计呢？

因为没办法一起统计啊，iOS的渲染流程决定的

大致是这样的流程：

1. CPU负责计算各种布局、自定义绘制等工作，完成后将渲染任务通过CoreAnimation提交给GPU。注意这些工作是在CPU侧，也是在主线程中完成
2. 提交给GPU后，GPU负责图层的合成等计算，再最终由显示器显示。该部分跟主线程和CPU就没关系了

## 如何解决卡顿

### CPU方面
- 减少视图的创建销毁，改用layer
- 布局使用frame
- 文本计算，可以放入子线程进行预排版
- 图片解码放入子线程
- 自定义绘制代码放入子线程，即异步绘制

### GPU方面
- 减少离屏渲染
- 避免过大图片，大纹理比较占用显存

### Instrument调试

官方关于优化卡顿，提升用户体验方面有专门的内容，建议多参考

建议参考[Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness)

## 监控卡顿

### 衡量卡顿

#### 字节
下图为字节监控卡顿时所采用的标准，供参考

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/stuck_benchmark.png?raw=true)

#### 京东

京东商城的卡顿监控结合与具体的业务属性提出了卡顿率的概念

`页面卡顿率=该页面存在卡顿的上报数之和/页面总上报量`

### 基于runloop

想要基于runloop做到卡顿监控，则必须了解runloop的循环体中都做了哪些事情

#### 思路一

- 大部分工作在source0触发的
- 所以我们开一个线程，等待接收主线程runloop的通知
- 如果等了很久才收到一个通知，说明runloop某一步耗时太多，就可能是卡顿了
- 我所看到的源码中，是只发现收到的`beforeSource`和`beforeWait`通知有超时时才认为有可能卡顿
- 这里面可以使用信号量来实现超时等待机制

#### 思路二

- 这是基于timer实现的，当然也是要在子线程中进行
- 该思路也是假定多数耗时操作发生在source0中
- 监听两个状态，beforesource0和beforewait
- 我们记录两次beforesource0之间的时间，时间太久就卡顿
- 之所以监听beforewait，当进入休眠时可能会导致两次source0时间过长，误以为卡顿，所以做些数据清除工作，而且一旦进入休眠状态子线程

### ping主线程

- 这个思路更加简洁
- 仍然开一个子线程，子线程中while一直循环
- 有一个flag，将flag设置为false，表示在子线程中运行
- 然后dispatch到主线程中，将flag设置为true
- 再等待一个时间后，去检测flag，如果还是true说明卡顿了

## 卡顿监控工业上的应用

大部分企业级（国内）的卡顿监控策略都是基于runloop的状态（通知）

另外，真实商业级别的实践中，远比本文提到的理论要复杂。比如参考文档中微信、字节在已有卡顿监控基础上做了很多提升性能、提高卡顿识别准确率的优化

根据参考文档中不同公司的卡顿方案分享来看，京东的卡顿监控策略与业务关联更紧密，值得深入研究

### 参考
- [字节跳动 iOS Heimdallr 卡死卡顿监控方案与优化之路](https://blog.51cto.com/u_15204236/4960735)
- [Matrix-iOS 卡顿监控](https://cloud.tencent.com/developer/article/1427933)
- [卡顿率降低50%！京东商城APP卡顿监控及优化实践](https://mp.weixin.qq.com/s/aJeAUAjcKOMvznDMGj2UUA)
- [iOS卡顿监控实施与性能调优-得物技术](https://mp.weixin.qq.com/s/Rs1lvFdQlXK6k9jkXHAhHQ)
	- 很多内容与微信的卡顿监控相似

## Q&A

### CADisplayLink

#### CADisplayLink原理是什么，为何必须关联runloop使用

#### CADisplay实现的FPS为什么只能监控CPU卡顿

### others
2. 什么是异步绘制
4. 有没有直观的方法来查看或验证UI或动画的布局、提交、绘制过程？
5. 仅通过监控FPS，能否准确捕捉到卡顿
6. 实际工业应用场景中在使用的卡顿监控方案是怎样的
	- 或者说不同卡顿方案的效果是怎样的
	- 如何评价卡顿方案的好坏
	- 现阶段市面上的卡顿方案是否好用，存在什么问题
7. 很多主线程中的操作耗时都要超过16ms，但怎么感觉不出卡顿？

## 备忘

### CADisplayLink官方建议的fps方法有歧义

`CADisplayLink`官方文档中给出了计算fps的方法

```
// Calculate the actual frame rate.
double actualFramesPerSecond = 1 / (displaylink.targetTimestamp - displaylink.timestamp);
```
经过实际测试，该值始终都保持60左右，即使在主线程中故意加入些特别耗时的逻辑

所以猜测，官方此处给的fps，和我们平常理解的有些出入

## 参考
- [天罗地网？ iOS卡顿监控实战（开源）](https://juejin.im/post/5db65fe0e51d452a1e58f37c)
- [卡顿产生的原因和解决方案](https://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/)
- [Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness)
- [iOS Core Animation: Advanced Techniques](https://www.oreilly.com/library/view/ios-core-animation/9780133440744/)
- [Tencent/matrix](https://github.com/Tencent/matrix)