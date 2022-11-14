# iOS横滑组件实现

> 这是我早先实现的一个自定义横滑组件，本文回顾一下当时实现过程遇到的问题和细节，最后有源码地址

所谓横滑组件其实就如图所示的效果：

![]()

列一下UI上的要求：

- 每次滑动一页，有pageEnable的效果
- 每次显示在屏幕中的item其实是三个而不是一个
- 每个item的间距、视图与屏幕边缘的边距严格按照UI上样子

## UICollectionView+pageEnable


使用UICollectionView并开启pageEnable是最容易想到的方案，我们来试一下能否满足需要

关键的几个参数如下所示

```
container.width = 375
collectionView.isPagingEnable = true
collectionView.width = 375
leftPadding = rightPadding = 16
cell.width = container.width - leftPadding - rightPadding
collectionView.contentInset = UIEdgeInset(0,16,0,0)
```

效果如下所示：

![]()

显然，没有达到预期：

- 问题1，每次滑动停止后，cell的位置不对
	- 通过打印contentOffset得知，UIScrollView开启pagingEnable后的自动翻页，每次修改contentOffset的值等于UIScrollView.width
	- 而且我们无法自定义每次翻页移动的距离
- 问题2，由于设置了collectionView.contentInset.left，所以第一cell可以移动到屏幕最左边而不能自动还原到初始位置

不甘心，继续调整

我画了一张图来表示要实现的效果：

![]()

- 根据上图的效果，我们希望的效果是每次移动cell时移动的距离(两条红竖线之间的距离)是一个cell的宽度+cell之间的距离--cell.width+interval
- 既然pageEnable特性每次移动的距离一定是scrollView.width，所以我们可以让scrollView.width = cell.width+interval
- 这或许能解决上面显示异常问题

我们更新一下配置参数，如下：

```
leftPadding = rightPadding = 16
container.width = 375
collectionView.isPagingEnable = true
cell.width = container.width - leftPadding - rightPadding
interval = 8
collectionView.width = cell.width + interval
collectionView.contentInset = UIEdgeInset(0,0,0,interval) // 这一句可能会引起你的困惑，但经过测试必须设置成这样，否则效果有问题，本文不做详细解释，跟scrollView自身对于contentSize和contentOffset的调整有关
```

来看一下效果：

![]()

哇，好像不错！但还是有问题：

- 我们希望同时显示三个cell，但该效果却只能显示1个cell
- 这是因为collectionView的宽度刚好能显示下一个cell和一个interval，没有更多空间来显示其他cell了

这就很尴尬了，为了利用pageEnable的特性，我们不得不修改collectionView的宽度小一些，但这却导致无法足够的cell个数

所以，结论是：❌

## UICollectionView + UIScrollView

在调研其他技术方案时，受一[Paging a overflowing collection view](https://khanlou.com/2013/04/paging-a-overflowing-collection-view/)启发，可以使用一个UICollectionView和一个UIScrollView一同实现类似效果

核心思想如下：

- 单独用一个UIScrollView，利用pageEnable特性来实现符合要求的横滑、拖拽翻页效果
- 单独用一个UICollectionView来利用它的cell显示、复用机制
- UIScrollView是不显示的，只用它的拖拽手势能力。当拖拽UIScrollView时，将contentOffset的移动应用到UICollectionView中

具体实现过程中有些细节需要注意，比如：

1. collectionView的contentInset需要设置
2. 将scrollView的移动应用到collectionView中时如何计算准确
3. 需要关闭collectionView的panGesture

再放一下效果



结论是：✅

### 优缺点

优点很明显：

- 既复用了UIScrollView的pageEnable手势和动画效果，也复用了UICollectionView的cell复用机制
- 由于复用了UICollectionView，所以相比通过UIScrollView自定义实现，在一些用户交互体验上可能更好，比如在快速横滑时，自定义的实现可能就没办法快速的准备好每一个cell并无缝从上一页切换过来，可能会有点卡顿
- 所有实现细节都是通过系统官方的public API，不存在任何trick行为，稳定性好

缺点：

在用户体验上没发现缺点。只是在封装为独立组件时需要注意更多细节，比如：

- 该组件将CollectionView封装了起来，所以必须给外部使用者暴露dataSource和delegate等必要的回调和数据源方法

## 使用UIScrollView完全自定义实现

我还看过另一种方案：

- 自己创建cell视图，添加到UIScrollView上
- 完全由自己来控制cell的复用和显示逻辑
- 滑动手势和效果方面，利用UIScrollViewDelegate方法来控制抬起手指后移动到到下一个或上一个cell的效果（该效果我曾经也实现过，可以参考[设计与Swipe-Delete不冲突的UIPageViewController](https://juejin.cn/post/6844903955428818952)）

这个思路看上去应该是可行的，我也看过类似的源码实现，是Github上的一个代码

但该源码的显示逻辑写的不好：

- 每次切换cell时，会同时通过delegate要求更新所有的cell数据（显示在屏幕中的cell和在缓存池中未用到的cell）