# Memory Leak in iOS

This article will list several memory leak senarios and respective solutions.

## Closure(Block)

`capture` in Closure may cause a strong reference

such as

`objectA` -> `closure` -> `objectA`

## Timer

- Runloop has a strong reference to timer until call `invalidate()`
- Timer has a strong reference to target if use these methods `init(timeInterval ti: TimeInterval, 
target aTarget: Any, xxxx`
- So it will cause a strong reference cycles 

`Runloop` -> `Timer` -> `Target`

## Delegation

- A is the delegation of B, A also has a property(B type)
- When the delegation property attribute of B is `strong`, it will cause strong reference cycle

`Delegation` -> `B` -> `Delegation`

## NotificationCenter

- when use the api below, it may cause strong reference cycle

```
func addObserver(forName name: NSNotification.Name?, 
          object obj: Any?, 
           queue: OperationQueue?, 
           using block: @escaping (Notification) -> Void) -> NSObjectProtocol
```
- To avoid a retain cycle, use a weak reference to self inside the block when self contains the observer as a strong reference

> when use `addObserver(observer:selector:xxx)`,
If your app targets iOS 9.0 and later or macOS 10.11 and later, you do not need to unregister an observer that you created with this function. If you forget or are unable to remove an observer, the system cleans up the next time it would have posted to it.