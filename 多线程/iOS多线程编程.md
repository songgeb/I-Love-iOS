# iOS多线程编程

- 为了更高效利用多核处理器优势，多线程编程是趋势
- iOS传统的由开发者创建管理线程的方式难写难维护
- 于是iOS、OSX系统从系统级提供了几种方式
- 开发者只需要关注要处理的任务即可，无需自行维护线程
- 而且管理线程的成本也转移给了系统，不再应用程序资源

iOS提供了两个比较高级的多线程技术：GCD和NSOperation

## GCD（Grand Central Dispatch）

系统根据当前系统运行环境，创建线程，将任务放到线程中执行

### DispatchQueue
- 可以接收`Block`或`function`并进行同步、异步的执行
- 执行顺序按照先进先出
- 内存管理也是引用计数
	- 但对于全局queue来说，开发者无需care
	- 自己创建的queue自己管理即可
- 可以suspend、resume

### Queue-Related Technologies
- Dispatch groups
- Dispatch semaphores
- Dispatch sources

### Concurrent Dispatch Queue
- 并发队列，也叫做全局队列
- 系统为每个App提供4个全局、并发队列
- 这四个队列主要是优先级不同

### Serial Dispatch Queue
- 串行队列，也叫做私有队列
- 主线程关联的main queue也是一个串行队列
- 可以通过context给queue关联数据，task可以使用这些数据
- 可以在queue销毁时执行方法以清理数据

### Dispatch semaphores
相比于系统级的信号量，该信号量性能更好，因为当资源无需等待时，该信号量并不会涉及到系统内核级的调用，只有资源被占用需要等待时才会；而系统级信号量不论何时调用都要与系统内核交互

- 可以对有限的资源进行访问控制
- 比如file descriptor，对于文件描述符，系统是有限制的，不能无限的打开文件资源
- 那我们可以设置一个semaphore，规定一个最大打开数，这样可以保证当前程序同一时间打开文件总数不会太大

### Dispatch Group
- 可以将若干个task提交到一个group中执行，然后block住当前线程，直到所有task都完成
- 也可以，给group设置callback，不阻塞当前线程，当所有task结束后，执行callback

	-
- dispatch\_group_async
- dispatch\_group_enter、dispatch\_group\_leave
- dispatch\_group_wait

### Dispatch Barrier
- dispatch\_barrier_async
- dispatch\_barrier_sync

- 使用barrier提交的任务，会等待前面提交的任务完成后再执行，然后再执行在barrier之后提交的任务
- 一般常用于`私有并发队列`中，可以对多个任务进行分组排序执行
- 对于全局队列，是不起作用的，因为其他地方也可能在使用全局队列

### Dispatch_apply
> This function submits a block to a dispatch queue for multiple invocations and waits for all iterations of the task block to complete before returning. If the target queue is a concurrent queue returned by dispatch_get_global_queue, the block can be invoked concurrently, and it must therefore be reentrant-safe. Using this function with a concurrent queue can be useful as an efficient parallel for loop.

### 线程安全
- task中尽量少用锁，虽然锁本身安全，但有可能引起其他task阻塞

## Dispatch Sources
- Dispatch Source是调度系统底层事件处理逻辑的基础数据结构
- 通常使用惯例是，监听某个系统事件，当事件到来时，Dispatch Source将指定的task`异步`提交到指定的queue中执行
- 当新事件到来，但老事件的eventhandler还没有执行时，内部会将两个事件合并。最终新的eventhandler会执行，收到的也是新的事件内容
- 如果新事件到来时，旧eventhandler正在执行，那就等结束后，新eventhandler再执行
- 因为source可能会一直持续，所以会持有queue和task，开发者要主动通过cancel方法来取消掉source
- iOS 6之后，dispatchqueue、dispatchsource统一由ARC来管理，无需主动retain、release

### Creating Dispatch Sources
- 刚创建完的source需要进行一些配置，所以状态是`suspended`，后面需要执行`dispatch_resume`才可以开始执行


## NSOperation and NSOperationQueue

- 核心类是`NSOperation`，将任务封装成`NSOperation`实例
- NSOperationQueue是一个可以支持NSOperation运行的队列，可以设置并发NSOperation任务数
- NSOperationQueue用来管理NSOperation的执行，比如决定使用哪个线程执行任务等。内部并不会无限制的创建线程，而是会考虑当前设备、系统的状态
- NSOperation并不依赖NSOperationQueue才能执行
- 与`Dispatch Queue`的相同点是，也是按照队列的先进先出原则
- 不同点是，`NSOperationQueue`支持任务间依赖关系
- queue本身不会主动的remove operation，而是让operation自己remove掉
- 比如，当这个operation发现被cancel了，那么执行过程中有检查cacel状态的代码，检查不通过直接return了，这样才是真正从queue删掉了。所以才让自定义operation时尽量多的去check各种状态
- 也就是说cancel并不是直接让operation停止的，间接的
- 这也解释了，为啥当suspend queue时，即使其中的operation已经被cancel了，也不会被remove掉。因为被suspend了，没有operation继续执行了，所以也就不会走到`间接return`代码了

## NSOperation

- 将任务执行进行封装，让用户只去关心具体要做的事情，无需过多考虑其他事情
- `NSOperation`只是一个抽象基类，提供一些公开的api，具体的工作需要根据自定义需求继承基类实现
- operation只能执行一次，不能重复执行(is a single-shot object)。即一个operation只能执行一次任务，不能重复使用同一个实例进行多次任务的执行（我想这种设计是想简化内部逻辑）
- 一般放到operationQueue中执行，也可以自己控制让他执行，但要考虑更多事情，比如要保证其是否ready，否则会报异常
- 既可以定义成同步执行的operation，也可以是异步的
	- 异步的operation，需要在start方法中实现将任务放到子线程中的逻辑
	- 同步operation平时用的更多，因为同步执行的operation也可以并行执行，即放到operationQueue就行了
- 很多属性可以通过kvc设置，通过kvo观察，但由于可以执行在任意线程中，所以kvo的通知也可能在任何线程，要注意UI的更新问题
- 默认的方法是线程安全的。但如果要重写方法、或自定义方法，要注意线程同步问题
- 可以设置其在`NSOperationQueue`中的优先级，来控制执行顺序，但`dependency`会先考虑
- 不论异步还是同步operation，都可以设置completionBlock，该block在`isFinished`变为true的时候执行
- 提供了cancel方法，但需要子类通过频繁的check`isCancelled`来真正的取消工作

### NSBlockOperation

- 可以将一个或多个block提交到并发queue中执行
- 这也就意味着`NSBlockOperation`只支持并行的block，不支持串行

### 配置NSOperation


#### 非并发Operation

仅需重写`main`方法

#### 并发Operation

- 需要通过KVO维护很多状态
- 不常用

#### 状态
- 可以通过KVO监听Operation的运行状态
- 可以通过`Cancel`取消Operation运行

#### Operation间依赖关系
- 通过operation的`addDependency`和`remove`建立依赖关系
- 关系保存在operation中，所以即使在不同的OperationQueue中的Operation，也可以有依赖关系
- 对于在OperationQueue中的Operation，当依赖关系满足后，会自动执行。若是需要手动启动的Operation，那需要自行监听

#### Operation Priority
- 通过`queuePriority`这个property可以设置operation的执行优先级
- 前提是，在同一个OperationQueue当中的Operation之间，优先级才能起作用
- 通过设置优先级，可以决定Operation的执行顺序
- 但一定要在满足依赖关系的前提下，优先级才会起作用

#### Completion Block
- 可以给Operation设置一个block，任务结束时执行


## QoS
> qualityOfService

可以理解为**任务优先级**，系统在为不同类型的任务分配CPU等资源时，要根据任务的优先级决定执行顺序。作为开发者，可以通过设置`QoS`可以帮助系统更好的执行任务

一共有如下几种优先级等级

|QoS|||
|:-:|:-:|:-:|
|User-interactive|根UI相关，需要立即执行||
|User-initiated|也是需要立即得到结果|几乎立即执行|
|Utility|需要些执行时间||
|Background|可能需要后台执行||

还有两种特别的`QoS`，开发者无法设置，系统自动设置的--`Default`和`Unspecified`

- `Default`的优先级介于`Utility`和`User-initiated`之间

对于`NSOperation`、`NSOperationQueue`、`dispatch queue`、`dispatch block`、`NSThread`、`pthread`，都支持通过`QoS`设置任务的优先级

### 优先级翻转(Priority Inversions)

正常情况下高优先级的任务总是优先于低优先级任务执行。
如果一个高优先级的任务变得依赖于低优先级的任务（比如低优先级任务持有了高优先级需要的临界资源），导致低优先级任务先执行，这就叫优先级翻转

iOS系统在一些优先级翻转的情况下会尝试提高低优先级任务优先级等操作来解决翻转问题

当然，开发者最好能在一开始就避免优先级翻转问题

[Prioritize Work with Quality of Service Classes](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html#//apple_ref/doc/uid/TP40015243-CH39)

## 思考
1. 可以用`NSBlockOperation`实现多个block执行的逻辑

## 参考
- [Concurrency Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ConcurrencyProgrammingGuide/Introduction/Introduction.html)
- [iOS探索 多线程之GCD应用](https://juejin.im/post/5e8b2c9451882573ac3ce409)
- [Operation and OperationQueue Tutorial in Swift](https://www.raywenderlich.com/5293-operation-and-operationqueue-tutorial-in-swift)
- [NSOperation](https://nshipster.com/nsoperation/)