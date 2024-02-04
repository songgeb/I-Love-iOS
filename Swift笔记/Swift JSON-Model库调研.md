# Swift JSON/Model库调研

近期(2023年11月)对Swift JSON与Model互转的代码库做了一点调研，希望找到好用的工具

## 目标

### 解决Swift原生Codable几个不易用的问题

> 需要说明一点，下面列举的所有问题，原生Codable都是可以解决的，只是做不到简易的要求，需要开发者手动写一些代码来完成

  - 类型不匹配或JSON字段缺失导致编解码失败
    - 默认情况下，使用Swift Codable时，如果一旦JSON数据中某个字段的类型与Model的属性类型不匹配，或者JSON中的值为null或缺失，则整个Model的编解码都会失败
    - 我们希望个别字段的缺少或类型不匹配不影响整个编解码过程
  - 不易类型兼容
    - 此处所说的类型兼容意思是，JSON值和Model对应字段类型不匹配但可以兼容时，比如Model要求bool类型，但返回值是int类型时，是可以进行兼容解析的
    - 但默认情况下，原生Codable会解析失败
  - 不支持多CodingKey：JSON Key与Model.property的关系，有时是多对一的
    - 即一个Model可能用于不同场景下，不同场景下可能拿到的JSON数据中字段名并不相同
  - 无法简易提供默认值：无法简便地为Mode的属性提供默认值，目前只能重写init来实现，且此时需要在init中为所有属性编写赋值逻辑，会多出一些重复工作
  - 无法简易地自定义Transform
  - 无法简易解析嵌套key

### 保证Model的封装性

  - 封装性为面向对象设计思想中的四个特点之一，即减少暴露对象的属性（成员变量）的存取权限，避免随意更改进而增加出问题风险
    - 具体到JSON框架当中，就是能否将属性标记为`let`，如果可以那就是严格保证了封装性
    - 如果只能做到`private(set) var`则只能说保留部分封装性（其实本质上仍不是真正意义上的封装性）
    - 如果只能标记为`var`则完全不能保证封装性
  - 之前在使用的JSON库虽解决了原生Codable的不易用问题，但或多或少存在违反设计原则问题，比如CodableWrapper基于PropertyWrapper实现，该feature要求每个属性一定是可变(var)的，这影响了对象的封装性

## JSON库对比

### [ObjectMapper](https://github.com/tristanhimmelman/ObjectMapper)

- 原理：基于协议自定义编解码过程，不依赖于原生Codable，不依赖反射
- 原生Codable出来之前，使用的比较多

```
class User: Mappable {
    var username: String?
    var age: Int?
    var weight: Double!
    var array: [Any]?
    var dictionary: [String : Any] = [:]
    var bestFriend: User?                       // Nested User object    
    var friends: [User]?                        // Array of Users    
    var birthday: Date?
    
    required init?(map: Map) {

    }

    // Mappable    
    func mapping(map: Map) {
        username    <- map["username"]
        age         <- map["age"]
        weight      <- map["weight"]
        array       <- map["arr"]
        dictionary  <- map["dict"]
        bestFriend  <- map["best_friend"]
        friends     <- map["friends"]
        birthday    <- (map["birthday"], DateTransform())
    }
}

let user = User(JSONString: JSONString)
```

### [HandyJSON](https://github.com/alibaba/HandyJSON)

- 自定义编解码过程，不依赖原生Codable
- 具体原理：从类信息里获取所有属性的特征，包括名称，属性在内存里的偏移量、属性的个数、属性的类型等等，然后将服务端返回来的数据用操作内存的方式将数值写入对应的内存，来实现json 转model
- 需要注意的是它强烈依赖 Metadata 结构，随着Swift版本和编译器的升级，这个结构随时可能有各种变化，容易引起崩溃等不稳定问题
- 阿里出品

```
class Cat: HandyJSON {
    var id: Int64!
    var name: String!
    var parent: (String, String)?
    var friendName: String?

    required init() {}

    func mapping(mapper: HelpingMapper) {
        // specify 'cat_id' field in json map to 'id' property in object
        mapper <<<
            self.id <-- "cat_id"

        // specify 'parent' field in json parse as following to 'parent' property in object
        mapper <<<
            self.parent <-- TransformOf<(String, String), String>(fromJSON: { (rawString) -> (String, String)? in
                if let parentNames = rawString?.characters.split(separator: "/").map(String.init) {
                    return (parentNames[0], parentNames[1])
                }
                return nil
            }, toJSON: { (tuple) -> String? in
                if let _tuple = tuple {
                    return "\(_tuple.0)/\(_tuple.1)"
                }
                return nil
            })

        // specify 'friend.name' path field in json map to 'friendName' property
        mapper <<<
            self.friendName <-- "friend.name"
    }
}

let jsonString = "{\"cat_id\":12345,\"name\":\"Kitty\",\"parent\":\"Tom/Lily\",\"friend\":{\"id\":54321,\"name\":\"Lily\"}}"

if let cat = Cat.deserialize(from: jsonString) {
    print(cat.id)
    print(cat.parent)
    print(cat.friendName)
}
```

### [KakaJSON](https://github.com/kakaopensource/KakaJSON)

- 原理和HandyJSON类似，也是基于Swift的Metadata结构，通过读写数据结构内存实现编解码
- 作者是MJRefresh的作者小码哥

```
struct Cat: Convertible {
    var name: String = ""
    var weight: Double = 0.0
}

// json can also be NSDictionary, NSMutableDictionary
let json: [String: Any] = [
    "name": "Miaomiao",
    "weight": 6.66
]

let cat1 = json.kj.model(Cat.self)

// jsonData can alse be NSData, NSMutableData
let jsonData = """{    "name": "Miaomiao",    "weight": 6.66}""".data(using: .utf8)!
let cat1 = jsonData.kj.model(Cat.self)
let cat2 = model(from: jsonData, Cat.self)

```

### 元编程方案

> 元编程（英语：Metaprogramming），又译超编程，是指某类计算机程序的编写，这类计算机程序编写或者操纵其它程序（或者自身）作为它们的资料，或者在编译时完成部分本应在运行时完成的工作。多数情况下，与手工编写全部代码相比，程序员可以获得更高的工作效率，或者给与程序更大的灵活度去处理新的情形而无需重新编译。--来自维基百科

原理：由于原生Codable能力足够强大，所以元编程在JSON部分的应用主要体在，基于原生Codable，通过元编程方案帮助我们自动生成繁琐且无多大意义的编解码代码

通过下面演示大概感受一下Sourcery元编程方案实现的自动生成Codable代码的效果

![](https://github.com/songgeb/picx-images-hosting/blob/master/20231121/sourcery.7coh620a2e00.gif?raw=true)

- 调研到的元编程方案有两种：Swift Macros和[Sourcery](https://github.com/krzysztofzablocki/Sourcery)
- SwiftMacros是Swift 5.9版本官方推出的feature；由于Swift是开源的（包括其AST），所以Sourcery是基于Swift开发的通过分析AST，自动生成代码工具
- 元编程方案优点
  - 本质上是帮助开发者补充胶水代码，稳定性有保证
- SwiftMacros方案优于Sourcery
  - SwiftMacros类似其他语言中的宏，但功能要丰富很多
  - 可以通过开发自定义的宏，自动生成Codable中繁琐的代码，且支持多种不同类型的宏，可以轻松展开、折叠宏，支持编译时校验、断点调试宏，宏安全方面也通过诸多限制得以保证
  - [CodableWrapper](https://github.com/winddpan/CodableWrapper)从1.0.0版本开始用SwiftMacros进行了重写，是一种可以直接使用的元编程方案
- SwiftMacros缺点
  - 只支持SPM方式接入，不支持Cocoapods，当然，即使使用Cocoapods也有办法使用宏，就是略微麻烦

- Sourcery方案缺点
  - 该方案需要自定义代码生成规则和模板，并且可能要求开发人员在指定要生成的代码时，遵守一定的书写规范，还是有一点熟悉成本

### [ExCodable](https://github.com/iwill/ExCodable)

- 原理：通过继承原生Codable协议，在Codable编解码过程前后和过程中添加自定义逻辑，并通过PropertyWrapper特性来精简开发者代码量。思想来自Codextended(1.5k star)
- 全部使用官方public API（有使用反射，但也仅使用了其public API进行读操作），没有猜测Metadata结构和进行内存操作
- 代码精简，一个文件，500+行

```
class ABCModel: Codable {

    @ExCodable("abc.a", "isOn")
    private(set) var boolValue: Bool = false
    @ExCodable("str", decode: { decoder in
        return "xxx"
    })
    private(set) var string: String? = nil
    
    required init(from decoder: Decoder) throws {
        try decode(from: decoder, nonnull: false, throws: false)
    }
    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, nonnull: false, throws: false)
    }
}

```

### [CodableWrapper](https://github.com/winddpan/CodableWrapper)

- .0.0版本之前，通过反射、内存操作、PropertyWrapper等技术，在Codable编解码过程前后和过程中添加自定义逻辑。但由于存在内存指针操作和依赖Metadata结构的原因，存在不稳定因素
  - 工程中已经验证，0.1.2版本的代码，在iOS升级到17后，使用系统原生JSONDecoder解码时，会导致崩溃
- 1.0.0版本开始，使用Swift Macros重写，由于使用的是Swift官方支持的能力，所以稳定性不会有问题

#### 1.0.0版本代码演示

```
@Codable
struct BasicModel {
    var defaultVal: String = "hello world"
    var defaultVal2: String = Bool.random() ? "hello world" : ""
    let strict: String
    let noStrict: String?
    let autoConvert: Int?
    
    @CodingKey("hello")
    var hi: String = "there"
    
    @CodingNestedKey("nested.hi")
    @CodingTransformer(StringPrefixTransform("HELLO -> "))
    var codingKeySupport: String
    
    @CodingNestedKey("nested.b")
    var nestedB: String
    
    var testGetter: String {
        nestedB
    }
}

```

#### 0.3.3版本代码演示

```
class CodableWrapperModel: Codable {
    Codec(transformer: SecondDateTransform())
    var registerDate: Date?
            
    @Codec("abc.a")
    private(set) var int: Bool = false
            
    @Codec("str, text")
    private(set) var string: String? = nil
}
```

### 综合对比

|特性|原生Codable|ObjectMapper|HandyJSON|KakaJSON|ExCodable|CodableWrapper(0.3.3)| Swift Macros方案 如CodableWrapper(1.0.0) |基于 Sourcery 的方案|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|类型不匹配或JSON字段缺失时不会导致编解码失败|❌|✅|✅|✅|✅|✅|✅|✅|
|类型兼容|❌|❌|✅|✅|✅|✅|✅|✅|
|多CodingKey|❌|❌|✅|✅|✅|✅|✅|✅|
| 简易提供默认值 |❌|✅|✅|✅|✅|✅|✅|✅|
| 简易解析嵌套key |❌|✅|✅|✅|✅|✅|✅|✅|
| 简易自定义Transform |❌|✅|✅|✅|✅|✅|✅|✅|
| 保持封装性 |✅|✅|❌|❌|❌|❌|✅|✅|
| 稳定性 |⭐️⭐️|⭐️⭐️|⭐️|⭐️|⭐️⭐️|⭐️|⭐️⭐️|⭐️⭐️|
| 接入成本 |easy|middle| middle | middle |easy|easy| middle |hard|
| 最低iOS版本要求 |8|10|8|8|9|11|13|8|
| Star |-|9.1k|4.2k|1.1k|0.1k|0.2k|0.2k|7.3k|

## 结论

汇总前面多个方案，个人最推荐SwiftMacros方案（比如1.0.0版本的CodableWrapper），其次是ExCodable。原因如下：

- CodableWrapper符合所有的目标要求，唯一缺点是由于SwiftMacros功能比较新，有一定接入成本，必须满足如下要求
  - 项目支持SPM（初步验证SPM和Cocoapods可以同时使用）或用替代办法（将CodableWrapper使用Cocoapods发布）
  - 工程最低支持的iOS系统版本必须大于等于13，最低Swift版本大于等于5.9（对应Xcode版本为15）
- 将ExCodable作为备选是因为，它能满足绝大部分场景要求，且代码最为精简，无trick行为稳定性有保证

## 参考

- [Swift 中的 JSON 反序列化 - 掘金](https://juejin.cn/post/7120415927891394574#heading-10)
- [一篇带给你Swift 中的反射 Mirror-swift反射机制](https://www.51cto.com/article/658210.html)
- [ExCodable](https://iwill.im/ExCodable/)
- [【WWDC23】一文看懂 Swift Macro - 掘金](https://juejin.cn/post/7249888320166903867#heading-19)
- [Swift Macros 元编程为Codable解码提供默认值 - 掘金](https://juejin.cn/post/7247028435339083836)
- [Swift如何在不使用SPM管理的项目中使用宏 - 掘金](https://juejin.cn/post/7272543983447883837)