# 正则表达式 in iOS

- 正则表达式用`NSRegularExpression`表示
    - `NSRegularExpression(pattern: "id=\\(d.)", options: .caseInsensitive)`
- 匹配的结果用`NSTextCheckingResult`表示
    - 包括匹配的结果的range信息
    - `range(at: index)`方法来获取每个group的信息

## 举例
```
//String string = http://www.xxx.com?id=10086&media=xxxx
//获取上面网址中的id值
do {
    let regularExp = try NSRegularExpression(pattern: "id=(\\d+)", options: .caseInsensitive)
    let firstResult = regularExp.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.count))
    if let range = firstResult?.range(at: 1) {
        let meipaiFeedId = (string as NSString).substring(with: range)
    }
} catch {
    printIfDebug(error)
}
```

## 参考
- [nsregularexpression](https://developer.apple.com/documentation/foundation/nsregularexpression)