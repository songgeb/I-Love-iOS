title: Codable
date: 2019-07-03 09:15:48
tags: []
categories: []
---
- Codable is a type alias
    > typealias Codable = Decodable & Encodable
- 什么是Codable
    - 在进行网络传输时，经常会将应用中的model转换为网络传输中的数据格式如json，这叫做编码(Encode)；那么接收到网络json数据后，将其转为app中的model则是解码(Decode)
    - Swift standard library中定义了几个协议和类来实现编码、解码
        - 协议有Encodable、Decodable、Encoder、Decoder
        - 类有JSONDecoder、JSONEncoder、PropertyListEncoder、PropertyListDecoder

### Encodable、Decodable

- 需要编解码的model需要遵循这两个协议
- Encodable有一个方法需要实现--`func encode(to encoder: Encoder) throws`
- Decodable的方法是--`init(from decoder: Decoder) throws`

### 编解码过程

根据`JSONDecoder`的[源码](https://github.com/apple/swift/blob/56a1663c9859f1283904cb0be4774a4e79d60a22/stdlib/public/SDK/Foundation/JSONEncoder.swift#L773)分析可将大致的编解码过程概括为如下：
1. 从执行`JSONDecoder`或其他coder的`decode/encode`方法开始
2. 根据要编解码的类型，分别执行相应类型所遵循的`Decodable`、`Encodable`的`init`和`encode`方法
3. `init`和`encode`方法内部，通过`Decoder`或`Encoder`的三个方法(参考下面Decoder小节)，获取到要进行编解码的中间数据结构`container`
4. 通过container具体的encode和decode方法将数据从container解码出来，或编码到container中
    - 这一步中的`encode`和`decode`方法内部，其实是递归的对model的每个property进行编解码，即执行property类型的`init`和`decode`方法对property编解码
    - 每层递归，系统都会根据不同层的CodingKeys数据，对container进行剥离（Decode协议一节有细讲），将剥离后的decoder或encoder，传到下一层的`init`或`encode`方法中
5. `init`和`encode`方法结束，编解码过程也就结束了

### 系统自动做的工作

为了节约开发时间，编译器会根据情况自动添加编解码的代码

比如当一个数据类型遵循`Encodable`或`Decodable`时，且该类型的`每个property也是codable的`，那编译器会:
1. 自动添加一个名为`CodingKeys`的实现了`CodingKey`协议的enum；enmu的每个case与该类型的每个property一一对应，即默认会为每个property都进行编解码
2. 自动实现了`init`和`encode`方法

当然，如果不是每个property都是`codable`的或者我们不想每个property都去编解码，我们也可以自己实现`CodingKey`，而`init`和`encode`方法系统仍可以自动实现
- 这样可以选择对部分属性进行编解码
- 当remote data的key名称和memory data的property名字不同时，可以通过自定义来匹配名称

### 支持的数据类型

> 一句话，支持所有实现`Decodable`、`Encodable`的数据类型

很多现有数据类型已经支持该协议

`String`、`Int`、`Double`、`URL`、`Data`、`Date`等等

### Decoder协议
> Encoder协议也是类似的几个属性和方法

`Decoder`和`Encoder`出现在前面所说的`init`和`encode`方法中，它将编解码的数据存放到中间数据结构container中。下面是该协议的属性和方法：

- var codingPath: [CodingKey] { get }
    - 这个值一般开发者用不到，只有在编解码过程中才会有值，用于编解码时寻找数据的层级
    - 出错后，可以使用该值来记录发生错误的key
- var userInfo: [CodingUserInfoKey : Any] { get }
    - 不知怎么用

- `func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey`
- `func singleValueContainer() throws -> SingleValueDecodingContainer`
- `func unkeyedContainer() throws -> UnkeyedDecodingContainer`

这三个方法用于从`container`中取数据或往其中写数据。从decoder的三个方法能够看出（WWDC中也有提到），编解码时支持三种样式数据的编解码。分别是
- 形如Dictionary的数据，且由`CodingKey`可知key的类型必须是`Int`或`String`，value是任何支持`Decodable`的类型。比如常见的最外层是jsonObject的json数据--对应`container<Key>`方法
- 任意一个支持`Decodable`的类型，对应`singleValueContainer`方法
    - 比如下面的json数据是一个表示文本信息的JSONObject，要转成`TextInfo`的model，其中的color这个key对应一个字符串类型，表示一个颜色值
        ```
        {
            "color": "(12, 12, 12)",
            "text" : "I am songgeb!"
        }
        ```
    - 我们想把这个颜色值解析成一个自定义的颜色类型比如叫做`MyColor`
    - 一步步来，我们先在`TextInfo`的`init`方法中，通过`container<Key>(keyedBy type: Key.Type)`方法获取到container，再执行container的decode方法，指定`MyColor`类型继续进行解码
    - 然后，就来到了`MyColor`的`init`方法中，此时的decoder对应的container是剥离后的，只剩下`"(12, 12, 12)"`内容。所以可以通过`singleValueContainer`方法获取到字符串的值，然后就可以进一步处理了
    ```
    //TextInfo中
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.color = try container.decode(MyColor.self, forKey: .color)
    }
    //MyColor中
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        ...
    }
    ```
- 数组类型（数组的每个元素都是支持`Decodable`），比如jsonArray数据类型。对应`unkeyedContainer`方法
    ```
    [
        {...}, {...}
    ]
    ```

### JSONDecoder和Decoder协议

当前有`JSONDecoder/JSONEncoder`和`PlistDecoder/PlistEncoder`两个类型来支持相应数据类型的编解码

- 注意，以`JSONDecoder`为例，这里说的Coder与`Encoder/Decoder`协议没有任何关系
- `Encoder/Decoder`的对象是和container绑定，也就是和编解码的中间数据绑定的
- 这里说的Coder如`JSONDecoder`则不与任何数据绑定，是独立可复用的编解码器

### CodingKey协议

- var stringValue: String { get }
- var intValue: Int? { get }
- init?(stringValue: String)
- init?(intValue: Int)

### 一些特殊的case

### JSONDecoder的strategy

### JSONDecoder的decode源码分析

1. JSONDecoder并不遵循Decoder协议
2. JSONDecoder内部通过私有类`_JSONDecoder`进行实际的解码工作, `_JSONDecoder`是遵循Decoder协议的
3. 解码第一步先用`NSJSONSerialization`将data转为jsonObject
3. 解码时传入初始化方法`init(from decoder: Decoder)`的参数正是`_JSONDecoder`
4. 通过`func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey`方法返回的是`KeyedDecodingContainer`类型
5. `KeyedDecodingContainer`将各种具体的container(如json)包装到其中

### KeyedDecodingContainer结构体
- 定义为，`struct KeyedDecodingContainer<K> : KeyedDecodingContainerProtocol where K : CodingKey`
- typealias KeyedDecodingContainer<K>.Key = K

- 是从json到object之间的一个存储数据的中间结构

### KeyedDecodingContainerProtocol

- associatedtype Key

## 参考
- [Encoding and Decoding Custom Types](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types)
- [Understanding and Extending Swift 4’s Codable](https://stablekernel.com/understanding-extending-swift-4-codable/)
- [Swift 4 JSON 解析进阶](https://bignerdcoding.com/archives/44.html)