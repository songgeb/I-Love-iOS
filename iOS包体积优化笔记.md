# iOS包体积优化笔记


## 如何得到包体积大小

### 苹果官方建议

> 该部分内容基本是翻译了参考中官方文档

首先，以下几种查看大小的方式都是不准确，且官方不建议的：

- Xcode编译结束后的App bundle
- 通过Xcode archive后的包
- 上传到App Store Connect上的IPA文件

之所以上面的包不准确，

- 一方面因为包中可能包含了一些最终不会出现在用户设备上的资源如DSYM和图片等；
- 另一方面，相比于上传到App Store Connect的文件，最终App Store中的文件大小可能会增加，苹果可能会增加一些防盗版、压缩等处理

苹果官方建议的获取包大小的方案有：

- Create an app size report
- Gather infomation from App Store Connect

![](https://docs-assets.developer.apple.com/published/8f5ee51a35acc3bf93bf2fc7d0c55653/reducing-your-app-s-size-1@2x.png)

- Create an app size report这一方法可以在开发电脑上，有Xcode就可以搞定的
- 而且也可以通过命令的方式，将该过程自动化，或集成到持续集成中

![](https://docs-assets.developer.apple.com/published/18e290971c5b775a3c34264f44a972c6/doing-basic-optimization-to-reduce-your-app-s-size-1@2x.png)

- file assets
	- using asset files instead of putting the data into your code
	- such as, use a property list for bundling any data with your app instead of using strings in code

![](https://docs-assets.developer.apple.com/published/b1a7494fa1ea9b2f09cd33a1f2d74702/doing-advanced-optimization-to-further-reduce-your-app-s-size-1@2x.png)

- Reduce the size of app updates
	- 系统在从App Store中更新App时，不总是下载完整App而是会更新update package
	- 减少不必要的修改，会降低update package的大小
- on-demand resoures
	- 将不常用或需购买使用的资源延迟提供
	- 既可以通过苹果提供的延迟提供机制，也可以通过自己的服务器延迟下载

### LinkMap

依赖Xcode链接程序时生成的LinkMap文件：

- 其中描述可执行文件的构成
- 根据其中的信息能够知道不同模块，不同类在可执行文件的大小

## 难点

1. 随着App业务变多，如何监控不同业务模块每次迭代带来的包体积增量（LinkMap）
2. 对于OC代码，一些代码调用是通过runtime，很难通过简单的静态扫描来甄别哪些类或资源没有使用

## 疑问
1. 何为png无损压缩？
2. 安装包超过150MB不能通过OTA下载，只能WIFI环境？
	- 我理解OTA跟WIFI不是对等且相反的概念吧？
3. WebP比PNG、JPG好在哪
4. HEIC比WebP好在哪
5. 官方文档中提到一个场景：对于用户引导这种feature，明显是不常用的，如何通过苹果官方的机制来延迟下载使用呢？

## 参考
- [iOS微信安装包瘦身](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ==&mid=207986417&idx=1&sn=77ea7d8e4f8ab7b59111e78c86ccfe66&scene=24&srcid=0921TTAXHGHWKqckEHTvGzoA#rd)
- [Reducing your app’s size-Apple Document](https://developer.apple.com/documentation/xcode/reducing-your-app-s-size)
- [10 | 包大小：如何从资源和代码层面实现全方位瘦身？](https://time.geekbang.org/column/article/88573)