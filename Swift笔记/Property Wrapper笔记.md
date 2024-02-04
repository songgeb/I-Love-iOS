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

两类初始化方法，分别是：

- 系统默认或自定义初始化方法
- `init(wrappedValue: T)`

### 系统默认初始化方法

```
struct SmallRectangle {
    @TwelveOrLess var height: Int
    @TwelveOrLess var width: Int
}
```

比如上面代码中，当初始化`SmallRectangle`时，其实等价于

```
SmallRectangle(height: TwelveOrLess(), width: TwelveOrLess())
```

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
    init(wrappedValue: Int) {
        maximum = 12
        number = min(wrappedValue, maximum)
    }
    init(wrappedValue: Int, maximum: Int) {
        self.maximum = maximum
        number = min(wrappedValue, maximum)
    }
}

struct NarrowRectangle {
    @SmallNumber(wrappedValue: 2, maximum: 5) var height: Int
    @SmallNumber(maximum: 9) var width: Int = 2
}
```

上述`NarrowRectangle`的初始化则等价于

```
NarrowRectangle(height: SmallNumber(wrappedValue: 2, maximum: 5), width: SmallNumber(wrappedValue: 2, maximum: 9))
```

### `init(wrappedValue: T)`初始化

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
}
```

此处`@SmallNumber var height: Int = 1`的写法就等价于，`UnitRectangle(height: SmallNumber(wrappedValue: 1), width: SmallNumber(wrappedValue: 2))`




