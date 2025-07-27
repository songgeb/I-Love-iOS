# UIKit笔记

UIKit中各UI控件备忘录

## UIVisualEffectView


- [UIVisualEffectView Tutorial: Getting Started](https://www.kodeco.com/16125723-uivisualeffectview-tutorial-getting-started)
- [3 Approaches to Applying Blur Effects in iOS](https://betterprogramming.pub/three-approaches-to-apply-blur-effect-in-ios-c1c941d862c3)

## UICollectionView
- `reloadItemsAtIndexPaths`执行时默认是有fade动画
- `reloadData`则不会
- 可以通过`[UIView performWithoutAnimation]:`取消fade动画

## 键盘
- 对同一个observer添加多次通知，该observer就会收到多次通知
- 在模拟器上由于不确定的因素，可能导致键盘show和hide通知展示多次
- `UIKeyboardWillChangeFrameNotification`时机可能早于`UIKeyboardWillShowNotification`
- 可以通过监听`UIKeyboardWillChangeFrameNotification`通知，判断frame于屏幕frame的关系

```
CGRect beginFrame = [value.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
CGRect endFrame = [value.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
BOOL willShow = beginFrame.origin.y >= SCREEN_HEIGHT && endFrame.origin.y < SCREEN_HEIGHT;
BOOL willHide = beginFrame.origin.y < SCREEN_HEIGHT && endFrame.origin.y >= SCREEN_HEIGHT;
```

## UITextView

- 不支持placeholder
- 但可以自己添加UILabel实现placeholder效果

## UITextField

### 复制粘贴
- 默认会有复制粘贴效果
- 没有很好的禁止粘贴的办法
- 可以通过`UITextFieldDelegate`的begin和endeditting回调，使得在编辑过程中设置`userInteractiveEnable`为NO来关闭粘贴效果

## Target-Action & UIControl
- target-action是一个设计模式，UIControl实现了该设计模式
- 如果target设置为nil，则事件会发送给firstResponder，沿着responder chain传递
- 当添加多个target时，action发生时，多个target的action method都会执行

## Bounds VS Frame

- frame是view的最小包围盒矩形
- 当view的transform变化时，比如旋转、缩放，都会导致frame改变；但bounds不会改变
- 官方说设置frame的size时会影响到bounds的size，是说开发者设置frame时会这样；像通过修改transform进行缩放时，frame的size发生了变化，但bounds仍不变

### 参考

- [View Programming Guide for iOS](https://developer.apple.com/library/archive/documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html)
- [iOS：重识Transform和frame](https://www.jianshu.com/p/e1fec2f92c63)

## UIImage

### images

貌似是为动图设置的比如gif，别的类型还不清楚
- 可以通过CG的方法获取data中每一帧数据，和UIImage的`animatedImage`方法创建包含`images`的UIImage
- 包含images数据的图片，在button、imageview上展示时都是动态的

## UIButton

### titleEdgeInsets

普通btn

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/uikit_btn.png?raw=true)

### imageEdgeInsets

### contentEdgeInsets

## 自定义视图

### 布局

#### frame布局
- `initWithFrame`中只添加对应的视图
- `layoutsubviews`中设置frame

#### autolayout布局
- `initWithFrame`中直接添加视图并设置约束即可

### 自适应高（宽）度视图

所谓的自适应高宽度视图，可以参照UILabel、UIButton这种，满足以下两点或其中一点

- 如果使用autolayout布局，只需要设置部分约束，则高度或宽度就会自动改变
- 如果使用frame布局，则通过执行sizeToFit，视图的frame会自适应到合适尺寸

如果要做很通用的视图组件，最好同时满足上面两点，这样使用方用着会很舒服

满足上面两点有两种思路

1. 为了让调用方在使用autolayout布局时可以自适应
	- 视图内部可以使用autolayout布局，然后添加满约束，同时有些约束要设置为低优先级
	- 同时为了满足sizeToFit可以work，还要重写视图的sizeThatFit方法，该部分使用frame布局，frame和autolayout的约束要保持逻辑一致

2. 第二种方式是
	- 自定义视图内部使用frame进行布局
	- 这样sizeThatFit方法中可以返回正确的宽高度
	- 同时，intrinsicContentSize也要有返回值，不能返回0
	- 而且要衡量view不同方法调用时机，避免出现循环调用问题
## UIProgressView

- 设置高度时，只能通过autolayout，通过frame不起作用