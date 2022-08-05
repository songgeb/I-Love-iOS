# bounds in iOS

> 深入理解代替单纯记忆

bounds指的是View.bounds

与其关联的内容其实还是挺多的，bounds与内容绘制、动画等都有关系

由于笔者能力限制，无法全部覆盖，本文仅解释一下bounds.origin的原理、意义

> 当然，由于bounds内部的源码是不知道的，所以以下所有的内容都是根据经验和试验得出

## 问题引入

你是否曾遇到过下面的问题？

1. 作为iOSer，你是否经常在面试中被问到Frame和Bounds区别是什么？
	- 可能你会很轻易的回答出Frame的意思。但Bounds呢？是不是会说“Bounds是基于自己坐标系的rectangle信息”
	- 那这个所谓的“基于自己的坐标系”你是否真正理解呢？
	- 我看过几个讲解Frame vs Bounds的视频，一个共同点是，当讲解到bounds.origin时，就卡了，含糊地带过
2. 当修改Bounds.origin时，所有的subViews进行了位移，但位移为什么和第一感觉不一致呢？
	- 该如何解释这种感觉不一致呢？

如上的问题，我都有过

下面我尝试用形象一些的思路来解释`Bounds.origin`

## Bounds.origin

首先，列出官方对Bounds的解释

> UIView.bounds, The bounds rectangle, which describes the view’s location and size in its own coordinate system.

关键点在于`coordinate system`指的是什么，坐标系原点在哪？

### View's own coordinate system

先看另一端官方的描述

> The bounds property defines the internal dimensions of the view as it sees them, and its use is almost exclusive to custom drawing code.

意思是，bounds定义了视图自己要显示内容的一个边界

为了方便地绘制视图内部的内容（不止是绘制内容了，像旋转、位移、缩放等效果），有一个虚拟的坐标系会让事情容易实现

所以可以想像一下，这个坐标系大概是这样子，它会跟着视图绑定在一起，即使视图旋转，坐标系也跟着转

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/bounds_coordinatesystem.png?raw=true)

### 坐标系原点

其实原点放在视图的左上角也不错，这样的话bounds.origin就不需要了

但实际上不是这样，可能是因为要实现scrollview的scroll效果吧

那坐标系原点在哪里

- 既然bounds.origin是view在坐标系中的位置，那自然可以推导出原点在哪里了
- bounds.origin可以被修改，所以坐标系的原点（或者说坐标系）也是在变的

我们看一个例子

1. 新创建一个View1，默认bounds.origin是(0, 0)，则说明此时View1的左上角就是坐标系的原点
2. 我们将View1.bouns.origin变更为(10, 10)，则坐标系原点就发生了位移，移到了距离View1左上角，向左向上10的位置。结果就是改坐标系下的所有内容都跟着发生位移

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/bounds_originchange.png?raw=true)

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/bounds_originchange_display?raw=true)

### 另一种bounds的理解角度

- 也可以将bounds认为是希望显示在屏幕上的内容的区域
- 比如当bounds.origin从(0, 0)变为(10, 10)时，则希望将(10, 10, width, height)区域的内容显示出来
- 当然，此处的(0, 0)和(10, 10)两个坐标点都是基于视图的左上角而言的（将视图左上角视作原点）

## 关于Bounds的其他思考

- 为何进行缩放后，Bounds却没有变化
	- 个人解释，是不是由于缩放的实现其实是将坐标系进行了缩放(刻度发生了变化)，所以，其实按照逻辑点来说Bounds并没有发生变化
	- 当然，我大概了解，缩放等变化背后其实就是矩阵乘法等数学操作，这个所谓的坐标系其实还是虚拟的

## 参考
- [UIView](https://developer.apple.com/documentation/uikit/uiview)
- [UIView frame, bounds and center](https://stackoverflow.com/questions/5361369/uiview-frame-bounds-and-center/11282765#11282765)