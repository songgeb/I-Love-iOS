# AFNetworking源码笔记

> 本文参照AFNetworking的4.0.1

- 整体架构是怎样的
- 主要解决什么问题，应用场景是什么
- 重要的模块是怎样实现的
- 有哪些优雅的技巧、设计

## Architecture

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/AFNetworking_architecture.jpg?raw=true)

- Objective C实现的网络请求库
- AFNetworking是对NSURLSession的高度封装，为使用者提供了简易的API

## QA
1. AFHTTPSessionManager为何要遵循NSSecureCoding协议
2. AFURLSessionManager中NSLock类型的lock干啥的？

## References
- [AFNetworking 概述（一）](https://github.com/draveness/analyze/blob/master/contents/AFNetworking/AFNetworking%20%E6%A6%82%E8%BF%B0%EF%BC%88%E4%B8%80%EF%BC%89.md)