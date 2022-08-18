# rethrows in Swift

最主要的作用是--让代码更简洁，省掉没必要的`try`

它是如何做到的呢？

来看一个实际的应用案例

```
// rethrows的方法定义如下

func rethrowingFunction(throwingCallback: () throws -> Void) rethrows {
     try throwingCallback()
 } 
 
 // 情况1：该种情况下在调用rethrowingFunction时就无需使用try
 rethrowingFunction {
     print("I'm not throwing errors")
 } 
 
 // 情况2：该情况下必须使用try或其他方式处理Error
 do {
 	try rethrowFunction {
 		// xxx do some thing
 		throw xxxxError()
 	}
 } catch {
 }
```

- 能够看的出来，起作用的原理是根据rethrowingFunction方法的closure参数中的内容
	- 如果closure的操作有可能throw error，那外部调用时就要处理Error
	- 如果closure的操作根本不可能throw error，外部调用也就无需做任何Error处理动作了

非常好，基于它的原理我们自己来推导一下，使用rethrows的条件：

- rethrows方法中至少得有一个接收closure的参数
	- 只有这样，编译器才能知道closure是否有潜在throws error的风险
- 这个closure的参数，必须是有可能throws error的

注意事项

下面这种情况是不能使用rethrows的，因为语义含糊。编译器无法只通过callback中的内容决定外部使用者是否要进行错误处理

```
func alwaysThrows() throws {
                throw SomeError.error
}

func someFunction(callback: () throws -> Void) rethrows {
	do {
		try callback()
		try alwaysThrows()  // Invalid, alwaysThrows() isn't a throwing parameter
	} catch {
		throw AnotherError.error
	}
}
```

## 其他

官方有一段表示rethrows方法的话

> “A throwing method can’t override a rethrowing method, and a throwing method can’t satisfy a protocol requirement for a rethrowing method. That said, a rethrowing method can override a throwing method, and a rethrowing method can satisfy a protocol requirement for a throwing method.”

翻译一下就是

- throw method 不能重载(重写)rethrow method
- throw method 不能满足rethrow method的协议
- rethrow method可以重载(重写)throw method
- rethrow method可以满足throw method的协议

原因也容易想到

- rethrow method给编译器传递的信息是，使用者是有可能不用做错误处理的；而throw method传递的信息是调用者必须做错误处理
- 如果throw method可以重写rethrow，那原来使用rethrow方法的地方岂不是要编译不过了

## 参考
- [How to use the rethrows keyword in Swift](https://www.avanderlee.com/swift/rethrows/)