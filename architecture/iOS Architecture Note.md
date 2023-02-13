# iOS Architecture Note

大佬Casa Taloyum在[iOS应用架构谈 开篇](https://casatwy.com/iosying-yong-jia-gou-tan-kai-pian.html)对一个App所做的事情进行了概括，感觉特别好，下面进行引用

一个移动应用，核心要实现的功能无外乎如下所示：

![](https://github.com/songgeb/I-Love-iOS/blob/master/architecture/Images/App_responsibility.png?raw=true)

为了实现这些功能，技术层面要解决如下的问题：

- 调用网络API
- 页面展示
- 数据的本地持久化
- 动态部署方案

稍微详细介绍一下每部分的内容：

- 如何让业务开发工程师方便安全地调用网络API？然后尽可能保证用户在各种网络环境下都能有良好的体验？
- 页面如何组织，才能尽可能降低业务方代码的耦合度？尽可能降低业务方开发界面的复杂度，提高他们的效率？
- 当数据有在本地存取的需求的时候，如何能够保证数据在本地的合理安排？如何尽可能地减小性能消耗？
- iOS应用有审核周期，如何能够通过不发版本的方式展示新的内容给用户？如何修复紧急bug？

以上是App对于用户方面所做的事情，App对于开发团队也有有一些事情要做：

- 收集用户数据，给产品和运营提供参考
- 合理地组织各业务方开发的业务模块，以及相关基础模块
- 每日app的自动打包，提供给QA工程师的测试工具

## View层的组织和调用方案

### 几个规范

#### ViewController不要有private method
	- private method是指除了View创建、delegate等逻辑之外的方法，比如图片裁剪，日期转换等小功能
	- private method应放到相应的模块，比如某个具体业务中，如果是通用的可以放入分类或工具类中。ViewController中逻辑已经很多了，不适合再加入这种小逻辑

#### 不建议使用BaseViewController

- 这样会增加业务方的使用成本，且并不属于使用继承的明显场景
- 可以改用AOP的方式，比如Method Swizzling

### MVC, MVVM等架构

谈到架构，有三个角色：数据管理者，数据加工者和数据展示者，所有的架构都是处理这三个角色的分工，制定他们之间交互的规范

iOS的架构有MVC, MVCS, MVVM, VIPER, MVP

#### MVCS

胖Model与瘦Model

## Q&A

1. 当无法进行大粒度抽象时，比如业务很复杂，参数很多时，要考虑策略模式
	- 看一下策略模式
## 参考
- [iOS应用架构谈 开篇](https://casatwy.com/iosying-yong-jia-gou-tan-kai-pian.html)
- [iOS应用架构谈 view层的组织和调用方案](https://casatwy.com/iosying-yong-jia-gou-tan-viewceng-de-zu-zhi-he-diao-yong-fang-an.html)