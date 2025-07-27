# LLDB debug 技巧 in iOS

## expr

全称expression，简称expr，表示在lldb中执行表达式


- 执行obj的方法: `expr [obj doSth]`
- 修改某个属性值：`expr obj.propertyA = 1`

如果想在lldb中使用表达式创建一些中间值，并保存，可以使用`$`

- 创建一个临时UIImage对象： `expr UIImage *$tempImage = [UIImage imageWithData:data]`
- 使用lld另一个命令访问刚才创建的临时对象：`po $tempImage`

## 参考
- [Intermediate iOS Debugging](https://medium.com/@crafttang/intermediate-ios-debugging-53d33efdff)
