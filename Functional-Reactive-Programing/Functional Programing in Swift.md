# Functional Programing in Swift

## What is functional programming?

Functional programming is not a language or syntax - it is a way of thinking about problems. Functional programming was around for decades before we had the monads. Functional programming is a way of thinking about how you tear down problems and then put them back together in structured ways.



## Features
- function is the first-class citizens
- immutable state and lack of side effects
- high order function
- partial function
- Pure Functions

## Imperative Programing

Imperative programming is a programming paradigm that uses statements to change the program’s state. Much like you would use imperative language while playing with your dog — “Fetch! Lay down! Play dead!” — you use imperative code to tell the app exactly when and how to do things.

Imperative code is similar to the code that your computer understands. All the CPU does is follow lengthy sequences of simple instructions. The issue is that it gets challenging for humans to write imperative code for complex, asynchronous apps — especially when shared mutable state is involved.

## Imperative solution vs Functional solution

```
var ridesOfInterest: [Ride] = []
for ride in parkRides where ride.waitTime < 20 {
  for category in ride.categories where category == .family {
    ridesOfInterest.append(ride)
    break
  }
}

let sortedRidesOfInterest1 = ridesOfInterest.quickSorted()
print(sortedRidesOfInterest1)
```

```
let sortedRidesOfInterest2 = parkRides
    .filter { $0.categories.contains(.family) && $0.waitTime < 20 }
    .sorted(by: <)
```

## References
- [An Introduction to Functional Programming in Swift](https://www.raywenderlich.com/9222-an-introduction-to-functional-programming-in-swift#toc-anchor-013)
- [Swift and the Legacy of Functional Programming](https://academy.realm.io/posts/tryswift-rob-napier-swift-legacy-functional-programming/)