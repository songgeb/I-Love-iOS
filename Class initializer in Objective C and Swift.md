# Class initializer in Objective C and Swift.md

日常OC和Swift混编开发中，会遇到初始化方法使用混乱的问题，我又仔细阅读了[Object Initialization](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Initialization/Initialization.html)和Swit Language Programing Guide-Class Initializer，希望详细了解下initializer在Swift和OC中的区别，并通过一些异常情况加深理解，由此也更清楚最佳实践

## 核心思想上没区别

如小标题所言，我认为核心思想上没区别，两类初始化方法的目的和策略是一致的：

目的：保证类经过初始化后所有成员变量都完成赋值和额外的配置工作（如何布局视图等），这同样也包括复杂的类继承关系情况

策略：

- 初始化分两个过程，OC和Swift都是这样
	- 第一步，为所有类的成员变量进行赋值，该过程执行路径是从子类到父类
	- 第二步，每个类进行除成员变量之外的其他配置工作如进一步调整成员变量的值、布局视图等，该过程路径是从父类到子类

为了保证以上策略，苹果官方无论是Swift还是OC都对编写初始化方法做了一些规定，我简单地总结一下：

- 一个类至少有一个Designated Initializer，其他的初始化方法叫做Convenience Iinitializer(Swift官方叫法)或Seconary Initializer(Objective C官方叫法)
- Designated Initializer中必须执行父类的Designated Initializer，Convenience Initializer中则只能调用当前类中的Convenience Initializer或Designated Initializer

> 更具体的规则在官方文档中都有说明

对于上述规则，通过官方的两个示例图能可以很直观的了解

Swift官方示例图

![](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2020/3/30/1712927fc363bdea~tplv-t2oaga2asx-zoom-in-crop-mark:1512:0:0:0.awebp)

Objective C示例图

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/oc_initialization_process.gif?raw=true)

## 具体实现上的区别

在具体实现上，Swift Class Initialization和OC Class Initialization还是有区别的：

### 初始化成员变量原理不同

虽然初始化策略第一步都是为成员变量赋初始值，但工作原理不同

先来看OC

OC官方的说法为：

> The default set-to-zero initialization performed on an instance variable during allocation is often sufficient. Make sure that you retain or copy instance variables, as required for memory management.

用代码举例：

```
- (instancetype)initWithFrame:(CGRect)frame {
											// 1.1
	if (self = [super initWIthFrame:frame]) { 1.2
		_instanceIntProperty = 1; // 2
	}
	return self;
}
```

真正为成员变量赋值的过程其实是在1.1和1.2，很多人可能一直是认为在2吧，2其实是初始化策略中的第2步。1.1这一行啥也没有，其实意思就是系统帮我们完成了成员变量赋值工作。只是它会讲所有的成员变量赋值为默认值0 or nil等

那Swift为成员变量赋值则更易识别

```
init(frame: CGRect) {
	_instanceIntProperty = 1 // 1.1
	super.init(frame: frame) // 1.2
	_instanceIntProperty = 2 // 2
}
```

毫无疑问，1.1就是赋值过程。默认情况下Swift Class的每个成员变量是没有默认值的，我们可以为其指定默认值或者在初始化方法中为其赋值，那么这个赋值过程就发生在1中

而且，通过上面代码相比OC，可以更清楚地看出初始化策略的第1、2步，上述代码中的1.1和1.2就是策略中的第1步，2以及后续代码时第2步

### Swift相比OC做了更多保护机制

Swift中加入很多保护策略，使开发者在自定义Class时更易写出符合规范的初始化方法，具体来说：

- 通过编译器强制要求先执行策略1，再执行策略2。即上面的代码我们不可能在不为_instanceIntProperty赋值的情况下而执行super.init(frame:)方法，否则编译出错
- 同样在编译阶段，强制约束类同级和跨层级之间Convenience Initializer和Designated Initializer的调用顺序，一旦违反规则，编译报错

## OC编写初始化方法易错点

相比于Swift，由于OC的动态特性以及编译器并不会强制约束开发者按照规则定义初始化方法，在实际开发中还是比较容易出错的。本节列举几个实际工程中遇到的例子：

> 先贴一下官方针对在OC中自定义初始化方法时的一些规则或者说提醒，当看完本节中的案例后再回来看这些规则，体会更明显

- When you define a subclass, you must be able to identify the designated initializer of the superclass and invoke it in your subclass’s designated initializer through a message to super. 
- You must also make sure that inherited initializers are covered in some way.
- When designing the initializers of your class, keep in mind that designated initializers are chained to each other through messages to super; whereas other initializers are chained to the designated initializer of their class through messages to self.
- The designated initializer for each class is the initializer with the most coverage; it is the method that initializes the attribute added by the subclass. The designated initializer is also the init... method that invokes the designated initializer of the superclass in a message to super.
- When creating a subclass, it’s always important to know the designated initializer of the superclass.
- Secondary initializers (as in this example) are frequently overridden versions of inherited initializers

### Designated Initializer中未调用父类Designated Initializer

```
@Interface ABCView: UIView
@end

@implementation ABCView
- (id)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
	/// balabala
}
@end
```

- 上述代码存在的问题是没搞清楚ABCView父类的Designated Initializer是谁。UIView的Designated Initializer是`initWithFrame:`
- 所以在实现自己的初始化方法时选择了`init`方法
- 这会导致，当使用`[[ABCView alloc] initWithFrame:frame]`初始化ABCView时，`commonInit`未执行

解决办法也很简单

```
- (instancetype)initWithFrame:frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)init {
	return [self initWithFrame:CGRectZero]; 
}
```

此时无论我们`[ABCView new]`, `[[ABCView alloc] init]`还是`[[ABCView alloc] initWithFrame:frame]`，都不会出错

追问一个问题：必须要重写`init`方法吗？

当然不是，可以完全不用重写`init`方法，因为UIView的`init`方法也是类似的实现，ABCView继承了该方法，所以效果是等价的


> 至于为什么规定Designated Initializer中必须执行父类Designated Initializer方法？我的另一篇文章中有提到--[再谈Initializer in iOS](https://juejin.cn/post/6953452839364460581)

### 子类覆盖了父类的实现

```
@Interface BaseClass: NSObject
@end

@implementation BaseClass
- (instancetype)init {
    self = [super init];
    if (self) {
        [self privateMethod];
    }
    return self;
}

- (void)privateMethod {
    NSLog(@"privateMethod in BaseClass!");
}
@end

@Interface SubClass: BaseClass
@end

@implementation SubClass

- (void)privateMethod {
    NSLog(@"privateMethod in SubClass!");
}
@end
```

需要说明的是两个类中的privateMethod方法都是其各自内部的私有方法

当执行`[[SubClass alloc] init]`时，我们会发现子类的`privateMethod`执行了，而父类的没有执行

原因在于OC的消息发送机制，内部在寻找`privateMethod`实现时，会先去看子类中有无该实现，有就执行。所以OC中其实本质上没有什么私有方法

但这确实给我们写初始化方法提了一个醒，在命名私有方法时可能需要考虑被覆盖的情况

### 复杂Designated Initializer的情况下，合理使用初始化方法相关的宏

比如，我们需要写一个高可复用的自定义视图，不同业务需要通过继承该视图的方式来使用它，初始化方法需要传入几个必需的参数，很显然这个参数最多的Initializer就是Designated Initialzer了，同时可能还需要提供几个便捷的Convenience Initializer

这时候使用该视图的开发人员使用时，看到有这么多初始化方法可能不知如何用

OC给我们提供了几个编译修饰符，来提高代码的易用性

```
@interface ABCView : UIView
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)initWithA:(TypeA)a b:(TypeB)b c:(TypeC)c NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithA:(TypeA)a;
@end
```

通过上面类似`NS_DESIGNATED_INITIALIZER`的宏，使用方会很容易了解谁是Designated Initialzer，避免继承时出错；并且由于我们内部不想重写`initWithFrame:`等方法，可以使用`NS_UNAVAILABLE`将相关方法从编译层面禁掉，使用方便根本无机会用错方法了

而且，由于Swift的强规则，如果OC的类写不好，在混编情况下，Swift中使用不规范初始化的OC类时，往往遇到各种棘手的问题

## 最后

终极建议：抛弃OC，改用Swift，Swift把所有问题都自动提醒出来或解决掉了，想啥呢，还在用OC？

当年学习OC时没敢选择官方英文文档，现在才仔细阅读，发现真的是好资料，覆盖了各种异常情况，同时会将初始化的目的和核心思想讲出来，这在中文材料中可不一定能体现出来。所以学好英语，看一手资料！

## 参考
- [Object Initialization](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/Initialization/Initialization.html)
- [再谈Initializer in iOS](https://juejin.cn/post/6953452839364460581)
- [Initializers in Swift Class](https://juejin.cn/post/6844904106658627597)