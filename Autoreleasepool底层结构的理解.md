# Autoreleasepool底层结构的理解



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