# What's new in Swift 5

## Raw Strings

在Swift 4中，当在String literal中使用反斜杠、双引号时，需要使用反斜杠进行转义，比如

```
let escape = "You use escape sequences for \"quotes\"\\\"backslashes\" in Swift 4.2."
print(escape)
// You use escape sequences for "quotes"\"backslashes" in Swift 4.2.
```

- 这会导致string literal中充斥着很多与语义无关的反斜杠，影响代码可读性

Swift 5中做了优化，我们只需要在string literal的开始和结束位置各添加一个#，那么literal部分便可以去掉干扰阅读的反斜杠了，比如

```
let escape = #"You use escape sequences for "quotes"\"backslashes" in Swift 4.2."#
print(escape)
// You use escape sequences for "quotes"\"backslashes" in Swift 4.2.

let multiline = #"""
                You can create """raw"""\"""plain""" strings
                on multiple lines
                in Swift 5.
                """#
print(multiline)

// multiline打印结果如下
You can create """raw"""\"""plain""" strings
on multiple lines
in Swift 5.
```

> 有一点需要注意，当在String interpolation中使用Raw Strings时，因为#会讲双引号字符串部分进行特殊处理，所以String interpolatiion也会被误当做纯字符串，所以要做下特殊处理，如下

```
let track = #"Nothing Else #Matters"#
print(#"songgeb is not \#(track)"#)
songgeb is not Nothing Else #Matters
```

## Some vs Any


参考

- [Understanding the “some” and “any” keywords in Swift 5.7](https://swiftsenpai.com/swift/understanding-some-and-any/)

## References

- [What’s New in Swift 5?](https://www.kodeco.com/55728-what-s-new-in-swift-5)
- [How to use custom string interpolation](hackingwithswift.com/articles/163/how-to-use-custom-string-interpolation-in-swift)