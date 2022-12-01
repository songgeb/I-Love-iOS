# iOS思考之self vs super

> 深入理解代替单纯记忆

有一个题目大致如此：

有一个类叫`TOSon`，它的父类是`TOFather`，`TOFather`的父类是`NSObject`。看如下代码分析打印结果

```
@implementation TOSon
- (instancetype)init {
  if (self = [super init]) {
    NSLog(@"self.class is %@", [self class]);
    NSLog(@"self.superclass is %@", [self superclass]);
    NSLog(@"super.class is %@", [super class]);
    NSLog(@"super.superclass is %@", [super superclass]);
  }
  return self;
}
@end
```

## 题目分析

说白了，关键想要考察的点大致有两个：

1. 什么是super，super和self的区别是什么
2. Objective C的消息派发机制

## 解题过程

首先看一下官方关于self、super的定义是怎么说的（[The Objective-C Programming Language-Defining a Class](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocDefiningClasses.html#//apple_ref/doc/uid/TP30001163-CH12-SW1)）

提取一下核心的内容：

- self应用于实例方法或类方法的调用(实质是消息发送)
- self是一个变量，表示当前实例对象或类对象，在进行方法调用时作为隐藏参数传入底层的runtime的方法查找和执行实际的方法
- super是一个给编译器使用的标记，并非变量
	- 所以我们无法打印super的内容
- super也可以用于实例方法或类方法的调用
- super与self的最大不同在于，super进行方法调用时寻找目的函数的过程不同于self
	- self寻找目的函数时当然就是从self所指的对象进行寻找
	- super则是直接在super所在位置的父类所表示的对象开始寻找
- super和self表示同一个receiver（英文原文叫做 self and super both refer to the receiving object）
	- 这一点其实我一开始是不太理解的，后面逐渐有了些了解

接下来看一下题目

### `[self class]`

- self表示当前`TOSon`类型的实例对象，我们试图打印`class`方法(消息)的返回值
- 通过`class`方法的注释我们可以了解到--`Returns the class object for the receiver’s class.`
- 通过打印结果我们也能看出---TSon

### `[self superClass]`

- superClass是`NSObject`协议的一个只读属性--`@property(readonly) Class superclass;`
- 注释文档中对该属性的描述是--`Returns the class object for the receiver’s superclass.`
- 所以，结果应该就是--TOFather

### `[super class]`

> 该问题经常出现在面试题中，面试官很多时候其实就是想考这部分

- 根据官方对于super的解释，我们知道该方法会从TOFather开始寻找class方法
- 通常情况下我们的自定义类都没有实现class方法，所以最终寻找class方法会一直找到`NSObject`协议中对该方法的实现
- 再来回顾一下`class`方法的注释--`Returns the class object for the receiver’s class.`
- 那对于`[super class]`来说，super就是class方法的receiver，super表示的receiver和self表示的是同一个
- 所以在该题目下[self class]和[super class]的返回值是一样的，都是TOSon

### `[super superclass]`

和`[super class]`同样的分析套路

- 首先，从TOFather类对象中开始寻找superclass实现，没找到，一直找到`NSObject`协议中
- `Returns the class object for the receiver’s superclass.`
- receiver和self一样，所以结果为TOFather

## 总结

- 该题最核心要考察的是对super和self的概念、使用、区别的理解是否深入
- 在我几年前刚学习iOS时，没有好好看The Objective-C Programming Language，反而去看了些质量不太高的博文，其实这里面才是宝藏
- 其实完全没必要非得从runtime源码层面分析super的实现或者class方法的底层实现，源码可能会随时间变化，基本思想却不会轻易改变

## 参考
- [The Objective-C Programming Language-Defining a Class](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocDefiningClasses.html#//apple_ref/doc/uid/TP30001163-CH12-SW1)
