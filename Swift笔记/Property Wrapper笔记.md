# Property Wrapper笔记

`property wrapper`（翻译为中文叫做属性包装器）可以为代码添加了一个层隔离，这层隔离是针对property的，添加的位置是：**property的定义代码和property如何存储的代码之间**

更简单通俗一点的描述是：

> 在`property`的存和取的过程中添加了一些代码，这些代码逻辑就是`Property Wrapper`

## Property Wrapper基本写法与工作原理

- `@propertyWrapper`标记 + (class或struct或enum)来定义一个`Property Wrapper`
- 该结构中必须声明一个`wrappedValue`属性，用于表示`包装后的值`

```
@propertyWrapper
struct TwelveOrLess {
    private var number = 0
    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, 12) }
    }
}

struct SmallRectangle {
    @TwelveOrLess var height: Int
    @TwelveOrLess var width: Int
}

rectangle.height = 24
print(rectangle.height)
// Prints "12"
```

基本原理是，编译器会自动将Property Wrapper中的逻辑合成到每个应用的属性上，通过显式的Property Wrapper写法能够看出大致的工作原理

```
struct SmallRectangle {
    private var _height = TwelveOrLess()
    private var _width = TwelveOrLess()
    var height: Int {
        get { return _height.wrappedValue }
        set { _height.wrappedValue = newValue }
    }
    var width: Int {
        get { return _width.wrappedValue }
        set { _width.wrappedValue = newValue }
    }
}
```

## Property Wrapper高级用法

现在我们再去审视Property Wrapper，可以更通俗易懂地描述一下它的工作原理：

> 在property的set和get过程中，引入一个中间层，这个中间层可以是class、struct或enum中的任意结构。在这个结构中可以加入任意逻辑

`Property Wrapper`的核心既然是这个中间层，那围绕中间层的定义，出现了一些`Property Wrapper`的高级用法

这些高级用法主要是来自`Property Wrapper`的不同初始化方法。那么`Property Wrapper`有几种初始化方式呢？

因为`Property Wrapper`可以用`class、struct、enum`任意类型表示，那初始化方法按照对应type写即可。但是，其中有一种初始化方法比较特殊---类似`init(wrappedValue:)`，即初始化方法中包含`wrappedValue`参数的情况

所以，下面我们据此分成两类初始化方法进行描述

- 系统默认或自定义初始化方法
- 有`wrappedValue`参数的初始化方法

### 自定义初始化方法

```
@propertyWrapper
struct SmallNumber {
    private var maximum: Int
    private var number: Int


    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, maximum) }
    }

    init() {
        maximum = 12
        number = 0
    }
}

struct NarrowRectangle {
	@SmallNumber var number: Int
}
```

- 上面代码中`SmallNumber`提供了一个初始化方法
- `NarrowRectangle`中`number`的写法，就是使用了上述初始化方法
- 注意一点，由于使用了`SmallNumber`初始化方法，所以可以认为默认情况下，`NarrowRectangle.number`是被赋值为0的，所以`let abc = NarrowRectangle()`写法是不会编译报错的，因为`number`可以被正确初始化

### 有`wrappedValue`参数的初始化方法

```
@propertyWrapper
struct SmallNumber {
    private var maximum: Int
    private var number: Int

    var wrappedValue: Int {
        get { return number }
        set { number = min(newValue, maximum) }
    }


    init() {
        maximum = 12
        number = 0
    }
    init(wrappedValue: Int) {
        maximum = 12
        number = min(wrappedValue, maximum)
    }
    init(wrappedValue: Int, maximum: Int) {
        self.maximum = maximum
        number = min(wrappedValue, maximum)
    }
}

struct UnitRectangle {
    @SmallNumber var height: Int = 1
    @SmallNumber var width: Int = 2
    @SmallNumber(wrappedValue: 2, maximum: 5) var  height: Int // 3
    @SmallNumber(maximum: 9) var width: Int = 2 // 4
}
```

- 参数中有`wrappedValue`参数时，为`wrappedValue`传参的方式比较特殊---此处`@SmallNumber var height: Int = 1`的写法就时将1作为`wrappedValue`进行传值
- 原理上讲的话，就等价于`UnitRectangle(height: SmallNumber(wrappedValue: 1), width: SmallNumber(wrappedValue: 2))`
- 还有更复杂的初始化，比如后面两种初始化方法
- `UnitRectangle`中3和4写法则使用了第3个初始化方法

## 总结

- `Property Wrapper`在property的存取过程中添加了一个中间层，可以增加自定义逻辑
- `Property Wrapper`可以将重复代码进行抽离、复用
- `Property Wrapper`的工作原理是编译器自动合成代码
- `Property Wrapper`的工作原理要求property必须是`var`的
- 基于`Property Wrapper`原理可以应用于复杂的场景，比如简化`Codable`过程--参考`CodableWrapper`和`ExCodable`代码库




