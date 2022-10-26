# 碾压面试之再提Objective-C Block

之前写过OC Block的两篇文章，主要围绕在语法备忘和通过深入学习Block结构（如capture变量原理、__block变量、内存循环引用）

本来觉得已经够用了，但实际面试中会问及更多底层的内容

本文就做个汇总

### 苹果公开Block源码了吗？

block对应的runtime library(libclosure)代码是开源的

- [libclosure](https://opensource.apple.com/source/libclosure/)

因为block的结构和行为很像OC中的对象（比如copy、内存管理），所以它的一些行为（如发送消息）是依赖于runtime的。从这个角度讲，可以认为block是开源的

### clang -rewrite-objc

查看网上的技术文章，基本都会提到使用`clang -rewrite-objc`命令将一段涉及block的代码翻译(重写)为C++代码，然后依据这个C++代码来分析block的底层实现

首先关于该命令的官方说法就一句话--**Rewrite Objective-C source to C++**（来自[Clang command line argument reference](https://clang.llvm.org/docs/ClangCommandLineReference.html)）

该命令的用途是什么？

我所查到的作用是，这是clang编译器提供的用于将OC语言编写的程序运行在Windows平台的工具，因为Windows平台中没有编译器能支持OC语言，所以可以使用该命令将程序转为C++代码的程序，再通过其他编译器编译后在Windows下运行。

--来自[What's the relationship between Objective-C source code and after clang -rewrite-objc C++ code?](https://stackoverflow.com/questions/55198496/whats-the-relationship-between-objective-c-source-code-and-after-clang-rewrite)

### Block的历史

我们看一下Wikipedia上的介绍
> Blocks are a non-standard extension added by Apple Inc. to Clang's implementations of the C, C++, and Objective-C programming languages that uses a lambda expression-like syntax to create closures within these languages. Blocks are supported for programs developed for Mac OS X 10.6+ and iOS 4.0+. 

### block是否是OC对象

**可以**认为block是OC对象，原因有：

- 从libclosure源码可以看出，block最终也是翻译为一个struct，且第一个成员变量是一个名为`isa`的指针，表示block的类型，这和其他的NSObject或子类对象结构时相似的
- 在行为上和普通OC对象也很类似
	- 如可以对block对象发送消息([block copy])
	- 可以当做对象存入集合容器中

> 苹果官方文档中也说过--Blocks are Objective-C objects(from [Working with Blocks](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html)
)

block和普通OC对象还是有些不同的

- 内存管理不同
	- 虽然Heap block也是引用计数来管理内存
	- 但Global block和Stack block则并非如此
- 使用起来更像是是function
- 且还能capture外部变量
- 还有像`__block`变量的支持

### forwarding指针的巧妙之处

首先，只有使用`__block`修饰的变量，对应runtime下的结构体中才有`forwarding`，该结构体大致是这样：

```
struct _block_byref_foo {
    void *isa;
    struct Block_byref *forwarding;
    int flags;   //refcount;
    int size;
    typeof(marked_variable) marked_variable;
};
```

要理解forwarding的巧妙之处，需要先看一段普通代码

```
__block int val = 0;
void (^blk)(void) = [^{++val;} copy];
++val;
blk();
NSLog(@"%d", val);
```

该代码所要表达的意思是，val变量既可以在block中修改，也可以在block以外修改

- block已经拷贝到heap上了，由于要始终持有val，所以val变量所对应的结构体也将被拷贝到heap上
- 我们知道以上代码块是在stack空间上执行的
- 当代码执行到`++val`一句时，stack上的变量val的结构体并没有销毁
- 就是说此时在stack和heap上出现了连个`val`对应的结构体，它们是如何共享或共同修改一个`val`的值的呢

看下图中，答案就是，stack和heap上的forwarding指针都指向heap上的val了

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/block_forwarding.png?raw=true)

> forwarding指针的设计对软件设计有一定帮助。
> 但不适合用作面试题，候选人知道forwarding能说明什么？能说明看过《Pro Multithreading and Memory Management
 for iOS and OS X》这本书。
> 这种记忆型知识点，容易记也容易忘

### capture时机与原理

capture的时机是**block初始化时**

block有可能capture三种类型的变量：局部变量、`__block`的局部变量、全局变量

前面两种情况最为常见

之前的文章中详细说过capture局部变量和`__block`变量的区别：值传递和引用传递的区别

在Block Implementation Specification也明确提到过

> Variables of auto storage class are imported as const copies. Variables of __block storage class are imported as a pointer to an enclosing data structure. Global variables are simply referenced and not considered as imported.


该问题作为面试题比较合适，在实际应用开发中很常见，也很容易出现问题。比如看如下代码，找错

```
Task *task;
task = [Task startWithBlock:^{
	// finish task
	[task cancel];
}];
```

### 多层block嵌套时，应如何写weakSelf

一段代码就可以清晰描述该问题

```
@weakify(self); // 1
[self dosth: ^{
	@strongify(self); // 2
	[self doOtherthing:^{
		// 3
		self.propertyA = xxx;
	}];	
}]
```

> 此处@weakify(self)等价于`__weak typeof(self) weakSelf = self;`
> @strongify(self)等价于`__strong typeof(self) self = weakSelf;`

- 问题：请问3处是否要weakSelf来避免内存循环引用
- 答案：要写，`@strongify(self)`

其实只要能理解capture的原理，该问题也就容易解决

doOthering中的block在capture外部self时，肯定选择当前代码块下的self，当前的self是一个strong的self，所以capture后，block也会强持有self

## 参考
- [Blocks (C language extension)](https://en.wikipedia.org/wiki/Blocks_%28C_language_extension%29)
- [Blocks Programming Topics](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Blocks/Articles/00_Introduction.html#//apple_ref/doc/uid/TP40007502-CH1-SW1)
- [Working with Blocks](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html)
- [objc 中的 block](https://blog.ibireme.com/2013/11/27/objc-block/)
- [Block Implementation Specification](https://clang.llvm.org/docs/Block-ABI-Apple.html)