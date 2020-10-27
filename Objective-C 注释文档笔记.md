# Objective-C 注释文档笔记

> 本文写作于2020年10月27日，代码环境为Xcode12，iOS14系统，Objective-C语言

## 类注释
```
/**
描述，如何使用该类
 
详细描述，使用该类是具体几种形式
 
- 描述1
 
- 描述2
 @warning 警告，使用时不要做xxxx
 */
@interface ViewController : UIViewController
@end
```

![](https://user-images.githubusercontent.com/5978164/97268266-8f02fa80-1866-11eb-90a3-603341206c46.png)

## 方法注释

```
/// 判断xxx是否满足条件
///
/// 详细描述一下该方法使用注意事项
/// @param num 参数num
/// @param obj 参数obj
/// @return YES：满足；NO：不满足
/// @warning 警告，注意不要xxx
- (BOOL)isQualifiedByA:(NSUInteger)num andB:(NSObject *)obj;
```

![](https://user-images.githubusercontent.com/5978164/97269718-ebffb000-1868-11eb-8709-d3ed4fb07c75.png)

## Deprecated使用


## 参考
- [Objective-C Documentation](https://nshipster.com/objective-c-documentation/)
- [AFHTTPSessionManager.h](https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFHTTPSessionManager.h)