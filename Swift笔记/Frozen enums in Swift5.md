# Frozen enums in Swift5

该特性对应的proposal是--[Swift evolution-Handling Future Enum Cases](https://github.com/apple/swift-evolution/blob/main/proposals/0192-non-exhaustive-enums.md)

## @unknown default

在Swift 4中，这样写Switch case是没有任何问题的

```
// UIUserInterfaceSizeClass一共就下面三个case
let axis: UIUserInterfaceSizeClass = .unspecified
switch axis {
case .unspecified:
    fallthrough
case .regular:
    fallthrough
case .compact:
    print("")
}
```

当升级到Swift 5后，编译器会给出一个警告

> Switch covers known cases, but 'UIUserInterfaceSizeClass' may have additional unknown values, possibly added in future versions.
> 
> Handle unknown values using "@unknown default"

如果接受修改建议，则代码如下

```
let axis: UIUserInterfaceSizeClass = .unspecified
switch axis {
case .unspecified:
    fallthrough
case .regular:
    fallthrough
case .compact:
    print("")
@unknown default:
    fatalError()
}
```

## 为什么引入`@unknown default`

由于Swift要求switch case必须exhausitive，为了满足该要求，在Swift 4及以前，我们使用switch case来进行枚举时，通常只有两种写法：

- 枚举所有case
- 枚举部分case，最后使用default覆盖其他case

但这两种情况都存在各自的问题：

当未来某个版本中，枚举的提供者新增了一个case，那么

- 如果之前使用枚举时枚举了所有case，则会编译出错，因为不满足exhausitive规则
- 如果使用default覆盖了所有case，虽然不会编译出错，但因为未对新增的case进行处理，业务逻辑上可能存在潜在的风险

`@unknown default`就是用来解决该上面问题的，它其实就做了一件事情：

- 当使用了`@unknown default`，但并没有枚举所有case时，编译器会给出未满足exhausitive的警告，而非像``default`那样编译错误

这直接带来的好处是：

- 当使用`@unknown default`同时已经枚举了所有case时，当后续枚举提供者新增了case，不会因为编译出错
- 同时鼓励开发者使用`@unknown default`替代原来的`default`，这样后续新增或删减case时，编译器会及时提醒开发者针对enum的变化做必要的调整

一句话总结该属性的目的

**既做到不影响开发者源码的可编译性，又能及时提醒开发者做好兼容适配工作**

> 注意，该属性目前并不适用所有的enum，具体看下一小节

## `@unknown default`适用范围

目前仅适用于：

- C中的enum
- 来自系统库入`UIKit`、`Swift Standard Library`中的enum

> 未来可能会允许开发者自己开发的Library，但目前不适用

我列举了Enum所有可能得情况，对上述适用范围进行了验证

- 在自己工程中定义了C Enum--ProjectSourceTestEnumType
- 在第三方库MJRefresh(OC编写)中定义了C Enum--MJTestEnumType
- 在SnapKit(Swift 编写)中添加了一个Swift自定义Enum--SnapKitTestEnum

```
        
func testEnumForCEnum(_ testEnum: MJTestEnumType) {
    switch testEnum { // Compiler Warning: Switch covers known cases, but 'MJTestEnumType' may have additional unknown values
    case .type1:  print("")
    case .type2: print("")
    }
}
    
func testEnumForStandardLibrary(_ axis: UIUserInterfaceSizeClass) {
    switch axis { // Compilier Warning: Switch covers known cases, but 'UIUserInterfaceSizeClass' may have additional unknown values, possibly added in future versions
    case .unspecified: print("")
    case .regular: print("")
    case .compact: print("")
    }
}

func testEnumForProjectCEnum(_ testEnum: ProjectSourceTestEnumType) {
    switch testEnum { // Compiler Warning: Switch covers known cases, but 'ProjectSourceTestEnumType' may have additional unknown values
    case .type1: print("")
    case .type2: print("")
    }
}

func testEnumForThirdLibrary(_ testEnum: SnapKitTestEnum) {
    switch testEnum { // 无警告
    case .case1: print("")
    case .case2: print("")
    }
}
```

### 为什么限定适用范围呢

来自官方的解释是

该特性主要适用对象并非enum in project source code，而是project所依赖的enum in library code。说白了就是给代码库开发人员的

- 之所以使用C Enum，是因为C Enum处理起来有点复杂，没办法区分一个C Enum属于project code还是library code，所以进行了统一处理

## 什么是Frozen enum

到此还没有结束，试想一下，如果所有iOS的系统库中的枚举都使用如上规则，那是不是就相当于建议iOS开发者在后续所有进行枚举时都添加`@unknown default`呢

似乎不太合理。所以引入了Frozen or non Frozen enum的概念，写法如下所示

```
@frozen public enum SnapKitTestFrozenEnum {
    case case1
    case case2
}

typedef NS_CLOSED_ENUM(NSUInteger, MJTestClosedEnumType) {
    MJTestClosedEnumType1,
    MJTestClosedEnumType2
};
```

- 此时再去枚举上面enum的时候，及时不写`@unknown default`，也不会有警告了
- 同时，当library的开发者如果真的往frozen enum中添加了一个case，我们接入后编译器会再次报错，告知违反了exhausitive规则

frozen是冻结的意思，表示不会再改变，比如系统库中的`NSComparisonResult `，比较结果只有大、小和相等三种情况，打死也不会出现第三种了，这种就可以标记为frozen了

```
typedef NS_CLOSED_ENUM(NSInteger, NSComparisonResult) {
    NSOrderedAscending = -1L,
    NSOrderedSame,
    NSOrderedDescending
};
```

当然，目前大部分枚举还都是non frozen的

## 总结

注意`@unknown default`的适用范围：

所有代码中的C Enum和系统库代码中的Swift或OC编写的enum


## 参考
- [Swift 5 Frozen enums](https://useyourloaf.com/blog/swift-5-frozen-enums)
