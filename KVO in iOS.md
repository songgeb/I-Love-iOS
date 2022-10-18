# KVO in iOS

指定一个对象的某个属性，当该属性值发生变化时，可以通知给其他对象。这个机制就叫做KVO（Key-value observing）

### 使用
- `addObserver...`方法注册observer，`observeValueForKeyPath:...`接收change通知
- `addObserver`方法并没有对observing object、observer 和 context强引用，所以可能需要手动持有
- 建议在注册observer时传递context
	- 传入的context，不做修改地在接收change回调时传回给`observeValueForKeyPath:`
	- 当子类和父类都KVO了属性时,子类的`observeValueForKeyPath:`方法的执行会覆盖掉父类的
	- 所以父类KVO的change都会走到子类的中，子类可能无法处理或者可能因为代码质量不高导致错误
	- 此时如果通过context判断，可以知道是否是当前类要处理的change
	- 可以给每个要KVO属性的类都声明一个context，用静态变量的地址很合适--`static void *xxxContext = &xxxContext;`
	- 而且官方建议，如果通过context判断发现当前类无法处理，务必将事件交给super
- 注册的KVO不会因为对象dealloc而自动解除，需要手动解除
	- 由于observer dealloc时不会自动解除KVO，所以observed object仍可能发送通知过来，导致给released object发送消息而crash

#### Options
注册observers时有哪些option可以传

```
typedef NS_OPTIONS(NSUInteger, NSKeyValueObservingOptions) {
	NSKeyValueObservingOptionNew = 0x01,
	NSKeyValueObservingOptionOld = 0x02,
	NSKeyValueObservingOptionInitial API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)) = 0x04,
	NSKeyValueObservingOptionPrior API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0)) = 0x08
};
```
- NSKeyValueObservingOptionInitial，若设置该选项则表示，`addObserver`方法结束前，`observeValueForKeyPath:`方法就会执行一次
- NSKeyValueObservingOptionPrior，表示property更改前进行一次通知

#### Notification

收到的更改通知是`NSDictionary<NSKeyValueChangeKey, id> *`类型

```
typedef NSString * NSKeyValueChangeKey NS_STRING_ENUM;
/* Keys for entries in change dictionaries. See the comments for -observeValueForKeyPath:ofObject:change:context: for more information.
*/
FOUNDATION_EXPORT NSKeyValueChangeKey const NSKeyValueChangeKindKey;
FOUNDATION_EXPORT NSKeyValueChangeKey const NSKeyValueChangeNewKey;
FOUNDATION_EXPORT NSKeyValueChangeKey const NSKeyValueChangeOldKey;
FOUNDATION_EXPORT NSKeyValueChangeKey const NSKeyValueChangeIndexesKey;
FOUNDATION_EXPORT NSKeyValueChangeKey const NSKeyValueChangeNotificationIsPriorKey;
```

- `NSKeyValueChangeKindKey`对应value值有
	
	```
	typedef NS_ENUM(NSUInteger, NSKeyValueChange) {
		NSKeyValueChangeSetting = 1,
		NSKeyValueChangeInsertion = 2,
		NSKeyValueChangeRemoval = 3,
		NSKeyValueChangeReplacement = 4,
    };
	```
- `NSKeyValueChangeIndexesKey`对应的value值是`NSIndexSet`类型

- 对于是集合类型的`observed property`，获取插入的新数据
	1. `addObserver`时指定`NSKeyValueObservingOptionNew`
	2. `change[NSKeyValueChangeNewKey]`即为插入对象组成的数组
- 对于是集合类型的`observed property`，获取删除的数据
	1. `addObserver`时指定`NSKeyValueObservingOptionOld`
	2. `change[NSKeyValueObservingOptionOld]`即为被删除对象组成的数组

### Dependent Key

`dependent key`是指，有一个属性A（通常是一个`computed property`）的值是由其他1个或多个属性值决定，那这些属性就是A的依赖属性，即为`dependent key`

当使用KVO监听A的依赖属性时，如果依赖属性的值发生变化，我们自然也希望收到通知。但默认情况下，系统无法帮我们做到

本小节就是为了解决该问题

该问题的处理方法根据A和依赖属性之间的对应关系决定，具体关系可以是1对1，或者1对N

#### 1对1

比如`Person`对象中`fullName`这个`computed property`要有`firstName`和`lastName`两个属性决定

有两种解决办法

在`Person`中重写该方法

```
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
 
    if ([key isEqualToString:@"fullName"]) {
        NSArray *affectingKeys = @[@"lastName", @"firstName"];
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    return keyPaths;
}
```

或者实现一个自定义方法

```
+ (NSSet *)keyPathsForValuesAffectingFullName {
    return [NSSet setWithObjects:@"lastName", @"firstName", nil];
}
```

#### 1对N

比如有一个`Department`，拥有一个数组，数组中是`Employee`，`Employee`有一个工资属性`salary`，`Department`有一个`totalSalary`的属性表示公寓内所有雇员的工资和

当用KVO监听`totalSalary`时，如果其中的雇员的工资发生变化，如何让监听`totalSalary`的对象

`totalSalary`的取值由一个集合中的多个对象来确定

这种情况，1对1的方案是无法解决的

唯一的方法就是，在`Department`内部，要对集合中每个对象的相应属性，这里也就是`Employee`的`salary`进行KVO监听，同时对`Department`的`employees`集合属性监听

然后数据发生变化时统一告知外部监听`totalSalary`的对象

### KVO Compliance

如何让类、属性支持KVO

- 默认情况下，系统会自动为我们声明的`property`添加KVO支持的逻辑
- 但根据自定义类的功能不同，可能也有一些特殊情况可能需要手动处理，比如前面提到的`Dependent Key`的情况

可以通过两种形式：**自动**和**手动**

> 手动和自动是可以并存的，并非只能选择一种实现方式

#### Automatic Change Notification

系统借助KVC特性，在`NSObject`内部做了默认实现

- 在属性发生变化时，`NSObject`的默认实现会第一时间捕捉到，并通知给`Observer`

#### Manual Change Notification

对于一些特殊情况，或者不支持KVC的情况，系统也允许我们手动实现KVO

- 重写`+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key`方法，通过key针对需要手动通知的属性，返回`FALSE`
- 在属性发生修改时执行
	`willChangeValueForKey:`和`didChangeValueForKey:`
- 对于集合类型的属性更改的情况，还要为上面两个方法传入修改的`index`信息

### KVO原理

对于Automatic KVO，系统通过`is-a swzzling`技巧实现自动的KVO

- 在注册observer时，系统自动创建另一个class，该class中会加入发送通知的逻辑
- 被注册的对象的isa指针将指向该class
- 所以当被观察的属性发生变化时，observer会收到通知

### KVO in Swift?

Automatic Change Notification依赖的是NSObject的默认实现，所以要求参与到KVO的对象必须是NSObject的子类

Manual Change Notification中重写的`+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key`方法也是NSObject中的

- 所以KVO是依赖NSObject的
- Swift中NSObject的子类是可以应用KVO的
- Swift中纯Swift的类不支持KVO（但可以使用属性的willSet和didSet特性）


### 应用场景

#### AVFoundation

- 在使用AVFoundation时，有很多的操作，监听progress的方式都是通过KVO的方式
- 因为其中的操作以异步、耗时操作为主，如果为每个操作都通过delegate、block回调等方式来实现progress通知的话，势必会导致API过多，不好用，所以KVO是个不错的选择

#### Architecture

使用KVO(比如基于KVO实现的KVOController框架)简化代码逻辑

- Cocoa应用程序(mac OS的App)中，Controller和Model之间使用KVO的情形比较多

### QA


### 参考
- [Introduction to Key-Value Observing Programming Guide
](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html#//apple_ref/doc/uid/10000177-BCICJDHA)
