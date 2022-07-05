# Autoreleasepool in iOS

之所以要写点关于Autoreleasepool的内容，其实来源于一次面试

> 面试官：说一下Autoreleasepool的底层实现

> 我：双向链表，每个节点存储对象引用，balabala

> 面试官：每个节点占多大内存？

> 我：。。。

Autoreleasepool的实现在[NSObject.mm](https://opensource.apple.com/source/objc4/objc4-532/runtime/NSObject.mm.auto.html)中，是开源的

但个人由于C++基础不好，且并无太大兴趣详细研究，于是认为：

- 了解Autoreleasepool的使用场景和工作原理对日常工作更有帮助
- 深挖Apple为何使用双链表、哨兵、4096byte的page来设计Autoreleasepool，比只是单纯知道这些内容更优意义，这考察的是架构、数据结构的能力。但Apple并没说为何这样设计

## 工作原理

站在高一点的角度来看Autoreleasepool，其实它只是iOS中内存管理中的组成部分之一，没有它有些工作是无法正常完成的

简单回顾iOS内存管理机制：关键就是Reference Count，大于0就不释放，等于0就释放

有的情况下，单靠系统提供的retain、release操作无法满足需要，典型案例是：通过一个方法获取一个对象

```
- (NSObject *)objectWithXXX:(params) {
	NSObject *obj = [NSObject new];
	return obj;
}
```

- 通过这种方式获取到的对象，开发者不知道是否应该由自己来控制该对象的内存（MRR时代），也不知道这个方法内部到底有没有retain过这个对象
- 苹果官方早就想到这一点，所以就做好了约定了：alloc/init、copy产生的对象，其内部是做过retain操作的，需要调用者来负责释放掉它；其他方法产生的对象，调用者只管使用就好，不需要主动释放（延迟释放，即由Autoreleasepool来释放）

具体的释放规则很简洁：
- 给对象发送autorelease消息时，加入到Autoreleasepool中
- Autoreasepool销毁时，对其中的所有对象发送release消息释放对象内存

## 应用场景
当下的iOS编程领域，需要开发者主动创建Autoreleasepool的时机并不多，因为系统会在合适时机自动创建，如：

- runloop开始时会创建，每次loop结束时会销毁。为的就是回收过程中产生的临时对象

除此之外，需要开发者主动使用的经典的应用场景就是`Reduce Peak Memory Footprint`

拿官方例子来说明下

```
for (NSURL *url in urls) {
 
    @autoreleasepool {
        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfURL:url
                                         encoding:NSUTF8StringEncoding error:&error];
        /* Process the string, creating and autoreleasing more objects. */
    }
}
```

- for循环中可能要创建一些比较占内存的、临时的对象
- 为了避免一次for-loop中汇集太多这样的对象导致内存吃紧，可以适时地使用Autoreleasepool

## 底层实现

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/autoreleasepool_linkedlist.jpg?raw=true)

- autoreleasepool底层是有一个个的`AutoreleasePoolPage`结构体构成
- 这些结构体通过`parent`和`child`建立一个**双向链表**结构

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/autoreleasepool_push.jpg?raw=true)

- 上图展示了创建autoreleasepool时和在autoreleasepool执行`[obj autorelease]`的操作
- 首先这两个操作最终的结果都是要在`AutoreleasePoolPage`中添加一个对象，每个page是有大小限制的，如果满了无法添加对象，则需要创建一个新的page，通过`parent`和`child`进行关联
- 如果是创建autoreleasepool，则添加一个`boundary`，这是一个哨兵，表示一个新的自动释放池开始了
- 如果是`[obj autorelease]`，则将`obj`加入其中
- 其实看得出来，每个page内部添加对象时是一个栈结构，有一个`next`指针指向栈顶

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/autoreleasepool_pop.jpg?raw=true)

- pop的时候没有太多可以讲的
- 为每个对象发送`release`消息
- 如果当前释放池中对象都没了，那就移除`boundary`哨兵对象


# 参考

- [AutoreleasePool底层实现原理](https://juejin.im/post/5b052282f265da0b7156a2aa)
- [Using Autorelease Pool Blocks](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmAutoreleasePools.html#//apple_ref/doc/uid/20000047-CJBFBEDI)