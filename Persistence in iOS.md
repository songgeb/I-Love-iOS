# Persistence in iOS

> 深入理解代替单纯记忆

汇总一下iOS中（Swift、Objective C）的持久化的方案

或者说将如下的专业名词进行分类、结束清楚

> nscoding、archive、serialization、userdefault、plist、core data（sqlite、realm）、codable

## Archive

OC和Swift下都支持

### Features
- 支持数据与byte stream（NSData）之间来回转换；两个过程分别叫做archive、unarchive
- 支持存储Object Graph，即对象间引用关系；且不会存储重复对象
- 支持自定义存储规则，如某些对象 or 属性可以不存储
- 支持OC Object、scalar、structure等多种类型
- 可以持久化到文件中

### How to use
- 核心类有两个：NSCoder、NSCoding
- NSCoder负责整个archive 和 unachive过程
- 如果希望对象类型支持，需要遵循NSCoding协议
- NSCoder类似一个抽象类，常用的具体子类有NSKeyedArchiver、NSKeyedUnArchiver

## Serialization & Deserialization

Serialization & Deserialization为序列化、反序列化的意思

> In computing, serialization (US and Oxford spelling) or serialisation (UK spelling) is the process of translating a data structure or object state into a format that can be stored (for example, in a file or memory data buffer) or transmitted (for example, over a computer network) and reconstructed later (possibly in a different computer environment).  -- from wikipedia

Objective C和Swift中对序列化的支持是不一样的

### Serialization in Objective C
|涉及类|功能|备注|
|:-:|:-:|:-:|
| NSJSONSerialization |支持JSON类型||
| NSPropertyListSerialization |仅支持Property List数据类型与xml数据之间的序列化|Property List是iOS中对一些数据类型的一个统称，可看参考中资料;PropertyList数据转化后的xml文件即为所说的plist文件|

- 以上类仅支持系统内置的类与对应数据类型的转换，如NSDictionary转为JSON数据，NSDictionary数据转为plist文件的数据
- 如果要让自定义对相关支持与不同类型数据的转换，需要额外的工作，比如借助YYModel将JSON转为NSDictionary再转为自定义对象

### Serialization in Swift

上面OC中的类都支持，除此之外，Swift中引入一套新的进行序列化的机制----Codable

- 功能更强大，比如可以使得JSON和自定义对象之间直接来回转换，在OC中必须要借助中间的数据类型如NSDictionary
- 自定义功能更多，如转换规则、错误规则
- 对与JSON、Property List数据之间转换提供了基于Codable的支持

## UserDefaults

- 用于存储轻量级的、需要持久化的键值对数据
- 仅支持存取Property List类型，即自定义对象是不支持存储到NSUserDefaults中的

## Database
Core Data、SQLite、Realm都是数据库

## QA

## References
- [Archives and Serializations Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Archiving/Archiving.html)
- [Property List 使用注意事项](https://juejin.cn/post/6844903992166711304)