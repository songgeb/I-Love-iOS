# iOS中跨页面数据同步方案

跨页面数据同步指的是不同页面可能需要同步更新某些状态，比如列表页与详情页，详情页中做了某些操作UI发生了变化，希望将变化同步到列表页

将不同的场景进行一下抽象，可以将“跨页面数据同步”描述为，某一处数据发生了变化，同时希望其他一处或多处地方也感知到并且也进行数据更新

要做到数据同步，有几种不同的实现思路：

- **主动拉**，每次都获取最新数据，比如每次进入页面都尝试获取一次最新数据
- **监听数据变化**，当某处数据变化时，通过某种机制将变化主动推给所有监听者

我认为**监听数据变化**方式要比**主动拉**好，因为主动拉不够准确和灵活，

- 主动拉方式，实现起来基本是每次某个固定时机（比如页面每次进入）进行无脑拉取，由于比较难定位到真正数据变化的时机，所以会造成多余的拉取工作

## 监听数据变化

该思路中对应的实现也有多种，比如：

- delegate、block回调
- NSNotificationCenter、[SwiftNotificationCenter](https://github.com/100mango/SwiftNotificationCenter)
- 支持强类型仿照EventBus实现的--[TPEventBus](https://github.com/wanhmr/TPEventBus)
- 基于响应式编程思想的实现
	- Swift中的Combine
	- 知名框架Rx系列，如RxSwift、ReactiveCocoa
- CoreData，再配合FetchResultController，任何CoreData的数据更新会自动通知到应用它的地方


## 疑问
1. eventbus与nsnotificationcenter区别？有什么优势？


## 参考
- [iOS 中跨页面状态同步方案比较](https://juejin.cn/post/6844903951268052999)
- [西瓜视频 Android 端内数据状态同步方案 VM-Mapping](https://www.infoq.cn/article/prxrkuxcbgvqw7ghbgs5)