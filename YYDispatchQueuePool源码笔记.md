# YYDispatchQueuePool源码笔记

工具作者在实际开发中，由于开了很多线程去做异步绘制、下载等工作，而且有的线程可能因为资源锁等待的原因，可能导致开更多的线程。当线程过多时，线程占用了过多资源，可能导致主线程受影响，出现卡顿问题

而iOS框架中有最大并发数概念的目测只有`NSOpeartionQueue`了，但GCD的代码却无法使用该特性

于是写了该工具，可以方便地创建一个`队列池`，类似于线程池的概念，可以避免开辟线程过多的问题

## Feature
- 内部使用串行队列来管理线程
- 最多串行队列数不超过32个，所以线程数也不会超过该值
- 提供两种获取队列池的方式
	- 全局方法，获取一个队列池
	- 自己创建一个队列池管理类，管理串行队列

## 原理

核心工作就两步骤

1. 根据qos、当前CPU情况以及所需的输入创建多个串行队列
	- 队列信息存储在`YYDispatchContext`结构体中
2. 结构体中有一个`counter`，每次调用`YYDispatchQueueGetForQOS`，`counter`加一，同时使用`counter % queueCount`作为下标来轮询地到context中获取一个queue

`YYDispatchContext`结构体如下

```
typedef struct {
    const char *name;
    void **queues;
    uint32_t queueCount;
    int32_t counter;
} YYDispatchContext;
```

## 参考
- [YYDispatchQueuePool](https://github.com/ibireme/YYDispatchQueuePool)
- [iOS 保持界面流畅的技巧](https://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/)