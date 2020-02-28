# iOS难点攻关

## 长期

## Core Animation

## Swift
[Cocoa Design Patterns](https://developer.apple.com/documentation/swift/cocoa_design_patterns)

## float
nan、inifinity
## webview中
wkwebview
## cell嵌套使用

autolayout布局有错误

## 线程安全问题

- queue
- synchronize
- nsthread

- [Concurrency Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008091-CH1-SW1)

## URLSession

## when to use struct

## Git
- head、ref、config等基础概念的理解

## translation in gesture

## Property in OC

Typically you should specify accessor method names that are key-value coding compliant (see Key-Value Coding Programming Guide)—a common reason for using the getter decorator is to adhere to the isPropertyName convention for Boolean values.

- 头文件中的`@property`只能说明在**头文件**中声明了setter和getter两个或其中的一个方法。.m文件中到底有没有是不确定的

- 为啥按照这个格式写`ClassName * qualifier variableName;`
- 当在attribute中写(getter=isWhat)时，使用点语法时，有哪些可能
- Core Foundation属性有什么注意事项

[Declared Properties](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocProperties.html#//apple_ref/doc/uid/TP30001163-CH17-SW1)

## Core Foundation

用的不多，理解不够

- Note: If you install a custom callback on a Core Foundation collection you are using, including a NULL callback, its memory management behavior is undefined when accessed from Objective-C.
- Casting and Object Lifetime Semantics 这一节没看完

### Core Foundation Memory Management

- 内存管理原则和Foundation类似
	- 当方法名中有"Create"和"Copy"时，则retaincount + 1
	- 方法名中包含"Get"时，引用计数不变
	- 但是没有ARC，retain和release得自己写
- 内存管理需要手动执行retain和release方法
	- 编译器无法知道CF对象的生命周期情况
- 相比Foundation，Core Foundation缺少autorelease机制
	- 所以通常如果需要通过Get方法获取数据时，最好retain一把
- 当将object当做参数传递时，方法中为了避免对象被释放，使用前最好也retain一把
	- 其实Foundation中也有类似问题，只是ARC下编译器会帮我们加上代码；MRR下，我们也是可以先retain一把的
- 由于编译器不清楚CF对象的生命周期，而编译器又可以通过ARC管理Foundation对象的生命周期，那CF对象和Foundation对象相互cast时，需要指明内存管理标示
	- \_\_bridge，可以用在两种对象互相转换时，ownership所有权没有任何改变
		- Foundataion下创建的对象转到CF时，告知CF，CF并没有拥有对象的所有权。相当于CF中Get方法获取对象
		- 反之亦然
		
		```
		NSURL *url = [[NSURL alloc] initWithString:"http://fuck.com"];
    	CFURLRef urlRef = (__bridge CFURLRef)url;
		```
		url的所有权没有发生任何转义，还是ARC下管理，所以无需执行CFRelease释放urlRef
	- \_\_bridge\_retained或CFBridgingRetain，在Foundation对象转换到CF对象时使用，相当于CF在用create或copy方法获得一个对象，所以CF下要记得CFRelease		
		```
		CFURLRef urlRef = (__bridge_retained CFURLRef)url;
		// do with urlRef
		CFRelease(urlRef);
		```
		urlRef拥有对url数据的所有权，所以要记得CFRelease(urlRef)释放
		
	- \_\_bridge_transfer或CFBridgingRelease，CF对象转为Foundation对象时使用，CF放弃了对象的所有权，无需通过CFRelease再次释放		

[Memory Management Programming Guide for Core Foundation](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFMemoryMgmt/CFMemoryMgmt.html#//apple_ref/doc/uid/10000127i)


[Core Foundation Design Concepts](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFDesignConcepts/CFDesignConcepts.html#//apple_ref/doc/uid/10000122-SW1)


## Sharing Access to keychain

## OC Runtime Programing Guide


## IndexSet

## window.level
- top window dertimine statusbar appearence

[window programing guide](https://developer.apple.com/library/archive/documentation/WindowsViews/Conceptual/WindowAndScreenGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40012555-CH1-SW1)

## new feature in Swift5

## Toll-Free Bridging

## OutputStream

## CoreAnimation完整Guide及核心概念联系

1. layer的zPosition可以决定先展示哪个吗
2. 哪些animatable的属性

## xib、storyboard

## 短期
### NSCoding
