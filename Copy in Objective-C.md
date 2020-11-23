# Copy in Objective-C

> 深入理解代替单纯记忆

一般说到拷贝指的是对象类型的拷贝而非`scalar`类型（如NSInteger、BOOL）

因为`scalar`类型赋值时使用的是`值传递`，本身就是一种拷贝

而对象的变量在赋值时是`引用传递`，真正的对象在内存里只有一份，所以当需要有多份的时候就涉及到拷贝了

## Copy要实现功能

官方如下要求
> The exact meaning of “copy” can vary from class to class, but a copy must be a functionally independent object with values identical to the original at the time the copy was made. A copy produced with NSCopying is implicitly retained by the sender, who is responsible for releasing it.

翻译一下，一个对象的拷贝必须

1. 在功能上是一个独立对象，拷贝对象的每个属性值必须和原对象对应属性值必须相等
2. 拷贝后的对象的内存管理权（ownership）交给了使用这个对象的一方来管理。它要负责该对象的内存释放

细品一下这两条原则

1. 关于第2条，因为目前都是ARC了，所以我们也不用做额外处理。具体内容可以看苹果官方内存管理文章
2. 第1条很重要
	- 对象的各个属性值都相等，这个是肯定的
	- `功能上的`独立对象其实是想说，拷贝后的对象不一定必须在内存中新开辟一块地方创建这个对象的拷贝
	- 也可以还是原来的对象，只是这个对象所有的属性都不允许被修改
	- 换句话说，对对象的拷贝做任何修改不应影响到原对象；或者干脆这个对象的内容就不能被修改

## 如何实现Copy

有了上面的理解，实现Copy就容易许多，无非就是按照官方的套路走

- 所有类的基类`NSObject`有一个`-(id) copy`方法
- 该方法内部会调用`NSCopying`协议唯一的方法`- (id)copyWithZone:`
- 需要支持拷贝功能的对象只需要实现`NSCopying`协议的`- (id)copyWithZone:`方法即可

实现`- (id)copyWithZone:`时需要注意些什么

- 如果父类实现了该方法，也要执行以下`[super copyWithZone:]`，以达到父类对属性完成拷贝

## Copy vs mutableCopy

这两个方法产生的对象的`mutability`（可变性）不同

## 深拷贝VS浅拷贝

对于对象类型的内容，拷贝时有深、浅拷贝区别（因为对于`scalar`类型数据都是深拷贝，或者说只有深拷贝）

**完全深拷贝**，拷贝后的对象的每一个属性内容与原对象占用完全不同的一份内存区域

平常开发当中完全深拷贝比较少，**多数是浅拷贝**

要想实现深拷贝，可以通过`Archive`技术，将对象转为data再转回对象

```
NSArray* trueDeepCopyArray = [NSKeyedUnarchiver unarchiveObjectWithData:
          [NSKeyedArchiver archivedDataWithRootObject:oldArray]];

```

## Copying Collections

集合类的拷贝默认（比如直接执行`copy`方法）都是浅拷贝

`initWithArray:copyItems:`中`copyItems`传YES时，**有可能**实现**第一层对象**的深拷贝

1. 传YES时，本质上是在将每个item放入新的集合中时，对每个item执行`copy`方法
2. 所以说是否能否实现第一层对象的真正深拷贝，取决于每个item的`copyWithZone:`的实现
3. 而且也只是对第一层对象执行`copy`方法
4. 如果要完全深拷贝，还是用`Archive`吧


## 参考
- [NSCopying](https://developer.apple.com/documentation/foundation/nscopying?language=objc)
- [Copying Collections](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Collections/Articles/Copying.html#//apple_ref/doc/uid/TP40010162-SW1)
