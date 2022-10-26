# Synchronization Tools in iOS


多线程中解决共享资源竞争的同步工具有lock, condition, atomic operation, etc.

锁是解决多线程安全问题的一个常见手段

## 自旋锁

`OSSpinLock`

- 特点是，当尝试获取锁失败时，线程并不会进入休眠，而是循环等待
- 好处是，当锁释放时可以理解获取锁并执行逻辑，相比线程状态之间的切换要快些。这对于需要短时间等待的情况很高效
- iOS 10之后，`OSSpinLock`被标记为废弃了。原因在下面优先级反转中有介绍

### 优先级反转

关于优先级反转，参考资料中《优先级反转那点事儿》讲的比较清晰。此处直接贴过来

![](https://pic3.zhimg.com/80/v2-39f5dabe2fdc9d411f654ab2fa86e94a_1440w.jpg)

- 线程A在一个比较低的优先级上工作, 假设是10吧。然后在时间点T1的时候，线程A锁定了一把互斥锁，并开始操作互斥数据。
- 这时有个高优线级线程C（比如优先级20）在时间点T2被唤醒，它也也需要操作互斥数据。当它加锁互斥锁时，因为互斥锁在T1被线程A锁掉了，所以线程C放弃CPU进入阻塞状态，而线程A得以占据CPU，继续执行。
- 事情到这一步还是正确的，虽然优先级10的A线程看上去抢了优先级20的C线程的时间，但因为程序逻辑，C确实需要退出CPU等完成互斥数据操作后，才能获得CPU。
- 但是，假设我们有个线程B在优先级15上，在T3时间点上醒了过来，因为他比当前执行的线程A优先级高，所以它会立即抢占CPU。而线程A被迫进入READY状态等待。
- 一直到时间点T4，线程B放弃CPU，这时优先级10的线程A是唯一READY线程，它再次占据CPU继续执行，最后在T5解锁了互斥锁。
- 在T5，线程A解锁的瞬间，线程C立即获取互斥锁，并在优先级20上等待CPU。因为它比线程A的优先级高，系统立刻调度线程C执行，而线程A再次进入READY状态。

上面这个时序里，线程B从T3到T4占据CPU运行的行为，就是事实上的优先级反转。一个优先级15的线程B，通过压制优线级10的线程A，而事实上导致高优先级线程C无法正确得到CPU。这段时间是不可控的，因为线程B可以长时间占据CPU（即使轮转时间片到时，线程A和B都处于可执行态，但是因为B的优先级高，它依然可以占据CPU），其结果就是高优先级线程C可能长时间无法得到 CPU。


### 优先级反转 vs 自旋锁

- 优先级反转问题的出现跟自旋锁没有关系
- 不使用自旋锁时也可能出现优先级反转问题。只要是线程或任务有多个优先级，理论上就可能有反转问题
- 操作系统在优先级反转发生时通常都会有自动的解决方案，比如提高低优先级线程的优先级等
- 在使用iOS中的`OSSpinLock`时
	- 由于这种锁不会记录持有它的线程信息，所有当发生优先级反转时，系统找不到低优先级的线程，可能因此无法通过提高优先级解决优先级反转问题
	- 再加上，高优先级线程使用自旋锁进行轮训等待锁时在一直占用CPU时间片，使得低优先级线程拿到时间片的概率降低
- 总结下来是
	- 优先级反转问题的出现跟自旋锁没有关系
	- 但一旦出现优先级反转问题，自旋锁会让优先级反转问题不容易解决，甚至造成更严重的线程等待问题


### atomic和os_unfair_lock

- OSSpinLock被废弃后，官方建议使用os_unfair_lock代替；
- os_unfair_lock其实是互斥锁（参考资料中有提到）
- 在老版本中，atomic内部也是用自旋锁实现的，但后续也改成互斥锁了


### 疑惑
1. iOS系统中优先级反转问题是如何解决的？--参考资料中的苹果官方文档有提到


## 递归锁

递归锁允许同一个线程多次获取锁，但当前线程获取锁之后，其他线程就无法获得该锁了

- `@synchronized(obj)`
- `pthread_mutex`
	- `@synchronized底层使用pthread_mutex`
- `NSRecursiveLock`

```
- (void)testLock{
  if(_count>0){ 
     @synchronized (obj) {
        _count = _count - 1;
        [self testLock];
      }
    }
}
```

- 上面使用递归锁，被锁住的代码递归的执行，不会导致死锁
- 非递归锁则会导致死锁
- `@synchronized(obj)`使用时要注意obj的地址不能是无效的，而且运行过程中不能改变

### 非递归锁

`NSLock`

### 其他

- `dispatch_semerphore`信号量值为1时也可以当做锁来用

## 疑问
1. iOS中锁是如何分类的，每种的特点、限制和应用场景是什么
2. NSConditionLock、NSCondition、NSLock、NSRecursiveLock

### 参考
- [About Threaded Programming](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/AboutThreads/AboutThreads.html#//apple_ref/doc/uid/10000057i-CH6-SW2)
- [谈 iOS 的锁](http://zenonhuang.me/2018/03/08/technology/2018-03-01-LockForiOS/)
- [优先级反转那点事儿](https://zhuanlan.zhihu.com/p/146132061)
- [不再安全的 OSSpinLock](https://blog.ibireme.com/2016/01/16/spinlock_is_unsafe_in_ios/)
- [dispatch_semaphore 会造成优先级反转，慎用！](https://blog.51cto.com/u_15064655/2573045)
- [Prioritize Work with Quality of Service Classes](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39)
- [ObjC 多线程简析（二）- os_unfair_lock的类型和自旋锁与互斥锁的比较](https://juejin.cn/post/6844903778328510471)
- [iOS——GCD的死锁案例](https://cloud.tencent.com/developer/article/1198721)
	- 里面有几个死锁的demo
- [Thread Safety in Swift](https://swiftrocks.com/thread-safety-in-swift)