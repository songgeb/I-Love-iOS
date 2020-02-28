## OptionSet

OptionSet作用类似于OC中按位枚举-`NS_OPTIONS`

- 要存放枚举值，所以`OptionSet`遵循了`RawRepresentable`，提供了`rawValue`属性
- 为了方便对rawValue进行位运算等操作，`OptionSet`要求`rawValue`必须遵循`FixedWidthInteger`(FixedWidthInteger的父protocol-BinaryInteger支持位运算)
- `OptionSet`还遵循了`SetAlgebra`
	- 能够方便的进行集合操作 
	- `SetAlgebra`继承的`ExpressibleByArrayLiteral`能够用arrayliteral的形式来给`OptionSet`赋值

```
struct ShippingOptions: OptionSet {
    let rawValue: Int

    static let nextDay    = ShippingOptions(rawValue: 1 << 0)
    static let secondDay  = ShippingOptions(rawValue: 1 << 1)
    static let priority   = ShippingOptions(rawValue: 1 << 2)
    static let standard   = ShippingOptions(rawValue: 1 << 3)

    static let express: ShippingOptions = [.nextDay, .secondDay]
    static let all: ShippingOptions = [.express, .priority, .standard]
}
```

- [optionset](https://developer.apple.com/documentation/swift/optionset)
- [Option​Set(NSHipster)](https://nshipster.com/optionset/)

## Error

```
protocol Error {
  var localizedDescription: String { get }
}
```

- `Error`是一个协议，表示一个可以`throw`的错误信息
- 任何类型都可以实现`Error`协议
- 比如enum遵循协议用来表示不同类型的错误信息，struct也可以遵循，用来表示信息量更大的错误信息
