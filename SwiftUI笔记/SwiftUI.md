# SwiftUI笔记

```
Text("0")
                .font(.system(size: 76))
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    alignment: .trailing)
```

- font、frame这些方法在SwiftUI中叫做modifier
- 有两类Modifier，修改属性的返回相同类型的原地modifier和经过一次封装后的封装类modifier
	- 原地modifier有font、foregroundColor等
	- 封装类modifier有background、cornerRadius等
	- 原地modifier的顺序不重要
	- 封装类modifier顺序不能错