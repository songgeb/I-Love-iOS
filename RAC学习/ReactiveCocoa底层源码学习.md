# ReactiveCocoa底层源码学习

## subscription

一个普通的`RACSignal`创建、订阅的过程中都发生了什么

- 自动创建了一个订阅者，这个订阅者其实就是在创建`RACSignal`时block中的入参subscriber

## RACSignal

### subscribe系列方法

```
- (RACDisposable *)subscribeNext:(void (^)(id x))nextBlock completed:(void (^)(void))completedBlock {
	NSCParameterAssert(nextBlock != NULL);
	NSCParameterAssert(completedBlock != NULL);
	
	RACSubscriber *o = [RACSubscriber subscriberWithNext:nextBlock error:NULL completed:completedBlock];
	return [self subscribe:o];
}
```

- subscribe系列方法做的工作是，内部新建了一个`RACSubscriber`订阅者
- 然后执行向self发送`- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber`消息

### + (RACSignal *)return:(id)value

```
+ (RACSignal *)return:(id)value {
	return [RACReturnSignal return:value];
}
```

来看一下`RACReturnSignal`的`return`实现

```
+ (RACSignal *)return:(id)value {
	RACReturnSignal *signal = [[self alloc] init];
	signal->_value = value;
	return signal;
}
```

## RACDynamicSignal

```
- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
	NSCParameterAssert(subscriber != nil);

	RACCompoundDisposable *disposable = [RACCompoundDisposable compoundDisposable];
	subscriber = [[RACPassthroughSubscriber alloc] initWithSubscriber:subscriber signal:self disposable:disposable];

	if (self.didSubscribe != NULL) {
		RACDisposable *schedulingDisposable = [RACScheduler.subscriptionScheduler schedule:^{
			RACDisposable *innerDisposable = self.didSubscribe(subscriber);
			[disposable addDisposable:innerDisposable];
		}];

		[disposable addDisposable:schedulingDisposable];
	}
	
	return disposable;
}
```
- `subscribe`方法做的事情就是执行了`RACDynamicSignal`的`didSubscribe`block代码
- 其实就是`createSignal`的block参数
- 就是一旦订阅`RACDynamicSignal`就会立即出发`didSubscribe`的代码逻辑

## RACSubject

```
RACSubject *letters = [RACSubject subject];
// Outputs: A B
[letters subscribeNext:^(id x) {
    NSLog(@"%@ ", x);
}];
[letters sendNext:@"A"];
[letters sendNext:@"B"];
```

- 是`RACSignal`的子类
- 但同时又遵循了`RACSubscribe`协议，所以有了`sendNext`等方法
- `RACSubject`内部维护了disposable(RACCompoundDisposable)和subscribers(数组)两个成员变量
- 从`RACSignal`继承下来的`- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber`方法的实现是
	1. 将传过来的subscribe（包了一层后）添加到`subscribes`中
- 执行`RACSubject`的`sendNext:value`时
	1. 其实就是遍历`subscribers`中的每个订阅者，然后对每个订阅者发送`sendNext:value`消息

### RACReplaySubject

- 是`RACSubject`的子类
- 内部维护了一个整型的`capacity`和`valuesReceived`数组
	- `valuesReceived`保存了信号曾经发送过的数据
- 它的`subscribe`方法做的工作是
	1. 从`valueReceived`中取出每个值，先向订阅者发送一遍
	2. 然后执行父类的`subscribe`方法，即将订阅者加入到`subscribers`中
- `sendNext`方法做的事情
	1. 先将要发送的value加入到`valuesReceived`中
	2. 执行父类的`sendNext`方法，向订阅者发送内容
	3. 如果`valuesReceived`中的值已经超过`capacity`了，需要从前面清理一波数据

## RACSubject vs RACSignal

### next等事件主动还是被动发
- 当订阅了`RACSignal`时，rignal的`didSubscribe`就会被触发，进而`subscribeNext:block`等回调会执行
- 当订阅了`RACSubject`时，需要主动执行`RACSubject`的`sendNext`等方法才会触发`subscribeNext:block`的回调执行

### 冷热信号

- RACSubject是热信号，RACSignal中除RACSubject外是冷信号
- 冷信号的特点是无状态的，每次订阅时都会执行一次`didSubscribe`block，即发信号的逻辑会重新执行一遍
- 热信号是有状态的，后来订阅的订阅者无法收到之前发送的事件

### 使用场景


## RACCommand

> A command, represented by the RACCommand class, creates and subscribes to a signal in response to some action. This makes it easy to perform side-effecting work as the user interacts with the app.

有必要解释一下这里提到的`side-effecting work`，翻译为副作用，到底啥是副作用呢

官方说明如上所示，本身没有数据流的概念，而是用来管理信号的类


## RACSignal Operations

这里说的operation是指`map`、`flattenMap`、`filter`等操作，通过这些操作的分析了解数据流过程中都干了什么

核心的操作是`RACSignal`的`bind`方法，其他operation操作最终都要走到这里

精简后的逻辑如下所示

```
- (RACSignal *)bind:(RACStreamBindBlock (^)(void))block {
    return [RACSignal createSignal:^(id<RACSubscriber> subscriber) { // (1)
        RACStreamBindBlock bindingBlock = block();

        [self subscribeNext:^(id x) { // (2)
            BOOL stop = NO;
            id middleSignal = bindingBlock(x, &stop); // (3)

            if (middleSignal != nil) {
                RACDisposable *disposable = [middleSignal subscribeNext:^(id x) { // (4)
                    [subscriber sendNext:x]; // (5)
                } error:^(NSError *error) {
                    [subscriber sendError:error];
                } completed:^{
                    [subscriber sendCompleted];
                }];
            }
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } completed:^{
            [subscriber sendCompleted];
        }];

        return nil
    }];
}
```

- `bind`操作返回了一个新的信号newSignal，`self`表示原来的信号
- 新创建的信号内部做了几件事情
- 1. 首先执行传入的block方法，获得一个本次operation真正要执行的操作的bindingBlock，注意这个bindingBlock的返回值是一个信号
- 2. 然后立即订阅原信号即`self`
- 当外部订阅newSignal时，会立即执行上面的1、2
- 由于执行了2中的，订阅原信号操作，触发了原信号的逻辑，可能会发送next事件
- 于是，bingdingBlock会被执行，执行结束后，产生一个中间信号middleSignal，若信号不为空（何时为空呢？比如filter操作中不满足要求时就是空），就对middleSignal进行订阅，那middleSignal信号中的逻辑也会立即执行，其实拿`map`为例，就是执行了`map`参数block中的逻辑，并将block的结果值通过`sendNext`发了出去

## RACScheduler

- `subscribeOn:`，表示该方法将创建一个信号返回，该信号的创建和接受要在指定的scheduler（线程）中
	- 但官方建议最好不要用，因为创建信号的逻辑在别的线程可能不安全
- `deliverOn:`，表示创建一个新的信号返回，该信号的事件将在指定线程中发送

## 疑问
1. 为什么订阅者`RACSubscriber`可以发送next等消息呢？
	- 不要将`[subscriber sendNext]`理解为订阅者发送消息，而要理解为向订阅者发送消息
2. `RACScheduler`的运行机制

## 参考
- [ReactiveCocoa Essentials: Understanding and Using RACCommand](http://codeblog.shape.dk/blog/2013/12/05/reactivecocoa-essentials-understanding-and-using-raccommand/)
- [细说ReactiveCocoa的冷信号与热信号（一）](https://tech.meituan.com/2015/09/08/talk-about-reactivecocoas-cold-signal-and-hot-signal-part-1.html)
- [ReactiveCocoa 组件的内存逻辑分析](https://zhangbuhuai.com/post/rac-part-3.html)