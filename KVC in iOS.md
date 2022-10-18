# KVC in iOS

KVC，Key-value coding，是一种可以实现对**对象的属性**进行非直接访问的一种方式，这种方式要求对象必须实现`NSKeyValueCoding`协议

`NSObject`实现了`NSKeyValueCoding`协议的方法，所以它的子类可以直接用KVC的方法
## 常用方法
```
// 直接获取或设置属性值
valueForKey:/valueForKeyPath:
setValue:forKey:/setValue:forKeyPath:
// 获取可变类型集合数据方法
mutableArrayValueForKey:/mutableArrayValueForKeyPath:
mutableSetValueForKey:/mutableSetValueForKeyPath:
```
- 当书写`keyPath`时，第一个属性部分是相对于`message receving object`而言的
	- `[department valueForKeyPath:@"employee.salary"]`
	- `employee`是相对于`department`而言
- 当获取可变的集合类型数据时，得到的是一个代理对象，可以直接对该集合进行操作，操作的结果会传递到真正的非可变集合数据中
- KVC的方法对对象类型属性和非对象类型属性（如`int`）等同视之

## 集合操作符(CollectionOperator)

当获取集合类型数据时，支持加入集合操作符，这样可以对返回的集合数据进行合并、求平均、求最值等简单操作，最终返回的是计算的结果值

操作符格式是

`keypathToCollection.@collectionOperator.keypathToProperty`

举例

```
/// 获取交易信息中最早的时间
NSDate *earliestDate = [self.transactions valueForKeyPath:@"@min.date"];

/// 获取所有交易信息中的交易人（payee）信息，而且交易人不重复
/// 重复的判断需要`isEqual`方法的支持
NSArray *distinctPayees = [self.transactions valueForKeyPath:@"@distinctUnionOfObjects.payee"];
/// 对集合的集合使用操作符
NSArray* moreTransactions = @[<# transaction data #>];
NSArray* arrayOfArrays = @[self.transactions, moreTransactions];
NSArray *collectedDistinctPayees = [arrayOfArrays valueForKeyPath:@"@distinctUnionOfArrays.payee"];
```

|集合操作符|功能||
|:-:|:-:|:-:|
|@count|元素个数|无需keypathToProperty|
|@avg/@sum|求平均、求和||
|@max/@min|求最值||
|@distinctUnionOfObjects|聚合对象，对象不重复||
|@unionOfObjects|聚合对象，允许重复||
|@distinctUnionOfArrays|将外层数组中每个数组里的每个对象的属性进行非重复聚合||
|@unionOfArrays|功能和上面类似，结果有重复||
|@distinctUnionOfSets|对集合的集合进行非重复聚合|

## KVC原理

本质上，实现了`NSKeyValueCoding`协议的`NSObject`在执行KVC的方法时，就是通过`key`去找匹配的`ivar`（成员变量），然后再进行`get`或`set`

那么最重要的也就是从`key`到`ivar`的查找过程了，官方有做详细说明，但由于都是文字，可能比较晦涩，这里贴上掘金上一个[大佬](https://juejin.im/post/5e5e06ba51882549063a9011)的总结图

![setter](https://github.com/songgeb/I-Love-iOS/blob/master/Images/kvc_setter.png?raw=true)

![getter](https://github.com/songgeb/I-Love-iOS/blob/master/Images/kvc_getter.png?raw=true)

## KVC in Swift？

当一个Class或其他Type实现了NSKeyValueCoding协议时，才可以说该类是KVC compliant或者说支持KVC的

NSObject实现了该协议，当然，在Swift中也可以让其他类型实现该协议

## 应用场景
1. Objective C中Model层数据转换，比如JSON转Model
2. 通过KVC可以查看或修改一些iOS系统内部的私有属性，但不推荐发布到release环境，可能审核不通过

## 疑问

## 参考
- [Introduction to Key-Value Observing Programming Guide
](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html)
- [Key-Value Coding Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/index.html)