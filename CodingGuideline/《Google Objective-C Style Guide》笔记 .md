#《Google Objective-C Style Guide》笔记
> 2020年12月23日


### Prefix
在定义类、协议、全局方法、全局变量时为了避免与系统框架、三方库代码发生冲突，建议追加前缀。

- 建议前缀至少3个字符，因为iOS系统框架代码会使用2个字符作为前缀，使用3个或更多的前缀能减少冲突几率

### Function Names

注意，Function叫做函数，它区别于Objective-C Method

函数的命名规范

```

static void AddTableEntry(NSString *tableEntry);
static BOOL DeleteFile(const char *filename);

// 对于非static的函数，因为OC中没有命名空间，所以添加前缀会降低命名冲突风险
extern NSTimeZone *GTMGetDefaultTimeZone(void);
extern NSString *GTMGetURLScheme(NSURL *URL);
```

### Constants
```
// 对于static作用域的常量，可以加k作为前缀
static const int kFileCount = 12;
static NSString *const kUserKey = @"kUserKey";
```

### Types with Inconsistent Sizes

在进行数学运算时，应避免使用NSInteger、CGFloat等类型，因为这些类型会根据架构不同，能表示的范围会随之变动。当然，如果是系统API要求或者返回了NSInteger等类型，则可以使用

```
// GOOD:

int32_t scalar1 = proto.intValue;
int64_t scalar2 = proto.longValue;
NSUInteger numberOfObjects = array.count;
CGFloat offset = view.bounds.origin.x;

// AVOID:
NSInteger scalar2 = proto.longValue;  // AVOID.
```

### Nonstandard Extensions

> Nonstandard extensions to C/Objective-C may not be used unless otherwise specified.

不建议使用非标准的C或OC扩展语法，非标准的扩展就包括compound statement expression，即

```
foo = ({ int x; Bar(&x); x })
```

### Use Umbrella Headers for System Frameworks
对于系统框架或静态库，推荐使用引入Umbrella Header头文件的引入方式。因为Umbrella Header文件进行过预编译，加载速度会更快

```
// GOOD:

@import UIKit;     // GOOD.
#import <Foundation/Foundation.h>     // GOOD.

// AVOID:

#import <Foundation/NSArray.h>        // AVOID.
#import <Foundation/NSString.h>
```

### Avoid Messaging the Current Object Within Initializers and -dealloc

```
// AVOID:

- (instancetype)init {
  self = [super init];
  if (self) {
    self.bar = 23;  // AVOID.
    [self sharedMethod];  // AVOID. Fragile to subclassing or future extension.
  }
  return self;
}
```

不建议这样写的原因是，

- 当子类也有`sharedMethod`方法时，在子类初始化时，因为首先会执行父类初始化方法
- 那么因为父类中`[self sharedMethod]`的写法，在父类初始化方法执行结束之前，先执行了子类的`sharedMethod`，此时可能产生异常，因为子类此时很可能数据没有ready

> 但是，我们很难避免这样的写法，比如自定义视图时，初始化方法结束时经常会执行`createUI`或`setupViews`等方法来添加子视图。所以这是OC语言层面的问题，不容易避免（Swift会强制，对父类初始化之前必须先完成对本类ivar的赋值操作，得以避免该问题）


### Avoid Throwing Exceptions

- 尽量不使用`@throw`抛出异常，推荐使用返回错误码或`NSError`的方式来返回、处理错误的方式
- 但对于使用了`@throw`方式抛出异常的三方库或系统库，我们的代码应该使用`@try @catch`进行处理，做合理的错误处理，并避免错误继续向上抛出
- 如果一定要使用`@throw`抛出错误，注释一定说清楚，方便调用方处理

#### 为什么少用`@throw`

[官方](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Exceptions/Exceptions.html)的解释如下

>  You should reserve the use of exceptions for programming or unexpected runtime errors such as out-of-bounds collection access, attempts to mutate immutable objects, sending an invalid message, and losing the connection to the window server. You usually take care of these sorts of errors with exceptions when an application is being created rather than at runtime.

翻译一下，通常exception(常见的有越界访问、运行时非法修改immutable对象等)应该在编写代码时进行预防，而不是等到运行中出错时再去补救

### BOOL Pitfalls

- OC中BOOL类型使用`signed char`进行存储([官方解释](https://developer.apple.com/documentation/objectivec/bool))
- 而`YES`其实是1，`NO`是0([官方解释](https://developer.apple.com/documentation/objectivec/objective-c_runtime/boolean_values))

所以，

- 不要通过强转或者使用int值当做BOOL类型
	- 比如将一个多字节表示的int值强转为BOOL类型	，只保留最后一个字节数据，最后一个字节不一定能反映真实的YES or NO
	- **注意：**在实际测试中发现，当强转到BOOL类型时，通常强转后结果都是正确的。（内部的裁剪规则我们无从知晓）
	
	```
	// AVOID:

	- (BOOL)isBold {
 	 	return [self fontTraits] & NSFontBoldTrait;  // AVOID.
	}
	- (BOOL)isValid {
  		return [self stringValue];  // AVOID.
	}
	```
	- 推荐如下的写法
	
	```
	// GOOD:

	- (BOOL)isBold {
  		return ([self fontTraits] & NSFontBoldTrait) ? YES : NO;
	}
	- (BOOL)isValid {
  		return [self stringValue] != nil;
	}
	```
- 避免将BOOL值直接与YES比较
	- if中的判断逻辑是：0则为假，非0则为真
	- YES是1，待比较的BOOL值却不一定是1
	
	```
	// AVOID:

	BOOL great = [foo isGreat];
	if (great == YES) {  // AVOID.
  		// ...be great!
	}
	```

## 参考
- [Google Objective-C Style Guide](https://google.github.io/styleguide/objcguide.html)