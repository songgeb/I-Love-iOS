# iOS面试之将多个异步任务串行起来

面试题：多个异步任务如何优雅地串行执行


## 题目简要分析

这是一个很好的面试题，主要考察了候选人是否有一定的开发经验和对代码质量的追求

- 对于没多少开发经验的人，可能都不太清楚题目中提到的场景；
- 对技术热爱、感兴趣的同学在遇到这种情况时很可能会思考，常规的异步多任务代码写起来比较啰嗦，可读性会严重下降，从而会促使开发者进一步思考如何改进该问题

举个不太优雅的例子

```
    let urlsession = URLSession(configuration: .default)
    let request = URLRequest(url: URL(string: "url")!)
    let task = urlsession.dataTask(with: request) { data, _, _ in
      urlsession.dataTask(with: request) { data, _, _ in
        urlsession.dataTask(with: request) { data, _, _ in
          //
        }
      }
    }
    task.resume()
```
- block嵌套的有点多了
- 如果不同任务的事件回调方式各不相同(下文有提到不同回调方式)，代码就会分散在不同地方，可读性更差

## 解题思路

这种场景自然是比较常见的了，因为原生iOS中事件回调的方式有如下几种：

- block
- delegation
- target-action
- notification, kvo

所以，题目中提到的异步任务都可能通过上面几种途径完成，比如通过URLSession发送网络请求时，URLSession就提供了block和delegation两种数据回调的方式

## 响应式编程答案

之前提到，该题目是考察开发经验的，我就直接说我的经验

我一看到该题目，我脑海里出现了几个关键字：链式调用, 高阶函数, 响应式编程

如果你曾了解过iOS中关于响应式编程的框架如ReativeCocoa、RxSwift，也会想到这些

- 这些框架的核心思想(本质就是响应式编程的思想)，是将事件的处理过程看做信号(数据)流
- 一个完整的操作必定是
	- 由某处发起一个任务
	- 任务产生了一些数据(信号)，经过不同阶段的处理最终产出结果数据(信号)
- 这些框架基于这种思想，将上一节中的所有事件回调方式都做了封装，统一了事件回调方式

对应到该题目中

- 不同的异步任务可以认为是数据(信号)经过的不同阶段的处理

所以我认为，可以模拟响应式编程的思路

来看下一个RxSwift如何创建和使用的

```
  let observable = Observable<String>.create { observer in
    // execute sync or async task
    // use onNext to notify next observer
    observer.onNext("data")
    return Disposables.create()
  }
  observable.map { element in
    // extra logic for data
    return element
  }
  observable.subscribe(
    // get final result
    onNext: { print($0) }
  )
```

通过注释能更清晰的了解到

- 先创建了一个任务，其中可以做同步或异步的事情，事情做完后通过onNext通知给后面接收数据进行处理的对象
- 通过map方法对上面的数据又了一些处理
- 第三部分，接收最终数据做后序工作

其实，除了RxSwift，还有专门针对简化异步任务的框架--PromiseKit，相比RxSwift它更精简，专注于简化异步任务，更适合解决该问题

### PromiseKit

在没看到PromiseKit之前，我想自己设计一个简单的异步任务串行调度工具，但写来写去，要么无法实现功能，要么会触发内存循环引用，根本原因是没有一个清晰的设计思路：设计怎样的数据结构来存储任务，如何控制任务之间的调度

先来看下PromiseKit的强大之处

这样一段先登录再获取头像再更新UI的操作，如果使用传统的block回调是这样

```
login { creds, error in
    if let creds = creds {
        fetch(avatar: creds.user) { image, error in
            if let image = image {
                self.imageView = image
            }
        }
    }
}
```

使用PromiseKit后

```
firstly {
    login()
}.then { creds in
    fetch(avatar: creds.user)
}.done { image in
    self.imageView = image
}
```

下面我来通过分析PromiseKit源码来了解背后的设计思想

> 基于PromiseKit 6.8.1

我们以如下简单的代码示例来介绍其设计思想

```
    // 1
    let task1 = Promise { seal in
      seal.resolve(.fulfilled(1))
    }

    task1
    .then({ value in
      // simulate a async task
      return Promise { seal in
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          seal.resolve(.fulfilled(1 + value))
        }
      }
    })
```

我们来看下类UML图

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/PromiseKit_classes.png?raw=true)

then方法的源码如下

```
func then<U: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) throws -> U) -> Promise<U.T> {
	let rp = Promise<U.T>(.pending)
	pipe {
		switch $0 {
		case .fulfilled(let value):
			on.async(flags: flags) {
				do {
					let rv = try body(value)
                    guard rv !== rp else { throw PMKError.returnedSelf }
                    rv.pipe(to: rp.box.seal)
                } catch {
                    rp.box.seal(.rejected(error))
                }
            }
        case .rejected(let error):
            rp.box.seal(.rejected(error))
        }
    }
    return rp
}

    public func pipe(to: @escaping(Result<T>) -> Void) {
        switch box.inspect() {
        case .pending:
            box.inspect {
                switch $0 {
                case .pending(let handlers):
                    handlers.append(to)
                case .resolved(let value):
                    to(value)
                }
            }
        case .resolved(let value):
            to(value)
        }
    }

```

经过一顿烧脑的思考，简单总结了一下then干的事情：

`promise.then { return newPromise( { xxxx } ) }`

1. 先创建一个新的Promise--rp，.pending状态
2. 然后对当前任务即promise执行pipe操作
	1. 如果promise的任务已经执行完（即已经是.resolved状态），则执行3
	2. 如果promise任务未执行完（处于.pending状态），把3要执行的block存到promise中，等到promise任务有结果后再执行3
	3. check下.resolved中的Result<T>数据
		- 如果是.fullfilled数据，则**异步**执行then对应的block的内容，得到一个新的任务Promise--rv；
		- 后序通过rv.pipe(to: rp.box.seal)，将rv和rp绑定起来，即rv有结果后会立即将结果传递给rp
		- 如果是.reject数据，
3. 该方法最后会将rp作为返回值返回给调用方

为了更清晰地解释多个任务的执行、串联过程，我们根据上面简单的示例，画出Promise的内部结构图来看下变化：

首先第一个执行的是如下代码

```
let task1 = Promise { resolver in
	resolver.resolve(.fulfilled(1))
}
```

内部做了两件事情：
- 先创建一个初始状态的Promise
- 然后执行该Promise对应的任务内容

由于该Promise的任务是同步执行的，所以执行完会立即有结果即--.fullfilled(1)，Promise内部结构的变化如图所示：

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/PromiseKit_demo_1.png?raw=true)

紧接着是then部分的代码：

```
task1
.then { value in
  // simulate a async task
  return Promise { seal in
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      seal.resolve(.fulfilled(1 + value))
    }
  }
}
```

1. 创建了新的Promise--rp
2. 检查task1任务是否已经完成，已经完成，所以异步执行then的block代码，紧接着将rp返回
3. then中的block代码异步执行，得到一个新的Promise-rv，但rv是异步任务，所以rv目前存储的数据还是初始状态，如图所示

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/PromiseKit_demo_2.png?raw=true)

- 代码来到了很关键的一步--`rv.pipe(to: rp.box.seal)`，rv和rp绑定，此时rv的任务还未完成，此操作后，rv内部数据是这样的：

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/PromiseKit_demo_3.png?raw=true)

- 现在，假设rv任务已经完成，标志任务完成的代码是then代码块中的--`seal.resolve(.fulfilled(1 + value))`
	- 其内部的实现也比较简单，就是将seal对应的box(同样也是rv.box)中的result更改为.resolved(.fulfilled(2))
	- 同时，取出rv处于pending状态时的Handlers中bodys数组中block来执行，其实就是将.resolved(.fulfilled(2))传递给`rp.box.seal`并执行
- `rp.box.seal`执行完成后，rp中的数据也就是正确的结果值了

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/PromiseKit_demo_4.png?raw=true)

至于其他的源代码分支，比如如何处理异常情况，因为核心思想是一致的，不再赘述

#### 总结

- Promise内部存了当前任务的状态和结果
	- 未执行状态.pending和已完成状态.resolved
	- .pending状态时会同时存放后序要执行任务(如果有的话)
	- .resolved状态时会存放任务结果值
- 当通过`then`等方法绑定新任务时
	- 会当前任务与新的任务关联起来，确保当前任务执行完后将结果传递到新任务中

## 其他答案

### Operation

- 我们也可以将任务封装到Operation中，或者直接用BlockOperation
- 结合OperationQueue，可以设置不同Operation之间的依赖关系，从而达到串行目的
- 但要注意，该方式下，当前任务执行时无法拿到上一任务的数据

## 参考

- [mxcl/PromiseKit](https://github.com/mxcl/PromiseKit)