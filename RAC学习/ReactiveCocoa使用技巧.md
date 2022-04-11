# ReactiveCocoa使用技巧

本文记录一些使用RAC过程中好用的技巧
## RACTuple
专业名叫`元组`

- 就是一个可以存储多个不同类型数据的数据类型
- 可以实现一个方法多个返回值

## RACSequence

一个可以替换`OC`中字典或数组的类型

可以据此遍历数组

```
NSArray * array = @[@"大吉大利",@"今晚吃鸡",@66666,@99999];
[array.rac_sequence.signal subscribeNext:^(id  _Nullable x) {
	 NSLog(@"%@",x);
}];
```

字典也可以

```
NSDictionary * dict = @{@"大吉大利":@"今晚吃鸡",
                            @"666666":@"999999",
                            @"dddddd":@"aaaaaa"
                            };
    
[dict.rac_sequence.signal subscribeNext:^(RACTuple * _Nullable x) {
	NSLog(@"%@",x);
}];
```

还有可以做映射的`map`方法

```
NSArray * persons = [[array.rac_sequence map:^id _Nullable(NSDictionary* value) {
	return [Person personWithDict:value];
}] array];
    
NSLog(@"%@",persons);
```

也有类似`firstObjectWhere:`的方法

```
UIView *emptyDataSetView = [self.tableView.subviews.rac_sequence objectPassingTest:^(UIView *view) {
	return [NSStringFromClass(view.class) isEqualToString:@"DZNEmptyDataSetView"];
}];
```

## 参考

- [iOS RAC - 集合RACTuple、RACSequence](https://www.jianshu.com/p/a57060bf6158)