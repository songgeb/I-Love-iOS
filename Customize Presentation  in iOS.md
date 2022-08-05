# Customize Presentation 

> 深入理解代替单纯记忆

presentation是指通过`presentxx`系列方法在一个ViewController打开另一个ViewController的行为；和通过`dismissxx`系列方法关闭当前ViewController，显示上一个ViewController的行为

从开发角度讲，完成该过程分需要确定两件事情：

1. Presentation前后的效果是什么样，比如目的ViewController的尺寸、显示位置是怎样的，有没有蒙层等
2. Presentation过程中的过渡动画是怎样的？要不要支持手势动画（比如iOS中优化屏幕边缘可以完成dismiss效果）

其实看完官方文档关于该部分的内容后，不难发现

Presentation(以present为例)的过程，说白了就是，

- 有一个containerView上，一个fromView（即presentingViewController.view），还有一个要显示的toView（即presentedViewController.view）
- 该containerView是用于执行presentation过程中的显示和动画，由系统管理。且fromView作为presentingViewController的视图，会自动加到containerView上
- Presentation的过程就是将toView添加到containerView上，并执行动画的过程（dismiss时则是将fromView从containerView中移除）

所以，下文将详细介绍这两件事：Transition Animation 和 Presentation Controller

## Create Custom Transition Animation
整体上仅需要简单的两步

1. set transitioningDelegate for presented ViewController
2. implement custom `transitioningDelegate` object
	- implement custom animator

下面看一下具体细节

## The Transitioning Delegate

首先，看一下自定义转场动画的工作原理

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/custom-presentation-and-animator-objects.png?raw=true)

```
public protocol UIViewControllerTransitioningDelegate : NSObjectProtocol {

    @available(iOS 2.0, *)
    optional func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?

    @available(iOS 2.0, *)
    optional func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?

    optional func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?

    optional func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?

    @available(iOS 8.0, *)
    optional func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?
}
```


- 如果要自定义转场，首先必须为presentedViewController提供一个delegate，该delegate实现`UIViewControllerTransitioningDelegate`协议
- delegate可以提供animator，animator负责present时的转场动画，比如动画样式、动画时间等；animator需要实现`UIViewControllerAnimatedTransitioning`协议
	- 其中的`animateTransition(using:)`方法，转场动画的核心代码就写在这里
- delegate也可以提供用户可交互的animator的能力，需要提供一个实现`UIViewControllerInteractiveTransitioning`的Interactive Animator
    - 实质是是否需要一些用户可交互的手势去驱动转场动画的执行
    - 系统提供了一个基于百分比，进行用户交互动画的类`UIPercentDrivenInteractiveTransition`
- 提供presentationController，用于自定义present时presntationStyle
- Transitioning Delegate不一定既提供animator，也提供presentationController
    - 如果不设置animator，UIKit会使用`modalTransitionStyle`的值；presentationController同理
    - 如果要让presentationController起作用，则必须设置`modalPresentationStyle`为`custom`

> 注意，用户可交互的animator和普通的animator并不是非此即彼的关系，自定义转场动画时普通animator必须要有；而用户交互的animator是可选的，就像navigationtroller提供的左滑dismiss用户交互一样，动画是要有的，但不一定支持手势来驱动转场动画

### The Custom Animation Sequence

不论present还是dismiss，UIKit首先会跟询问`transitionDelegate`的`animationControllerForPresentedController:presentingController:sourceController:`，找到自定义的`Animator`

#### present时

1. `transitionDelegate.interactionControllerForPresentation:`检查是否用户手势驱动动画
2. `animator.transitionDuration`，获取动画时长
3. 如果不需要用户交互驱动动画，则直接执行`animator.animationTransition`；如果需要交互则先`interactionController.startInteractiveTransition:`，再进行`animator.animationTranstion`
4. UIKit等待animator执行`completeTransition:`方法，通知UIKit动画已经完成
5. UIKit调用`presentViewController:animated:completion:`中的completion回调；执行`animator.animationEnd`

> 代码测试发现，用于用户交互的`UIViewControllerInteractiveTransitioning`，其工作原理大致上是，当present方法调用后，animator中的`animationTransition`会立即执行，就是说此时可能view层级中已经有了要添加的view，只是，动画不会完成，要等待用户交互完成


### The Transitioning Context Object

该部分说一下具体的自定义动画该如何实现，需要依赖哪些信息

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/transitioning-context-object.png?raw=true)

> 视图表示的是绿色vc present 蓝色vc的过程

- transtion动画开始之前，由UIKit创建context object
- context object实现了`UIViewControllerContextTransitioning`协议
- transition动画其实是要在一个`containerView`添加/删除要展现的view，同时执行动画。`containerView`就是图中白色的视图，它和绿色、蓝色vc的视图是不同的
- context object中保存了transition所需的信息，如会引用transition所涉及的vc、view(比如上一条说的containerView)等
- 由于多次进行transition时，状态不容易同步的原因，不建议自己缓存一些状态数据，应该使用context object提供的数据，它可以保证数据状态一致

```
func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        //get animation parameters
        let fromVC = transitionContext.viewController(forKey: .from)
        let toVC = transitionContext.viewController(forKey: .to)
        let containerView = transitionContext.containerView
        
        let toView = transitionContext.view(forKey: .to)
        let fromView = transitionContext.view(forKey: .from)

        guard let toV = toVC, let fromV = fromVC else {
            return
        }
        
        //set start point
        let containerFrame = containerView.frame
        var toViewStartFrame = transitionContext.initialFrame(for: toV)
        var toViewFinalFrame = transitionContext.finalFrame(for: toV)
        var fromViewFinalFrame = transitionContext.finalFrame(for: fromV)
        
        if isPresenting {
            guard let toView = toView else { return }
            //toView是要添加的view
            //开始动画前让toView在container右下角
            toViewStartFrame.origin.x = containerFrame.size.width
            toViewStartFrame.origin.y = containerFrame.size.height
            containerView.addSubview(toView)
            toView.frame = toViewStartFrame
            UIView.animate(withDuration: 1, animations: {
                toView.frame = toViewFinalFrame
            }) { (finished) in
                let success = finished && !transitionContext.transitionWasCancelled
                if !success {
                    toView.removeFromSuperview()
                }
                transitionContext.completeTransition(success)
            }
        }
}
```

## The Transition Coordinator

- transition过程中，UIKit会创建coordinator。如果在这个过程需要做同步做一些操作可以使用它
- 可以通过transition中相关vc的`transitionCoordinator`获取
- 和context object类似，他也有transition的众多信息
- transition coordinator仅在transition执行过程中有效

比如，想在transition过程中做一个其他的动画

```
coordinator?.animate(alongsideTransition: { ctx in
          let time = ctx.transitionDuration
          guard let view = ctx.viewController(forKey: .to)?.view else {
              return
          }
          UIView.animate(withDuration: time, delay: 0, options: .allowUserInteraction) {
              view.transform = CGAffineTransform.init(rotationAngle: Double.pi / 4)
          } completion: { finished in
          }      
})
```

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

## Q&A
1. 对Apple关于Prensentation的设计评价一下？

## 参考
- [View Controller Programming Guide for iOS](https://developer.apple.com/library/archive/featuredarticles/ViewControllerPGforiPhoneOS/index.html#//apple_ref/doc/uid/TP40007457-CH2-SW1)