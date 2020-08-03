# iOS中的锁

### 自旋锁

`OSSpinLock`

`atomic`

`os_unfair_lock_t`


- 特点是，当尝试获取锁失败时，线程并不会进入休眠，而是循环等待
- 好处是，当锁释放时可以理解获取锁并执行逻辑，相比线程状态之间的切换要快些
- 这对于需要短时间等待的情况很高效
- iOS 10之后解决了`OSSpinLock`的不安全问题，使用`os_unfair_lock_t`，atomic的实现底层就依赖它

#### 优先级翻转

正常情况下高优先级的任务总是优先于低优先级任务执行。
如果一个高优先级的任务变得依赖于低优先级的任务（比如低优先级任务持有了高优先级需要的临界资源），导致低优先级任务先执行，这就叫优先级翻转

- 优先级翻转跟自旋锁没有关系
- 不使用自旋锁时也可能出现优先级翻转问题
- iOS的`OSSpinLock`，在优先级翻转的情况下，可能导致低优先级对高优先级依赖的资源一直没有释放，因为高优先级使用的自旋锁一直占用CPU
- iOS系统中也会自动处理优先级翻转问题，具体可参考本文最后的参考文章--**《Prioritize Work with Quality of Service Classes》**

> 该部分是我对优先级翻转的理解，在查iOS自旋锁不安全的问题时，总会看到是由于自旋锁而导致了优先级翻转。我的理解则不同，优先级翻转不管用什么锁都是有可能出现优先级翻转问题，自旋锁的问题在于高优先级任务占用CPU，导致长时间不响应

### 递归锁

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

### 参考

- [谈 iOS 的锁](http://zenonhuang.me/2018/03/08/technology/2018-03-01-LockForiOS/)
- [Prioritize Work with Quality of Service Classes](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39)

