# JSON与Model互转 in Swift

- Codable, ObjectMapper, CodableWrapper

## Codable存在什么问题

根据日常开发经验，我们看一下Swift原生的Codable使用起来会有什么不方便的地方

### 无法设置默认值

```
struct User: Codable {
    var name: String
    var age: Int
}

let json = #"{"name": "Tom"}"#
let user = try JSONDecoder().decode(User.self, from: Data(json.utf8))
```

以上代码会报错，原因是JSON中没有age，所以decode时直接报错缺少该字段。那有没有办法解决呢？

当然是可以的，即自己重新实现`init`方法

但这样并不精简，为了一个字段默认值，我还得写一堆胶水代码。能不能直接这样呢？

```
struct User: Codable {
    var name: String
    var age: Int = 0
}
```

显然，不行

### 