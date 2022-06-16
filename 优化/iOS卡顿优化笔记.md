# iOS卡顿优化笔记

- 使用Instrument设置16ms采样率来查看耗时操作

## 导致卡顿的原因

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios_screen_display_cpu_gpu.png?raw=true)

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios_frame_drop.png?raw=true)

- 绘制的过程（下面讲）
- 线程开的太多，消耗过多系统资源，导致CPU过载

### 绘制的过程

- 准备好视图，runloop在beforewait时机通过CoreAnimation提交进行布局页面更新任务
- CPU中进行layout的解析、frame的计算、图片解码、文本绘制
- 如果有`drawRect`代码还要开辟额外内存空间进行绘制，这叫CPU离屏渲染
- 提交给GPU后，进行合成、渲染，放入帧缓冲区，等待展示

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

## 监控卡顿

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

## 小技巧

- 可以通过`CADisplayLink`来计算FPS
- 因为`CADisplayLink`的重复周期就是每一帧刷新的时机

## 疑问
1. CADisplayLink的原理是什么，和runloop有什么关联
2. 什么是异步绘制
3. 大佬文章中说的，显示系统vsync通过与runloop交互来完成UI更新和动画更新，没说清楚

## 参考
- [天罗地网？ iOS卡顿监控实战（开源）](https://juejin.im/post/5db65fe0e51d452a1e58f37c)