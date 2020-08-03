# NSCache笔记

支持临时在**内存**中缓存对象

- 也是按照`key-value`对的形式存取数据、删除数据
- 内部也会根据设置和系统内存使用情况自动移除陈旧对象
- 区别于`NSDictionary`，不会将key进行copy
- 可以设置最大对象数和最大存储size，但内部不会一定按照这个设置清除陈旧对象
- api线程安全

## 实践

### SDWebImage 3.x
SDWebImage的3.x版本中，缓存对象`SDImageCache`，内部实际用的就是`NSCache`来做的内存缓存

只不过其内部又加入了基于文件的磁盘存储逻辑

具体的做法是继承了`NSCache`，初始化时同时监听了低内存警告的通知，当发生低内存警告时，会自动清理缓存中的图片

### SDWebImage新版
SDWebImage新版本中，`SDImageCache`进一步完善逻辑，分成`SDMemoryCache`和`SDDiskCache`两个实例

同时`SDMemoryCache`中还加入了一个新feature，如果`SDImageCacheConfig`中的`shouldUseWeakMemoryCache`是true的话，`SDMemoryCache`内部会维护一个`NSMapTable`的容器，除了在`NSCache`中缓存图片外，`NSMapTable`中还有一个弱引用指向图片。

当一些情况下`NSCache`中的数据被清除时，再次使用时，如果按照常规操作可能要去磁盘中取或者网络下载，但有可能图片本身还没有被释放，此时就可以使用弱引用直接拿到图片了

# 参考
- [iOS缓存 NSCache详解及SDWebImage缓存策略源码分析你要知道的NSCache都在这里](https://cloud.tencent.com/developer/article/1089338)