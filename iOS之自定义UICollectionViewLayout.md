# iOS之自定义UICollectionViewLayout

## Core Layout Process

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/customcollectionviewlayout_coreprocess.png?raw=true)

UICollectionView进行布局时需要借助UICollectionViewLayout，两者交互的过程大致分三个阶段：

1. 首先执行UICollectionViewLayout的`prepare`方法，做数据准备
2. UICollectionView通过UICollectionViewLayout 的`collectionViewContentSize`属性或方法获取滚动视图的内容尺寸
3. UICollectionView通过UICollectionViewLayout的`layoutAttributesForElementsInRect: `方法获取正在展示中的cell的样式等信息

## 如何自定义布局

通过重写上面三阶段不同的方法，我们可以自定义布局

- prepare阶段，我们可以做一些数据缓存工作，方便后序使用
- 比较关键的是后序layoutAttributesForElementsInRect阶段
	- 该阶段我们可能根据需要为cell、supplementaryView、decorationView创建不同的layoutAttribute对象
	- 通常的做法可能是，通过datasource遍历寻找那些需要调整样式的cell（比如可视区域内的cell），为每一个cell创建一个layoutAttribute，放入数组作为结果返回
- 因为layoutAttributesForElementsInRect可能会频繁执行，所以要考虑性能问题
- `layoutAttributesForElementsInRect:`是针对多个元素创建laoutAttrbute，还要考虑可能也要为单个的item提供layoutAttribute的情况，就是类似`layoutAttributesForItemAtIndexPath:`这一类的方法

## 自定义布局可以做哪些事

- 可以看一下`UICollectionViewLayoutAttributes`中支持哪些属性，比如zIndex、transform
- 可以自定义插入、删除动画
- 瀑布流效果，在社交软件中很常用
- 通过创建`UICollectionViewLayoutAttributes`的子类+增加自定义背景色属性，为collectionView添加sectionBacgroundColor


## 参考

- [Creating Custom Layouts](https://developer.apple.com/library/archive/documentation/WindowsViews/Conceptual/CollectionViewPGforIOS/CreatingCustomLayouts/CreatingCustomLayouts.html#//apple_ref/doc/uid/TP40012334-CH5-SW1)