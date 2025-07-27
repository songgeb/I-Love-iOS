# Key-Path expression in Swift

A key-path expression refers to a property or subscript of a type.

We can use it to get or change the property or data at subscript.

It is like the key or keypath in KVO, but more powerful.

The basic format is:

`\type name.path`

- The type name is the name of a concrete type, including any generic parameters, such as String, [Int], or Set<Int>.
- The path consists of property names, subscripts, optional-chaining expressions, and forced unwrapping expressions.
- At compile time, a key-path expression is replaced by an instance of the [KeyPath](https://developer.apple.com/documentation/swift/keypath) class.

```
struct SomeStructure {
    var someValue: Int
}

let s = SomeStructure(someValue: 12)
let pathToProperty = \SomeStructure.someValue

let value = s[keyPath: pathToProperty]
// value is 12
```

### Omit type name

The type name can be omitted in contexts where type inference can determine the implied type.

```
class SomeClass: NSObject {
    @objc dynamic var someProperty: Int
    init(someProperty: Int) {
        self.someProperty = someProperty
    }
}

let c = SomeClass(someProperty: 10)
c.observe(\.someProperty) { object, change in
    // ...
}
```

### Use as subscript

```
let greetings = ["hello", "hola", "bonjour", "안녕"]
let myGreeting = greetings[keyPath: \[String].[1]]
// myGreeting is 'hola”
```

> can also use `\[String][1]`

### Use optional chaining and force unwrapping

```
let count = greetings[keyPath: \[String].first?.count]
print(count as Any)
// Prints "Optional(5)
```

> force unwrapping in keypath can also cause runtime error

### Identity Key Path

`\.self` or `\Type name.self` refers to a whole instance.

```
var compoundValue = (a: 1, b: 2)
// Equivalent to compoundValue = (a: 10, b: 20)
compoundValue[keyPath: \.self] = (a: 10, b: 20)
```

### Use like function or closure

> Swift 5.2 required

You can use a key path expression in contexts where you would normally provide a function or closure. Specifically, you can use a key path expression whose root type is SomeType and whose path produces a value of type Value, instead of a function or closure of type (SomeType) -> Value.

```
struct Task {
    var description: String
    var completed: Bool
}
var toDoList = [
    Task(description: "Practice ping-pong.", completed: false),
    Task(description: "Buy a pirate costume.", completed: true),
    Task(description: "Visit Boston in the Fall.", completed: false),
]

// Both approaches below are equivalent.
let descriptions = toDoList.filter(\.completed).map(\.description)
let descriptions2 = toDoList.filter { $0.completed }.map { $0.description }
```

## Reference
- [Key-Path Expression-The Swift Programing Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/expressions/#Key-Path-Expression)
- [What is a KeyPath in Swift](https://sarunw.com/posts/what-is-keypath-in-swift/)
