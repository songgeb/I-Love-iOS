# Currying and Partial application

> 深入理解代替单纯记忆

- Currying和Partial application都是**函数式编程**范式中的概念
- 尽管如此，在一些高级语言中（如Swift、Scala），在语法层面或者可以通过一些技术手段实现这些概念

本文将从概念和使用场景方面介绍这两个名词

## 概念

Currying则翻译为柯里化
；Partial application可翻译为部分应用
看下各自的概念：

> Partial application from Wiki:
In computer science, partial application (or partial function application) refers to the process of fixing a number of arguments of a function, producing another function of smaller arity. Given a function 
f:(X×Y×Z)→N{}, we might fix (or 'bind') the first argument, producing a function of type 
partial(f):(Y×Z)→N{}. Evaluation of this function might be represented as fpartial(2,3){}.

> Currying from Wiki:
In mathematics and computer science, currying is the technique of translating a function that takes multiple arguments into a sequence of families of functions, each taking a single argument.

Partial application是指，先固定一个函数的部分参数，创建另一个函数，该函数只需接受剩余的参数

比如

```
// 原始函数
func multiply(_ x: Int, _ y: Int, _ z: Int) -> Int {
    return x * y * z
}

// 部分应用（固定 x）
func partialMultiply(by x: Int) -> (Int, Int) -> Int {
    return { y, z in
        return multiply(x, y, z)
    }
}

// 使用方式：
let multiplyBy2 = partialMultiply(by: 2)
let result = multiplyBy2(3, 4)  // 相当于 multiply(2, 3, 4)
print(result) // 24
```

- 我们基于原函数`multiply`创建了`partialMultiply`，`partialMultiply`就是概念中所说的固定了`x`这个参数
- 返回值仍是一个函数，类型是`(Int, Int) -> Int`，该函数可以接受`y`和`z`参数

> 其实在上面Swift代码中，`partialMultiply`的返回值类型是`Closure`不是`Function`，但两者在这样的场景下使用是非常类似，也就是说虽然Swift中没有`Partial application`的语法，但可以通过`Closure`实现类似概念

在使用过程中能更清楚看到这一点：

- 执行`partialMultiply`函数，并传入为2的`x`参数
- 返回的新函数，命名为`multiplyBy2`
- 后续通过执行`multiplyBy2`，并传入剩余的参数，就实现了让2与`y`和`z`相乘

Currying指的是，将一个接受多个参数的函数，转换为一系列函数，每个函数仅接受一个参数

```
// 原始函数
func multiply(_ x: Int, _ y: Int, _ z: Int) -> Int {
    return x * y * z
}

func curryMultiply(_ x: Int) -> (Int) -> (Int) -> Int {
    return { y in
        return { z in
            return x * y * z
        }
    }
}

// 使用方式：
let step1 = curryMultiply(2)     // 返回 (Int) -> (Int) -> Int
let step2 = step1(3)             // 返回 (Int) -> Int
let result = step2(4)            // 返回 2 * 3 * 4 = 24

// 或者链式调用
let result2 = curryMultiply(2)(3)(4)
print(result2) // 24
```

- 原函数是`multiply`
- 通过`curryMultiply`，对原函数进行转换，返回值也是一个函数(`(Int) -> (Int) -> Int`)，其实是函数的嵌套（或者说函数的函数）
- 在使用时能看出来，原`multiply`的执行，被拆分成了`curryMultiply`、`step1`和`step2`三次执行，每次执行仅接受1个参数

> 能够看出来，`Currying`其实是`Partial application`的一种特殊情况

## 使用场景

比较明显的是，两个概念都可以用于代码的复用（或者说函数的复用），比如上面代码中的`multiplyBy2`函数就可以作为一个变量或者全局函数来复用

#### 与高阶函数结合使用

```
func add(_ x: Int, _ y: Int) -> Int {
    return x + y
}

// Partial application：固定第一个参数
func add(_ x: Int) -> (Int) -> Int {
    return { y in x + y }
}

let add5 = add(5)
let result = [1, 2, 3].map(add5)  // [6, 7, 8]
```

#### 预定义日志level级别

```
func log(level: String, message: String) {
    print("[\(level)] \(message)")
}

// 部分应用：绑定 log level
func logger(for level: String) -> (String) -> Void {
    return { message in log(level: level, message: message) }
}

let errorLog = logger(for: "ERROR")
let infoLog = logger(for: "INFO")

errorLog("Something went wrong")
infoLog("App started")
```