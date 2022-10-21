## Core Animation笔记

动画其实就是在`1/60`(s)时间内准备每一帧图片，就形成了不卡顿的动画。我们不需要自己准备，`CoreAnimation`为我们做了

![](https://github.com/songgeb/I-Love-iOS/blob/master/Animation/Images/ca_architecture.png?raw=true)

## layer

- layer是渲染内容显示的载体，真正要显示的内容其实是其背后的bitmap或指定的image
- layer的backing store，指的是一块用于存储要通过GPU进行绘制的bitmap的内存部分
- 官方没说，但从[Getting Pixels onto the Screen](https://www.objc.io/issues/3-views/moving-pixels-onto-the-screen/)这里可以知道，并不是所有情况下会开辟backing store这块内存的。比如这个layer要显示一张图片（content设置为CGImage），就不会额外开辟内存，绘制内容时直接将CGImage交给了GPU；但若重写了drawRect方法，便会开辟这块内存
- 我想可能官方所说的backing store不只是额外开辟的这块内存，也包括了CGImage这种内容
- layer有个delegate属性，可以通过delegate的方法，指定layer显示的内容或者对sublayer进行布局
	- UIView的layer会自动将试图本身作为layer的delegate

### anchorpoint、position、frame
1. layer的所有变换都是基于anchorpoint
2. frame是个function value，由anchorPoint、position、bounds和transform共同决定
3. 关于anchorPoint
    - 一个layer的anchorpoint是(0, 0) -> (1,1)的范围来表示
    - anchorPoint是transform的支点
    - 一个layer的anchorpoint是基于当前layer的坐标系的，比如(0.5, 0.5)就是layer的中心
    - 一个layer的position，这个position点其实始终和anchorpoint重合的。但它的值则是`anchorPoint所在的位置`基于`superlayer坐标系`的坐标值。
    - 对anchorPoint和position的理解可以参考白纸、桌子和图钉的故事--[彻底理解position与anchorPoint](http://wonderffee.github.io/blog/2013/10/13/understand-anchorpoint-and-position/).
    - 修改anchorPoint不会改变position的值，反之亦然。(代码试验得出)
    - `layer.position.x = layer.frame.origin.x + layer.anchorPoint.x * layer.bounds.size.width` (同理y值也是如此，其实公式中缺少了transfrom的因素，如果不考虑transform的话这样是没问题的)
    - 有几个常见的问题
        1. 修改position会不会影响anchorpoint？反之呢？---不影响，代码试验为证。
        2. 修改anchorPoint为什么会使得layer移动吗？--- 基于第一个问题和上面的等式，修改了anchorPoint后，既然position不变，bounds也不会变。那只能frame改变了。也可以通过图钉的故事了解：将图钉固定在桌子上以此来保证position不变，此时移动白纸的话就相当于修改anchorPoint，所以frame肯定是会变得。
    - 还未解答的问题
        1. 为什么anchorPoint改变时，position也不变？苹果这样设计的用意是什么？
    
### CoreAnimation中layer类型
1. 三种类型：`model layer tree`(也叫layer tree)、`presentation layer tree`、`render tree`
    - model layer tree: 存储animation的target value，与用户接触最多
    - presentation layer tree: 存储了动画过程中的当前值；不能修改，但可以获取当前动画值
    - render tree: 执行真正的动画时用到，对用户是私有的
3. presentationLayer tree和layer tree是一一对应的
    - 通过`presentationLayer`可以访问到presentationLayer
    - presentationLayer中的值变现了animation中实时变化的值，但layer tree中的值则是animation结束后最终的值
4. view和layer的关系，要展示的内容、动画都是依赖layer。但view可以接收响应事件，绘制内容等。
5. 每个layer tree中的layer，都对应presentation layer tree和render tree中的一个对象
6. 在layer tree中的layer，可以通过`presentationLayer`获取到相应layer

### layer
1. UIView的layer一旦创建后不能修改
2. CALayer是其他layer类型的基类
3. `contentGravity`，类似UIImageView的`contentMode`，默认是填充满，不保持ratio
5. layer的background在底部，然而border却是在上面，contents在中间，即使后面在addSubLayer，sublayer也是在中间

    ![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/layer_border_background.png?raw=true)
    ![QQ20190122-204106@2x.png](http://ww1.sinaimg.cn/large/bfdfb219gy1gbwz50pjx1j20640620t3.jpg)
6. border是占据bounds区域的
    
    ![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/border.png?raw=true)
6. 如果显示的内容不需要透明度，建议把`opaque`设置为YES，提高性能
6. layer有圆角时，一定不能设置opaque为YES，因为layer要靠透明来实现
9. layer可以通过kvc添加属性、添加action

#### shadow
1. shadow的部分其实已经超出了bounds部分，但layer的size不变
2. 在不指定shadowPath的情况下，默认的shadowPath规则，如果layer不是全透明，就对整个layer围绕border添加shadow，如果layer背景是全透明的，就在layer的border周围、content还有sublayer都添加shadow

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/coreanimation_shadow_path.png?raw=true)

2. 相关的属性有
    - shadowColor
    - shadowOffset, 需要一个CGSize类型的值，对于iOS，可以理解为offset方向是朝下(height)、右(width值)展示阴影
    - shadowOpacity
 
#### layer对象管理着一个bitmap，3种方式可以给layer赋值bitmap
- 通过`contents`属性，直接赋值一个image；适合图片不常变化的情况
- 给layer设置代理对象，代理对象实现`displayLayer:(layer)`方法，直接给contents赋值`layer.content=bitmap`；或者代理对象实现`drawLayer:theLayer inContext:context`，在context上直接绘制。这适合图片常变化的情况
    - view初始化时，会自动把view作为back-stored layer的代理对象，我们无需干预其内容赋值过程
    - 如果两个方法都实现，则系统只会考虑`displayLayer`方法
- 创建CALayer的子类，并重写`display`或`drawInContext:`方法，实现自己管理自己的内容
    - 自己管理自己内容的情况不多见，比如`CATileLayer`将大图进行多个切片，管理着各个切片的展示
    - `display`中给`content`赋值，或`drawInContext:`中自己绘制

### animation

#### 简单动画
简单动画并非某种特定动画类型，而是相对容易实现、简单地修改几个属性就能实现的动画。

简单动画可以有两种实现方式：explicit（创建`CABasicAnimation`对象添加到layer上）和implicit（隐式动画，即修改layer的可支持动画的属性如`opacity`，自动产生动画效果）

1. explicit动画完成之后，animation对象从layer中删除，不会更新layer tree中对象的值，而是使用当前值（即初始值）重绘一遍，就又回到动画初始状态。所以，要记得在创建动画之后，把动画的最终值设置给layer tree对象。
2. explicit或implicit动画会执行在当前线程的runloop中，所以当前线程一定要有runloop。
3. 动画执行的时机是，当前线程runloop的下次更新cycle。所以如果设置多个动画属性值时，多个动画会一起执行。

- [Animatable Properties](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/AnimatableProperties/AnimatableProperties.html#//apple_ref/doc/uid/TP40004514-CH11-SW1)

#### Keyframe Animation

- keyTimes--???
- timeFunction--??
- values，设置一个数组，表示关键帧动画中变化的值
- path，如果不设置values，也可以用path(CGPath)设置变化的值
- calculationMode, 动画算法
    - kCAAnimationLinear、kCAAnimationCubic该类值对动画的控制度最大
    - kCAAnimationCubicPaced，设置该值后，设置的keyFrames和timeFunction就不起作用了
    - kCAAnimationDiscrete，离散动画，设置该值后，动画就会在keyFrames中的值跳跃式的进行动画，没有中间过渡效果

#### stop explicit animation
> 注意，隐式动画是没办法被remove的

- 可以通过`removeAnimationForKey:`或`removeAllAnimations`停止动画
- 个人认为`UIView.animationWithDuration...`的方式执行动画是explicit动画，不是implicit。只是这个animationkey我们不知道，但可以通过removeAllAnimation来移除动画

#### 多个动画同时执行
1. 由于是下次runloop执行动画，可以串行的添加多个animation对象，或者修改多个implicit animatable property
2. 使用`CAAnimationGroup`，添加多个动画对象，设置一个动画时长，layer.add(group, forKey: "222")
3. `Transactions`对象???

### 监听动画的开始、结束
1. 对于`Transaction`的动画，可以设置`completionBlock`
2. 对于普通动画，可以设置`delegate`，有开始和结束的回调方法

> 如果要将两个动画先后顺序串起来，官方推荐通过设置`beginTime`属性实现，不建议用上面方法

### Customizing the Timing of an Animation

能够控制时间的核心是`CAMediaTiming`协议，`CALayer`和`CAAnimation`都实现了该协议

- [关于暂停动画的很好的解释](https://stackoverflow.com/questions/20946481/comprehend-pause-and-resume-animation-on-a-layer)

```
-(void)pauseLayer:(CALayer*)layer {
   CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
   layer.speed = 0.0;
   layer.timeOffset = pausedTime; // 1
}
 
-(void)resumeLayer:(CALayer*)layer {
   CFTimeInterval pausedTime = [layer timeOffset];
   layer.speed = 1.0;
   layer.timeOffset = 0.0; // 2
   layer.beginTime = 0.0; // 3
   CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
   layer.beginTime = timeSincePause;
}
```

> 1、2、3点不太容易理解

1. 既然speed已经是0了，动画应该立即停止了，为什么没有这一句timeOffset=pausedTime，动画就会回到初始位置？
    - 这句有两个作用，其一，记录下暂停的时间，以方便重新启动动画时知道在哪个位置重新开始
    - 其二，如果不设置timeOffset，动画会自动回到初始位置（并没查到理论依据，实验得出的结论）
    - 立即上面两条需要对`beginTime`、`timeOffset`等概念已经动画执行的过程有所了解
    - 关于几个属性的解释可参考下面的图示
    - 底层根据设置的这些属性，计算出动画过程中每一个时间点对应的每一帧，当设置speed=0，layer位置会根据timeOffset，回到相应的位置，如果没有设置timeOffset，即使用默认值0，就回到初始位置；过一会儿如果重新设置speed=1，

- [关于beginTime、timeOffset等概念的示例图，方便理解](https://foolish-boy.github.io/2016/%E6%B5%85%E8%B0%88Layer%E5%92%8CAnimation/)


![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/animation_begintime.png?raw=true)

### CGAffineTransform

仿射： 变换前平行的两条线，变换后仍是平行的。

初步的理解是，(x,y)通过与一个3*3的变换矩阵相乘，能够得出(x',y')，这个变换矩阵可以是平移、旋转、缩放，也可以是他们的组合。

- scale，缩放动画，从`中心点`缩小或放大
    
## 疑问

1. 见到了一次UIView.animation的compltion中，isFinish是false的情况。
    - vc1的viewdidload中进行动画，但vc1进入的瞬间，push进了vc2
2. 当创建layer，添加动画代码串行的写时，就看不出动画效果了；但是如果使用basicaniamtion，设置了begin和end后，就又work了---原因还不是特别清楚
3. 如果要将两个动画先后顺序串起来，官方推荐通过设置`beginTime`属性实现，不建议用上面方法
4. coreanimation将view内容缓存到bitmap中，这样底层绘画硬件就可以直接操作了。
5. ca整个流程和view-based drawing一大不同点是，view-based的绘画要调用drawRect方法，且在主线程中操作，很耗资源；而ca的是在硬件中处理缓存好的bitmap，效率高。
6. 设置layer的背景色时，如果使用pattern images时，Core Graphic使用的坐标系正好和默认的是相反的。要注意
7. 仿射变换是指的从一个坐标系的(x,y)映射到另一个坐标系的(x',y')吗？前后基于两个坐标系吗？
8. 通过scale、rotate等操作后，layer的frame和bounds有没有变
9. layer.transform，transform支持哪些变换类型

### UIScrollView的滚动和手动添加的CAAnimation有什么区别？

- UIScrollView的滚动动画是基于Runloop，在主线程中实现的
- CAAnimation则是依赖CoreAnimation，将动画任务提交到独立于Application的Render Server由GPU实现的

### CoreAnimation与Core Graphics区别

## 好的练习题
- [How To Make a Custom Control Tutorial: A Reusable Knob](https://www.raywenderlich.com/5294-how-to-make-a-custom-control-tutorial-a-reusable-knob)

## 参考

- [Core Animation Programing Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html)
