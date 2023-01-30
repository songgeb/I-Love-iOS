# 一名iOS高级工程师可能需要具备什么能力

> 2023年01月25日

## 说在前面

当读者看了后面关于“需要具备什么能力”内容后，可能会觉得比较难

如是说，我的感觉是一样的。其实说到这个话题我有挺多感想、抱怨想说，但还是控制一下，这里只简单地驳斥一个观点：

- 不是iOS行业不行了，是你能力不够

我很理解这句话的意思，无非是勉励求职者充实自己多学习而已。

我要驳斥的是，

- 不可否认这个社会有能力的人有不少，特别是我见过一些对技术超级热爱，无需过多的压力自己就能快速学习。但这肯定是少数，大部分人是比较平庸的
- 所谓平庸，比如懒惰经常战胜自律，一件正确的事情很难坚持下去，很长时间一直原地踏步没有大的进步，尽管他可能还是想做出点事情
- 那么我们这些平庸的人的出路在哪？
- 如果了解一下其他发达国家的情况，要知道一个好的社会，是有责任让这些平庸的大多数通过自己的努力买上房、车，过上舒服的生活
- 只是简单扔出一句“能力不够”，并没太考虑大环境，对平庸的人也不公平
	- 网上看到一句话，大致意思，是一个年轻人每天按时上下班，甚至经常无偿加班，周末在家刷刷手机，聚餐
	- 这在任何其他国家都是一个励志或者至少算是积极的年轻人
	- 但在我们国家却被人们说成不努力，躺平
- 诚然，社会环境我们改变不了。那在这种情况下大部分平庸的人该如何做，才是更有价值的问题

如何做？我也一直在探索和实践，也期望以后能分享一下心得

本文算是列一下iOS中比较有价值的问题，也可以看做是面试题吧

但我本人始终反对所谓的背八股文

我会通过查阅资料了解每个题目背后知识点的原理，理解后再加以刻意练习，希望能做到1、2、3个月后，遇到该问题，还能根据底层的基础知识推导出问题的答案

## 对高级title的理解

开始之前简单的介绍一些我对“高级”的理解：

国内外对title的定义区别不太一样，国内公司通常将工程师分成：初级、中级、高级、资深、技术专家等，后面可能还会有总监之类

国外的分级少一些，junior, middle, senior，在往上可能就是architect（架构师）

本文所说的内容更多是面向于国内的高级、资深、技术专家以及国外的senior这个层面

## 正文

### 架构与设计

基础部分

- MVC、MVVM、MVP、VIPER优缺点
	- 单向数据流
- 组件化
	- 常用组件化方案
	- 组件间如何通讯
- Router（路由）有哪些方案
- 熟悉基本的设计原则
- 熟悉常见的设计模式
- 响应式编程

实践部分

1. 

### iOS基础

- Block 
	- capture variable原理
	- __block 变量 vs 普通变量
- KVO
	- KVO工作原理
- Runloop原理
- OC runtime相关
	- 消息发送、消息转发
	- Method Swizzling
- ARC内存管理原理
- 数据持久化
	- UserDefaults
	- Core Data
	- Sqlite Database
	- Keychain
	- Realm database
	- NSKeyedArchiver and NSKeyedUnarchive
	- Saving files directly on the file system
	- Plist

### UI

- 熟悉Autolayout
- 事件响应链
- UI渲染过程
	- CPU和GPU侧的职责
	- 什么是离屏渲染
	- 异步绘制
- 熟悉CoreAnimation

### 各种优化

- 卡顿优化
- 包体积优化
- 启动优化

### 源码阅读

- SDWebImage, AFNetworking, Texture

### 代码熟练程度

该部分想说的是对于一些常规的功能，面试者能否比较流畅地给出解决方案并编码实现，主要考察候选人对开发工具和iOS常见技术的熟练程度

其实国内面试考的不太多，

### 其他

- Cocoapods

## 参考

- [So you think you can call yourself a "Senior iOS Developer"?](https://blog.undabot.com/so-you-think-you-can-call-yourself-a-senior-ios-developer-767fb9d6e423)
- [一封来自大牛的招聘感悟： iOS开发人群到底怎么了?](https://cloud.tencent.com/developer/article/1382783?from=article.detail.1382782&areaSource=106000.1&traceId=nzKWh4lQsr7KEf_AysUL8)
- [iOS面试总结（2020年6月）](https://zhangferry.com/2020/07/24/interview_summary_202006/)