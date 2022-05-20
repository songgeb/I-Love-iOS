# for-in in Objective-C/Swift

> 深入理解代替单纯记忆

> 好久没写博客了，水一篇凑个数，解答几个困惑很久的问题

## for-in in Objective-C

```
NSArray *array = [NSArray arrayWithObjects:
        @"one", @"two", @"three", @"four", nil];
 
for (NSString *element in array) {
    NSLog(@"element: %@", element);
}
```

### 哪些类型可以使用`for-in`特性

- Objective-C中，`for-in`特性叫做Fast Enumeration
- 所有遵循`NSFastEnumeration`协议的类型，都能使用Fast Enumeration特性

### Fast Enumeration有哪些特性

- 既然叫做快速枚举，那相比其他遍历方式，一般是比较快的
- 语法简洁
- 遍历集合过程中，不允许修改集合。保证安全

以下代码会运行出错：❌❌

```
NSMutableArray *array = [NSMutableArray arrayWithObjects:@"1", @"2", nil];
for (NSString *str in array) {
    if ([str isEqualToString:@"1"]) {
        [array removeObject:str];
    }
}
```

### 遍历顺序

经常遇到的一个疑问是：使用Fast Enumeration时，是按照从前往后的顺序在遍历的吗？

官方的原话是这样：
> For collections or enumerators that have a well-defined order—such as an NSArray or an NSEnumerator instance derived from an array—the enumeration proceeds in that order, so simply counting iterations gives you the proper index into the collection if you need it.

```
NSArray *array = <#Get an array#>;
NSUInteger index = 0;
 
for (id element in array) {
    NSLog(@"Element at index %u is: %@", index, element);
    index++;
}
```

总结下

- 对于NSArray使用Fast Enumeration时，是按照从前到后的顺序遍历的
- 对于其他类型的集合（如NSDictionary），顺序是不确定的

### 参考
- [Fast Enumeration](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjectiveC/Chapters/ocFastEnumeration.html)
- [NSFastEnumeration](https://developer.apple.com/documentation/foundation/nsfastenumeration)
- [iOS 中集合遍历方法的比较和技巧](https://blog.sunnyxx.com/2014/04/30/ios_iterator/)

## for-in in Swift

```
let array = [1,2,3]
for value in array {
}

for (index, value) in array.enumerated() {
}

for i in 0..3 {
}

for i in stride(from: 10, to: 0, by: -1) {
}
```

### 为什么可以使用for-in语法

通过上面的例子可见，Swift中的for-in更丰富

- 所有遵循`Sequence`的类型，都能用for-in语法遍历数据
	- 除了常见的`Array`、`Dictionary`，还有`EnumeratedSequence`、`StrideTo`等很多类型
- 能够通过`Sequence`遍历的关键在于，conforming type需要实现`func makeIterator() -> Self.Iterator`方法
	- 该方法也决定了遍历元素的顺序

### 在对Sequence使用for-in时，需注意什么

> The Sequence protocol makes no requirement on conforming types regarding whether they will be destructively consumed by iteration. As a consequence, don’t assume that multiple for-in loops on a sequence will either resume iteration or restart from the beginning

Sequence协议并没有要求conforming type在遍历元素时

- 不能修改序列中的元素
- 遍历结束后，游标自动回到初始位置，即可以进行多次相同的遍历操作

### Collection

`Collection`协议继承自`Sequence`

像Array、Dictionary都实现了`Collection`协议

- `Collection`规定，遍历过程中不能向集合删除、添加元素

### 为什么一边遍历Array(Dictionary)一边删除不会报错

```
var array = [1,2,3,4]
for i in array {
    array.remove(at: 0)
}
```

不会报错，岂不是和`Collection`协议的规定冲突了么？

- 不会报错其实是因为Array(Dictionary)是值类型，for循环中进行remove操作时会触发copy-on-write
- 其实在遍历的过程中有两个Array，遍历的Array元素不会删除，真正删除元素是在另一个Array中

### for-in遍历顺序

前面提到了，决定for-in遍历顺序的是`func makeIterator() -> Self.Iterator`方法

像Array、Dictionary等Collection默认都是生成一个`IndexingIterator`

该iterator，就是按照C`=ollection的indices，进行遍历的

通过查看Collection协议的indices方法，默认实现是按照升序的

所以

Array通过for-in遍历时，也是按照从前往后的顺序遍历

### 参考
- [Collection](https://developer.apple.com/documentation/swift/collection)
- [Remove element from collection during iteration with forEach](https://stackoverflow.com/questions/37997465/remove-element-from-collection-during-iteration-with-foreach)