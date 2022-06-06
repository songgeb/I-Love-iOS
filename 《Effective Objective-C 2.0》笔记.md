# 《Effective Objective-C 2.0》笔记

> 感觉这本书的英文原版，语句本身不是很容易理解，至少相比苹果官方文档的英文水平差一些。可以比对中文版一起理解

> 文中的图片显示不出来可能因为github资源地址无法访问，科学上网试试看

## 2. Objects, Messaging, and the Runtime

### Item 6: Understand Properties

- 非property声明实例变量的方法，编译时编译器会将每个对象的每个实例变量在内存中的位置偏移量硬编码处理
- 所以当有新增实例变量时，需要进行重新编译才能计算出正确所有实例变量正确的偏移量
- 而property的定义方式中，编译器并非硬编码，而是运行时再去找要访问的实例变量

### Item 7: Access Instance Variables Primarily Directly When Accessing Them Internally

- 不要再`Initializer`和`Dealloc`中使用`Dot`语法
- 原因是这两个方法中，当前对象的生命周期可能并不完整，对象中的实例变量或其他状态可能也未知
- 而使用`Dot`语法设置或获取实例变量时，如果类或子类重写了`setter`或`getter`方法，而且其中的逻辑有可能涉及哪些未知的状态的话，可能引起未知的行为
- 总之，`Dot`语法应在确保对象初始化结束，对象完整的情况下使用

#### 参考
- [不要在 Initializer 和 Dealloc 方法中使用 Setter 和 Getter](http://dijkst.github.io/blog/2013/12/07/bu-yao-zai-initializer-he-dealloc-fang-fa-zhong-shi-yong-setter-he-getter/)
- [Practical Memory Management](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmPractical.html)

### Item 8: Understand Object Equality

`NSObject`协议中涉及`Equality`的是这两个方法

```
- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;
```
- 其实用于判断相等的方法只需要用到第一个方法
- 至于hash方法为什么也建议要实现以下，是因为如果重写了`isEqual`方法，通常说明可能要自定义一个类
- 该自定义类在实际应用中很可能被添加到`Dictionary`作为key，或其他基于哈希表结构的集合中，而此时必须依赖`hash`值进行存取
- 所以实现`isEqual`方法的同时最好也实现以下`hash`方法
- 关于`hash`方法的取值可以参考[Hash in iOS](https://juejin.im/post/5d47a735f265da03934bc456)
- mutableobject in collection的情况
- mutableobject加入到哈希表结构中后，必须保证mutableobject的hash值不变
	- 要么保证mutableobject的hash与mutableobject被修改的元素无关
	- 要么就避免mutableobject被改动

### Item 9: Use the Class Cluster Pattern to Hide Implementation Detail

### Item 11: Understand the Role of objc_msgSend

- `static binding`和`dynamic binding`是C语言中两种方法执行逻辑
- 如果编译期间就知道要执行的方法，那编译期就会将该方法的地址硬编码到指令中，这边是`static binding`
- `dynamic binding`则是，编译期间无法确定要执行方法，一定要等到运行时才能确定

举例说明一下

```
void doTheThing(int type) {    
if (type == 0) {        
printHello();    
} else {        
printGoodbye();”
}
```

- 编译器编译完成后的代码，printHello()和printGoodbye()位置会通过硬编码写入地址的方式，调用对应函数。这就是`static binding`或者说`static dispatch`

```
void(*fnc)();
if (type == 0) {        
fnc = printHello;    
} else {        
fnc = printGoodbye();”
}
fnc();
```

- 这种方式则是`dynamic binding`，直到运行时才能确定执行哪个方法

- Objective-C便是采用了`dynamic binding`
- `objc_msgSend`是很多OC执行方法后底层调用的方法
	- `void objc_msgSend(id self, SEL cmd, ...)`
- 当然，除了该方法，还有一些处理一些特殊情况底层方法。比如给super发消息（执行方法）时的`objc_msgSendSuper`
- 这些方法的工作原理是
	1. 每个类都有自己的方法列表
	2. 每个方法都类似C语言中的函数定义一样
	3. 方法列表中存储着这些函数的指针和`selector`
	4. `objc_msgSend`这些方法边通过`self`和`selector`找到相应的方法执行
	5. 如果当前类找不到，则会根据类层级关系去父类中寻找
- 上面的方法查找（消息传递）过程看上去比较麻烦，如果每次都这样找会不会很耗性能
	- 其实`objc_msgSend`等方法为每个类用map缓存了方法调用信息
	- 如果同一个类方法同一个方法，会比较快

### Item 12: Understand Message Forwarding

Message Forwarding，翻译为消息转发。

是指当`receiver`无法处理收到的`message`时，或者通俗的理解，为对一个对象或者一个类执行一个本来不存在（编译期间）的方法时，如果不作处理则会抛出异常闪退。

OC的运行时提供了消息转发的方法，使得开发者可以有机会处理这种情况，以避免异常闪退。比如可以动态添加这个未知方法，或者将消息转发给其他`receiver`

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/OC_MessageForwarding.png?raw=true)

1. 当遇到未知方法时，根据方法类型，会执行`NSObject`的`resolveInstanceMethod:`或者`resolveClassMethod`方法
2. 该方法中开发者有机会拿到`selector`，可以动态的给`receiver`新增一个该`selector`的方法。这样则会执行新增的方法
3. 如果上面的方法返回`NO`，表示无法处理的话。则来到`NSObject`类的`forwardingTargetForSelector`方法
4. 在这一步，我们有机会将该消息转发给其他的`target`
5. 如果这一步也处理不了，就来到终极的`forwardInvocation`了，这个方法中，能够拿到一个包含`target`、`selector`、`parameter`的`NSInvocation`对象，我们可以对这些属性做各种修改，当然也可以修改target，将消息转发给新的target
6. 如果这都搞不定，那就等着异常闪退吧

#### 应用

- `CALayer`内部便是使用了上面消息转发方法
	1. 实现了可以给`CALayer`子类添加任意属性，缺可以不需要合成实例变量
	2. 同时也支持使用KVC的方式添加任意属性
- 因为`CALayer`内部使用消息转发动态添加了相应的access方法，并存储了相应数据

### Item 13: Consider Method Swizzling to Debug Opaque Methods

核心的方法就是`method_exchangeImplementations(method1, method2)`

```
- (void)swizzleMethod1 {
    NSLog(@"swizzleMethod1");
}

- (void)swizzleMethod2 {
    NSLog(@"swizzleMethod2");
}

- (void)methodSwizzle {
    Method method1 = class_getInstanceMethod([self class], @selector(swizzleMethod1));
    Method method2 = class_getInstanceMethod([self class], @selector(swizzleMethod2));
    
    method_exchangeImplementations(method1, method2);
    
    NSLog(@"method2->");
    [self swizzleMethod2];
}
```

### Item 14: Understand What a Class Object Is

#### 如何确定某个对象能否能响应某个方法(selector)
- 通过`isa`指针和`super_class`指针
- OC对象内部其实是一个如下样子的结构体

```
typedef struct objc_class *Class;
typedef struct objc_object *id;

struct objc_object {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
};

struct objc_class {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;

#if !__OBJC2__
    Class _Nullable super_class                              OBJC2_UNAVAILABLE;
    const char * _Nonnull name                               OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
#endif

} OBJC2_UNAVAILABLE;

```

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/instance_class_metaclass.png?raw=true)

- `instance`通过`isa`可以确定对应的类
- 类又通过`isa`确定该类的类型，即元类`metaclass`
- 所有元类继承自同一个根元类
- `instance`、类和元类的底层结构都是类似的
- 类中存放了`instance`的成员变量和方法列表
- 元类中存放了类的类方法和类属性
- 而类的实例`instance`，可以有多个。但类和元类在应用中是单例，只有一份
- 所以类比较相等的话，可以直接用`==`
	
	```
	id object = /* ... */;
	if ([object class] == [EOCSomeClass class]) {
	}
	```

#### Introspection(内省)

Introspection就是系统进行类型检查，查看某个对象、类是否包含某个属性，能否响应某个方法（消息）

整个查找过程就是按照上面`isa`和`super_class`建立起来的`hierachy`来查找

反应到具体OC的API上，就是`isKindOf`、`isMemberOf`这些方法使用内省的机制

#### 疑问
1. `NSProxy`的作用，以及与`Message Forwarding`关联

## 疑问
1. 如何理解Runtime

## 3. Interface And API Design
### Item 22: Understand the NSCopying Protocol

- copy的实现基于两个关键方法
	- `NSObject`类的`copy`方法
	- `NSCopying`协议的`copyWithZone:`方法
- copy过程通过调用`copy`方法，进而执行`copyWithZone:`方法，二者缺一不可
- 所以如果要让一个类可以copy，则必须实现`NSCopying`协议，实现`copyWithZone:`
- 通常系统的集合类进行copy时都是浅拷贝，深拷贝的话要看支不支持，或者自定义类是需要自己实现深拷贝

## 4. Protocols and Categories

### Item 23: Use Delegate and Data Source Protocols for Interobject Communication”


### Item 27: Use the Class-Continuation Category to Hide Implementation Detail

`Class-Continuation Category`其实指的就是`Class Extension`


## 6. Blocks and Grand Central Dispatch

### Item 41: Prefer Dispatch Queues to Locks for Synchronization

- 使用dispatchqueue给共享资源枷锁，最容易想到的是用一个**串行队列**，读和写操作都是用`dispatch_sync`在串行队列中修改、获取数据
- 但仍有优化空间
- 其实为了保证数据同步，只要让读和写同步就可以，多次读的话并不需要同步
- 所以我们可以维护一个并发队列
- 读操作使用`dispatch_sync`获取
- 写操作使用`barrier_async`，由于`barrier`的特性，如果写操作先提交执行了，那后面提交的读操作，即使多线程，也要等待写操作结束
- 疑问在于，`dispatch_sync`的方式将任务提交到并发队列里时，是否开辟新线程的问题
- 从网上的简单实践来看，貌似使用的是caller的线程，而非开辟新线程
- 但我的结论是，队列和线程之间是独立的，我们不能依据简单的测试代码就得出上面的结论
- 正确的理解是，对于并发队列，不论`asyn`还是`sync`的提交方式，队列内部都是有可能开辟多个线程来执行任务的。所以相信书上的