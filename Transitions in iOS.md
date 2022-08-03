# Custom Modal Transitions in iOS


## Customizing the Transition Animations

### The Transitioning Delegate

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/custom-presentation-and-animator-objects.png?raw=true)

- 必须实现`UIViewControllerTransitioningDelegate`协议
- 如果需要自定义转场动画，则必须提供animator方法，animator负责present时的转场动画，比如动画样式、动画时间等；animator需要实现`UIViewControllerAnimatedTransitioning`协议
- 可选地另提供用户可交互的animator，实现`UIViewControllerInteractiveTransitioning`
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

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/transitioning-context-object.png?raw=true)

> 视图表示的是绿色vc present 蓝色vc的过程

- transtion动画开始之前，由UIKit创建context object
- context object实现了`UIViewControllerContextTransitioning`协议
- transition动画其实是要在一个`containerView`添加/删除要展现的view，同时执行动画。`containerView`就是图中白色的视图，它和绿色、蓝色vc的视图是不同的
- context object中保存了transition所需的信息，如会引用transition所涉及的vc、view(比如上一条说的containerView)等
- 由于多次进行transition时，状态不容易同步的原因，不建议自己缓存一些状态数据，应该使用context object提供的数据，它可以保证数据状态一致

### The Transition Coordinator

- transition过程中，UIKit会创建coordinator。说是负责一些额外的动画工作，不懂
- transition不仅是present或dismiss，屏幕旋转、或一些导致视图变化的因素都会导致transition发生？
- 可以通过transition中相关vc的`transitionCoordinator`获取
- 和context object类似，他也有transition的众多信息
- context object仅在transition执行过程中有效

### Creating Animations that Run Alongside a Transition

在transition过程中，通过coordinator的两个方法可以执行一些额外的动画。当然，仅限于transition过程中，因为coordinator仅在这个期间有效