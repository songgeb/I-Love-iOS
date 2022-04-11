# RAC学习笔记3
> 深入理解代替单纯记忆
2021年01月14日

初学RAC之后，已经可以上手写一些简单的功能了。但在遇到高阶应用的时候还是因为对底层理解不够而无所适从，比如：

1. zip、concat的区别是什么？
2. 能否通过RAC实现多个异步任务的同步执行
3. RACDispose是什么，怎么用？
4. RAC为什么那么容易触发循环引用，如何轻松解决循环引用

## Stream

即一系列的内容

- 这些内容是有先后顺序的，必须按照先后顺序，第一个处理完之前，不可能拿到第二个
- 在RAC中`RACStream`表示Stream，它本身是一个抽象类
	- `RACSignal`和`RACSequence`是`RACStream`的子类

## RACSignal
- RAC可以保证同一个信号的两个event，不可能并发传递到处理callback中
- 即当一个event正在被处理时，另一个event会等待

## Subscription

- Subscriptions retain their signals, and are automatically disposed of when the signal completes or errors.
- Subscriptions can also be disposed of manually.

## RACSubject

可以手动控制的signal

## RACSequence

类似`NSArray`的集合类，但有更多特性

- 默认情况，RACSequence中的item是lazy load的

```
NSArray *strings = @[ @"A", @"B", @"C" ];
RACSequence *sequence = [strings.rac_sequence map:^(NSString *str) {
    NSLog(@"%@", str);
    return [str stringByAppendingString:@"_"];
}];

// Logs "A" during this call.
NSString *concatA = sequence.head;
```

## Cold and Hot Signal

ReactiveCocoa官方这样说：
> 
- hot: already activated by the time it's returned to the caller
- cold: activated when subscribed to

但还是不理解

冷、热信号的概念源于.NET框架Reactive Extensions中的Hot Observable和Cold Observable
>
- Hot Observable是主动的，尽管你并没有订阅事件，但是它会时刻推送，就像鼠标移动；而Cold Observable是被动的，只有当你订阅的时候，它才会发布消息
- Hot Observable可以有多个订阅者，是一对多，集合可以与订阅者共享信息；而Cold Observable只能一对一，当有不同的订阅者，消息是重新完整发送

### 为什么要区分冷、热信号


### 问题
1. 为什么要有冷热信号区分

## RACSignal VS RACSequence

- RACSignal是`push-driven`，RACSequence是`pull-driven`
- `push-driven`其实

## RACDispose

## side effects

1. 要了解RACCommand，就得知道multicast是干啥的
2. 进而要了解RACMulticastConnection是干啥的

```
// This signal starts a new request on each subscription.
RACSignal *networkRequest = [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
    AFHTTPRequestOperation *operation = [client
        HTTPRequestOperationWithRequest:request
        success:^(AFHTTPRequestOperation *operation, id response) {
            [subscriber sendNext:response];
            [subscriber sendCompleted];
        }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [subscriber sendError:error];
        }];

    [client enqueueHTTPRequestOperation:operation];
    return [RACDisposable disposableWithBlock:^{
        [operation cancel];
    }];
}];

// Starts a single request, no matter how many subscriptions `connection.signal`
// gets. This is equivalent to the -replay operator, or similar to
// +startEagerlyWithScheduler:block:.
RACMulticastConnection *connection = [networkRequest multicast:[RACReplaySubject subject]];
[connection connect];

[connection.signal subscribeNext:^(id response) {
    NSLog(@"subscriber one: %@", response);
}];

[connection.signal subscribeNext:^(id response) {
    NSLog(@"subscriber two: %@", response);
}];
```

## 疑问
- RACStream的两个子类：RACSignal、RACSequence的区别是什么？
- multicast的使用

## 参考
- [Framework Overview](https://github.com/ReactiveCocoa/ReactiveObjC/blob/master/Documentation/FrameworkOverview.md)
- [DesignGuidelines](https://github.com/ReactiveCocoa/ReactiveObjC/blob/master/Documentation/DesignGuidelines.md)
- [细说ReactiveCocoa的冷信号与热信号（三）：怎么处理冷信号与热信号](https://tech.meituan.com/2015/11/03/talk-about-reactivecocoas-cold-signal-and-hot-signal-part-3.html)