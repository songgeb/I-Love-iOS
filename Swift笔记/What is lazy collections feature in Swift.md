# Lazy collections feature in Swift

> 深入理解代替单纯记忆

当前最新Swift版本为Swift 5.10

之前一直没注意过`Lazy Collection`这个Swift特性，最近在看[Design protocol interfaces in Swift-WWDC](https://developer.apple.com/videos/play/wwdc2022/110353)时偶然看到，查阅了一下资料，发现这个特性很早就有了，早在WWDC2018时官方在`Using Collections Effectively` session中就提到了

先对该特性做一个概括性的描述：

- 该特性是`Sequence` protocol的一个属性---`var lazy: LazySequence<Self> { get }`
- 该属性返回的值同样描述了一个Sequence，虽然元素和原Sequence是相同的
- 但对返回的Sequence进行各种高阶函数操作时（如map、reduce、filter等等），就拥有了`lazy`（延迟计算）能力
- 所谓`延迟计算`的特性，可以理解为，直到真正需要用到集合中的元素时（而非在此之前的某个时机），才会真正去遍历或读取集合中的元素，且尽可能只读取所需要的元素，避免多余的读取操作

我把官方文档中对`lazy`属性的描述原文贴出来：

> A sequence containing the same elements as this sequence, but on which some operations, such as map and filter, are implemented lazily.

我认为其实但看上面的内容是比较难描述`lazy`的能力，通过下面的两个例子可以更容易理解

## Demo1

```
let array = [1, 2, 3]

let mappedArray = array.map({
    print("map on array --- \($0)")
    return $0
})


let lazyMappedArray = array.lazy.map({
    print("map on lazy array --- \($0)")
    return $0
})

print(lazyMappedArray.first)
```

控制台输出结果为

```
map on array --- 1
map on array --- 2
map on array --- 3
map on lazy array --- 1
Optional(1)
```

以上例子得出的结论是：

- 普通的集合，在没有`lazy`能力加持下，当执行到`array.map`时就会对集合所有元素进行遍历
- 有了`lazy`能力加持后，`array.lazy.map`执行时，`map`中的closure完全不会执行
- 直到执行到`lazyMappedArray.first`时，`map`的closure才会执行。而且并不会遍历整个array，仅对第一个元素执行了closure

## Demo2

另一个场景是，有些时候我们需要声明一个`Readonly`的属性，返回一个集合，

- 该集合的创建可能需要遍历一个已有的集合
- 该`Readonly`的属性可能需要在程序整个生命周期中执行多次，每次使用都会执行上面的逻辑

```
struct ABC {
    let array = [1, 2, 3]
    var mappedArray: [Int] {
        return array.map {
            print("map on array --- \($0)")
            return $0
        }
    }
    
    var lazyMappedArray:  LazyMapSequence<LazySequence<[Int]>.Elements, LazySequence<[Int]>.Element> {
        return array.lazy.map({
            print("map on lazy array --- \($0)")
            return $0
        })
    }
}

let abc = ABC()
var mappedArray = abc.mappedArray
var lazyMappedArray = abc.lazyMappedArray
abc.mappedArray
abc.lazyMappedArray

lazyMappedArray.first
lazyMappedArray.first
```

控制台输出结果是

```
map on array --- 1
map on array --- 2
map on array --- 3
map on array --- 1
map on array --- 2
map on array --- 3

map on lazy array --- 1
map on lazy array --- 1
```

- 每次执行`abc.mappedArray`，array都会被遍历一遍
- 而`abc.lazyMappedArray`则不会去遍历array，因为还没有使用`lazyMappedArray`中的元素
- `lazyMappedArray.first`尝试读取集合元素时，才会真正执行map closure逻辑

## 总结

- `Lazy collection`特性是通过`Sequence`的`lazy`属性来提供给开发者使用，所以实现了`Sequence`协议的类型都支持`lazy`能力
- 所谓`延迟计算`的特性，可以理解为，直到真正需要用到集合中的元素时（而非在此之前的某个时机），才会真正去遍历或读取集合中的元素，且尽可能只读取所需要的元素，避免多余的读取操作
- `lazy`所赋予的延迟计算能力，在仅使用大数据量集合的部分元素、创建临时集合场景时，能显著降低额外性能损耗


## 参考
- [Swift Collection 中的 lazy 作用](https://juejin.cn/post/6844903566772027406)
- [“懒”点儿好](https://swift.gg/2016/03/25/being-lazy/)
- [[ WWDC2018 ] - 高效使用集合 Using Collections Effectively](https://juejin.cn/post/6844903623189594125)