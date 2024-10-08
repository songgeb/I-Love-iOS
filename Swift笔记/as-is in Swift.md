# Type Casting(as/is) in Swift

> 深入理解代替单纯记忆

本文主要是对as和is语法的备忘

Type Casting，翻译为类型转换

Swift中使用as和is，进行**类型判断**和**类型转换**

## 类型判断-is

语法：`expression is type`

工作原理：运行时检测expression是否是type类型，是则返回true，否则false

```
struct StructA {
    let a: Int = 2
}

var someThing: Any = StructA()
if someThing is StructA {
    print("someThing is StructA")
}

protocol ProtocolA {
}

extension StructA: ProtocolA { }

if someThing is StructA {
    print("someThing is StructA")
}
```

- Type可以是普通的类型，如Class、Struct、Enum、Tuple
- 也可以是Protocol

## 类型转换-as

as是将类型A的实例转换成B类型实例的语法，

as的用法有三种情况：as?、as!和as

- `expression as? type`
- `expression as! type`
- `expression as type`

|项目|解释||
|:-:|:-:|:-:|
|as?|runtime时期，尝试进行类型转换，转换成功返回否则返回nil，所以返回值是Optional的||
|as!|先做as?的工作，然后强制解包|如果转换失败，则会因为强制解包而crash|
|as|当编译期间，编译器可以确定A->B类型转换一定成功时，可以使用as将A转换为B|一般用于upcasting或bridging|

- upcasting，译为向上转换
	- subclass->superclass
	- concrete type -> Any
- bridging则是由Swift Standard Library中的类型转为对应的Cocoa中的数据类型，比如`String as NSString`

```
func f(_ any: Any) { print("Function for Any") }
func f(_ int: Int) { print("Function for Int") }
let x = 10
f(x)
// Prints "Function for Int"
             
let y: Any = x
f(y)
// Prints "Function for Any"
             
f(x as Any)
// Prints "Function for Any
```

## 还有什么？

as和is在Pattern Maching中也有使用，比如下面代码

```
var things: [Any] = []

... add something to things

for thing in things {
	switch thing {
		case 0 as Int:
			print("zero as an Int")
		case 0 as Double:
			print("zero as a Double")
		case let someInt as Int:
			print("an integer value of \(someInt)")
		case let someDouble as Double where someDouble > 0:
			print("a positive double value of \(someDouble)")
		case is Double:
			print("some other double value that I don't want to print")”
		default:
			print("default")
	}
}
```

> 后面单独为Pattern Matching写笔记记录一下

