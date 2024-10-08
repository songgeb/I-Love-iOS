# Protocol in Swift

> 本文编写于2024年04月04日，此时Swift最新版本为Swift 5.10

用简洁的语言来描述`Protocol`就是：

- `Protocol`是一组`Property`、`Method/Function`的要求，中文翻译为协议
- Swift中的`Class`、`Enum`、`Struct`类型可以实现`Protocol`，这些类型必须满足`Protocol`中的要求
- `Protocol`中可能会有associated type、where等高级的语法特性，但归根到底还是反映到`Property`和`Fuction`的要求上

## 本文要解决的问题
- 系统学一下Swift中的Protocol
- 对比OC中的Protocol，都多了哪些能力
- 这些高级的Protocol技巧，在实践中的使用是怎样？目前只有概念但完全没有实践经验
- 什么是existential type？
- 什么是primary associatedtype？
- primary associatedtype与generic parameters of a concrete type的区别


## 基础语法

### Property Requirements

```
protocol AProtocol {
    var instanceProperty: String { get set }
    var readonlyInstanceProperty: String { get }
    static var aTypeProperty: Int { get set }
    static var aReadonlyTypeProperty: Int { get }
}
```

> 注意，`static`标注的属性，`Class`和其他类型在实现该协议时都可以支持该属性。但如果在`Protocol`中，用`class`标注属性时，则只有`Classs`能支持，其他类型不支持。所以Swift编译器不允许在`Protocol`中使用`class`

###  Method Requirements



## 高级用法

## 参考
- [Protocols-The Swift Programming Language (5.10)
](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols#Adding-Constraints-to-Protocol-Extensions)
- 