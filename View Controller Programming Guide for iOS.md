## View Controller Programming Guide for iOS

两种展现vc的方式 **present** 和 **container**

### 从storyboard中加载vc时

1. 先构建vc，对outlet和action属性
2. 调用`awakeForomNib`，此时view位置啥的都没有最终确定
3. 调用`viewDidLoad`，`viewWillAppear`等

### 生命周期过程
1. 初始化发方法(从Interface Builder则是先`initWithCoder`再`initWithNib`；代码初始化则是其他)
2. 如果从Interface中初始化，则执行`awakeFromNib`；此时traitCollection是空的，子视图位置也不OK。需要注意`outlet`属性并也并不一定OK，可以参考下面的`awakeFromNib`部分
3. viewDidLoad
4. viewWillAppear
5. viewWillLayoutSubviews
6. viewDidAppear

### init(nibName:bundle:)

- designated initializer for UIViewController
- storyboard中初始化vc时（如下两个途径），系统先调用了**init(coder:)**方法，后调用该方法。触发时机如下所示：
    - 直接在storyboard中配置了vc，segue触发了初始化vc
    - 代码中通过`instantiateViewController(withIdentifier:)`方法时


### awakeFromNib

1. 该方法调用时机是，所有nib的archive中的对象都load并且initialize结束后
2. 当执行该方法时，所有的outlet和action都ready了（官方虽然这么说，但是并不准去，请参考2）
3. 对于2，需要注意的是，经过亲测，对于`UIViewController`来说，该方法执行时，即使调用了`super`的方法之后，设置在`rootView`层级上的UI控件都是`nil`；只有在执行完`loadView`之后，这些控件才ready的。就是说是`lazy`的

### Preserving and Restoring State

- 通过`NSKeyedArchiver`可以持久化存储任何对象，并且结合`initWithCoder`和`encodeWithCoder`方法可以实现对象的保存和还原
    - 适合任意符合`NSCoding`协议的对象
    - 可以在程序运行的任何时候，进行保存和还原
- UIViewController中，`UIKit`也提供了一种页面存储、还原的方法
    - 仅限于存储和还原UIViewController的内容
    - 该特性基于`UIKit`，保存、还原发生时机固定，仅限于关闭app时保存，启动app时还原
    - 简单列举该特性相关的方法，如`UIViewController.restorationIdentifier`

## Present ViewController

### presenting vs presented

A present B

- B是presented vc，但B.presentingVC不一定是A
- 当A是childVC时，那B.presentingVC是A的parent
- 当A作为container，那B.presentingVC才是A
- 感觉可以这样理解，container vc和presentaion是iOS的两种展现视图方式；presented和presenting只在presentation的体系中

### Presentation Styles

```
typedef NS_ENUM(NSInteger, UIModalPresentationStyle) {
    UIModalPresentationFullScreen = 0,
    UIModalPresentationPageSheet API_AVAILABLE(ios(3.2)) API_UNAVAILABLE(tvos),
    UIModalPresentationFormSheet API_AVAILABLE(ios(3.2)) API_UNAVAILABLE(tvos),
    UIModalPresentationCurrentContext API_AVAILABLE(ios(3.2)),
    UIModalPresentationCustom API_AVAILABLE(ios(7.0)),
    UIModalPresentationOverFullScreen API_AVAILABLE(ios(8.0)),
    UIModalPresentationOverCurrentContext API_AVAILABLE(ios(8.0)),
    UIModalPresentationPopover API_AVAILABLE(ios(8.0)) API_UNAVAILABLE(tvos),
    UIModalPresentationBlurOverFullScreen API_AVAILABLE(tvos(11.0)) API_UNAVAILABLE(ios) API_UNAVAILABLE(watchos),
    UIModalPresentationNone API_AVAILABLE(ios(7.0)) = -1,
    UIModalPresentationAutomatic API_AVAILABLE(ios(13.0)) = -2,
};
```

#### Automatic

- default value
- For most view controllers, UIKit maps this style to the `UIModalPresentationStyle.pageSheet` style, but some system view controllers may map it to a different style.

#### Full-Screen Styles

1. 下面的style都会盖住全屏，用户都没办法再跟被盖住的页面进行任何交互；但是，不是所有style下，下面页面的内容都能够展示，有的可以透过来
2. 通过该种style进行presentation时，真正执行presentation的vc不一定是presenting vc，`UIKit`会找到符合全屏present的vc，如果找不到，则用window.rootViewController。但这不会改变presenting和presented vc。

> UIModalPresentationFullScreen 和 UIModalPresentationFullScreen在present时，UIKit都会在动画结束后，将被遮盖住的vc的view删掉（原因不明）。如果为了让下面的vc内容显示，可以让使用两个style的cover形式

全屏样式style枚举有：

- UIModalPresentationFullScreen
    - present之后会remove掉presentingVC的view
- UIModalPresentationOverFullScreen
    - 也是占满屏幕，但不会remove掉presentingVC的view。为的是如果presenting VC是半透明的，有内容需要从后面透过来时，就要这样设计了

#### Sheet Styles

- UIModalPresentationFormSheet
	- regular width, regular height, system add a dimming layer over the background content and centers presented vc's content
	- can customize content size under regular width, regular height with `preferredContentSize`
	- regular height, compact width, like a sheet with part of the background content visible near the top of the screen
	- compact height, same as `UIModalPresentationFullScreen`
- UIModalPresentationPageSheet
	- regular width, regular height, system add a dimming layer over the background content and centers presented vc's content
	- content size under regular width, regular height can not be changed
	- regular height, compact width, like a sheet with part of the background content visible near the top of the screen
	- compact height, same as `UIModalPresentationFullScreen`

Where the background content remains visible, the system doesn’t call the presenting view controller’s viewWillDisappear(_:) and viewDidDisappear(_:) methods.

#### Popover Style

- `UIModalPresentationPopover`

The Current Context Styles

- `UIModalPresentationCurrentContext`

- 该属性，使得present时不一定遮盖住presentedVC，可以自定义present时遮盖住哪个vc
- 比如，splitVC中，如果进行跳转可以选择新跳转的presentedVC要遮盖住master还是detail

#### Custom

- Using this option to customize presentation style and transition style

### Presentation Styles 和 Transition Styles

两者是不一样的：

- Presentation Styles，转场结束后显示的样式，是区别于transition style的
    - modalPresentationStyle 
- Transition Styles，转场过程中的动画样式
    - modalTransitionStyle
- Transition style一定是在modal presentation的前提下才有意义(从属性命名上也能看得出来)
- 两者都是设置给被present的vc，即presentedvc

### Transition Styles

Transition Styles is referred to the property `modalTransitionStyle` of `iewController`


```
typedef NS_ENUM(NSInteger, UIModalTransitionStyle) {
    UIModalTransitionStyleCoverVertical = 0,
    UIModalTransitionStyleFlipHorizontal API_UNAVAILABLE(tvos),
    UIModalTransitionStyleCrossDissolve,
    UIModalTransitionStylePartialCurl API_AVAILABLE(ios(3.2)) API_UNAVAILABLE(tvos),
};
```

- default value is `UIModalTransitionStyleCoverVertical`,when present, bottom to top
- `UIModalTransitionStyleFlipHorizontal`, horizontal 3D flip from right-to-left
- `UIModalTransitionStyleCrossDissolve`, cross-fade
- `UIModalTransitionStylePartialCurl`

### Presenting vs Showing a View Controller

1. show更加灵活，更推荐
2. present就是通过modal的形式

#### Showing a View Controller

- showViewController:sender:
    - 大部分情况，都是present modally
    - navigationcontroller重写了该方法，执行push操作
    - splitviewcontroller也重写了，比较复杂？？？？？
    - 实质上，该方法先去通过` targetViewControllerForAction:sender: `去找vc层级中实现了该方法的target，找到了就执行；找不到就用window.rootvc进行present
- showDetailViewController:sender:
    - 该方法与前面的无detail的方法，看api说明好像很类似
    - 最大的不同是，该方法适用于splitvc的detail context（还没搞懂？？？？）

### Dismissing a Presented View Controller

1. 调用presentingvc的dimiss方法
2. 也可以调用presentedvc的dimiss方法，其实也是转给了presentingvc执行

### segue

segue是Interface Builder中方便两个vc之间进行presentation的机制
- 设置展现方式，show、present modally
- present时可以设置presentationStyle、transitionStyle
- 也可以自定义segue

1. segue的起点要么有defined action，比如control、bar button item
2. 或者是对tableview的row和collectionview的cell
3. 有的控件同时支持多个segue，比如tableview的row，accessory的button和整个row都支持segue
4. 执行segue时，可以在`shouldPerformSegueWithIdentifier:sender:`和`performSegue`中准备数据


#### unwind segue

一个通过配置storyboard，方便关闭vc，节省代码的的方案

1. 在某个vc中写一个IBAction方法，参数是UIStoryboardSegue，这个vc是关闭其他vc之后要显示的那个
2. 在要关闭的vc的storyboard中，用control-click将button或其他的连接到`Exit Object`中
3. 会自动弹出刚才写的IBAction方法，选一下即可
4. button点击时会传递到IBAction的方法中，系统自动关闭vc，并且IBAction的方法也可以自己写些其他操作

> IBAction一定要写，否则找不到target

### transition context

1. UIKit创建的，用来完成整个transition操作；有转换前后的vc信息
2. 由它去获取ainimationobject

### custom presentation

- presentation controller来控制转场的过程，比如设置presented vc的view尺寸、设置进入动画
- animator object

## Container ViewController
1. container vc只管理自己的view和children的**root view**，负责对root view布局
2. 至于container的children的内容，则由children来管理

### 代码实现

```
containerVC.addChild(child1)
containerVC.view.addSubview(child1.view)
//set frame or constraints
//child.view.frame = xxx
child.didMove(toParent: containerVC)
```

```
child1.willMove(toParent: nil)
child1.view.removeFromSuperview()
child1.removeFromParent()
```

### Interface Builder实现

拖一个`Container View`来用即可

### Children VC的appearence方法执行时机

- 默认情况，系统会自动给Child发送appearence消息，也可以通过下面方法阻止系统自动发送
- containert通过`shouldAutomaticallyForwardAppearanceMethods`重写return NO;可以自己控制发送时机
- 在合适的时机, container执行成对的两个方法即可
    ```
    -(void) viewWillAppear:(BOOL)animated {
        [self.child beginAppearanceTransition: YES animated: animated];
    }
 
    -(void) viewDidAppear:(BOOL)animated {
        [self.child endAppearanceTransition];
    }
 
    -(void) viewWillDisappear:(BOOL)animated {
        [self.child beginAppearanceTransition: NO animated: animated];
    }
 
    -(void) viewDidDisappear:(BOOL)animated {
        [self.child endAppearanceTransition];
    }
    ```

### Container的一些属性交给Childred决定

#### status bar style

- childViewControllerForStatusBarStyle
    - container中指定状态栏样式由哪个子视图控制器决定
- preferredStatusBarStyle
    - 子视图控制器中返回期望的状态栏样式
- childViewControllerForStatusBarHidden
- prefersStatusBarHidden

#### preferredContentSize

子视图控制器中可以指定一个期望的size，外面container可以直接使用，方便布局

## Creating Custom Presentations

presentation controller用来控制

- 是`UIPresentationController`的子类
- 可以控制presented vc的大小，即finalFrame
- 可以添加一些额外的视图，比如蒙层
- 当设备信息发生变化时，如旋转，进行页面适配

> UIPresentationController提供了很多控制transition过程、获取各种信息的方法

### PresentationController VS Animator

- Animator只负责presentedVC和presentingVC的rootView的增加、删除以及动画，不涉及额外的视图；额外的蒙层等其他视图由PresentationController进行增删和动画
- Animator中通过context object获取的finalFrame，数据来源来自PresentationController的`frameOfPresentedViewInContainerView`方法

### The Custom Presentation Process

对于present过程如下所示，对于dismiss也是类似过程，只是api方法不同

1. `transitionDelegate`的`presentationControllerForPresentedViewController:presentingViewController:sourceViewController:`方法，获取presentationController
2. 通过transitionDelegate获取animator
3. 执行presentationController的`presentationTransitionWillBegin`方法；
    - 自定义添加的视图，可以写到这里
    - 动画也可以写到这里，使用coordinator的animate相关方法
4. UIKit会调用presentation Controller的`containerViewWillLayoutSubviews`方法，可以进行视图的微调
5. 调用presentationController的`presentationTransitionDidEnd:`方法

## Building an Adaptive Interface

- 好的适配策略建议使用autolayout
- `traitCollection`中的水平和垂直sizeClass常用一些，idiom信息少用
    -  UIScreen, UIWindow, UIViewController, UIPresentationController, and UIView都可以或得到traitCollection
- 官方提到适配过程中有两个层级--adapt when trait change和adapt when size change
    - trait改变时的适配是粗粒度的，可以直接在Interface Builder中给不同SizeClass刚添加不同约束、属性搞定
    

### When Do Trait and Size Changes Happen?

- 屏幕旋转导致SizeClass改变
- containerVC改变导致SizeClass改变
- containerVC将childVC的size改变，进而导致SizeClass改变

> 当发生sizeclass改变时，UIKit会通知相关的对象，从window开始，一级一级往下传播，传播给container，再传播给childvc

#### UIViewController的SizeClass传播过程

1. `willTransitionToTraitCollection:withTransitionCoordinator:`trait将要改变
2. `viewWillTransitionToSize:withTransitionCoordinator:`view的size将要改变
3. `traitCollectionDidChange:`trait改变结束

#### 某些情况收不到trait改变通知

1. containerview重写了childvc的sizeclass时，childvc是收不到的
2. vc的size固定宽高时，也是收不到的

#### Changing the Traits of a Child View Controller

- childVC会继承containerVC的trait信息，当container的trait改变时，childVC也会同步改变
- container可以通过`setOverrideTraitCollection:forChildViewController:`控制childVC的trait
    - 重写后，childVC只听从于重写后的结果

#### Adapting Presented View Controllers to a New Style

- 当`modalPresentationStyle`使用系统样式时，SizeClass改变时UIKit会自动修改样式以适配不同的屏幕；如从hR变为hC时，自动变为`UIModalPresentationFullScreen`
- 如果`modalPresentationStyle`自定义的话，我们自己的presentationController可以控制适配方式
- 当然，即使UIKit会自动调整样式，我们仍可以动态修改；甚至可以在trait变化时替换一个新的vc进行展示
    - 给`presentationController`设置delegate；可以通过`presentedVC.presentationController`获取
    - 实现delegate的`adaptivePresentationStyleForPresentationController:`该方法能改变present样式；比如hR情况下popover的样式，当转为hC时，如果我们改为`UIModalPresentationNone`则，表示presentationController选择使用SizeClass改变前的样式，即仍是popover
    
    ![](/images/changing-adaptive-behavior-for-presented-view-controller.png)
    - 实现delegate的`presentationController:viewControllerForAdaptivePresentationStyle:`可以替换新的vc进行展示

## 其他

### hidesBottomBarWhenPushed

该属性用起来比较诡异，需要避免其他问题，具体问题参考[这里](https://stackoverflow.com/a/23269013/5792820)

## 参考
- [View Controller Programming Guide for iOS](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/index.html#//apple_ref/doc/uid/TP40007457-CH2-SW1)
- [iOS 视图控制器转场详解](https://blog.devtang.com/2016/03/13/iOS-transition-guide/)

## 疑问

1. 为什么使用showvc方法时，设置的modalPresentationStyle和transitionstyle最终不一定生效？
5. 如果用presentation controller来修改presentedvc的尺寸，那么animator中貌似也可以修改啊。。。冲突？
    - animator是可以修改，但animator
×
拖拽到此处
图片将完成下载