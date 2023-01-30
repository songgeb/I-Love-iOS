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

Implicit Animations即隐式动画，就是那些由系统自动配置、提交执行的动画

其实就是指property animation，无论直接修改或是通过UIView的animate系列方法进行动画，都是隐式动画

因为作为调用者，我们无需配置动画时长、动画函数等设置，这些事情都有Core Animation框架替我们做了

### Transaction
- 所有隐式动画都是由系统自动触发
- 隐式动画的原理，是系统通过CATransaction类，将动画进行封装
- CATransactioin的设计比较奇特
	- 它不能通过传统的alloc创建使用，系统内部使用栈结构管理了很多个CATransactioin对象，我们只能像栈一样pop, push或获取top transaction的属性（比如动画时长）

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

### CAMediaTimingFuction

Core Animation uses easing to make animations move smoothly and naturally instead of seeming robotic and artificial.--Easing Function

> Every physical object in the real world accelerates and decelerates when it moves. So, how do we implement this kind of acceleration in our animations? One option is to use a **physics engine** to realistically model the friction and momentum of our animated objects, but this is overkill for most purposes.

Easing function is represented by `CAMediaTimingFunction`. Two ways to use easing function:

- For `CAAnimation`, set `timingFunction`
- For implicit animations, use `+setAnimationTimingFunction:` of `CATransaction`

How to create `CAMediaTimingFunction`, simplest way is 

```
let fn = CAMediaTimingFunction(name: .linear)
```

name list is:

```
kCAMediaTimingFunctionLinear
kCAMediaTimingFunctionEaseIn
kCAMediaTimingFunctionEaseOut
kCAMediaTimingFunctionEaseInEaseOut
kCAMediaTimingFunctionDefault
```

> Default value of implicit animation's timingFunction is kCAMediaTimingFunctionEaseInEaseOut. Default value of CAAnimation is kCAMediaTimingFunctionLinear

### UIView Animation Easing

```
UIViewAnimationOptionCurveEaseInOut
UIViewAnimationOptionCurveEaseIn
UIViewAnimationOptionCurveEaseOut
UIViewAnimationOptionCurveLinear
```

default value of timingFunction is UIViewAnimationOptionCurveEaseInOut

### CAKeyframeAnimation Easing

```
let animation = CAKeyframeAnimation(keyPath: "backgroundColor")
animation.duration = 2
animation.values = [
      UIColor.blue.cgColor,
      UIColor.red.cgColor,
      UIColor.green.cgColor,
      UIColor.blue.cgColor
]

let timingFunction = CAMediaTimingFunction(name: .easeIn)
animation.timingFunctions = [timingFunction, timingFunction, timingFunction]
```

### Custom Easing Functions

#### The Cubic Bézier Curve

![](https://github.com/songgeb/I-Love-iOS/blob/master/Animation/Images/animation_cubicgraph.png?raw=true)

custom timingfunction below:

```
let timgFn = CAMediaTimingFunction(controlPoints: 1, 0, 0.75, 1)
```

![](https://github.com/songgeb/I-Love-iOS/blob/master/Animation/Images/customtimingfunction.png?raw=true)

#### More complex animation curve

bounce animation. Consider a rubber ball dropped onto a hard surface: When dropped, it will accelerate until it hits the ground, bounce several times, and then eventually come to a stop.

![](https://github.com/songgeb/I-Love-iOS/blob/master/Animation/Images/bounceanimation_animationcurve.png?raw=true)

This effect can not be represented by a single cubic Bezier curve. But we have other options:

- Use CAKeyFrameAnimation, split aniamtion into several steps, each with its own timing function
- Implement animation using a timer to update each frame

#### Automating the Process

对于前面比较复杂的动画，虽然可以用CAKeyFrameAnimation实现，但计算过程比较繁琐，不易复用。有什么办法让这个过程更简便易用？

我们可以将一个动画想象成无数个片段，每两个片段之间其实可以认为是线性变化的一个动画，组合起来就是最终动画了。每一个片段可以看做CAKeyFrameAnimation的每个KeyFrame，所以可以用CAKeyFrameAnimation来实现，那么关键问题就是：

- 分成多少个片段
- 每个片段是什么

至于片段数，可以分成 duration(second) *  60，按照一秒60帧来分；每一个片段的内容要通过插值函数获得，这个插值函数已经有前人提供了--[Robert Penner's Easing Functions](http://robertpenner.com/easing/)

## Timer-Based Animation

### Frame Timing

可以使用`NSTimer`, `CADisplayLink`来尝试准备每一帧的内容，来模拟动画

### Physical Simulation

还可以通过物理引擎(physics engine)来创建与实际生活中关联更紧密，更能模拟现实生活物体的动画

## Tuning for Speed

Most animation performance optimization is about intelligently utilizing the GPU and CPU so that neither is overstretched. To do that, we first have to understand how Core Animation divides the work between these processors.

### CPU VS GPU

#### The stages of animation

- Layout—This is the phase where you prepare your view/layer hierarchy and set up the properties of the layers (frame, background color, border, and so on).

- Display—This is where the backing images of layers are drawn. That drawing may involve calling routines that you have written in your -drawRect: or -drawLayer:inContext: methods.

- Prepare—This is the phase where Core Animation gets ready to send the animation data to the render server. This is also the point at which Core Animation will perform other duties such as decompressing images that will be displayed during the animation (more on this later).

- Commit—This is the final phase, where Core animation packages up the layers and animation properties and sends them over IPC (Inter-Process Communication) to the render server for display.

then, the render server does following things for each frame:

- Calculates the intermediate values for all the layer properties and sets up the OpenGL geometry (textured triangles) to perform the rendering
- Renders the visible triangles to the screen

The first five work is done on CPU side, the last work is handled by GPU.

### Measure, Don’t Guess

Use Instruments

## Efficient drawing

### Software drawing

The term drawing is usually used in the context of Core Animation to mean software drawing (that is, drawing that is not GPU assisted). Software drawing in iOS is done primarily using the Core Graphics framework, and while sometimes necessary, it’s really slow compared to the hardware accelerated rendering and compositing performed by Core Animation and OpenGL.

应避免Software drawing，即占内存又慢

But as soon as you implement the CALayerDelegate -drawLayer:inContext: method or the UIView -drawRect: method (the latter of which is just a wrapper around the former), an offscreen drawing context is created for the layer, and that context requires an amount of memory equal to the width × height of the layer (in pixels, not points) × 4 bytes. For a full- screen layer on a Retina iPad, that’s 2048 × 1536 × 4 bytes, which amounts to a whole 12MB that must not only be stored in RAM, but must be wiped and repopulated every time the layer is redrawn.

### Vector Graphics

Vector Graphics叫做矢量图形

> 矢量图形可以大致这样理解，可以通过数学等式绘制出来的图形。相比于传统的图片，由于可以通过数学等式计算出来，所以矢量图形可以做到缩放不失真

之所以会用到Core Graphics去绘制图形，很大原因是可以绘制Vector Graphics，其中包括：

- Arbitrary polygonal shapes (anything other than a rectangle) 
- Diagonal or curved lines
- Text
- Gradients

通过使用硬件加速的图形绘制技术能够提高新能：

- 绘制多边形时可以优先选择CAShapeLayer(内部使用硬件加速进行优化)
	- 通过简单的绘图应用试验可知，使用Core Graphics实现的CPU和内存占用明显高于CAShapeLayer
- 另外还有CATextLayer和CAGradientLayer

### Dirty Rectangles

- setNeedsDisplayInRect:

### Asynchronous Drawing

异步绘制，即支持将部分绘制任务移到非主线程中执行

iOS系统原生提供了两种异步绘制机制

- CATileLayer
	- 可以通过设置切片layer，不同切片在绘制发生在非主线程
- layer.asynchronousDrawing
	- 开启该属性后，系统会自动配置drawLayer中的参数CGContext，绘制命令不会立即执行，会自动排队执行，以达到不影响用户交互的目的
	- 适用于频繁绘制的场景

## Image IO

### Loading and Latency

- flash storage is faster than traditional hard disk
- but around 200 times slower than RAM

### Threaded loading

- Scrolling animations are updated on the main run loop, and are therefore more vulnerable to CPU-related performance issues than CAAnimation, which is run in the render server process.

### Deferred Decompression

### Resolution Swapping

- When you observe a moving image, your eye is much less sensitive to detail, and a lower-resolution image is indistinguishable from Retina quality.

### Caching

### File Format

- jpng

## Layer Performence

### Inexplicit Drawing

But in addition to explicitly creating a backing image, you can also create one implicitly through the use of certain layer properties, or by using particular view or layer subclasses.

It is important to understand exactly when and why this happens so that you can avoid accidentally introducing software drawing if it’s not needed.

#### Text

#### Rasterization

- Color Hits Green and Misses Red

### Offscreen Rendering

#### use CAShapeLayer to rounded corner

#### Stretchable Images

- circular image combined with `contentCenter` property

#### Blending and Overdraw

### Reducing Layer Count

- Object Recycling
- Core Graphics Drawing

## 问题
1. 经测试，calayer的mask不支持动画
2. implicit animation和explicit animation在原理上的区别是什么？
2. uiview的类，直接修改frame无法产生隐式动画
4. 如何查看implicit animation的timingFunction
5. self.layerView.layer.geometryFlipped
6. 通过CoreGraphics画图，每次path变化都要重绘，性能不好，有什么办法优化吗？
	- CAShapeLayer好在哪？
7. Vector Graphics与刚体变换区别？
8. CATileLayer好在哪
9. UILabel使用什么技术渲染文字
10. Core Graphics vs Core Animation

## 参考
- [Improving Image Drawing Performance on iOS](https://developer.apple.com/library/archive/qa/qa1708/_index.html)
