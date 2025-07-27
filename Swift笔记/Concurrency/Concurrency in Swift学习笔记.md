# Concurrency in Swift学习笔记-初识

读完官方《The Swift Programming Language》中的Concurrency部分后，感觉对其中的很多概念并没有深入的讲解，也没办法容易地上手写代码

于是查阅了其他的资料，希望对整体的设计理念和实践有清晰的认识，方便后应用到项目中

- 并发模型Concurrency自Swift 5.5版本引入

无论是Concurrency，还是其他语言的并发工具，都是为了解决并发中的两个问题：

1. 如何确保不同运算运行步骤之间的交互或通信可以按照正确的顺序执行。
2. 如何确保运算资源在不同运算之间被安全地共享、访问和传递

## 概念虽多但职责清晰

各模块职责清晰

- 异步函数(Asynchronous Functions)：提供语法工具，使用更简洁和高效的方式，表达异步行为
- 结构化并发(Structured Concurrency)：提供并发的运行环境，负责正确的函数调度、取消和执行顺序以及任务的生命周期
- actor 模型：提供封装良好的数据隔离，确保并发代码的安全
 
### 异步函数
简单讲，就是用`async`标记的函数

```
// 异步函数
func loadSignature() async throws -> String? {
	let (data, _) = try await URLSession.shared.data(from: someURL)
	return String(data: data, encoding: .utf8)
}
// 执行函数
let signature = await loadSignature()
```

- 执行该函数时必须在前面加`await`关键字，代表了函数在此处可能会**放弃当前线程**，它是程序的潜在**暂停点(Suspension Points)**
- 放弃线程的能力，意味着异步方法可以被“暂停”，这个线程可以被用来执行其他代码。如果这个线程是主线程的话，那么界面将不会卡顿
- 被 await 的语句将被底层机制分配到其他合适的线程，在执行完成后，之前的“暂停”将结束，异步方法从刚才的 await 语句后开始，继续向下执行

异步函数的 async 关键字会帮助编译器确保两件事情:

1. 它允许我们在函数体内部使用`await`，继续调用其他异步函数
2. 它要求其他人调用该函数时，必须使用`await`关键字

### 结构化并发
- 对于同步函数来说，线程决定了它的执行环境。而对于异步函数，线程的概念被弱化，异步函数的执行环境交由任务 (`Task`) 决定
- Swift 提供了一系列 `Task`相关 API 来让开发者创建、组织、检查和取消任务
- 这些 API 围绕着 Task 这一核心类型，为每一组并发任务构建出一棵结构化的任务树：

	- 一个任务具有它自己的优先级和取消标识，它可以拥有若干个子任务并在其中执行异步函数。
	- 当一个父任务被取消时，这个父任务的取消标识将被设置，并向下传递到所有的子任务中去。
	- 无论是正常完成还是抛出错误，子任务会将结果向上报告给父任务，在所有子任务完成之前 (不论是正常结束还是抛出)，父任务是不会完成的。

> 听上去和`Operation`很类似，但语法写起来更简洁

既然异步函数的上下文是`Task`，那第一个`Task`，或者说第一个任务树环境是怎么来的？

- 要回答这个问题还需要更深入的学习，但初期的话，可以先从`Task`这个结构开始了解
- 简单地使用 Task.init 就可以让我们获取一个任务执行的上下文环境，它接受一个 async 标记的闭包，代码如下所示：

```
        struct Task<Success, Failure> where Failure : Error {
            init(
                priority: TaskPriority? = nil,
                operation: @escaping @Sendable () async throws -> Success
            )
        }
        
        var results: [String] = []
        func someSyncMethod() {
            Task {
                try await processFromScratch()
                print("Done: \(results)")
            }
        }
        func processFromScratch() async throws {
            let strings = try await loadFromDatabase()
            if let signature = try await loadSignature() {
                strings.forEach {
                    results.append($0.appending(signature))
                }
            } else {
                throw NoSignatureError()
            }
        }
```

- 在这个`Task`中执行的闭包，就是一个新任务树的根节点

### Actor模型

actor模型是为了保证多线程并发读写共享资源不冲突而存在的，简单理解actor模型的话可以参考如下代码：

```
class Holder {
	private let queue = DispatchQueue(label: "resultholder.queue")
	private var results: [String] = []
	func getResults() -> [String] {
		queue.sync { results }
	}
	
	func setResults(_ results: [String]) {
		queue.sync { self.results = results }
	}
	
	func append(_ value: String) {
		queue.sync { self.results.append(value) }
	}
}
```

- 以上的类`Holder`是在不使用Actor是为了避免共享资源读写冲突而实现的，即通过串行队列对results的读写进行保护

而actor模型的写法则是这样：

```
actor Holder {
	var results: [String] = []
	func setResults(_ results: [String]) {
		self.results = results
	}
	
	func append(_ value: String) {
		results.append(value)
	}
}
```

- 只是在class名之前加了一个`actor`关键词，我们可以简单的认为它就拥有了像上面引入串行队列或者加锁后可以安全读写的效果
- 有一个戏谑的称呼，原来的写法是手动挡，引入`actor`后是自动挡的class

## 疑问
1. 当在thread1上通过`await`执行async function时，此时会发生挂起，那这个async function是不是一定在会在thread1上执行呢？

这个疑问主要是因为我看到官方文档的说法：

> This is also called yielding the thread because, behind the scenes, Swift suspends the execution of your code on the current thread and runs some other code on that thread instead.

我认为肯定无法确定是运行在thread1上，因为官方还有另一句话：

> When an asynchronous function resumes, Swift doesn’t make any guarantee about which thread that function will run on.

即，当async function恢复（或者说await调用结束后）时，并不能保证当前执行async function的线程

2. 当在thread1上通过await执行async function结束后，是否一定会回到thread1上？

我想也不是的

## 参考
- [WWDC-Explore structured concurrency in Swift](https://developer.apple.com/videos/play/wwdc2021/10134/)
- [WWDC-Swift concurrency: Update a sample app](https://developer.apple.com/videos/play/wwdc2021/10194/)
- [《Swift 异步和并发》-王巍](https://objccn.io/products/async-swift)
