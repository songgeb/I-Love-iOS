# 读《iOS应用架构谈 本地持久化方案及动态部署》笔记

原文链接--[iOS应用架构谈 本地持久化方案及动态部署](https://casatwy.com/iosying-yong-jia-gou-tan-ben-di-chi-jiu-hua-fang-an-ji-dong-tai-bu-shu.html)

设计持久层时，需要注意做到几个隔离：

- 持久层与业务层的隔离
- 数据库读写隔离
- 多线程控制导致的隔离
- 数据表达和数据操作的隔离

## 胖Model vs 瘦Model

"胖模型"和"瘦模型"是描述数据模型在业务逻辑处理中扮演角色的两种方式。

"胖模型"（Fat Model）是指模型中包含大量的业务逻辑。优点是：

1. 代码重用：由于业务逻辑在模型中，所以可以在多个控制器或视图中重用。
2. 保持控制器和视图的简洁：将业务逻辑放在模型中可以使控制器和视图保持简洁，更易于维护。

缺点是：

1. 模型复杂度高：模型中包含大量的业务逻辑可能会使模型变得复杂，难以理解和维护。
2. 难以测试：由于业务逻辑和数据紧密耦合，可能会使单元测试变得困难。

"瘦模型"（Thin Model）是指模型主要负责数据的存储和简单的数据操作，而将大部分业务逻辑放在服务或控制器中。优点是：

1. 模型简单：模型主要负责数据的存储和简单的数据操作，所以模型的复杂度较低，易于理解和维护。
2. 易于测试：由于业务逻辑和数据分离，可以更容易地进行单元测试。

缺点是：

1. 代码重用性低：由于业务逻辑在服务或控制器中，可能会导致代码重复。
2. 控制器和视图可能变得复杂：如果将大量的业务逻辑放在控制器或视图中，可能会使它们变得复杂，难以维护。

在实际开发中，应根据具体的项目需求和团队习惯来选择使用胖模型还是瘦模型。

## 持久层与业务层隔离

> 作者倾向于去Model化，即使用通用的类型（比如字典）表示业务模型

## 数据库读写隔离

此处不是数据库读和写要隔离开，而是而是以某一条界限为准，在这个界限以外的所有数据模型，都是不可写不可修改，或者修改属性的行为不影响数据库中的数据

通常这个界限和业务层与持久层隔离的界限是保持一致的，即业务层从持久层拿到数据后的修改是不会更新到数据库的。这样做的目的是提高代码的可维护性，一个反例是Core Data的设计，任何业务层代码对NSManagedObject属性的修改在context执行save时都会更新到数据库，这使得一些问题很难调试

## 多线程导致的隔离

## 数据表达和数据操作的隔离

