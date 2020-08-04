# WWDC-Image and Graphics Best Practices 笔记

内存、CPU消耗增多时，相应电量消耗也增多

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/imagebuffer_databuffer_framebuffer.png?raw=true)

- JPEG、PNG等格式都是压缩格式，在内存中是一段连续的`data buffer`
- 解码过程是要将`data buffer`转为`image buffer`
- `image buffer`和真正的图片大小成比例的，所以当是大图时，解码工作很耗CPU
- 解码工作由`Core Graphics`完成

## DownSampling

通过DownSampling，降低解码所占用内存大小

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/downsampling-1.png?raw=true)

- 说白了就是通过`Core Graphic`API获取到缩略图

## Decoding in Scrollable view

滚动scrollview同时加载多个图片时遇到内存、CPU激增，导致卡顿

在Collectionview的prefetching时机进行预处理，提前对图片进行解码工作，可以分散CPU占用情况

同时将解码工作放到后台线程，能减少卡顿

## 疑问

1. 通过autoreleasepool可否避免UIImage内存激增问题

## 参考

- [Image and Graphics Best Practices](https://developer.apple.com/videos/play/wwdc2018/219)