# 《iOS Core Animation Advanced Techniques》笔记

> `Core Animation`这个名字有些误导性，其实动画功能只是该框架的一部分，原来叫`Layer Kit`，表示跟图层绘制渲染相关功能

## Layer

### content
content属性接收图片内容时只能是`CGImageRef`类型

### contentsScale
- 由于`content`属性只能接收`CGImageRef`类型数据，该类型数据并没有scale信息（不像UIImage），所以需要设置正确才能展示合理
- 该属性是逻辑值，表示在不同设备中向一个**逻辑像素**中绘制几个物理像素内容
	- 在非Retina设备上contentScale是几，一个逻辑像素就会绘制几个物理像素
	- 在2x的Retina设备上contentScale应该设置为2，一个逻辑像素点钟会绘制4个像素

### contentsRect
- 这是一个`CGRect`类型的属性，但取值是从0-1.0
- 该属性表示，最终展示使用layer.content的哪一部分
- 默认是`(0, 0, 1.0, 1.0)`，即默认content都要显示
- 如果设置为`(0, 0, 0.5, 0.5)`，则表示当前layer只显示要显示内容的左上1/4部分

### contentsCenter

该属性的名称很容易混淆其实际意思，该属性并不控制绘制内容的位置，而是控制当layer被resize时被拉伸的部分

- 该属性值是`CGRect`，默认取值是{0, 0, 1, 1}，表示内容整体会被拉伸
- 通过示例图能很容易理解该属性的规则
- 该属性不仅可以通过代码设置，Interface Builder中也可以设置，看下面第二张示例图
- 该属性让我们想到`UIImage`的`resizableImage`系列方法

[![cwONIP.png](https://z3.ax1x.com/2021/04/11/cwONIP.png)](https://imgtu.com/i/cwONIP)
[![cwOaPf.png](https://z3.ax1x.com/2021/04/11/cwOaPf.png)](https://imgtu.com/i/cwOaPf)


## Layer Geometry

### frame、bounds、position
- UIView的frame、bounds、center与这三个属性对应
- frame属性是一个`computed property`，由bounds、position、transform属性共同确定
- position表示的是anchorpoint(锚点)与superlayer的相对位置
- 默认情况下anchorpoint在layer的中心位置，而UIView没有anchorpoint属性，所以UIView中对于layer.position属性，叫做center

### Coordinate Systems

- layer相对于superlayer的`bounds`进行布局

#### geometryFlipped

iOS中布局使用的坐标系，是以父layer的左上点作为布局原点；mac os中则是以左下点；

通过设置该属性为YES，则会在iOS和mac os规则之间切换。比如，iOS中设置该属性为YES，则布局时会以左下作为原点

### The Z Axis

- `zPosition`属性是给三维展示准备的，`zAnchorPoint`也是类似
- 但平常开发中几乎碰不到三维展示
- 在`zPosition`相等时，多个layer的展示层级是根据layer添加顺序；但当`zPosition`大时，它会展示在上层，此时添加顺序就不奏效了
- 注意：修改`zPosition`只是在可视化上改变它的层级，至于touch事件则还是按照layerTree的顺序

### Rounded Corners

- layer.cornerRadius，仅能影响到backgroundcolor；如果要影响到content或sublayer，需要开启maskToBounds


### 给一个layer添加不同圆角半径的方法

### Shadow in layer
- shadowOffset，默认值是{0, -3}
	- 之所以是-3的原因是最初是在mac os上出现的
- shadow的形状是由layer中的内容决定，而非边界决定
- 可以用shadowPath来控制产生阴影的形状

### mask
> The color of the mask layer is irrelevant; all that matters is its silhouette. The mask acts 
like a cookie cutter; the solid part of the mask layer will be “cut out” of its parent layer and 
kept; anything else is discarded

- mask属性也是一个layer
- mask像一个曲奇形剪刀，和parent layer相交的部分，且alpha不等于0的部分会保留下来，其余的舍弃

### scaleFilter

对应两个属性：minificationFilter、magnificationFilter

表示在缩小或放大layer的内容时，通过什么样的插值算法来得到缩放后的图像像素

- kCAFilterNearest，最近邻
	- 速度快，但容易产生马赛克、锯齿，适合没有曲线、简单的图像
- kCAFilterLinear，二次线性插值
	- 可以保留原图像的轮廓，适合有曲线的图像
- kCAFilterTrilinear，三次线性插值

## Implicit Animations

### Transaction
- 所有隐式动画都是由系统自动触发
- 系统通过CATransaction类，将动画进行封装
- CATransactioin的设计比较奇特，它并不只表示一个动画事务，其内部使用栈结构管理了很多个事务

### Layer Actions

## Explicit Animations

### Transitions

- 根据前面的讲解，implici animation和explicit animation都是针对layer的property的动画
- 如果想对一个页面或一个整体进行动画，或者对不支持动画的property进行动画，则无法使用implicity和explicit动画
- 此时就需要Transitions了，它可以对整个layer进行动画。当然动画类型只有固定的几种
- Transitions的本质是
	- 执行动画前为layer做一个snapshot
	- 对snapshot整体进行动画

## Layer Time
- timeOffset不太懂

## Easing
- UIView的动画方法默认使用的是kCAMediaTimingFunctionEaseInEaseOut
- 但若自己创建CAAnimation时，timing fuction默认值是kCAMediaTimingFunctionLinear
- 

## 问题
1. 经测试，calayer的mask不支持动画
2. uiview的类，直接修改frame无法产生隐式动画
3. 一个layer，直接修改animatable property可以自动产生隐式动画。但一个view.layer，直接修改却不行



 