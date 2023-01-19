# Swift

## 概念

### 是函数式语言吗？

- [Swift Is Not Functional](https://robnapier.net/swift-is-not-functional)

### 什么是高阶函数

高阶函数是一种这样的函数：可以接收函数作为参数或者这个函数可以返回一个函数，满足任意之一就可以叫做高阶函数

## Swift vs Objective C

### 参考
- [Static vs Dynamic Dispatch in Swift: A decisive choice](https://medium.com/@bakshioye/static-vs-dynamic-dispatch-in-swift-a-decisive-choice-cece1e872d)
- [Increasing Performance by Reducing Dynamic Dispatch](https://developer.apple.com/swift/blog/?id=27)
- [Swift Protocol Extensions Method Dispatch](https://medium.com/@leandromperez/protocol-extensions-gotcha-9ef1a42c83b6)

## Type property

- 用`static`来创建stored type property或computed type property
- 开发者必须为stored type property提供一个初始值，因为它不能像instance property时那样，在type初始化时为property赋一个初始值，而要求必须要有一个初始值
- stored type property是lazy initialized
- 而且stored type property还可以保证只初始化一次，并且是多线程安全的
- 有一种情况下也可以使用`class`来修饰type property
	- 仅当class中，且是computed type property
	- 相比于static，class type property支持subclass重写

> 当然，class function也是可以被subclass重写的

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

## Tuple

介绍几个tuple有意思的用法

### 同时定义多个变常量
```
var (a, b, c) = (1, "2", 3.0)
print(a)
print(b)
print(c)
```

### 变量交换值
```
(a, b) = (b, a)
```

### 分解

```
let http404Error = (404, "Not Found")
let (statusCode, statusMessage) = http404Error
print("The status code is \(statusCode)")
// 输出 "The status code is 404"
print("The status message is \(statusMessage)")
// 输出 "The status message is Not Found"
```

## 位运算

- &，都为1，才为1，否则就是0
- |，有一个是1就是1，除非都是0
- ^，相同就是0，不同就是1
- ~，not，取反操作

|p|q|p&q|pxq|p^q|
|:-:|:-:|:-:|:-:|:-:|
|0|0|0|0|0|
|0|1|0|1|1|
|1|0|0|1|1|
|1|1|1|1|0|

#### 位运算应用
- 可以用“与”运算来判断一个整数的奇偶，因为二进制数从低位，第二位开始就都是2的n次方，组合起来肯定是偶数，奇数的可能性只可能是第1位决定，所以通过`n&0x1`如果结果是1，肯定是奇数
- 如果一个数组中所有数字都出现一次，仅有一个例外。可以用`^`异或操作，对数组中所有数字挨个求`^`，最终剩下的值就是那一个不成对的数了

## 运算符优先级

参考文章可以当做运算符优先级字典来查询

- [Operator Declarations](https://developer.apple.com/documentation/swift/swift_standard_library/operator_declarations)
- [Swift Operators](https://nshipster.com/swift-operators/)

## Access Control

- open、public
	- module内部、外部都可以访问
	- open只用于修饰class，并且允许在其他module中继承
- internal
	- 仅module内部可访问
- fileprivate
	- 仅源文件内部可访问
- private
	- 仅类型定义内部可访问
	- 或者相同源文件下的extension可访问

## Copy-on-Write

- Swift中有值类型和引用类型数据
- 值类型在赋值时通常都要开辟一块新内存，将旧内容完全复制过去
- 但当值类型的数据比较多时，每次都拷贝效率低
- 所以Swift对一些值类型做了优化，只在必要时才做拷贝工作
- 比如将数组var1复制给变量var2，只有在对var2中的数组元素做改动时才会真正拷贝，这就叫copy on write
- 我们开发者也可以效仿swift的做法，对自己定义的值类型数据做这种优化

```
final class Ref<T> {
  var val : T
  init(_ v : T) { val = v }
}

struct MyType<T> {
    var ref : Ref<T>
    init(_ x : T) { ref = Ref(x) }

    var a: T {
        get { return ref.val }
        set {
          if (!isKnownUniquelyReferenced(&ref)) {
            ref = Ref(newValue)
            return
          }
          ref.val = newValue
        }
    }
}

var v1 = MyType(1)
var v2 = v1
v2.a = 3
print(v1.a)
print(v2.a)
print(v1.ref === v2.ref ? "true" : "false")
```

- [Understanding Swift Copy-on-Write mechanisms](https://medium.com/@lucianoalmeida1/understanding-swift-copy-on-write-mechanisms-52ac31d68f2f)

## self vs Self

- Self is only available inside protocol, it refers to the type that conforms to the protocol
- self refers to the value of current type no matter where the self is in

- [Self vs self - what's the difference?](https://www.hackingwithswift.com/example-code/language/self-vs-self-whats-the-difference)

## Protocol types cannot conforms to protocol

- [Protocol Types Cannot Conform to Protocols](https://github.com/apple/swift/blob/main/userdocs/diagnostics/protocol-type-non-conformance.md)

## Operator

- [Precedencegroup’s assignment](https://forums.swift.org/t/precedencegroups-assignment/14069)

## Function vs Closure

- [Closures vs. Functions](https://developer.apple.com/forums/thread/43606)

## Variable shadowing

其实就是支持在fnction中定义一个和parameter name相同的变量或常量

## 疑问
1. Swift是类型安全语言？类型安全是什么意思？
2. dynamic关键词的深入理解，以及和@objc合用的注意事项
3. 写算法时经常碰到的hashMap.keys到底是什么类型，和Array、String之间的关系是什么
4. 哪些方法有sort方法，都有几种sort方法声明，每种写法如何
5. 如何理解Swift support dynamic library而OC不支持？

## 参考
- [What is new in Swift5](https://www.raywenderlich.com/55728-what-s-new-in-swift-5)