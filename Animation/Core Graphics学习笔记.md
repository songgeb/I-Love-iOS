# Core Graphics笔记

`Core Graphics` is known as `Quartz 2D`

两个坐标空间，`user space` 和 `device space`

> 我们在`user space`上画东西，然后由`Core Graphics`内部将内容投射到`device space`上，进行显示。

# Overview

UIview中的`draw`方法中，Core Graphics进行了绘画，是CPU参与了计算。如果需要频繁的重绘，应该用Core Animation，因为是GPU参与计算，性能好。

## painter model -> Page

1. 使用painter model往page上画东西，一个接一个，后面的可能会覆盖到前一个上。
2. 根据context不同，最终输出的Page也不同，比如printer、PDF等

## Drawing Destinations: The Graphics Context

`CGContextRef`表示不同的输出类型


## Graphics States

states用了stack结构来管理，`CGContextSaveGState`会让state压栈，`CGContextRestoreGState`则会触发出栈。

> 所以所有与state关联的属性，会被保存起来，restore的时候可以恢复并重新使用。像path，则不与state关联，也就无法保存了。具体哪些state被保存可以参考[官方文档](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_overview/dq_overview.html#//apple_ref/doc/uid/TP30001066-CH202-BBCGCGBA)

举个例子就容易理解了：

当我savestate时，state就被保存了起来。你后面再进行的设置color等操作，会保存在新的state中。这个新的state对老的并没有影响。restore后，老的state就回来了，之前的新的color也就没有了，被老的取代了。

## Quartz 2D Coordinate Systems

Quartz中有两个坐标系统，`user space`和`device space`

user space：`浮点类型数据，原点在左下角`。在上面执行各种绘画操作，该坐标系与显示的设备之前是独立的。

device space：不同设备上显示绘画东西的系统

两个坐标系关系：通过CTM（Current Transform Matrix），可以将user space的点映射到不同设备的device space中

CTM的另一个作用是：CTM通过变换改变坐标系统来实现绘画物体的平移、缩放、旋转等效果。

ctm可以参考[这篇文章](https://songgeb.github.io/2018/01/29/iOS%E4%B8%AD%E7%9A%84CGAffineTransform/)

## Memory Management: Object Ownership

用的是Core Foundation的MRC。

> Quartz中通过create/copy创建的对象要手动release。

如果需要持有某个对象，一般有和这个对象相对应的retain和release方法。也可以用全局的`CFRetain`和`CFRelease`方法。

# Graphics Contexts

## Drawing to a View Graphics Context in iOS

1. 在view的`drawRect:`方法中，通过`UIGraphicsGetCurrentContext`方法获取Graphics Contexts。
2. `drawRect`方法中的绘画操作都会自动应用到Graphics Contexts；如果在其他地方画的话，需要创建Graphics Contexts
3. draw不能直接调用，如果需要更新的话，可以调用setNeedsDisplay()。
4. setNeedsDisplay并不是直接调用draw，而是将view标记为`dirty`，下次刷新循环时才会更新。所以如果你在一个方法中连续调用多次setNeedsDisplay也不会触发多次刷新。

> 也不需要考虑坐标系问题，UIKit中虽然坐标系原点在左上角，和Core Graphics的坐标虽然不同，但UIView对坐标系做了调整，来匹配UIKit的坐标系统。

## Creating a Bitmap Graphics Context

## CGImage

CGImage数据不包含orientation

## Color and Color Spaces

### 开始

人眼能分辨出大约1000万中颜色

color space和color mode有啥区别？

彩色是怎样显示到屏幕上的呢？

对于液晶显示屏，自身并没有颜色，显示彩色实际上是通过彩色滤光片实现的。即在液晶前面会有rgb三色的彩色滤光片，rgb的彩色图像数据，输入到程序中，程序以此来控制不同亮度的光线投射到液晶面板上，彩色滤光片会吸收掉不希望显示的颜色所对应的波长的光线，剩下的透过滤光片显示到屏幕上。

如果你用放大器查看电脑显示屏中白色区域，你能够观察到白色确实是由红色、绿色、蓝色组成。

颜色模型并不只有sRGB、CMYK、YUV等，其实有好多种，至少有10+中。

#### Color Space
Apple’s ColorSync的颜色空间大概分为几类：

NOTE: alpha跟颜色空间应该没啥关系，alpha只是最后展示，计算的时候参与其中

1. 灰度空间
2. rgb类的空间，主要用于显示，是设备依赖的（即非设备独立）
    - HSV and HLS spaces也属于该类

3. cmyk类空间，主要用于打印输出，也是设备依赖的
    - cmy & cmyk空间都是
4. 设备独立的空间，比如L*a*b，主要用于颜色比较、转换
    - 也叫做CIE-based color spaces
    - L\*u\*v和L\*a\*b空间就是
    - Calibrated RGB & Calibrated gray是设备独立的
    - ICC & Generic Color Spaces都是设备独立的
    - **iOS不支持设备独立的颜色空间**
    - 通过`CGColorSpaceCreateWithName`创建的space是Generic Color Spaces
5. 命名颜色空间（Named Space），主要用于打印和图像设计
    - 里面是一些离散的颜色，不连续
6. Heterogeneous HiFi color spaces（完全不懂）

#### iOS只支持设备独立的颜色空间

- CGColorSpaceCreateDeviceGray
- CGColorSpaceCreateDeviceRGB
- CGColorSpaceCreateDeviceCMYK

#### Indexed Color Spaces & Pattern Color Spaces

- indexed color包括一个用颜色表，包括256个entry，还有一个基础颜色空间，每个entry在基础颜色空间中都有一个对应颜色值。（从概念上感觉很像伪真彩）
- pattern color？？？？

#### Setting Rendering Intent

这个rendering intent大概意思是，将context中的颜色空间显示到设备上时，如何进行转换的。其实是两个颜色空间之间的转换规则

- kCGRenderingIntentDefault
- kCGRenderingIntentAbsoluteColorimetric
    - 如果context的颜色值，落到了设备颜色空间的外面，那就取最接近这个颜色值且包含在设备颜色空间内的值。否则就一一映射
- kCGRenderingIntentRelativeColorimetric
    - 所有颜色值在转换后都会被更改，但具体怎么改，不知道
    - Core Graphics中除了bitmap相关的context，其他的都用这个intent
- kCGRenderingIntentPerceptual
    - 转换时会将落在设备颜色空间外的颜色值，压缩到内部。且保留什么关系
    - bitmap context默认用这个
- kCGRenderingIntentSaturation
    - 保留原始颜色的色彩保护度

#### HSV & HLS 

两个基于rgb的颜色空间

HSV是色调、色彩饱和度、亮度的简称，是一个描述一个颜色的三个维度

#### rgb

1. rgb是color mode，是几种光线的基色促成：红、绿、蓝。
2. rgb是增量式的颜色，一开始什么颜色的都没有，认为是黑色，rgb每个分量增加，颜色就越来越明显
3. 因为人感知光的细胞是三种视锥细胞，分别可以感知红色、绿色和蓝色。所以选择红绿蓝三色。
4. 格拉斯曼定律的实验反映了，rgb三色的叠加可以表示人类能够看到的所有颜色

sRGB是color space，使用的是rgb mode，是微软与20世纪90年代创建的，特别为互联网中颜色传输指定的标准；Adobe RGB也使用了rgb mode，是Adobe公司在1998年创建的，目的是让打印出来的和在屏幕上看到的颜色一致。

#### cmyk

cmyk这种color space，是由几种用于打印的基色组成：cyan（青色即蓝绿色）、magenta（洋红）、yellow、black

cmyk是减量式的颜色，不同颜色的墨水吸收不同波长的光线，剩下的不能吸收的光线则被反射到人的眼里，就是看到的颜色。

#### Pantone Matching System

这是一个燃料的颜色，更加贴近生活中看到的物品的颜色。由14中颜色染料构成。付费的。

#### cmyk vs rgb

RGB light combines to create white; whereas CMYK inks combine to form an imperfect black.
![](/images/Cmyk-rgb-add-sub.jpg)

#### 各种color space的颜色范围(gamut)


![](/images/gamut-comparison.png)

### alpha通道

最开始只有颜色空间如sRGB，而没有alpha通道。alpha通道的出现源自电影行业，电影行业中需要有透明的效果，在胶片电影时代使用化学方法，将多个背景、前景胶片合成到一起实现透明效果。后来数字电影出现，化学方法改为计算机计算的方法，但还是需要多个胶片进行合成，因为透明信息的胶片和影片胶片是独立存放的，合成使用时很不方便。这才促使将alpha通道技术的出现，即将alpha信息与影片、图像信息放到一起存储和计算。

加入alpha之后，当向一个context中绘制图形时，计算一个图形每个像素颜色值的每个分量(根据不同颜色空间值不同，比如sRGB)的公式是：

`destination = (alpha * source) + (1 - alpha) * backgroundcolor`

> `source`是新绘制图形的颜色值，`backgroundcolor`是context背景的颜色值。

- 在使用CoreGraphic绘制内容时，既可以通过context设置全局的透明度，也可以设置具体绘制内容的透明度
- 需要注意的是，如果既设置了全局透明，也设置了绘制内容透明时，那公式中**alpha值是两者的乘积**


#### 参考

- [RGBA-wiki](https://zh.wikipedia.org/wiki/RGBA)

### 参考

- [光子到显示器上的漫长之路--------数字图像显示原理](http://blog.csdn.net/lz0499/article/details/78138493)
- [光与色的故事---颜色模型浅析](http://blog.csdn.net/lz0499/article/details/77126717)
- [色彩空间基础](https://zhuanlan.zhihu.com/p/24214731)
- [Quartz 2D Programing Guide](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Introduction/Introduction.html)

## paths


## Transforms

> rotation旋转时，如果角度是正，则旋转方向是逆时针。

# Bitmap Images and Image Masks

bitmap image和image masks在Quartz中用`CGImageRef`类型(Swift中是`CGImage`)表示

## About Bitmap Images and Image Masks

1. bitmap是pxiel的数组
2. JPEG、TIFF、PNG图像都是bitmap图像
3. bitmap被限制为矩形图片，但因为可以使用alpha透明通道，所以也会生成不同形状的、选装等图像
4. bitmap的每个通道由1到32位组成

## Bitmap Image Information

### Decode Array

## Creating Images

### Creating an Image from a Bitmap Graphics Context

通过`CGBitmapContextCreateImage(context)`方法从bitmap graphics context中获取image。执行完该方法后，如果修改context并不会影响到image，因为该方法了一次拷贝。

> 小技巧：该方法并不一定每次都拷贝，只有后面修改context时才会拷贝。所以，如果有对image的操作，可以在修改context之前做完，这样不会发生真正的拷贝。

# 疑问

1. graphics context到底是个什么东西？怎么就能在上面画东西呢？graphics的state有是啥，出栈入栈啥意思？transform中的改变空间坐标是个么？
1. pdf context是resolution independent的，bitmap却是有resolution的。当bitmap的image画到pdf context中时，会收到resolution限制。这句话中基本都看不懂。
2. Premultiplied，为啥要将color component与alpha value相乘呢？