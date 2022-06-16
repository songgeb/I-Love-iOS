# SDWebImage源码阅读笔记
> 深入理解代替单纯记忆

> 本文参考SDWebImage版本是5.8.4

## 目标

- 梳理清楚数据流过程
- 对其中重要的细节，比如解码，编码插件逻辑要熟悉

## 应用场景



## 过程

1. 从`UIImageView+WebCache.h`分类中的`setImage`方法开始
2. 进入`UIView+WebCache.h`的方法，这里直接调用`SDWebImageManager`的loadImage方法
3. `SDWebImageManager`中根据情况
	- 先去缓存(imageCache)中取数据，
	- 若取不到或必须现下载的话，就调用imageLoader的下载方法
	- 返回`SDWebImageCombinedOperation`类型数据，支持cancel方法
4. `SDWebImageManager`中通过`imageLoader`进行下载，默认情况下是`SDWebImageDownloader`

## UIImageView+WebCache

## UIView+WebCache

- sd_latestOperationKey
- sd_operationDictionary
	- 类型是`SDOperationsDictionary`，就是一个`NSMapTable<strong, weak>`
	- 用于存放operation
- sd_imageURL
	- `NSURL`类型，存放本次图片加载的url
- sd_imageProgress
	- 图片
- sd_imageIndicator
	- protocol-SDWebImageIndicator类型
	- 用于加载图片过程中显示

## SDWebImageManager

- failedURLs: Set\<URL>
	- 在内存中记录曾经请求失败的url，当再次请求时不予处理
- runningOperations: Set\<SDWebImageCombinedOperation>
- imageLoader: id\<SDImageLoader>
- imageCache: id\<SDImageCache>

### loadImageWithURL

核心的加载图片方法

1. 加载图片核心方法，返回一个`SDWebImageCombinedOperation`，存入runningOperations中
2. 先根据情况去缓存器中找，然后再考虑是否下载
3. 下载结束后还会进行缓存操作
4. 执行结束后从runningOperations中移除

### feature
1. 支持通过协议的方式自定义图片加载器和缓存器

## SDWebImageCombinedOperation

- cacheOperation: id\<SDWebImageOperation>
- loaderOperation: id\<SDWebImageOperation>

## SDWebImageOperation

一个重要的协议

- 该协议只有一个`cancel`方法
- SDWebImageCombinedOperation
- SDWebImageDownloaderOperation
- SDWebImageDownloadToken
- 上面三个都有遵循该协议

## SDImageCache

### 内存缓存
内存缓存部分使用了系统的`NSCache`，该部分在另一篇文章《NSCache笔记》中有提到，此处不再重复

### 磁盘缓存
- 磁盘缓存的底层实现是直接往沙盒中写文件
- 删除过期文件的策略
	- 首先根据`shouldRemoveExpiredDataWhenEnterBackground`的配置，默认是YES
	- 若上面配置是YES，则在app进入后台时会进行清理数据操作
	- 清理数据按照给定的两个配置，最大缓存时长和最大存储文件size
	- 读取每个文件的修改日期信息（此处也可以指定文件的创建日期等配置），若该文件上次修改时间距离现在已经超过了最大缓存时长则清理
	- 当剩余的文件size仍然超过最大存储文件size时，按照修改时间再清理一波
	- 当然，如果app收到`terminate`通知，会强制清理一波，清理逻辑和上面一致

## SDWebImageDownloader

- URLOperations: NSMutableDictionary\<NSURL *, NSOperation\<SDWebImageDownloaderOperation> *> *
- downloadQueue: NSOperationQueue

### 核心逻辑

1. 创建一个`NSOperation<SDWebImageDownloaderOperation> *> *`类型的operation，并添加到downloadQueue中执行，同时添加到`URLOperations`中
2. operation结束后，从`URLOperations`中移除，同时执行添加到operation中的progress和completionhandler

### 其他feature
1. 通过config可配置自定义的下载operation--`NSOperation<SDWebImageDownloaderOperation> *> *`
2. 自己也可以当做独立的图片下载器来使用

## SDWebImageDownloaderOperation类

- typedef NSMutableDictionary\<NSString *, id> SDCallbacksDictionary;
- callbackBlocks: NSMutableArray\<SDCallbacksDictionary *>
	- callbackBlocks中存放的是progress和completionhandler
- coderQueue: NSOperationQueue
	- 用于解码图片的queue
- 进行实际网络请求的核心operation
- 继承自`NSOperation`，实现了`SDWebImageDownloaderOperation`协议
- 异步执行的`NSOperation`
- 可以添加多个progress和completion handler

## SDWebImageDownloaderOperation协议

开发者可以自定义下载的operation，只要遵循该协议，就可以应用到`SDWebImageDownloader`中


## SDWebImageDownloadToken

- 遵循了`SDWebImageOperation`协议
- weak downloadOperation: NSOperation\<SDWebImageDownloaderOperation>
- weak downloadOperationCancelToken: id
从`SDWebImageDownloader`的request方法返回的就是这个对象

## 图片解码

通过两个全局函数来解码

- `SDImageLoaderDecodeImageData`
- `SDImageLoaderDecodeProgressiveImageData`

默认情况下，图片解码时机是在`SDWebImageDownloaderOperation`中，下载结束后

## 亮点

### 面向协议
1. 通过context和各种协议支持高度自定义
	- `SDImageLoader`支持自定义图片加载器
	- `SDWebImageDownloaderOperation`支持自定义图片下载逻辑的operation，官方使用`NSURLSession`，我们可以自定义用非session的方式
	- `SDImageCache`支持自定义缓存器

## 疑问
1. 官方的`how to use`文档以给cell的图片赋值为例，但并没有执行cancel方法，会不会有问题？
	- 一般来说问题不大，因为同一个view再次通过setimage设置图片时，会将之前的operation取消掉
	- 但最好在cell的prepareforreuse中cancel一下，一方面可以及时的取消下载请求等逻辑，另一方面我们假定复用的cell在出现之前一定调用了一次setimage的情况下才可以正常work，但这个过程不一定准确
2. `UIView+WebCache`中，为什么从`SDWebImageMutableContext`中移除`SDWebImageContextCustomManager`定义的自定义manager
3. 如何使用的`NSURLCache`
5. 嵌套这么多会不会有内存泄露问题
	- 不会
	- UIView中使用了`NSMapTable<strong, weak>`类型关联对象，所以不会强引用operation
	- 再往内层就是SDWebImageManager了，它的runningOperations确实强持有了operation，但结束后会释放
6. 借鉴学习一下`SDWebImageDownloaderOperation`内部的网络请求实现

## 理解练习

下面的代码，最终imageView会显示哪个图片？同时会出现什么情况？

```
for i in 0..<10 {
	imageView.sd_setimage(url)
}
```

> 不会出现图片闪烁情况，因为对于同一个imageView，每次setImage之前都会先cancel掉之前的请求
