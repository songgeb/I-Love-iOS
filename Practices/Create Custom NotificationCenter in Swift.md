# Create Custom NotificationCenter in Swift

> 深入理解代替单纯记忆

> 本文使用的Swift版本 > 4.0

## 功能
- 基础功能
	- 单例
	- addObserver(支持接收selector作为参数)
	- addObserver(支持接收closure作为回调参数)
	- postNotification
	- removeObserver
- 多线程，必须保证多线程安全
- 进阶功能，使用addObserver(selector)注册observer后，如果忘记removeObserver，NotificationCenter内部可以自动clean up（系统NotificationCenter的API就是这样做的）

## 设计

### Public API

先列出来上面提到的API在系统NotificationCenter中的定义，我们后序会仿照此来写

```
func addObserver(forName name: NSNotification.Name?, 
          object obj: Any?, 
           queue: OperationQueue?, 
           using block: @escaping (Notification) -> Void) -> NSObjectProtocol
           
func addObserver(_ observer: Any, 
        selector aSelector: Selector, 
            name aName: NSNotification.Name?, 
          object anObject: Any?)
          
func removeObserver(_ observer: Any, 
               name aName: NSNotification.Name?, 
             object anObject: Any?)
             
 func post(name aName: NSNotification.Name, 
   object anObject: Any?, 
 userInfo aUserInfo: [AnyHashable : Any]? = nil)
```

- API的name参数是Optional的，说明如果传入nil，则所有的通知都会收到回调
- 其实没搞明白第一个API的返回值为啥是NSObjectProtocol的。我们基于简洁和纯Swift化实现思路，考虑返回非Objective C对象。具体返回什么在后面设计数据结构时说
- API中的observer和object的参数是Any(或Any?)的，如果想做到这一点其实在后续的实现中会发现有难度
	- 比如如何做到对一个Any类型的observer发送selector消息
	- 再比如在发送通知时，如果过滤掉那些不符合post方法object参数要求的通知呢？说白了就是Swift中不容易比较两个Any类型的内容
	- 所以，我选择进行简化，改用AnyObject类型
- 至于参数中的Notification的Name，我们可以简化下，使用String即可

分析后，我们即将要实现的API如下所示：

```
func addObserver(forName name: String?, 
          object obj: AnyObject?, 
           queue: OperationQueue?, 
           using block: @escaping (Notification) -> Void) -> 待定
           
func addObserver(_ observer: AnyObject, 
        selector aSelector: Selector, 
            name aName: String?, 
          object anObject: AnyObject?)
          
func removeObserver(_ observer: AnyObject, 
               name aName: String?, 
             object anObject: AnyObject?)
             
 func post(name aName: String, 
   object anObject: AnyObject?, 
 userInfo aUserInfo: [AnyHashable : Any]? = nil)
```

### 数据结构

- 至少需要设计Notification, Observer和存储Observer的结构
- Notification仅用作通知内容的载体
	- 包含name、userInfo即可
	- 所以首选建议使用结构体
	- 但后序写代码过程中会发现不行，因为最终该类型数据要传回给回调方法(selector)，因为selector是Objective C下的东西，selector方法必须标记为@Objc，所以Notification也只能用类了，且只能用OC类
- Observer要存储在NotificationCenter内部，而且逻辑要求也复杂些
	- 需要保存selector、closure、operationQueue
	- 比如要考虑高阶功能，即内存释放特性
	- 所以考虑使用类结构
- 关键的Observer存储结构来了
	- 首先很容易想到使用[String: [Observer]]来存储
	- 但这样的存储使得有个功能的实现增加了难度--addObserver方法中的object参数，在postNotification时，如何实现筛选出符合object要求
	- 当然，我们可以将addObserver时的object存储在Observer中，后序再拿出来进行筛选
	- 但还有一个更简单的方法--调整observer的存储结构，让object作为key--**[String: [ObjectIdentifier(object): [Observer]]]**
	- 现在observer列表就是按照name和object两个维度来存储了，取对应Observer时方便、快捷
	- 还有个问题没解决，name为nil时怎么办？addObserver中的object为nil时怎么办？
	- name为nil时，则意味着对应的Observer要接收所有通知。显然，这是一个合理的逻辑，所以必须要处理name为nil的情况
	- object为nil时，意味着，只要订阅了对应name通知的所有Observer都要收到通知。所以也是合理的逻辑
	- 所以我们调整一下数据结构，让其可以存储nil
	- **[String?: [ObjectIdentifier(object)?: [Observer]]]**

- 关于通知的回调方式的讨论
	- 目前有两种通知的回调方式：selector和closure。selector的方式下，在addObserver时需要传入Observer参数，closure对应的addObserver则不需要
	- 我觉得实现时，可以将两种情况合并为一种，即都需要有一个Observer，只是closure的方式下，需要NotificationCenter内部创建一个

### 多线程
- 使用串行队列来解决多线程安全问题

## 实现

源码放在这里了--[MyNotificationCenter](https://github.com/songgeb/MyNotificationCenter)

## 参考
- [iOS源码解析: NotificationCenter是如何实现的?](https://juejin.cn/post/6844904129580498957#heading-15)