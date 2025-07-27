# Animated Image in iOS

> 深入理解代替单纯记忆

> 本文开始写作时间为2023年07月02日，代码测试环境为：Xcode 14.3 iOS 16

## 可不看的废话
好久没写技术博客了，持续学习不能懈怠，既要浪也要学习，既要站着又要挣钱

## 写本文动机

日常开发中UIImageView的使用频率特别高，特别是动画（WebP、GIF） 场景。有时候会遇到一些虽小但比较恶心的问题，比如：

- UIImageView支持哪些动图，为什么不支持WebP
- YYAnimatedImageView中播放WebP时如何监听动画结束
- 为什么YYAnimatedView的animationRepeatCount属性设置不起作用
- 位图与矢量图的区别？
- 哪些图是位图，哪些是矢量图
- 为什么有的图片格式是jpg，但仍然是动图，比如[Floating Buttons](https://cloud.githubusercontent.com/assets/390805/8467915/4da90948-2097-11e5-9f4a-bc02da152774.gif)

我想，这一切问题的原因主要是对动图（如GIF、WebP、矢量图等）、UIImageView、UIImage的工作原理理解不深入有关。本文就尝试来啃一下相关知识点，Come on!

## UIImageView原生支持的动图能力

UIImageView所支持动图能力的接口比较简单，就下面几个：

```
open var animationImages: [UIImage]? // The array must contain UIImages. Setting hides the single image. default is nil
@available(iOS 3.0, *)
open var highlightedAnimationImages: [UIImage]? // The array must contain UIImages. Setting hides the single image. default is nil
open var animationDuration: TimeInterval // for one cycle of images. default is number of images * 1/30th of a second (i.e. 30 fps)
open var animationRepeatCount: Int // 0 means infinite (default is 0)
```

再加上`UIImage`的获取animatedImage的几个方法（返回的UIImage赋值给UIImageView.image产生的效果等同于UIImageView. animationImages）

可见，

- UIImageView的动图API很简洁（很少）
- UIImageView到底支持哪些动图类型，目前来看完全取决于数据源UIImage

那么UIImage支持哪些图片或者动图类型呢？

## UIImage支持哪些图片格式

该问题不好回答，该问题的答案和开发经验相关，我先问了下ChatGPT，它告诉我支持：JPG、PNG、GIF、TIFF四种。我将信将疑，基于我的经验我感觉UIImage应该不支持GIF，要不我们为什么还用第三方库来显示GIF呢，于是自己测试了一下，发现用UIImage创建的GIF数据，无法使用UIImageView播放动画

但这并不能说明iOS中的UIImage不支持GIF格式，因为随后我查阅文档发现ImageIO框架中至少有处理GIF、WebP、TIFF、JFIF图片格式的API，所以很难说UIImage不支持它们，至于到底支不支持，还是多学点之后再来回答该问题

## GIF

简单列一下关于GIF的历史和特性：

- Stephen Wilhite在Compuserve公司工作时于1987年率领团队研发了GIF图形文件格式（版本为87a）。成像清晰、体积小，适合当时低带宽的网络环境。最初GIF并不支持动图
- 1989年Compuserve公司发布了GIF的增强版本（89a），扩充了图形控制区块（GCE）等几个区块，支持了透明色和多帧动画
- 优秀的压缩算法使其在一定程度上保证图像质量的同时将体积变得很小
可插入多帧，从而实现动画效果。
- 可设置透明色以产生对象浮现于背景之上的效果
- 由于采用了8位压缩，最多只能处理256种颜色，故不宜应用于真彩色图片

从GIF的背景知识中，还可以了解到：**GIF并不是简单地将多个图片合成到一起然后快速播放变成动图，而是有一套算法来计算每一帧各个像素点的数据**

### Loop count

loop count意思是GIF播放的循环次数

现在我们日常遇到的GIF，绝大多数都是一直循环播放的。但开发当中可能会遇到播放指定循环次数的情况，如何控制呢？

我结合上面GIF的基本背景知识和优秀第三方开源代码库YYAnimatedView、FLAnimatedView了解到：**GIF的循环次数是存储于GIF本身结构中的**

引用[为什么有的GIF图片只会播放一遍，而有的会重复播放？](https://www.zhihu.com/question/65916436)的一张图来说明：

![](https://pica.zhimg.com/80/v2-bc054c660eda17951c12295372da8ffc_1440w.webp?source=1940ef5c)

上图就是一个GIF动画的GCE部分结构的描述，31D一行表示的就是循环次数

同时我也注意到YYAnimatedView、FLAnimatedView两个库中，都没有设置loop count的功能，原因可能就在于此，不是没想到要添加设置loop count的功能，而是这个数据仅由数据源GIF自身决定

> 目前的GIF都是循环播放的，如果想自己制作一个播放指定次数的GIF可以使用PS或在线GIF制作网站[ezgif](https://ezgif.com/maker)

所以，文初的一个问题得以解释：**为什么YYAnimatedView的animationRepeatCount属性设置不起作用？**

- 因为animationRepeatCount属性其实是UIImageView的属性，YYAnimatedView继承了UIImageView，所以我们用YYAnimatedView时感觉可以通过animationRepeatCount来控制循环播放次数
- 其实GIF的循环次数存在GIF数据内部。YYImage遵循的YYAnimatedImage协议中有一个animatedImageLoopCount方法，就是用来获取某个动图数据源的循环次数的，使用GIF生成的YYImage可以通过该方法获取到正确loop count
- 这是YYAnimatedView作者对类似问题的回复-[animationRepeatCount 和 gif总帧数](https://github.com/ibireme/YYImage/issues/1)

如何获取GIF的loop count？

iOS原生框架ImageIO中提供了获取loop count的API。引用[iOS 获取gif图片循环次数和时长](https://cloud.tencent.com/developer/article/1133103)的部分代码：

```
//将GIF图片转换成对应的图片源
CGImageSourceRef gifSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
NSInteger loopCount;//循环次数
CFDictionaryRef properties = CGImageSourceCopyProperties(gifSource, NULL);
if (properties) {
    CFDictionaryRef gif = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
    if (gif) {
        CFTypeRef loop = CFDictionaryGetValue(gif, kCGImagePropertyGIFLoopCount);
        if (loop) {
            //如果loop == NULL，表示不循环播放，当loopCount  == 0时，表示无限循环；
            CFNumberGetValue(loop, kCFNumberNSIntegerType, &loopCount)
        }
    }
}
CFRelease(gifSource);
```

## WebP

WebP是一种同时提供了有损压缩与无损压缩（可逆压缩）的图片文件格式。Google于2010年9月30日首次公布WebP格式。WebP 2是Google自2021年6月起开发的新一代WebP。它的具体实现为libwebp2。这种新格式的主要目标是达到与AV1类似的压缩比，并同时保有更快的编码和解码速度。

- WebP的设计目标是在减少文件大小的同时，达到和JPEG、PNG、GIF格式相同的图片质量，并希望借此能够减少图片档在网络上的发送时间
- 根据Google较早的测试，WebP的无损压缩比网络上找到的PNG档少了45％的文件大小，即使这些PNG档在使用pngcrush和PNGOUT处理过，WebP还是可以减少28％的文件大小
- WebP有静态与动态两种模式。动态WebP（Animated WebP）支持有损与无损压缩、ICC色彩配置、XMP诠释资料、Alpha透明通道
- 2020年9月，在iOS 14和macOS Big Sur的Safari 14中加入了WebP支持

## 参考
- [iOS开发图片格式选择](https://zhangferry.com/2020/04/05/ios_photo_format_compare/)
- [iOS 动图优化实践](https://blog.wyan.vip/2022/07/iOS_Animated_Image.html)
- [How Flipboard Plays Animated GIFs on iOS](https://engineering.flipboard.com/2014/05/animated-gif)
- [为什么有的GIF图片只会播放一遍，而有的会重复播放？](https://www.zhihu.com/question/65916436)
- [GIF - 维基百科，自由的百科全书](https://zh.wikipedia.org/wiki/GIF)
- 好用的GIF制作网站-[ezgif](https://ezgif.com/maker)
- [iOS 客户端动图优化实践](https://mp.weixin.qq.com/s/MW14R1JfXRmQvgN2NNi3iA)





