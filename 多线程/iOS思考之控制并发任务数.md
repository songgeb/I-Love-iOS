# iOS多线程题目之控制并发任务数

> 深入理解代替单纯记忆

## 题目描述

有这样一个有意思的题目，可能很多面试题中也考察到过：


- 有一个比较耗时的处理数据的方法，比如叫做`func processData(data: Int)`
	- 数据可以是任意类型，此处使用Int来简化问题
- 现在要求实现另一个批量处理数据的方法`func processDatas(data: [Int], completion: ([Int]) -> Void)`
	- 该方法异步处理数据，所有任务完成后通过completion进行回调
	- 要求同时处理的数据的任务数最多4个

本文尝试探索有哪些实现方式

## DispatchGroup+DispatchSemaphore

核心思想：

- 通过DispatchGroup来控制多任务完成后才通过completion回调
- 通过DispatchSemaphore来控制最大并发任务

代码思路：

- 初始化
	- 创建并发队列queue，可以是自己创建的也可以是系统global的
	- 创建DispatchGroup对象group
	- 创建DispatchSemaphore对象semaphore，默认值是4
- 异步方式向queue提交数据处理任务，数据处理任务如下
	- 遍历每个输入的任务数据，先执行group.enter，表示任务即将执行
	- 再信号量值是否满足要求(semaphore.wait())即先减一后判断是否大于等于0，大于等于0就继续执行，否则等待
	- 为了让4个任务同时执行，此处仍然要通过异步方式向queue中提交具体的任务内容
	- 任务结束后，执行semaphore.signal()和group.leave()
- group.notify，任务结束后通过completion回调

代码实现如下

```
    let semaphore = DispatchSemaphore(value: 4)
    let group = DispatchGroup()
    let queue = DispatchQueue(label: "queue", attributes: .concurrent)

    var results: [Int] = []
    queue.async {
      for data in datas {
        group.enter()
        semaphore.wait()
        queue.async {
          let result = self.processData(data)
          results.append(result)
          semaphore.signal()
          group.leave()
        }
      }
```

## OperationQueue

OperationQueue支持配置任务并发数，所以核心要解决的事情是所有任务完成后如何回调

请看代码

```
    var results: [Int] = []
    let completionOperation = BlockOperation {
      completion(results)
    }
    let lock = NSLock()
    let operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 4
    for data in datas {
      let operation = BlockOperation {
        print("当前执行中任务为--\(data)")
        lock.lock()
        results.append(self.processData(data))
        lock.unlock()
      }
      completionOperation.addDependency(operation)
      operationQueue.addOperation(operation)
    }
    operationQueue.addOperation(completionOperation)
```

## 疑问
1. 上面两个代码中，OperationQueue方式中使用NSLock来保护results，但GCD的实现却没有，难道不会有线程安全问题吗

## 总结
- 单纯就控制并发任务数来说的话可以考虑信号量和OperationQueue.maxConcurrentOperationCount
- OperationQueue的思路更简单


## 参考
- [Wait for all Operations in queue to finish before performing task](https://stackoverflow.com/questions/42495794/wait-for-all-operations-in-queue-to-finish-before-performing-task)
- [iOS实录16：GCD小结之控制最大并发数](https://www.jianshu.com/p/5d51a367ed62)