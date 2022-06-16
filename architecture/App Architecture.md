# App Architecture

Applications Are a Feedback Loop

1. Construction—Who constructs the model and the views and connects the two?
2. Updating the model—How are view actions handled?
3. Changing the view—How is model data applied to the view?
4. View state—How are navigation and other non-model state handled?
5. Testing—What testing strategies are used to achieve reasonable testcase code coverage?

The answers to these five questions form the basis of the application design patterns we’ll look at in this book.

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/application_feedback_loop.png?raw=true)

## 书中未提及的架构

### MVP

### VIPER

## MVC

- Model和View由ViewController关联起来
- View要做到独立（自给自足）、可复用
- 为了做到View独立可复用和保证UI来自单一数据源，需要通过观察者模式订阅Model的变化

### View State
那些与数据源Model无关的UI上的变化，统称为View State，比如

- 导航栏的变化，新的ViewController进入
- View内部状态的变化，如UISwitch点击后，自动发生UI变化

这些View State在处理时，一般会在本地简单处理掉，比如一个按钮点击后，文案要发生变化，那就直接写个方法修改就好

### Apple将MVC看成三种设计模式的组合

- ViewController将视图层级组合在一起管理，这是组合模式
- ViewController作为Model和View的沟通桥梁，处理它们之间各种交互，这是策略模式
- 当Model数据变化时需要更新视图，需要通过观察者模式实现

### 优点

- 与iOS的一些Framework比较搭配，比如Storyboard
- 简单、学习使用成本低

### 缺点
- ViewController臃肿
- 业务逻辑不容易测试
	- 只能使用集成测试（integration test）

### 如何改进缺点
- ViewController臃肿问题：将任务分解到不同组件中
	- 比如数据处理相关的可以放到Model层
	- 复杂视图部分，是否可以抽离成子ViewController
	- 当ViewControler中充斥大量回调处理逻辑且这些逻辑只是将时，考虑将这些与ViewController的视图关联不大的逻辑移到

### 疑问
1. 实际开发中，View经常会持有Model，这样做可能会降低可复用性，这种做法是否不合理？
2. MVC中还需要通过观察者模式来监听Model的变化吗？实践中感觉没用过
3. Interface test、data-driven regression tests、Integration Test

## MVVM+C

As with all good patterns, this isn’t just about moving code into a new location. The purpose of the new view-model layer is twofold:

1. To encourage structuring the relationship between the model and the view as a pipeline of transformations.
2. To provide an interface that is independent of the application framework but substantially represents the views’ presentation state.

### 疑问
1. 订阅model操作也要在ViewModel中吗？

## 疑问
1. 如何理解书中提到的View State
2. MVVM+C中的Coordinator的优势是什么？
3. MVVM中ViewModel需不需要持有Model？
4. 文中多次提到State Restoration，实际开发中几乎没用过，可能需要学一下

## 参考
-[App Architecture](https://www.objc.io/books/app-architecture/)