# Clean Architecture学习笔记

![](https://cdn.jsdelivr.net/gh/songgeb/picx-images-hosting@master/CleanArchitecture.70aa44fhju.webp)

Clean Architecture是Robert C. Marti在2012年提出的概念，他汇总了已有的架构系统，将核心的思想汇聚到该架构系统中--一种按层划分的系统架构模型

上图中每一圈对应一层，从里到外分别是：Entities、Use Cases、Presenter Layer、UI/Web Layer

### 依赖原则

该架构系统中最重要的一点便是其规定了每一层之间严格的依赖原则，即：

**只能是外层依赖内层，一定不能出现内层依赖外层**

- 内层的任何代码（方法、类、数据结构）都不能对外层有任何依赖

#### 为什么必须只能外层依赖内层

> 以下内容来自ChatGPT

在Clean Architecture中，要求只能外层依赖内层，而不能内层依赖外层，主要是为了实现以下几个关键目标：

1. 独立性：
内层（核心业务逻辑）不依赖于外层（UI、数据库、网络等），使得核心业务逻辑独立于具体的实现细节。这种独立性使得业务逻辑可以在不改变的情况下被复用或移植到不同的应用程序中。

2. 可测试性：
由于内层不依赖于外层，核心业务逻辑可以在没有UI、数据库或网络等外部依赖的情况下进行单元测试。这大大简化了测试过程，提高了测试的覆盖率和质量。

3. 可维护性：
当外层的实现细节（如UI框架、数据库技术等）发生变化时，内层的业务逻辑不需要做出相应的修改。这种分离使得代码更容易维护和扩展。

4. 灵活性：
通过依赖倒置原则（Dependency Inversion Principle），外层通过接口或抽象类与内层进行交互，具体的实现细节可以在外层进行定义和修改。这种设计使得系统更加灵活，能够适应不断变化的需求。

5. 模块化：
内层和外层的分离使得系统更加模块化，每个模块都有明确的职责和边界。这种模块化设计有助于团队协作和代码管理。
总结来说，Clean Architecture通过限制依赖方向，确保了系统的独立性、可测试性、可维护性、灵活性和模块化。这些特性使得系统更加健壮，能够更好地应对复杂的业务需求和技术变化。



### Entities

- Entities表示业务数据模型

### Use Cases

中文翻译为“用例”

- 这是应用程序特定的业务规则/流程
- 它包含了应用程序所有的功能
- 它来协调数据流，如从Entities到外部，或者反过来（指导Entities做怎样的修改）

### Interface Adapters

- 负责将对数据进行转换
- 将外部的数据转换为内部Use Cases和Entities所需的数据格式
- 将内部的数据格式转换为外部UI、外部数据库、外部服务所需的格式

### Crossing boundaries

- 有时内圈是需要使用外圈的，但直接使用就违反了单向依赖原则

### 总结

The outermost circle is low level concrete detail. As you move inwards the software grows more abstract, and encapsulates higher level policies. The inner most circle is the most general.


## 疑问
1. 为什么只能外圈依赖内圈，不能反过来


## 参考
- [The Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Clean Architecture and MVVM on iOS](https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3)

