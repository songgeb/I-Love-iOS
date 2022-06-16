# MVVM学习笔记


![](https://user-images.githubusercontent.com/5978164/93760502-b7338400-fc3e-11ea-8080-e6504c0c5d25.jpg)

- ViewModel有两项主要的职责
	- 存储用于视图展示的数据，这些数据通常是只和展示相关，而不一定就是底层的数据model，更常见的形式是，vm持有底层model，然后有一些只和展示相关的属性，用于提供给视图使用
	- 除了存储视图相关的数据，vm也负责与业务相关的数据网络请求、数据转换等工作，这样有助于减轻vc的负担
- ViewModel的目的是尽量让它与其他部分（ViewController、Model）隔离开
- 就像纯函数一样，不论何时，不论外部环境如何变化，同样的输入只对应同样的输出，不会改变外部，也不会被外部改变，这就是没有副作用，页就是纯函数含义
	- 比如说一个函数中的工作是发送网络请求，其实这就有副作用，因为对整个app的网络环境产生了变化
- ViewModel内部核心的工作应该是进行各种计算、数据读写等，最终将得出的结果存储到ViewModel的property中，等待外部使用
- ViewModel是只关心业务不关心视图，因为不用关联view，所以也就容易测试了
- vc不关心业务，只需处理好viewmodel和view之间的逻辑即可
- ViewModel的存在就是为了极大的消除副作用
- 除了图中所说，MVVM中还有一个隐藏的`Binder`约定
- 这个`Binder`主要是用于`view`和`viewModel`之间数据同步的
- `view`和`viewModel`之间一般是双向绑定，`view`的事件会触发`viewModel`数据更新；`viewModel`的数据变化会导致`view`状态变化

## 参考
- [ReactiveCocoa and MVVM, an Introduction](http://thumbworks.io/blog/2014/12/06/reactivecocoa-mvvm-introduction/)
- [iOS 关于MVVM Without ReactiveCocoa设计模式的那些事](https://zhuanlan.zhihu.com/p/38420233)