# AFNetworking源码笔记

> 本文参照AFNetworking的4.0.1

- 整体架构是怎样的
- 主要解决什么问题，应用场景是什么
- 重要的模块是怎样实现的
- 有哪些优雅的技巧、设计

## Architecture

核心的类如下所示：（不是所有类）

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/AFNetworking_architecture.jpg?raw=true)

- Objective C实现的网络请求库
- 提供基于HTTP协议和其他数据协议（如ftp等）的网络数据请求支持
- AFNetworking是对NSURLSession的高度封装，所以NSURLSession支持的所有能力也都支持，比如multipart数据上传、下载进度跟踪
- AFNetworking将复杂的网络请求工作封装为一个个独立的API，只需要传递数据的URL和数据返回后进行处理的block即可
- 提供了一个外部也可使用的网络监控的工具--AFNetworkReachabilityManager
- 提供了几个UI层的扩展功能，监听网络状态
	- 更新status bar中ActivityIndicator
	- 更新UIRefreshControl
- 完善的单元测试

## AFURLSessionManager

- 框架最核心的类就是AFURLSssionManager，负责session、数据请求任务的创建、管理工作
- AFURLSessionManager中持有一个session；同时为每个task创建了一个AFURLSessionManagerTaskDelegate对象，用于管理任务的回调事件

### AFURLSessionManagerTaskDelegate

- 负责每一个NSURLSessionTask进度管理、任务结束回调工作
- 其中，使用了两个NSProgress的实例来存储上传、下载进度，通过KVO NSProgress的属性监听进度的变更
- 任务结束后都会回调到主线程中

## AFHTTPResponseSerializer
未完待续


## Good Practice
未完待续

## QA
1. AFHTTPSessionManager为何要遵循NSSecureCoding协议
	- 因为NSSecureCoding更安全，参考[NSSecure​Coding](https://nshipster.com/nssecurecoding/)
2. AFURLSessionManager中NSLock类型的lock干啥的？
	- AFURLSessionManager内部要用字典存储多个任务对应的taskdelegate，因为外部调用方可能在任何线程下使用该框架，所以lock是为了防止多线程写数据错误问题
3. 代码中发那么多通知干啥？
	- 在请求任务任何中断、完成、失败的情况下都会发送通知
	- 此举主要为了方便AFNetworking的调用方根据网络任务转台做一些工作，比如框架中UI层的扩展功能都是通过通知来完成

## References
- [AFNetworking 概述（一）](https://github.com/draveness/analyze/blob/master/contents/AFNetworking/AFNetworking%20%E6%A6%82%E8%BF%B0%EF%BC%88%E4%B8%80%EF%BC%89.md)