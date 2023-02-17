# iOS网络编程笔记

## URLSession

- 支持iOS App后台suspend时下载数据
- 通过创建`URLSessionTask`来执行任务
- 一个session可以创建多个task
- 可以给session设置delegate，用于监听网络请求状态
- 也可以为task提供completion block，这种情况下，delegate方法就不会执行了
- task刚创建完处于suspend状态，可以cancel、restart、resume task
- 尽可能复用session，避免重建没必要的session
- 注意，session的delegate方法，是执行在一个串行的operationQueue中，所以task的结果是串行回调

> session对delegate是强引用，如果session不进行invalidate，会引起泄漏

### session类型
- shared，单例，不能设置delegate和configuration对象
- 也可以根据需要自己创建`URLSession`，根据configuration不同，有三种类型的session
    - default session，使用了`URLSessionConfiguration.default`，和shared类似，但可以设置configuration
    - Ephemeral session，使用了`URLSessionConfiguration.ephemeral`，不能往磁盘中写入cache、cookie和credentials证书信息
    - Background session，使用`URLSessionConfiguration.background`，可以在suspend情况下上传、下载数据

### 协议的支持
- http/https，http/1.1、http/2
- ftp、file、data
- 也可以自己添加协议

### NSCopying的支持
- copy `URLSession`和`URLSessionTask`时，返回自己
- copy `URLSessionConfiguration`时，创建一个新的对象返回

### Shared Session
- 不能设置deegate和configuration
- 不能进行后台下载
- 不适用需要重新实现cache、cookie的情况

##  URLSessionConfiguration

- 可以控制timeout、cache、cookie、对host的最大可建立的连接数等
- 还可以控制移动数据下是否建立连接等
- 一个URLSession创建的所有task共享一个`URLSessionConfiguration`
- URLSession在使用configuration时，会先将其copy一份。所以初始化URLSession结束后，再修改configuration就没用了
- `NSURLRequest`的配置可以重写configuration中的配置，但如果configuration中的要求更严苛，那也会尊重。比如如果configuration中要求不能使用移动数据访问网络，那NSURLRequest就不能访问

## URLSessionTask

1. 通过`URLSession`创建task
1. task可以下载数据、下载文件、上传数据
1. 几个个类型的task
    - `URLSessionDataTask`，与服务器交互数据的数据结构是NSData，适用于频繁、短暂的请求
    - `URLSessionUploadTask`，支持后台上传
    - `URLSessionDownloadTask`，接收文件格式数据，支持后台上传、下载数据
    - `URLSessionStreamTask`，用于tcp通信

### State

- `URLSessionDataTask`等Task类都是继承自`URLSessionTask`
- 有几个API
	- resume
	- suspend，挂起后相当于暂停，还可以resume
	- cancel

## Handling an Authentication Challenge

## Socket

- socket翻译为套接字，是支持TCP/IP协议的网络通信的基本操作单元。
- 它是网络通信过程中端点的抽象表示，包含进行网络通信必须的五种信息：连接使用的协议，本地主机的IP地址，本地进程的协议端口，远地主机的IP地址，远地进程的协议端口。
- socket是在应用层和传输层之间的一个抽象层，它把TCP/IP层复杂的操作抽象为几个简单的接口供应用层调用已实现进程在网络中通信。
- 它不属于OSI七层协议，它只是对于TCP，UDP协议的一套封装，让我们开发人员更加容易编写基于TCP、UDP的应用。

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/Socket_architecture.png?raw=true)

### 带着问题学习
1. iOS中长链接的实现方式有哪些，特点和使用场景是什么
2. WebSocket与Socket区别是什么

### 初识Socket

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/Socket_communication_process.png?raw=true)

- iOS框架层面没有对socket的支持；但C的代码库中有socket的相关API，可以用之
- 根据 [iOS 用原生代码写一个简单的socket连接](https://juejin.cn/post/6844903940459331598)的demo可以完整的体验一把简单地socket长链接

需要注意的是

- 必须需要一端首先出于accept状态后，另一端才能建立连接和发送数据

### 长链接方案


### 参考
- [iOS 用原生代码写一个简单的socket连接](https://juejin.cn/post/6844903940459331598)
- [聊聊iOS中网络编程长连接的那些事](https://zhuanlan.zhihu.com/p/34944894)

## 遗留问题
1. 如何处理重定向问题


## 参考
- [URL Loading System](https://developer.apple.com/documentation/foundation/url_loading_system)
- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [URLSessionConfiguration](https://developer.apple.com/documentation/foundation/urlsessionconfiguration)
- [Fetching Website Data into Memory](https://developer.apple.com/documentation/foundation/url_loading_system/fetching_website_data_into_memory)
