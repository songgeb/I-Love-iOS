# ReactiveCocoa学习笔记
> 深入理解代替单纯记忆

ReactiveCocoa是一种**函数响应式**的编程框架

## 响应式编程

- 与响应式相对的是主动型编程
- 以开关控制灯泡为例，主动型编程是开关类中持有一个灯泡，开关发生变化时调用灯泡的方法控制灯泡亮和灭
- 响应式则不同
	- 开关作为被观察者，只需要提供一个接口，表示接受监听者
	- 当开关发生变化时，只需要告诉监听者即可
	- 灯泡当然就是监听者了，当收到开关状态变化的消息时，修改自己的亮和灭
- 很显然，响应式降低了灯泡和开关之间的耦合度

## 函数式编程
## ReactiveCocoa
- ReactiveCocoa提供了一些特性，可以将那些基于事件驱动的逻辑，换一种编码方式编写，这种方式就是函数响应式的形式
- 所谓基于事件驱动的逻辑，有很多种，具体到iOS中，可以是delegate方法、target-action、kvo、通知，同步异步的事件都可以，也可以自定义信号，比如一个异步网络请求的逻辑可能需要通过delegate来拿到请求回调再处理结果，我们完全可以封装为一个RACsignal

### RACSignal
- 能够做到上面的事情的基础就是RACSignal
- RACSignal可以按照字面意思理解为信号
- 信号可以发送很多事件
- 有三种事件：next、error、complete
- next事件会多次发送，error和complete则是互斥且只会发送一次
- next之所以会多次，因为某个事件可能发生多次，比如一个btn点击事件
- 对这些事件的响应则要通过**订阅**这些事件--`subscribe`系列方法
- 可以对一个信号进行多次订阅
- RAC给很多UI组件通过分类的方式添加了信号事件，可以很方便的通过`rac_textSignal`类似的方法得到这些信号

### 事件流
- 响应式编程的核心在于，将一个事件的逻辑看做一次数据流
- 一个事件发生后，数据流经多个节点，最终得到处理，这叫做事件流
- 在整个事件流中，可能经过多个环节-map、filter等，每个节点可以对数据进行转换
- 事件流中每一次经过节点，返回的都仍是信号，所以可以进行类似链式调用

#### 举例1
![](https://user-images.githubusercontent.com/5978164/92364836-3c3e7980-f126-11ea-96b9-ee40facee112.png)

这是两个textfield和一个登陆按钮的故事：

1. 两个textfield分别是username和password
2. 要求两个textfield输入的字符数必须大于3时才有意义，否则textfield会显示背景色提示，同时登录按钮不可点击

上图便是事件流（或数据流）的一个完整体现

1. 两个textfield通过`rac_textSignal`得到信号
2. 信号发送next事件，先经过`map`，对文本数据进行校验并转换为BOOL类型，进一步转为UIColor类型，从而决定textfield的背景色
3. 同时，并行的另一条分支是，通过对两个信号进行`combine`结合操作，结合后的结果可以决定登录按钮的状态

对应如下代码

```
    // 两个textfield背景色控制
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidUsername:value]);
    }];
    RAC(self.usernameTextField, backgroundColor) =
    [validUsernameSignal map:^id(NSNumber *isValidNumber) {
        return [isValidNumber boolValue] ? UIColor.clearColor : UIColor.yellowColor;
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidPassword:value]);
    }];
    
    RAC(self.passwordTextField, backgroundColor) =
    [validPasswordSignal map:^id(NSNumber *isValidNumber) {
        return [isValidNumber boolValue] ? UIColor.clearColor : UIColor.yellowColor;
    }];
    
    // login btn enable控制
    // 联合两个signal为一个signal
    RACSignal *signUpActiveSignal =
    [RACSignal
     combineLatest:@[validUsernameSignal, validPasswordSignal]
     reduce:^id(NSNumber *isUsernameValidNumber, NSNumber *isPasswordValidNumber) {
        return @([isUsernameValidNumber boolValue] && [isPasswordValidNumber boolValue]);
    }];
    
    [signUpActiveSignal subscribeNext:^(NSNumber *canSignUpNumber) {
        self.signInButton.enabled = [canSignUpNumber boolValue];
    }];
    
    // btn touchupinside
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
    doNext:^(id x) {
        self.signInButton.enabled = NO;
        self.signInFailureText.hidden = YES;
    }]
    flattenMap:^id(id value) {
        return [self signInSignal];
    }]
    subscribeNext:^(NSNumber *successNumber) {
        self.signInButton.enabled = YES;
        BOOL isSuccess = [successNumber boolValue];
        self.signInFailureText.hidden = isSuccess;
        if (isSuccess) {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
```

#### 举例2
![](https://user-images.githubusercontent.com/5978164/92365488-7c9df780-f126-11ea-8978-40226a605c64.png)

该例子是在searchTextField中输入内容，搜索twitter数据，并展示的过程

1. `requestxxx`获得自定义的请求twitter数据信号
2. 通过`then`操作，等待`complete`事件，否则直接将error信息给最后的执行者
3. twitter数据请求成功后，事件流中的信号转为searchTextField的`rac_textSignal`信号
4. 进行`filter`、`throttle`等一系列操作，通过`flattenMap`中的`signalForSearchText`创建发请求的signal，并执行请求

对应如下代码

```
[[[[[[[self requestAccessToTwitterSignal]
  then:^RACSignal *{
    @strongify(self)
    return self.searchText.rac_textSignal;
  }]
  filter:^BOOL(NSString *text) {
    @strongify(self)
    return [self isValidSearchText:text];
  }]
  throttle:0.5]
  flattenMap:^RACStream *(NSString *text) {
    @strongify(self)
    return [self signalForSearchWithText:text];
  }]
  deliverOn:[RACScheduler mainThreadScheduler]]
  subscribeNext:^(NSDictionary *jsonSearchResult) {
    NSArray *statuses = jsonSearchResult[@"statuses"];
    NSArray *tweets = [statuses linq_select:^id(id tweet) {
      return [RWTweet tweetWithStatus:tweet];
    }];
    [self.resultsViewController displayTweets:tweets];
  } error:^(NSError *error) {
    NSLog(@"An error occurred: %@", error);
  }]; 
```

### 深入理解事件流
- ReactiveCocoa内部会有全局变量存储着signal等信息
- 如果创建了信号，但并没有任何的订阅者，那ReactiveCocoa并不会存储pipline中的信号等对象
- subscribe方法返回一个`RACDisposable`对象
- 正常情况下signal发送完complete或error后，订阅状态会自动移除，但使用`RACDisposable`也可以手动移除
- 当pipline中信号发送了error，error会直接传到最终的error处理block中

### RACSignal常用方法

|方法|描述|备注|
|:-:|:-:|:-:|
|map|- (instancetype)map:(id (^__strong)(__strong id))block;|对信号发送的事件的数据进行转换|
|flattenMap|- (instancetype)flattenMap:(RACStream * (^__strong)(__strong id))block;|当block中返回的也是一个RACsigna时，使用flattenMap可以避免后面拿到RACsignal类型的数据，flattenMap会对signal的数据进行解包|
|combine|+ (RACSignal *)combineLatest:(id<NSFastEnumeration>)signals reduce:(id (^__strong)())reduceBlock;|将多个信号进行合并，结果就是任何一个信号发送next时，block都会执行|
|then|- (RACSignal *)then:(RACSignal * (^__strong)(void))block;|等待recevier代表的signal发送了complete或error事件后，pipline中流程才会继续，如果是complete，则会执行block中的方法，信号会转换为block中产生的信号；如果是error，则直接交给subscribeerror中处理了|
|deliverOn|- (RACSignal *)deliverOn:(RACScheduler *)scheduler;|该方法得到的信号，后面的event将会在指定的线程中|
|throttle|- (RACSignal *)throttle:(NSTimeInterval)interval;|节流控制，比如在textfield中输入内容搜索时，希望输入了一个字符后停留500ms的情况才执行搜索。该方法就是当停留了指定时间(秒)后下一次`next`事件还未到，才会发送该次`next`事件|
|doNext|- (RACSignal *)doNext:(void (^__strong)(__strong id))block;|signal发送完next事件后会执行该方法block中的逻辑。该方法并不需要返回什么数据类型，只是给开发者一个时机做一些`side-effect`的事情|
|concat|- (RACSignal *)concat:(RACSignal *)signal|返回一个新的信号，这个新的信号会先通过receiver发送事件，发送结束后紧跟着发送参数signal中的事件|
|startWith|- (instancetype)startWith:(id)value|返回一个新stream（或者说信号），事件值以value开始，后面紧跟着receiver的事件|
|takeUntil|- (RACSignal *)takeUntil:(RACSignal *)signalTrigger|receiver会一直往订阅者发送消息，直到signalTrigger发送了next或者complete|

### 使用技巧
- `RAC(self.passwordTextField, backgroundColor) = xxxsignal`，这里的宏的意思是xxxsignal中的事件结果会被赋值到textField的backgroundColor


## 疑问
1. keypath宏干嘛的？
2. `RACSignal`的`createSignal`方法

## 参考
- [ReactiveCocoa Tutorial – The Definitive Introduction: Part 1/2](https://www.raywenderlich.com/2493-reactivecocoa-tutorial-the-definitive-introduction-part-1-2)