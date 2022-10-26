title: Objective-C block 深入了解
date: 2017-12-05 13:55:28
tags: [block]
categories: [iOS, 学习]
---

本文中代码所依赖的环境是

`Xcode 9.0` `Apple LLVM 9.0.0` `ARC环境`


## block的类型

Objective-C中block有三种类型：

* `__NSGlobalBlock__`
* `__NSStackBlock__`
* `__NSMallocBlock__`

以上是通过`NSLog`打印不同类型log的输出结果。从结果可以看出分别对应着`全局block`、`栈block`和`堆block`。

### NSGlobalBlock

当block中没有使用`block外部`的任何`局部变量`时，即为全局block。全局block在内存的全局数据区

```
int a = 111;
// block without captured variable
block_type block = ^{
    int b = 0;
    printf("a : %d, globalVar:%d", b, globalVar);//此处使用了block内部的局部变量和全局变量
};
NSLog(@"block with no captured auto variable :%@", block);// block with no captured variable :<__NSGlobalBlock__: 0x1000020b8>
```

通常情况全局block使用的情况比较少。

### NSStackBlock 和 NSMallocBlock

栈和堆block使用情况比较多。

**栈block**: 使用了(捕获)局部变量的block在创建之初，就是栈block。block在内存的栈区

```
int a = 111;
NSLog(@"stack block : %@", ^{NSLog(@"a:%d", a);}); // stack block : <__NSStackBlock__: 0x7ffedff74a98>

```
> 其实栈block不止以上情况会出现，文章后面会看到其他一些情况也会看到stack block


**堆block**: 栈block在一些时机，会`copy`到堆区中，即为堆block。堆block可以实现，当超出block所在的代码块区域时仍能保留并执行。

```
NSLog(@"malloc block : %@", [^{NSLog(@"a:%d", a);} copy]);// malloc block : <__NSMallocBlock__: 0x60400024f180>
```

## 细看NSStackBlock 和 NSMallocBlock

上面只是大体了解了下几种block，现在我提出了一些在使用block时经常遇到的问题：

1. block如何实现捕获局部变量？
2. 为什么直接捕获的局部变量不能修改，而使用`__block`修饰的变量则可以被修改？
3. 使用`weakSelf`来避免循环引用时，是不是一定要配合`strongSelf`使用？

### block如何实现捕获局部变量

可以通过查看block内部的实现来一探究竟，比如使用

`clang -rewrite-objc block.m`

> 该命令是将oc代码转为c++实现代码，因为oc或block对象本质上是一些结构体。如果提示`cannot create __weak reference because the current deployment target does not support weak`错误可以加上一些参数试下`clang -rewrite-objc -fobjc-arc -stdlib=libc++ -mmacosx-version-min=10.7 -fobjc-runtime=macosx-10.7 -Wno-deprecated-declarations block.m`

通过将oc代码转为底层的结构体实现，能够分析出block捕获局部变量的过程。相关文章比较多，可以参考文末的参考。此处不再赘述，直接说结论：

**`block会将局部变量拷贝一份，作为自己的成员变量`**

其实这也可以解释，**为什么在block中无法修改捕获到的局部变量**，因为block中使用的变量其实已经不再是外部的局部变量了，而是block自己的成员变量。但我们期望的是修改外部变量，所以你改block的成员变量有啥用啊？索性编译器直接提示你，不能改！

### __block修饰的变量为什么可以修改

__block的变量同样也会被block捕获，但注意，**`block会将局部变量包一层，可以认为包成了一个结构体，然后将结构体的指针作为block的成员变量`**。block通过该指针访问局部变量，既然是指针，那么block中也就可以修改外部的局部变量了。

文字多了太枯燥，上两张图缓和一下：

<div align=center>

![非_ _block变量](/images/block-capture-1.jpg)
</div>

<div align=center>
非_ _block变量
</div>

<br>

<div align=center>
![_ _block变量](/images/block-capture-2.jpg)
</div>
<div align=center>
_ _block变量
</div>


> 图片来自唐巧的[《谈Objective-C block的实现》](http://blog.devtang.com/2013/07/28/a-look-inside-blocks/)


其实，非block变量和block变量在block的区别是 **值传递 和 引用传递**

### block的内存管理

关于第三个问题，要涉及到block的内存管理

大家都知道，block循环引用一般是 `self -> block -> self(或者self.property)`这种结构导致互不释放资源。在此之前，有一个前置的问题是**block为什么可以被持有？又为什么可以持有self？**


**因为堆block可以像oc对象一样，栈block是不行的**

前面有提到，**捕获了局部变量的block创建之初都是栈block**，栈block就像一个函数一样，函数执行完，函数中的局部变量就都出栈，内存中就不存在了。但实际当中，我们的block可能要在函数执行完，仍要保留一段时间，比如网络请求：

```
NSURLSession *session;
NSURLRequest *request;
[session dataTaskWithRequest:request
           completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
           //do something    
}];
```

block能够保证超出作用域后仍能保留的原因其实是，**栈block被copy到了堆中，堆block和oc对象类似，也是通过引用计数来进行内存管理**

新的问题来了：

* 谁来copy栈block到堆中？
* 谁来管理堆block的引用计数？

#### 栈block拷贝到堆中

本文只针对ARC环境，**ARC环境**和**系统API**几乎为我们做了绝大多数copy工作：

1. 当block被赋值给强引用时
2. 当函数返回的是block时
3. Cocoa框架中方法名含有usingBlock
4. 一些没有usingBlock的系统方法也可以比如上面的网络请求
5. GCD所有的方法
6. 显示地对block执行copy方法

来一段代码瞅瞅

```
int a = 111;

// strong block with captured variable
void(^block2)(void) = ^{
    NSLog(@"a:%d", a);```};
NSLog(@"strong block with captured auto variable:%@", block2);// strong block with captured variable:<__NSMallocBlock__: 0x1004249f0>

// weak block with captured variable
__weak void(^block1)(void) = ^{
    NSLog(@"a:%d", a);
};
NSLog(@"weak block with captured auto variable:%@", block1);// weak block with captured variable:<__NSStackBlock__: 0x7ffeefbff550>

// get block from method
NSLog(@"get block from method : %@", [self getBlock]);// get block from method : <__NSMallocBlock__: 0x600000447a40>

// copy block explicitly
NSLog(@"stack block : %@", ^{NSLog(@"a:%d", a);}); // stack block : <__NSStackBlock__: 0x7ffedff74a98>
NSLog(@"malloc block : %@", [^{NSLog(@"a:%d", a);} copy]);// malloc block : <__NSMallocBlock__: 0x60400024f180>

// block as argument
[self printBlock:^{
	NSLog(@"%d", a);
}];

- (void)printBlock:(block_type)block {
    NSLog(@"block as argument : %@", block);// block as argument : <__NSStackBlock__: 0x7ffeeca47ac0>
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"block in dispatch_asyn:%@", block);// block in dispatch_asyn:<__NSMallocBlock__: 0x604000646330>
    });
}

- (block_type)getBlock {
    int a = 123;
    return ^{NSLog(@"%d", a);};
}

```

> 代码中能够看到在`将block赋值给弱引用`和`将block当做参数传递`时也是stack block


### strongSelf在避免循环引用中是否必须？

先举个避免循环引用的🌰

```
__weak typeof(self) weakSelf = self;
self.block = ^{
	__strong typeof(weakSelf) strongSelf = weakSelf;
	// do something
};
```

* self.block中使用self为什么会产生循环引用
    
    在block拷贝到堆中时，block捕获到self，并把self拷贝到block内部作为自己成员变量（即使block中引用的是self.property，block内部访问该property时仍然是通过`self->property`的方式进行访问，所以仍然是捕获的self），同时会执行能够强持有self的操作，即使得self引用计数+1。block执行结束后，由于self持有block，所以不会释放，self由于被block的成员变量强持有，所以也不会被释放。于是循环引用
    
* 先简单说下使用weakSelf为什么能避免循环引用：

	block捕获了weakSelf这个局部变量，当做自己的成员变量，但由于是weak的，所以作为block的成员变量的weakSelf，并不会强持有self（即不会让self的引用计数+1）。

* 接下来，另一个问题是：strongSelf会不会造成循环引用呢？

	不会的，因为strongSelf是block内部的局部变量，strongSelf被赋值时，由于是强引用，所以会强持有self，让self的引用计数+1，但block执行结束后strongSelf的生命周期结束，self的引用计数-1，也就不会造成循环引用了。
	
那么strongSelf的必要性就容易解释了，执行block中的某些逻辑时，如果self释放了可能会造成严重的问题，为了执行block时不让self释放，我们要用strongSelf这个强引用局部变量控制着self。

至于会造成什么严重问题，请看下面两个🌰

```
__weak typeof(self) weakSelf1 = self;
block_type block4 = ^{

	// 例子1
    NSLog(@"weakSelf : %@", weakSelf); // weakSelf : <MyObject: 0x60000001fb10>
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"weakSelf in dispatch : %@", weakSelf1);// weakSelf in dispatch : (null)
    });
    
    //例子2，该例来自唐巧的博客
    // 如果正在执行networkReachabilityStatusBlock时，self释放了，多半情况下会崩溃
    AFNetworkReachabilityStatusBlock callback = ^(AFNetworkReachabilityStatus status) {
         weakSelf.networkReachabilityStatus = status;
       akSelf.networkReachabilityStatusBlock(status);
         }
     };
};
self.block = block4;

```

> \__strong typeof(weakSelf) strongSelf = weakSelf; 此处\__strong是必要的，如果不写，则转换成c++源码后是 MyObject *const __weak strongSelf =  weakSelf; 这样也就起不到对self强引用的作用


```
__weak typeof(self) weakSelf1 = self;
block_type block4 = ^{
    typeof(weakSelf) strongSelf = weakSelf1; /*注意：此处并没有使用__strong */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"strongSelf in dispatch : %@", strongSelf); /* strongSelf in dispatch : (null) */
    });
};
self.block = block4;
```

* block中`__strong typeof(self) strongSelf = weakSelf;`的写法会导致对`self`的强引用吗？

不会。这要弄清楚什么是`typeof()`。
    - 首先，`typeof()`不是Objective-C，也不是标准C语言的操作符，是扩展的特性，需要有编译器支持才可以
    - 另外，`typeof()`在编译期间决定类型，编译后的代码已经没有`self`相关内容了，所以不会对`self`有强引用

## 项目中例子分析

拿项目代码中block例子分析一把

```
- (void)startTask {
	Task *task = [self startTaskWithCompletion:^{
    	NSLog(@"task : %@", task);// 此时block捕捉到的是未初始化的task，即nil。相当于值传递
    	// do something with task
	}];
}

```

分析过程：

1. 代码中的赋值过程是，先执行`startTaskWithCompletion:`，再对task赋值
2. 初始化block时，task还是nil
3. 所以block中task成员变量也是nil
4. 赋值方法执行完后，task指向了新的task对象，但block中的task由于是值拷贝，所以还是nil
5. 之后代码执行到block中时，task还是nil

解决方案：

改用引用传递，
**`Task *task -> _ _block Task *task`**


## 参考
[Objective-C高级编程:iOS与OS X多线程和内存管理](https://www.amazon.cn/%E5%9B%BE%E4%B9%A6/dp/B00DE60G3S)

[AutomaticReferenceCounting-llvm官方文档](https://clang.llvm.org/docs/AutomaticReferenceCounting.html#blocks)

[WorkingwithBlocks](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html)

[Objective-C 拾遗：从Heap and Stack到Block](http://ios.jobbole.com/81900/)

[谈Objective-C block的实现](http://blog.devtang.com/2013/07/28/a-look-inside-blocks/)

[iOS 面试题（三）：为什么 weakSelf 需要配合 strong self 使用](http://www.10tiao.com/html/224/201612/2709545254/1.html)

[Swift与OC真正去理解Block解决循环引用的技巧](http://www.jianshu.com/p/bf2b8f278a81)

[Block 梳理与疑问](http://www.saitjr.com/ios/advance-block.html)