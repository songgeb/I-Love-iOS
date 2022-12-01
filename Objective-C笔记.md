# Objective-C笔记

### Category and Extension

- category中只能添加方法
- 方法名不能与原类中冲突，否则运行时可能会出现覆盖的问题
- extensnion中既可以添加方法也可以添加方法
- extension必须要在有原类源码的情况下才能声明，因为声明的方法要在类的`implementation`中实现

### self vs super
```
@implementation Son : Father
- (id)init
{
    self = [super init];
    if (self)
    {
        NSLog(@"%@", NSStringFromClass([self class]));
        NSLog(@"%@", NSStringFromClass([super class]));
    }
    return self;
}
@end

Son *son = [[Son alloc] init];

// 打印结果
// son
// son
```

- 简言之，区别于self，super只是一个编译器标识符（Magic Keyword），对super执行方法时，会找到self的父类的方法列表中对应的方法，并通过objc_msgSend的方式执行
- super指向的内容仍然是self，所以在父类中找到方法后，objc_msgSend执行时传的第一个参数仍是self
- [iOS-Self & Super(Runtime)](https://www.jianshu.com/p/71bbcb99ddbc)
- [Cocoa Fundamentals Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html#//apple_ref/doc/uid/TP40002974-CH4-SW3)

### sleep vs usleep

usleep的参数时u秒

### 宏定义的使用

- 宏定义并不是OC的特性，而是C语言的语法
- 宏定义有对象宏 和 函数宏
    - `#define PI 3.1415926`是对象宏
    - `#define MIN(x, y) (x < y ? x : y)`是函数宏（注意这个MIN的写法并不完备，完备写法请看参考文章）


#### 常用的预定义宏

不同编译器预定义了一些内置的宏，方便开发者拿来使用

#### 那些之前没见过的宏

- PATH_MAX

### 常见的宏中的运算符

- \##：`#define JOINT(A, B) A##B`, 将A和B参数的值拼接到一起
- \#：`#define String(A) #A`，将A的变量名（并非A的值）转为字符串

### 函数宏中的可变参数

```
//1
#define Log(format, ...) NSLog(format, ##__VA_ARGS__)
//2
#define Log(format, ...) NSLog(format, __VA_ARGS__)
```
- 三个点用在宏定义的声明部分，__VA_ARGS__用在实现部分
- 既然是参数个数可变，那么也可以是0个参数，即没有参数
- 此处之所以写`##`，是一个特例，因为可以可变参数可以为0个，那么对于2的写法，就会多出一个逗号，编译是不通过的。如果加了`##`，编译器会在可变参数为0时，将其前面的逗号吃掉
- `...`和`__VA_ARGS__`配对使用，与这个配对有相同作用的是`NAME...`和`NAME`配对使用，这里的NAME可以是任意内容

### 如何打印百分号%

```
NSLog(@"%"); //%无法打印出来
NSLog(@"%%"); //正确姿势，且适用于`print`和Swift的String方法
```

#### 参考
- [宏定义的黑魔法 - 宏菜鸟起飞手册](https://onevcat.com/2014/01/black-magic-in-macro/)
- [builtin-macros in clang](http://clang.llvm.org/docs/LanguageExtensions.html#builtin-macros)
- [predefine macros in gcc](https://gcc.gnu.org/onlinedocs/cpp/Predefined-Macros.html#Predefined-Macros)
- [宏定义中\# 和 \##的区别](https://stackoverflow.com/questions/4364971/and-in-macros)

### Attribute
- UNAVAILABLE_ATTRIBUTE
- NS_DESIGNATED_INITIALIZER

### NSMapTable的使用

- [NSMapTable: more than an NSDictionary for weak pointers](http://www.cocoawithlove.com/2008/07/nsmaptable-more-than-nsdictionary-for.html)

### NSHashTable


## 参考
- [Programming with Objective-C](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html#//apple_ref/doc/uid/TP40011210)