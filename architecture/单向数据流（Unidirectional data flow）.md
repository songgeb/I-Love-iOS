# 单向数据流（Unidirectional data flow）

从几个问题开始学习单向数据流

- 单向数据流是什么，历史和背景有哪些
- 适用场景
- 工业中的应用有什么


多个UI操作维护着一个变量，多个状态变量去更新同一个UI元素

## 单向数据流在iOS中的应用

从OneV的例子来看

- title
	- 决定title的数据只有todo数组个数
	- 需要更新title的地方有两处：增加todo，和删除todo
- tableview
	- 决定tableview数据的是todo数组
	- 需要更新tableview的时机有首次显示列表
	- 增加todo，删除todo时
- +号
	- 决定+的数据是第一个cell中textfield的内容
	- textfield内容变化时要更新
	- 增加todo时

如果能用单一的状态控制UI的变化


- 其单向的特点，适用于于复杂的页面，比如视频播放页面，可以降低开发复杂度
- 提高页面及其中逻辑的可测试性

## 参考
- [单向数据流动的函数式 View Controller](https://onevcat.com/2017/07/state-based-viewcontroller/)
- [Unidirectional Data Flow](https://www.geeksforgeeks.org/unidirectional-data-flow/)
- [架构系列—基于状态管理的单向数据流架构](https://juejin.cn/post/6844904179467550734)
- [单向数据流和双向数据流及双向数据绑定](https://blog.csdn.net/qq_43101321/article/details/102585867)
- [Unidirectional Data Flow Architecture (Redux) in Swift](https://medium.com/seyhunakyurek/unidirectional-data-flow-architecture-redux-in-swift-6fa2ed5c3c76)