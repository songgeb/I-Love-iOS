# SizeClass in iOS

> 深入理解代替单纯记忆

> 代码与截图基于`Xcode 10.1 + Swift 4.2`

## 概念
- **iOS 8**引入了Size Class概念
- 是因为iOS设备（包括iPod、iPhone、iPad等）尺寸太多，之前开发者为了适配需要了解每个设备的宽、高
- ***而Size Class是想为所有尺寸的iOS设备抽象出一个统一的尺寸描述规则***

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/size-class%203.png?raw=true)

1. 图中列出了当时(2017年)所有iPhone和iPad的尺寸(半透明的矩形代表不同设备)，并且提供了portrait和landscape两个方向
2. 两条白线列出了四个象限，分别对应着`compact`和`regular`的尺寸。compact小于regular
3. 白线的位置距离左上角是否固定？目前来看iPhone Xs landscape下的宽度应该是`wC`和的`wR`的界限(width compact、width regular)；同样iPhone Xs landscape下的高度应该是`hC`和`hR`的界限。随着新设备出来，我想白线是会变的
3. 任何一个设备，左上角对齐放入这个坐标系下，宽或高所在的象限就是它的Size Class值
4. 例如，iPhone Xs Max的landscape情况下，是compact height + regular width

## Interface Builder中的使用

> 默认状态下，设置的属性适用于所有的Size Class值

开启/关闭Size Class的位置


![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/size_class_open.png?raw=true)

### 套路一

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/sizeclass-vary_for_trait.jpeg?raw=true)

1. 选择`vary for trait`，选择`height`或`width`，也可都选。解释下弹出的`height`和`width`两个选项
    - 由前面`device` + `orientation`可以确定一个Size Class值了，比如`wC * hR`。如果选择了`height`，则表示后面我们要添加的一些属性比如autolayout，将针对所有符合`hR`状态（即宽度上比较窄时，例如iPhone 垂直状态、iPad垂直和landscape状态）的设备
    - 其实选中`height`或`width`后，`Xcode`会自动提示有哪些状态符合条件。类似`Varying 42 Regular Height Devices`
2. 选好后，后面针对这种状态自定义自己想要的属性就行了，比如添加autolayout

3. 选择`Done Varying`

### 套路二

我们通过Interface Builder给各种UI空间添加属性时，会在属性左边看到`+`号，这里可以添加各种Size Class下不同的属性值

## 代码中的使用

- 通过`UITraitCollection`对象可以获取到Size Class值
- `UITraitCollection`是`UITraitEnvironment`协议的属性
- 下面这些类实现`UITraitEnvironment`协议
    -  **UIScreen**, **UIWindow**, **UIViewController**, **UIPresentationController**, **UIView**


## 参考

- [Size Classes and Core Components-WWDC2017](https://developer.apple.com/videos/play/wwdc2017/812/)
- [What is 'Vary for Traits' in Xcode 8?](https://stackoverflow.com/questions/39890055/what-is-vary-for-traits-in-xcode-8)
- [Building Adaptive User Interfaces](https://developer.apple.com/design/adaptivity/)