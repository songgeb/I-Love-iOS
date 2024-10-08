# 《WWDC2024 Session-Analyze heap memory》学习笔记

该Session主要对于堆上开辟的内存可能遇到的几种常见问题进行分析，同时介绍了一下可以使用的分析工具以及开发建议

## Transient growth

翻译为“瞬时的内存增长”

该文中给出了一个例子：

- 一个for-loop(循环)代码，每次loop接收一个本地图片的url，读取图片数据，转为缩略图

![](https://cdn.jsdelivr.net/gh/songgeb/picx-images-hosting@master/20240930-120456.1sf0je5hd0.webp)

创建缩略图的部分代码如下所示：

![](https://cdn.jsdelivr.net/gh/songgeb/picx-images-hosting@master/20240930-120524.8l025uvori.webp)

- 可见107行代码耗费了6.7G内存，内存占用过大
- `render.faultThumbnail`中仅仅是使用了`PhotoThumbnail.image`即最终的缩略图结果

这样会带来什么问题？

- 通过`makeThumbnail`的实现可以知道最终返回的`PhotoThumbnail`对象是要通过AutoreleasePool管理的
- 所以对象的释放时机要等到AutoreleasePool释放时，至少不是在for-loop过程中
- 所以在for-loop过程中将会产生多个内存占用很大的临时对象(`PhotoThumbnail`)，进而持有着大量的比较耗内存的`imageData`
- 于是就会出现瞬时内存占用的峰值，从Xcode内存可视化监控上来看如下图所示：

![](https://cdn.jsdelivr.net/gh/songgeb/picx-images-hosting@master/20240930-120549.2doo5ozxnd.webp)

通过主动添加`Autoreleasepool`方式优化后：

```
for loadThumnails(with render: ThumbnailRender) {
	for photoURL in urls {
		autoreleasepool {
			render.faultThumbnail(from: photoURL)
		}
	}
}
```

- 将`PhotoThumbnail`对象释放时机提前，效果如下：

![](https://cdn.jsdelivr.net/gh/songgeb/picx-images-hosting@master/20240930-120544.2rv3wk88ik.webp)

### 经验

- 在编写loop代码时，要注意过程中是否会产生autoreleased的对象，导致瞬时内存增长

## Persistent growth

翻译为内存“持久的增长”，正如字面意思，app中可能会出现问题导致内存占用在一直增加。使得内存的走势呈现阶梯状

可以通过`Instrument`中的`Allocation`工具，通过打点(`Mark Generation`)方式，记录问题发生过程中，新开辟了哪些对象

Session当中，Apple工作人员演示了一个有意思的事情：

- 通过`Mark Generation`找到可疑对象
- 通过对象地址，在Xcode Memory Graph中找到对应对象，分析其被引用关系，最终确定原因：缓存失效，导致每次加载缩略图都会将图片放入缓存，导致内存持久增长
- 我发现Xcode Memory Graph中，选中对象后能够看到对应到代码中的属性名等具体信息，相比以前也丰富了

![](https://github.com/songgeb/picx-images-hosting/raw/master/20240930-173129.6pnhdk5w5w.webp)

## MallocStackLogging
Apple介绍了Xcode的`MallocStackLogging`功能

在`Diagnostics`中开启`MallocStackLogging`后，在`Xcode Memory Graph`中便能看到每个对象alloc时的call stack

![](https://github.com/songgeb/picx-images-hosting/raw/master/20240930-172124.6pnhdjsyy2.webp)

## Memory leak

可以通过Xcode Memory Graph中检测到内存泄漏

- Xcode Memory Graph无法检测所有的内存泄漏
	- 因为有些不确定类型不确定用途的指针引用是允许的 
	- 比如使用Unsafe形式主动开辟的控件

## Perfermance

该小节列举几个可以降低内存占用的技巧

- weak和unown的在内存占用和性能方面有所差异，可以根据情况选择
- 定义类型时少用reference type、any、copy on write类型

![](https://github.com/songgeb/picx-images-hosting/raw/master/20240930-170351.6t73b91yvc.webp)

## 其他

- 尽管在进行`Profile`时推荐使用Release环境+真机设备，但对于heap内存的调试，模拟器环境和真机也是比较接近的，可以使用模拟器代替

## 参考
- [Analyze heap memory](https://developer.apple.com/videos/play/wwdc2024/10173/)