# ReactiveCocoa笔记-实践篇

## RACSubject
由于`RACSubject`遵循了`RACSubscriber`协议且是`RACSignal`的子类，所以既可以被订阅，也可以主动发送消息

### 自定义代理

可以代替iOS原生的代理模式

比如有页面A和B，A可以跳转到B，B处理完逻辑后，将内容通过代理回传给A

iOS原生代理实现可以是，

1. B中声明一个Delegate Protocol，让A实现该协议
2. B中持有一个对Delegate Protocol的弱引用变量`delegate`
3. 跳转到B时，将`delegate`赋值为A实例
4. B中处理完逻辑后，执行代理方法

改用RAC实现则可以这样实现

1. B中定义一个`RACSubject`类型的信号变量`delegateSignal`
2. 跳转到B时，初始化B的同时，也初始化并赋值`delegateSignal`
3. 同时订阅`delegateSignal`信号
4. B中处理完逻辑后直接给`delegateSignal`发送消息`[delegateSignal sendNext: obj]`

> RAC的实现感觉和为B定义一个block没啥区别


## RACCommand
### 猜喜页RACCommand使用实践

介绍一下上下文

- `MMCGuessLikeViewModel`表示猜喜页需要展示相关的数据信息
- `recommendCommand`，该command的核心任务是创建一个搜索推荐内容的请求的信号`requestSignal`，并订阅该信号，同时请求结束后，通过`subscriber`继续发送事件
- 外部vc中，通过`viewModel.recommandCommand`获取到该`RACCommand`，并订阅该command的`executionSignals`进行收到数据后的处理工作
- 然后在合适的时机执行`[recommendCommand execute]`即可

