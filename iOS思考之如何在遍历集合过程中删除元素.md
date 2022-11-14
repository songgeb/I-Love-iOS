# iOS思考之遍历集合过程中删除元素的几种方式

> 深入理解代替单纯记忆

> 这里的集合不只是`Set`，还包含所有容器类型的数据结构，比如数组、字典，其实在iOS中统称为`collection`即集合

> 我发现有时遇到该问题时虽然知道怎么解，但还是有点困惑，可能还是理解的不到位，索性这次将所有方案列出来，做一下分析，也算是个备忘

首先，遍历集合过程中并不是只有删除元素会出问题，**增加、替换**仍会出错，通过大致猜测一下内部实现（比如有个游标，随着遍历一直在更新）很容易能理解

但遍历过程中更新元素内部的内容是没问题的

## copy collection

```
NSMutableDictionary *dict = [NSMutableDictionary dictionary];
dict[@"1"] = @1;
dict[@"2"] = @2;
NSMutableDictionary *copyDict = [dict mutableCopy];
for (NSString *key in copyDict) {
  dict[key] = nil;
}
NSLog(@"%@", dict);
```

## 先记录后删除

```
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  dict[@"1"] = @1;
  dict[@"2"] = @2;
  NSMutableArray *keysToDelete = [NSMutableArray array];
  for (NSString *key in dict) {
    if ([key isEqualToString:@"2"]) {
      [keysToDelete addObject:key];
    }
  }
  [dict removeObjectsForKeys:keysToDelete];
  NSLog(@"%@", dict);
```

## 倒序遍历+删除

```
  NSMutableArray *array = [NSMutableArray array];
  [array addObject:@1];
  [array addObject:@2];
  [array addObject:@3];

  [array enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isEqual:@1]) {
      [array removeObject:obj];
    }
  }];
  NSLog(@"%@", array);
```

- 不推荐这种方式
- 首先，倒序遍历也是遍历，遍历过程中的增删替换的风险仍存在，或者说背后的实现苹果并没有明确告诉我们不会出问题，虽然现在来看确实没问题
- 另外，倒序遍历仅适合数组，字典和集合没有类似方法

## 参考

- [Best way to remove from NSMutableArray while iterating?](https://stackoverflow.com/questions/111866/best-way-to-remove-from-nsmutablearray-while-iterating)
- [iOS 中集合遍历方法的比较和技巧](https://blog.sunnyxx.com/2014/04/30/ios_iterator/)