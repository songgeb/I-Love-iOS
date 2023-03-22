
# Autolayout笔记

> 深入理解代替单纯记忆

### autolayout engine
- 2011年第一次引入aotulayout
- 引擎计算的时候考虑很多东西，对我来说比较陌生的有self-sizing view、alignmentRect
- self-sizing view，就像tableview cell，不需要认为设置外部的约束，只用做内部的内容的约束即可
### alignmentRect
- aotulayout engine对每个view最终会计算出一个alignment rect，这个rect用于与其他view做约束时使用
- 可以通过重写alignmentRectInset来更改这个rect，比如我不想让一个view和另一个view的frame做约束，而是和另一个view的局部做约束。那我就需要重新实现另一个view的alignmentInset内容
- 但像UIButton、UILabel这些组件的alignmentRectInset都是0，所以frame和alignmentRect是相同的，即使有shadow

### UILayoutGuide

1. 相当于一个rect，但没有view的概念，没有layer，更加轻量级。
2. 方便布局，可以当做container，包住views，整体居中或其他任何布局
3. 当做多个view间需要等间距时，也可以用它

### autolayout在scrollview的应用

- 这篇文章不错,[史上最简单的UIScrollView+Autolayout出坑指南](https://bestswifter.com/uiscrollviewwithautolayout/)
- 练习（用container的方法向scrollview添加子view）

### translatesAutoresizingMaskIntoConstraints
    
是否要用`autoresizingMask`作为布局选项，而非autolayout

- 如果开启，则不仅`autoresizingMask`起作用，设置frame也起作用
- 如果开启，`autoresizingMask`会创建position和width、height完备的约束，所以会和autolayout冲突。所以使用`autolayout`就要关闭它
- 如果关闭它，同时也不使用autolayout时，设置frame还是work的
- IB中，对于自己新建的view，该属性会自动关闭；但像vc的view（root view）该属性是true
    
### Programmatically Creating Constraints
- 通过编码实现autolayout有三种方式

```
//anchor, from iOS 9.0
view.leadingAnchor.constraint(equalTo:).isActive = true

//NSLayoutConstraint, from iOS 6.0
NSLayoutConstraint(item: myView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leadingMargin, multiplier: 1.0,lier: 1.0,ier: 1.0,er: 1.0,r: 1.0, 1.0,1.0,.0,0,,t: 0.0).isActivt Language, from iOS 6.0
let views = ["myView" : myView]
let formatString = "|-[myView]-|"
let constraints = NSLayoutConstraint.constraints(withVisualFormat: formatString, options: .alignAllTop, metrics: nil, views: views)
NSLayoutConstraint.activate(constraint)//一般VFL的形式会同时产生多个constraints，所以要用该方法开启constraints
```

- 关于`isActive`（可能是用惯了add/removeConstraint，我经常忘记写这个属性）
    * 该属性源自**iOS 8**，官方建议iOS 8之后，尽量用这个属性来`添加`和`删除`约束
    * 在iOS 8之前通常用`add/removeConstraint`方法
        
### **toplayoutGuide/bottomlayoutGuide**

- **iOS 7 -- iOS 11**，从iOS 11起使用`safearea`
- 代码中使用`NSLayoutConstraint`或`VFL`时可以直接将`vc.topLayoutGuide`看做一个`attribute`
- 代码中使用`anchor`时，可以用`vc.topLayoutGuide.bottomAnchor`

### **safearea**

从iOS 11引入，官方建议使用`safearea`

- 含义如其名，安全的可用于布局的区域，矩形区域
- 即提供了api来获取具体的safearea的各个值，用于frame布局；也提供了anchor属性，来用于autolayout布局
- 用于autolayout的属性是`safeAreaLayoutGuide`
- 用于frame布局的属性是`safeAreaInsets`
- 对于rootView of UIViewController，可以通过更改该vc的`additionalSafeAreaInsets`来修改rootView的safeArea
    - 像我们在用navigationController时，获取到rootVC的view的safeArea就已经去除了navigationBar的部分了。这正是因为navigationController设置了chilVC的`additionalSafeAreaInsets`值

#### layoutMargins

- UIView的属性，也是`UIEdgeInsets`类型，表示四个方向上的距离
- 该属性的含义是，建议subview距离当前view的边距
- autolayout中的应用时，比如Interface Builder中的工具中`Constraint to margins`，就是指的正在编辑的view的某个边距离superView的layoutMargin的距离（而不是距离superview的bounds）；或者VFL中`|-[view]-|`是指的view的左右边和superview的layoutMargin的左右对齐
- 本身这个值是可以修改的，至于layoutMargin的默认值
    - UIViewController的rootView的layoutMargin左右的默认值是16，上下不是很固定
    - 其他View默认值是8
- iOS 11引入一个`insetsLayoutMarginsFromSafeArea`属性
    - 当开启时表示，如果layoutMargins某一边在safeArea之外，则强制将layoutMargin的该边同步成safeArea相等的值
    - 如果不开启，则保持原来的值
    - 默认开启；同时，在Interface Builder中对应`Size Inspector`中的`SafeArea Relative Margins`
- iOS 11之后建议使用`directionalLayoutMargins`替代`layoutMargins`

#### safearea vs topLayoutGuide
1. topLayoutGuide或bottomLayoutGuide是UIViewController的属性
2. safearea是以view为单位

### intrinsicContentSize

- intrinsicContentSize本质上还是约束
- 这个约束是系统为组件添加的

```
// Compression Resistance
View.height >= 0.0 * NotAnAttribute + IntrinsicHeight
View.width >= 0.0 * NotAnAttribute + IntrinsicWidth
 
// Content Hugging
View.height <= 0.0 * NotAnAttribute + IntrinsicHeight
View.width <= 0.0 * NotAnAttribute + IntrinsicWidth
```
- 系统自动添加了4个约束
	- compression resistance对应两个，contenghug对应两个
	- compression的两条约束优先级是750，compression的是250
	- 所以，一个默认优先级的intrinsicContentSize的控件，当内容变化时，容易往外撑开
- 也正是这4约束的存在，导致了intrinsicContentSize冲突问题
	- 比如两个UILabel-A、B放在一行，其中一个A的内容变化时，宽度自动变宽，就可能挤到B
	- 当B被挤到时，它是应该被挤压，还是应该自己保持宽度，让A被挤压
	- 这种决策的依据就是上面4条约束的优先级顺序，优先级越高的肯定越优先满足
	- 这也就是`setContentHuggingPriority:forAxis:`和`setContentCompressionResistancePriority:forAxis:`存在的意义
- intrinsicContentSize通常会因为系统自动增加的约束而使得开发者少写一些约束
- intrinsicContentSize在实现自适应高、宽度的自定义视图方面也有些帮助

### Animation in Autolayout

```
UIView.animate(withDuration: 0.5) {
    //adjust constraints
    self.view.layoutIfNeeded()
}
```

### debugging autlolayout
- ambiguous layout-模棱两可、模糊不清的问题；
	- 一般可能是缺少一些约束，可能有好多种最终布局的可能
	- 举例，view1.height = 24(priority=750)， view1.height >= 30(priority=750)，其实可以理解为无法同时满足，但却不是unsatisfiable问题，因为不是required
	- UIView/UILayoutGuid/NSLayoutAnchor.hasAmbiguousLayout
	- exerciseAmbiguityInLayout

	- 这种问题一般不会在控制台打印异常
- unsatisfiable (conflict) layout，required的约束太多，无法同时满足
	- 仅限required约束；参见上面ambious的例子
	
- constraintsAffectingLayoutForAxis，打印view的constraints

### storyboard & xib

- safearea是iOS 11开始的特性，如果低版本时，使用storyboard时，safearea会自动降为top/bottom layout guide。注意，**xib**却不会，所以推荐使用storyboard
- 将xib中的东西拷贝到storyboard中时，constraint会被拷贝过去，但xib中所有跟fileowner相关的outlet都不会被拷贝过去，即使在storyboard中给vc设置了class。

### performence in autolayout
1. 建议用hidden，不建议频繁remove/add constraints
2. 当frame和autolayout布局混用时，`systemLayoutSizeFitting`这个方法每次都会创建、删除一个engine，比较耗性能，要注意。

### 最佳实践

- [SnapKit 最佳实践](https://kemchenj.github.io/2018-04-05/)

### 疑问
1. layoutMargin和readableMargin属性杂用？

### 参考

- [Auto Layout Guide](https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/AutolayoutPG/index.html#//apple_ref/doc/uid/TP40010853-CH7-SW1)
- [WWDC-2018 High Performance Auto Layout](https://developer.apple.com/videos/play/wwdc2018/220)
- [WWDC-2016 What's New in Auto Layout](https://developer.apple.com/videos/play/wwdc2016/236)
- [WWDC-2015 Mysteries of Auto Layout, Part 1](https://developer.apple.com/videos/play/wwdc2015/218/)
- [WWDC-2015 Mysteries of Auto Layout, Part 2](https://developer.apple.com/videos/play/wwdc2015/219/)
- [What's New in Table and Collection Views](https://developer.apple.com/videos/play/wwdc2014/226/)
- [WWDC-2013 Taking Control of Auto Layout in Xcode 5](https://developer.apple.com/videos/play/wwdc2013/406/)
- [WWDC-2012 Auto Layout by Example](https://www.youtube.com/watch?v=z0oA4ryCvHU)
- [WWDC-2012 Best Practices for Mastering Auto Layout](https://developer.apple.com/videos/play/wwdc2012/228/)
- [WWDC-2012 Introduction to Auto Layout for iOS and OS X](https://www.youtube.com/watch?v=efAV8xnH864)
- [Positioning Content Within Layout Margins](https://developer.apple.com/documentation/uikit/uiview/positioning_content_within_layout_margins)
- [Positioning Content Relative to the Safe Area](https://developer.apple.com/documentation/uikit/uiview/positioning_content_relative_to_the_safe_area)
- [iOS开发之xib技巧介绍](http://www.ifun.cc/blog/2014/02/22/ioskai-fa-zhi-xibji-qiao-jie-shao/)
- [UICollectionViewFlowLayout下使用Autolayout实现动态cell高度](https://songgeb.github.io/2018/11/19/UICollectionViewFlowLayout下使用Autolayout实现动态cell高度/)



