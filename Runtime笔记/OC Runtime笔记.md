# OC Runtime 笔记

## objc_msgSend

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/runtime_messaging1.gif?raw=true)

- 类这个数据结构中有一个`Dispatch Table`，存放着当前类的实例方法的selector和方法实现地址信息
- 当通过`[object message]`形式发送消息时
- `objc_msgSend`方法根据`receiver`和`selector`，根据下面的路线寻找相应`selector`的实现
- 若当前类中找不到，则通过`superclass`去父类中找，一直找下去
- 这个过程在面向对象中也叫做动态绑定`dynamic binding`
- 每个类中对`selector`做了缓存，缓存不仅包括本类中使用过的方法，也有从继承下来的方法。先访问缓存，速度更快

- 编译结束后，编译器其实会将`receiving object`和`selector`作为两个隐藏参数写入到方法实现中
- 在方法中可以`_cmd`来获得`selector`，用`self`获取`receiving object`

## Dynamic Method Resolution

### Dynamic Method Resolution
- 开发者可以动态的添加类或实例方法
- `resolveInstanceMethod`或`resolveClassMethod`这两个方法会当在系统在类层级中找不到对应方法时执行
- 开发者可以选择在这个时机使用runtime的一些方法比如`class_addMethod`给类添加方法

### class、objc\_getClass、object\_getClass方法

```
// Returns the class definition of a specified class.
id objc_getClass(const char *name);
```

```
// Returns the class of an object.
Class object_getClass(id obj);
```

```
// Returns the class object.
+ (Class)class; // in NSObject Class

// Returns the class object for the receiver’s class.
- (Class)class; // in NSObject Protocol
```

我们来看下打印结果

```
[instance class] is 0x10fa70b30
[Class class] is 0x10fa70b30
object_getclass(instance) is 0x10fa70b30
object_getclass(class) is 0x10fa70b08
objc_getMetaClass(Class) is -> 0x10fa70b08
```

- 从规律上来说这三个方法的作用不是很容易记忆
- 然后从每个方法官方的注释和方法签名上来理解一下可能更容易记忆
- 需要一些前置知识
	- 区分这三个概念：实例、类对象、元类
	- `Class`类型的定义是`typedef struct objc_class *Class;`
	- 其实对于类对象、元类，都是`Class`类型
	- 实例的定义是`struct objc_object {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
};`
	- 类对象和元类都是单例

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/instance_class_metaclass.png?raw=true)

### ivar的值存在哪里

之所以有这个疑问是因为，从OC实例、类对象、元类的C结构体来看，搞不明白一个实例的成员变量的值在哪里，因为在类对象中只是存储了ivar的name和type

- 其实ivar成员变量并没有存在`objc_class`结构体中
- 而是对于每个实例，成员变量存储位置实际上紧跟着这个实例的内存地址来存储

### Getting a Method Address

前面我们知道一个方法的执行，要通过一些查找过程才能最终确定方法实现

runtime也提供了直接获取方法实现地址的方法

```
- (IMP)methodForSelector:(SEL)aSelector;
```

使用该方法和OC的发送消息的不同在于，发送完消息runtime要经过一系列查找，而该方法则不用

## Messaging Forwarding

消息转发，是当给某个对象发送消息时，本身该对象并没有处理该消息的方法时，默认情况下会走到`NSObject`的`doesNotRecognizeSelector`方法，抛出异常

但运行时提供了一些机会，让开发者可以修改消息内容，或者修改消息的receiver，即将消息转发给其他对象

> 这部分详细流程在《Effective in Objective-C》笔记中有提到

### Forwarding and Multiple Inheritance

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/forwarding_multipleinheritance.gif?raw=true)

- 给`Warrior`对象发送了`negotiate`消息，但并没有实现
- `Warrior`将消息转发给了`Diplomat`对象来处理
- 看上去好像`Warrior`能处理`negotiate`消息，好像`Warrior`对象继承了`Diplomat`的方法
- 这就是所谓的多继承

## Type Encodings

- 未完待续

# 参考
- [Objective-C Runtime Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008048-CH1-SW1)