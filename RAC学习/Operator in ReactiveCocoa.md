# Operator in ReactiveCocoa

> 深入理解代替单纯记忆


本文记录一下ReactiveCocoa（Objective C版本）中常用的操作符，算是备忘吧

> 本文基于`ReactiveObjc 2.5.5`版本

## 前提

为了后面讲解方便，统一一下一些名称的概念

- 我们一般都将RACSignal称为`信号`，有人也把它叫做`信号流`，其实不论怎么称呼，只要了解到**`RACSignal`用来表示数据流**即可
- 本文中，我们也将`RACSignal`称为`信号`，信号可以发送数据，发送数据的信号即为数据流
- 当然，信号发送的数据也可以是信号

## bind、flatten、flattenMap、map

### bind

`- (RACSignal *)bind:(RACStreamBindBlock (^)(void))block`

> `typedef RACStream * (^RACStreamBindBlock)(id value, BOOL *stop);`

![](https://s3.ax1x.com/2021/02/03/yKUssg.png)

分析`bind`的源码，可知道具体操作是：

1. 该方法会创建一个新信号N并返回
2. 当N被订阅时，会立即订阅原信号O
3. 当O发送数据时，通过bind的参数block，产生中间信号M，然后订阅信号M
4. 中间信号发送数据时，会通过N将数据发送出去

结合上图，换成更容易理解的话就是

1. 原信号(original signal)，每发送一个数据(右侧红球)
2. block会收到原信号发送的数据(value)，构建新信号M，比如图中间顶部的绿色球所在的箭头即为新信号M
3. 当M信号发送数据时(绿色球即代表M发送的数据)，最终订阅者就会收到该数据(绿色球)。紫色、蓝色等球也是类似的
4. 总结为一句话，原信号被转化为了block中的信号，block中的信号发送什么数据，最终订阅者就能收到什么数据

> bind是其他几个操作(flattenMap、map、flatten)的基础

### flattenMap

`- (instancetype)flattenMap:(RACStream * (^)(id value))block`

其内部也是调用的`bind`，做的事情是一样的，但功能没有`bind`强大

### flatten

`- (instancetype)flatten`

`flatten`为关键字的方法在其他语言中也很常见，有人将它翻译为`拍平`，比如将一个数组的数组--`[[1, 2], [3, 4]]`拍平后就是`[1, 2, 3, 4]`

在RAC中也可以这么理解，需要注意的是，只有`信号的信号`才能执行`flatten`进行拍平

- flatten返回一个新的信号，该信号将原信号(原信号发送的数据也是信号)拍平
- 订阅flatten返回的信号，收到的数据将是原信号中的每个信号发送的数据

### map

RACStream方法

`- (instancetype)map:(id (^)(id value))block`

内部使用flattenMap进行封装，block中只需要根据接收到的原信号发过来的数据，转换为返回新信号中新数据

## filter

`- (instancetype)filter:(BOOL (^)(id value))block`

返回一个新的信号，新的信号数据由，满足block中条件的原信号数据组成

```
RACSignal *signal = [signal1 filter:^BOOL(NSString *value) {
	// 满足该条件的数据会出现在signal中
        return value.length > 20;
    }];
```

## ignore

`- (instancetype)ignore:(id)value`

返回一个`RACStream`，新的数据流中，忽略参数指定的值

> 内部会使用`isEqual`判断是否满足忽略条件

```
[[self.inputTextField.rac_textSignal ignore:@"sunny"] subscribeNext:^(NSString *value) {
    NSLog(@"`sunny` could never appear : %@", value);
}];
```

### ignoreValues

`- (RACSignal *)ignoreValues`

忽略所有的next值，只接受error和complete事件

## distinctUntilChanged

`RACStream`的方法

`- (instancetype)distinctUntilChanged`

对原信号的数据做如下处理，每收到一个数据，与前一个数据比较，如果相等(通过`isEqual`比较)，则忽略，直到结束，或者遇到不同的数据

如下的例子中，使用distinctUntilChanged可以避免label多次更新

```
RAC(self.label, text) = [RACObserve(self.user, username) distinctUntilChanged];
self.user.username = @"sunnyxx"; // 1st
self.user.username = @"sunnyxx"; // 2nd
self.user.username = @"sunnyxx"; // 3rd
```

## take

### take:

`- (instancetype)take:(NSUInteger)count`

RACStream的方法

只取前count个next值

### takeLast:

`- (RACSignal *)takeLast:(NSUInteger)count`

取后count个数据

### takeUntilBlock:

RACStream方法

`- (instancetype)takeUntilBlock:(BOOL (^)(id x))predicate`

直到block中判断返回为YES时，停止取值

### takeWhileBlock:
RACStream方法

`- (instancetype)takeWhileBlock:(BOOL (^)(id x))predicate`

直到block中为NO时，停止取值

## skip

skip系列和take系列方法很像，可以类比学习，此处不赘述

- `- (instancetype)skip:(NSUInteger)skipCount`
- `- (instancetype)skipUntilBlock:(BOOL (^)(id x))predicate`
- `- (instancetype)skipWhileBlock:(BOOL (^)(id x))predicate`

## concat

RACStream方法

`- (instancetype)concat:(RACStream *)stream`

将两个数据流的数据，按照先receiver后stream的顺序串联起来

### concat

`- (RACSignal *)concat`

该方法只能用于信号的信号，将`信号的信号`的数据串联起来

## then

`- (RACSignal *)then:(RACSignal * (^)(void))block`

- block中需要返回一个signal
- then方法会等待receiver发送数据结束，即收到complete数据，然后再订阅block中的信号
- then方法返回的信号中，只有block中信号的数据

## merge

`- (RACSignal *)merge:(RACSignal *)signal`

返回的新信号的数据，是两个信号的数据合到一起的数据，收到数据的先后顺序按照两个信号实际发出信号的时间为准

```
RACSubject *letters = [RACSubject subject];
RACSubject *numbers = [RACSubject subject];
RACSignal *merged = [RACSignal merge:@[ letters, numbers ]];

// Outputs: A 1 B C 2
[merged subscribeNext:^(NSString *x) {
    NSLog(@"%@", x);
}];

[letters sendNext:@"A"];
[numbers sendNext:@"1"];
[letters sendNext:@"B"];
[letters sendNext:@"C"];
[numbers sendNext:@"2"];
```

## reduce

### reduceEach

reduceEach是`RACStream`的方法

`- (instancetype)reduceEach:(id (^)())reduceBlock`

reduce这个词此处可以翻译为归纳

- reduce的作用是化零为整，即收到的是零散的数据，输出的是一个数据
- 那么该方法要求，receiver发送的数据必须是零散数据，即`RACTuple`类型
- reduceBlock的参数就是`RACTuple`的每一项
- 通过reduceBlock中加工后，返回的数据，则是reduce方法产生的新信号所发送的数据

```
    RACSignal *signal1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:RACTuplePack(@(1), @"string")];
        [subscriber sendCompleted];
        return nil;
    }];
    RACSignal *signal = [signal1 reduceEach:^id(NSNumber *first, NSString *second){
        return first;
    }];
     [signal subscribeNext:^(id x) {
        NSLog(@"next value %@", x);
    } completed:^{
        NSLog(@"complete");
    }];
    // output
    // next value 1
    // complete
```

### 参考
- [化零为整：Reduce 详解](https://swift.gg/2015/12/10/reduce-all-the-things/)

### scanWithStart

scanWithStart是`RACStream`的方法

`- (instancetype)scanWithStart:(id)startingValue reduce:(id (^)(id running, id next))reduceBlock`

- startingValue表示一个初始值，内部会遍历信号中的每一个值，执行reduceBLock，初次的running值就是startingValue，之后每一次得到的值时reduceBlock返回的内容
- 其实reduceBlock就像一个累加器一样


## switchToLatest

`- (RACSignal *)switchToLatest`

该方法与flatten类似，也是只能`信号的信号`才能执行

[![y7dddx.png](https://s3.ax1x.com/2021/02/22/y7dddx.png)](https://imgchr.com/i/y7dddx)

- 图中右上角的红球，表示的是原信号O发送的数据，也是信号
- 原信号O发送了很多个信号，但阅了`switchToLatest`返回的信号后，最终收到的数据却只有原信号发送的最新的信号L发送的数据
- 从图中来看，原信号O开始发送的信号中，有发送绿色球数据，有的紫色紫色球，这些数据最终都没有收到，最终真正收到的数据是，O发送的最后一个信号发送的三个咖啡色的球

> 参考部分是一个switchToLatest的经典应用场景

### 参考
- [ReactiveCocoa: Understanding switchToLatest](https://spin.atomicobject.com/2014/05/21/reactivecocoa-understanding-switchtolatest/)

## combineLatestWith:

`- (RACSignal *)combineLatestWith:(RACSignal *)signal`

将receiver`最新的`值与参数signal的每个值合并到一起

- 两个信号都发送complete时，合并后的信号也会发送complete

[![yHuXNR.png](https://s3.ax1x.com/2021/02/22/yHuXNR.png)](https://imgchr.com/i/yHuXNR)

## zip:

zip是`RACStream`中定义的方法，其子类RACSignal和RACSequence都进行了实现

这里我们仅对`RACSignal`的实现进行说明

`- (RACSignal *)zipWith:(RACSignal *)signal`

- 从当前signal和待zip的signal中，从前往后，各取一个next数据，合并为一个`RACTuple`的值，通过新信号发送出去
- 如果两个signal中的next值数量不匹配，则舍弃后面不匹配的next值
- 两个signal都complete时，新信号发送complete

[![yHZZaq.png](https://s3.ax1x.com/2021/02/22/yHZZaq.png)](https://imgchr.com/i/yHZZaq)

## scanWithStart

## combinePreviousWithStart:reduce

`- (instancetype)combinePreviousWithStart:(id)start reduce:(id (^)(id previous, id next))reduceBlock`


## return

```
RACSignal *signal = [RACSignal return:@1];
[signal subscribeNext:^(id x) {
                    NSLog(@"%@", x);
                }
                error:^(NSError *error) {
                    NSLog(@"error!");
                }
                completed:^{
                    NSLog(@"complete!");
                }];
// 打印结果
// 1
// complete
```

## empty

```
RACSignal *signal = [RACSignal empty];
[signal subscribeNext:^(id x) {
                    NSLog(@"%@", x);
                }
                error:^(NSError *error) {
                    NSLog(@"error!");
                }
                completed:^{
                    NSLog(@"complete!");
                }];
// 打印结果
// complete
```

## catch

`- (RACSignal *)catch:(RACSignal * (^)(NSError *error))catchBlock`

- 返回一个新信号N
- 当receiver发生error时，catchBlock中收到相应错误信息，并返回一个新的信号M，同时订阅M，自此以后新信号N中的数据便是M中的数据了
- 当receiver不发生error时，数据仍会通过N进行发送
- 还有一个精简的方法是`- (RACSignal *)catchTo:(RACSignal *)signal`，意思是相同的
	- 比如`[A catchTo: B]`表示，返回一个新信号，其中的数据是，如果A不发生错误就是A的数据，如果A发生错误，则数据边来源于B

## throttle

`- (RACSignal *)throttle:(NSTimeInterval)interval`

throttle动词形式翻译为`节流阀`

该方法接收一个时间间隔i，当receiver连续发送next时，如果这几个next数据在i之内，则只保留最后一个

[![6CZSU0.png](https://s3.ax1x.com/2021/02/28/6CZSU0.png)](https://imgtu.com/i/6CZSU0)

## 参考
- [ReactiveCocoa核心元素与信号流](https://tech.meituan.com/2016/10/14/reactive-cocoa-signal-flow.html)
- [Reactive Cocoa Tutorial [0] = Overview](http://blog.sunnyxx.com/2014/03/06/rac_0_overview/)
- [BasicOperators](https://github.com/ReactiveCocoa/ReactiveObjC/blob/master/Documentation/BasicOperators.md)