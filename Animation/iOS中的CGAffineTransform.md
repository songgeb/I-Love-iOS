title: iOS中的CGAffineTransform
date: 2018-01-29 11:08:35
tags: [CGAffineTransform]
categories: [iOS]
---
> 加深理解代替单纯记忆

在学习`Core Graphics`时，对图形变换的实现原理不太理解，图形变换(transform)在iOS动画框架`Core Animation`中应用也很多，本文我将通过解释`CGAffineTransform`的数学原理，尝试给出比较容易理解和使用`CGAffineTransform`相关API的方法

### Mac App中的local coordinate system

在向设备（Mac or iPhone）屏幕上绘制内容时，是要有一个坐标系统的，这个坐标系有一个原点，最简单直接的绘制过程就是，每个待绘制的内容都有自己的坐标和尺寸，根据原点绘制。

但有个问题，比如像Mac中，可以同时运行多应用，可以有多个Window，所有的内容都依据屏幕的原点来绘制会使得工作变得很复杂。

于是，`Cocoa`引入了`local coordinate system`的概念，也就是设备屏幕Screen、应用Window和View都有自己的坐标系统。每一级内容依据自己的原点绘制，View的内容依据View原点绘制，Window的内容依据Window的原点，以此类推。一级的内容绘制完成后，将内容映射到上一级的坐标系中。如图所示：

![](https://user-gold-cdn.xitu.io/2019/7/24/16c21f74bc96085c?w=1342&h=795&f=png&s=47768)


### 类比到iOS应用上

iPhone屏幕一次只能显示一个应用，但和Mac App的原理相似。可以将iPhone内容的显示视为Mac App中的一个Window

在使用`Core Graphics`时，`CGContext`便表示了一个`local coordinate system`。它显示到iPhone上的过程也是：
1. 先计算图像在应用的local coordinate system的位置
2. 映射到设备的屏幕的坐标系下

### 如何在不同坐标系间进行映射
![](https://user-gold-cdn.xitu.io/2019/7/24/16c21f7c2b5e5d65?w=226&h=69&f=gif&s=1415)

上面的等式等价于：
![](https://user-gold-cdn.xitu.io/2019/7/24/16c21f801b9603dc?w=100&h=47&f=gif&s=886)

该公式表示，(x, y)是一个坐标系的点，通过矩阵相乘后，得出了另一个坐标系下的点(x', y')。

这个被乘的矩阵对应着`Core Graphics`中的`CGAffineTransform`，(x, y)和(x', y')则分别对应不同`CGContext`坐标系下的点。

先随意感受一下transform的样子

```
let context = UIGraphicsGetCurrentContext()!
print(context.ctm) //CGAffineTransform(a: 2.0, b: 0.0, c: -0.0, d: -2.0, tx: 0.0, ty: 1000.0)
```

`CGAffineTransform`的不同取值可以实现“平移”、“缩放”、“旋转”变换，那么是如何实现的呢？

我们从`CGAffineTransform`变换相关的API入手，看一下怎样才能更好地理解变换的过程。

> 关于`context.ctm`后面也会介绍

### 三组API

iOS中与`CGAffineTransform`相关的API有三组，分别是：
- CGContext类
    1. CGContext.[translate | scale | rotate]
    2. CGContext.concatenate(transform)
- CGAffineTransform类
    1. CGAffineTransform.[translate | scale | rotate]
    2. CGAffineTransform.concatenating(transform)
- UIKit中
    1. UIBezierPath.apply(transform)

> `UIKit`中的apply方法底层也是在调用`CGAffineTransform`的方法，只是平常开发中`UIKit`使用较多，所以这里也提一下

#### UIBezierPath.apply(transform)

- UIBezierPath表示要绘制的对象，也就是一个坐标系下的若干点的集合
- 参数transform，则是前面公式中的3*3的矩阵

`UIBezierPath.apply(transform)`的直接结果就是导致了UIBezierPath的坐标发生了变化，上代码：

```
let context = UIGraphicsGetCurrentContext()
let size = CGSize(width: 20, height: 20)
let path = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: size))//一个圆形图案
print(path.bounds) //(0.0, 0.0, 20.0, 20.0)
let t1 = CGAffineTransform(translationX: 20, y: 20)
//t1: CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 20.0, ty: 20.0)
path.apply(t1)
print(path.bounds) //(20.0, 20.0, 20.0, 20.0)
```

![](https://user-gold-cdn.xitu.io/2019/7/24/16c21f8f39c4219e?w=236&h=194&f=png&s=4044)

这段代码比较容易，可以理解为path这个圆形图案，从(0, 0)移动到了(20, 20)。

> `path.apply(t1)`的底层数学实现就是上一小节中的公式，也可写成`newPath = path * transform`

该结论后面会用到，再来看另一组API

#### CGContext类

```
UIGraphicsBeginImageContext(CGSize(width: 500, height: 500))
let context = UIGraphicsGetCurrentContext()
let size = CGSize(width: 80, height: 80)
let path = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: size))
print(path.bounds) //(0.0, 0.0, 80.0, 80.0)
UIColor.white.setFill()
path.fill()
```
![](https://user-gold-cdn.xitu.io/2019/7/24/16c21f888839e313?w=334&h=304&f=png&s=4335)

```
context.translateBy(x: 100, y: 100)
print(path.bounds) //(0.0, 0.0, 80.0, 80.0)
path.fill()
```
![](https://user-gold-cdn.xitu.io/2019/7/24/16c21f94c8caf258?w=330&h=302&f=png&s=5094)

从结果来看，path相对于左上角原点的位置变成了(100, 100)，但path的bounds并没有变，直观上看好像是由于`context.translate`导致了坐标系变了。

> 从效果上来看，`context.translate`和`path.translate`的效果是一致的，为什么呢？

我们来看下`context.translateBy(x: 100, y: 100)`的底层实现，首先看下方法的注释:

```
/* Translate the current graphics state's transformation matrix (the CTM) by
       `(tx, ty)'. */
    @available(iOS 2.0, *)
    public func translateBy(x tx: CGFloat, y ty: CGFloat)
```

`CTM(current transform matrix)`是当前context的坐标系所对应的矩阵:
```
print("context变换前:\(context.ctm)")
context.translateBy(x: 100, y: 100)
print("context变换后:\(context.ctm)")

//context变换前:CGAffineTransform(a: 1.0, b: 0.0, c: -0.0, d: -1.0, tx: 0.0, ty: 500.0)
//context变换后:CGAffineTransform(a: 1.0, b: 0.0, c: -0.0, d: -1.0, tx: 100.0, ty: 400.0)
```

我们可以推导出，**newCTM = transform * CTM** (此处的transform在该例中是translateBy(x: 100, y: 100)所对应的矩阵)

> 此时，如果进一步思考，这个`ctm`用来做什么的呢？

`ctm`是从应用的页面映射到硬件设备屏幕上所需的矩阵：`devicePath = path * newCTM`

> 注意：根据苹果官方的解释，ctm应该是应用页面映射到view坐标系统的矩阵，而不是映射到设备屏幕像素点的矩阵。因为从view坐标系统映射到具体物理像素点还要经过缩放。至于什么是view坐标系我没搞懂，不过并不影响此处我们研究的问题


那么我们把上面的式子展开，就是`devicePath = path * transform * CTM`，矩阵相乘满足结合律，也可以写成`devicePath = (path * transform) * CTM`，
`path * transform`不就是`newPath`么，所以可以得出`devicePath = newPath * CTM`

**重点来了**
1. `path.apply(transform)`和`context.translate`效果一致，是因为最终都走到了`devicePath = newPath * CTM`这一步
2. 但`path.apply(transform)`和`context.translate`又不是完全等价的
    - context改变后，新的path要根据`newCTM`进行点的映射
3. 所以我们可以这样想
    - 使用`UIKit`组API画东西时，是固定了画布（即context的ctm），任意绘制path
    - 使用`CGContext`时，则是先移动、旋转、缩放画布，那么新画的内容就得依据新坐标系了，而且上面已绘制的内容也会受影响

> `CGContext.concatenate(transform)`是类似的，只是接收的参数不同

#### CGAffineTransform类

从上面两小节中可以看出，`CGAffineTransform`在变化过程中提供了具体变换的数据结构。这一小节中我们需要注意，`transform`进行叠加时，**顺序很重要**。

- `CGAffineTransform.concatenating(transform)`

    ```
    /* Concatenate `t2' to `t1' and return the result:
        t' = t1 * t2 */
    @available(iOS 2.0, *)
    public func concatenating(_ t2: CGAffineTransform) -> CGAffineTransform
    ```

    这个没啥问题，`t = t1 * t2`


- `CGAffineTransform.[translate | scale | rotate]`

    ```
    /* Translate `t' by `(tx, ty)' and return the result:
         t' = [ 1 0 0 1 tx ty ] * t */
    
    @available(iOS 2.0, *)
    public func translatedBy(x tx: CGFloat, y ty: CGFloat) -> CGAffineTransform
    ```
    **坑在这里**，如果`t = t1.translatedBy(x : 1, y: 1)`，则`t = CGAffineTransform(translationX: 1, y: 1) * t1`。顺序是反过来的。
    
### 总结

1. 我们经常看到`UIKit中原点在左上角`和`CoreGraphics(Quartz)中原点在左下角`这种说法，其实最终都是通过上面提到的矩阵乘法来实现最终点的映射
2. UIKit绘制内容时底层仍然是`CoreGraphics`在工作。只不过UIKit框架修改了ctm，使得我们觉得`原点左上角`
3. 绘制内容时有两个思路可选：一种是使用CGPath这些对象直接在context中绘制内容；另一种则是，一边改context一边画，或者说一边改画布的坐标系一边绘制。这种方式对应的是context的api。这种方式适合绘制复杂的自定义内容
4. 实际开发中，尽量避免`UIKit`和`CoreGraphics`混用。这里面有个经典例子就是，在`UIKit`获取的context情况下，使用`CGContextDrawImage`画出来的图片，位置正确，但内容却在y轴方向发生了镜像
    
### 参考

- [Drawing and Printing Guide for iOS](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW3)
- [Quartz 2D Programming Guide](https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_affine/dq_affine.html#//apple_ref/doc/uid/TP30001066-CH204-SW1)
- [Coordinate Systems and Transforms](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html)
- [Core Graphics Tutorial: Curves and Layers](https://www.raywenderlich.com/34003/core-graphics-tutorial-curves-and-layers)