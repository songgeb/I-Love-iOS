本文算是一个对iOS中事件响应的一个简单“综述”，方便快速查询相关资料


- iOS事件有三种
	- 触摸事件（touch events）
	- 加速计事件（motion events）
	- 远程控制事件（remote control events）
- `UIResponder`是一个抽象类，只有继承了`UIResponse`类之后，才能处理上面的事件
- `UIView`、`UIApplication`、`UIViewController`都是它的子类
- `UIEvent`表示一个事件
- `UITouch`表示触摸事件中的一个触摸对象（多个手指触摸时就有多个对象）


## 触摸事件响应过程

> 注意，这里说的只是触摸事件

1. 系统产生触摸对象，通过`UIApplication`、`UIWindow`等上层对象发出
2. 通过hitTest过程，找到first responder，确认了事件responder chain（响应链）
3. 然后两条路一起进行事件响应的处理，在默认情况下
	- 响应链上的手势识别器优先于first responder收到`touchBegan`等消息，优先判定是否可以识别手势
	- first responder也会收到`touchBegan`消息
	- 但如果响应链上的手势识别器识别成功了，first responder则会收到`touchcancel`消息，first responder的响应链也会因此中断
	- 如果手势识别未成功，则不会中断响应链

## 手势识别器

- 手势识别器有两种：discrete 和 continuous
- 两种手势识别器的状态变化不同

系统内置的手势识别器按照类型进行划分如下：

**discrete gesture recognizer**

- UITapGestureRecognizer
- UISwipeGestureRecognizer
- UIScreenEdgePanGestureRecognizer

**continuous gesture recognizer**

- UIPanGestureRecognizer
- UIRotationGestureRecognizer
- UIPinchGestureRecognizer

### state of discrete gesture recognizer

![state of discrete gesture recognizer](https://docs-assets.developer.apple.com/published/7c21d852b9/9ce946b4-9661-4a40-86bc-2f78abf3a8b1.png)


### state of continuous gesture recognizer

![](https://docs-assets.developer.apple.com/published/7c21d852b9/86fa3739-c97b-44cc-b51d-0215697660b7.png)

## 一点心得

关于responder chain与gesture recognizer之间的协同工作原理，官方并没有详细说明，目前网上的文章主要是以代码测试结果为依据。这里强烈推荐参考文章中的第一篇

所以

可能实际项目中仍会遇到一些很难解的问题

## 未解难题
1. 向tableview中添加一个自定义view，view.userInteractionEnable = YES；此时，被view遮盖住的cell，无法点击，但是在view区域拖动，tableview却可以跟随滚动。为什么？

## 参考
- [iOS | 响应链及手势识别](https://juejin.cn/post/6905914367171100680)
- [About the Gesture Recognizer State Machine](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/implementing_a_custom_gesture_recognizer/about_the_gesture_recognizer_state_machine?language=objc)