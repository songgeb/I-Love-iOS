# Masonry源码阅读笔记

> 本文参照[Masonry](https://github.com/SnapKit/Masonry)版本为1.1.0

读音：英 [ˈmeɪsənri]，来自有道词典

## MASConstraintMaker

- constraints，存放着向某视图添加的所有约束对象，对象类型为MASConstraint
- 也是该框架工作的入口

```
[redView mas_makeConstraints:^(MASConstraintMaker *make) {
	make.top.equalTo(superview.mas_top)
}];
```

上面语句会触发如下代码同步执行

1. 首先会创建一个MASConstraintMaker的对象，就是这里的make
2. make.top这一句，会产生一个MASViewConstraint对象constraint（或者MASCompositeConstraint对象），该对象就是约束中的first item（当然，对应的attribute为top）
3. 执行MASViewConstraint对象的equalTo方法，会创建对应的second item，同时将second item存入constraint中
4. `mas_make...`的block中所有语句执行完毕后，会产生多个constraint，make都会保存这些约束信息
5. 紧接着会执行MASConstraintMaker的install方法，install方法中会：
	- 对make中每一个constraint，执行install方法，即将约束添加到视图中
	- 如果有重复的约束，则会更新Constant

## MASViewAttribute
表示一条约束中某个item的attribute。

first item和second item创建时都会创建对应的MASViewAttribute

## MASConstraint
一个抽象类，有两个子类：MASViewConstraint、MASCompositeConstraint

- MASViewConstraint存储着一条约束所需的所有信息，如first item、second item、attributes、constant等
- MASCompositeConstraint用于包装多个MASViewConstraint，比如`make.size.equalTo(CGSizeMake(10, 10));`，这里执行完`make.size`之后所产生的的constraint就是MASCompositeConstraint类型，包含了width和top两个constraint

## MASLayoutConstraint

系统类`NSLayoutConstraint`的子类，表示一条约束。
## 学到什么

### inset是怎样工作的
以前使用inset时总是不太明白

- inset在Masnory会转成 { inset, inset, -inset, -inset }的UIEdgeInsets的数据类型
- 而且仅会对first item's attribute起作用；并且只有它是top、left（leading）、bottom、right（trailing）时起作用

### 语言技巧

代码中有不少可以提高代码易用性、可读性、减少警告的技巧

- equal是对mas_equal方法的宏定义
- mas_equal()中的参数可以是多个类型
	- mas\_equalTo(40)、mas\_equalTo(view)、mas\_equalTo(view.mas_right)
	- 其实内部会将不同的值统一转为MASViewAttribute
- __unused、noescape等attribute的使用

## 结语

- 代码中包含较多的block调用，对可读性有一定影响，但由此带来的易用性（链式调用）很赞
- 并无太多架构设计思想在其中，有一处抽象类的使用；使用分类（Category）比较多
- 只要对Autolayout原理比较了解，还是比较容易读懂源码，尤其是一些专业名词，如first item、attribute、relation等



