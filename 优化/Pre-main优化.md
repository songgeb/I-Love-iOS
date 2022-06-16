# Pre-main优化

> 深入理解代替单纯记忆

## WWDC2016-406-Optimizing App Startup Time

### pre-main

`main`方法之前都干了些什么事情，可以分为四步

>
1. dylib loading
2. rebase/binding
3. ObjC setup
4. initializer

- 内核将app和dyld加载内存
- 第一步从dyld加载dylib(动态库)开始，Dyld(dynamic loader)dylibs从app的header文件，然后递归的找到所有依赖的dylibs，然后将他们加载到内存中
- `Rebasing`和`Binding`
	- 是通过修改每个dylib内部区域，将dylib内部或与其他dylib依赖关系，建立连接
- ObjC setup
	- 通知OC运行时，建立类名和类的全局映射表，更新类的实例变量信息、添加category的方法
- initializer，执行`+load`
	- 所以`+load`方法在main之前就执行了
	- 但由于可能存在耗时任务影响启动速度，所以建议使用后执行的`+initializer`方法
- `main`执行

### 优化方案

官方建议，启动时间应该控制在`400ms`以内

这个时间标准不止包含`pre-main`的时间，也包括了从`main`方法到`AppDelegate.didFinishLaunch`方法的时间

- 通过`DYLD_PRINT_STATISTICS`和`DYLD_PRINT_STATISTICS_DETAILS`这两个环境变量可以查看pre-main用时

> `main`到`didFinishLaunch`这个过程加载了`nib`资源等工作

#### dylib loading

- 减少使用dylibs
- 可以合并多个功能类似的dylib

#### rebasing/bingding

- 可以通过`dyldinfo`查看绑定信息
- 这一步中主要是在dylib的`__DATA`的区域增加依赖dylib调用的指针
- 可以通过减少类数量来减少耗时
- 减少C++虚函数使用，因为也需要类似上面的操作
- 多使用Swift struct

#### initializer

- `+load`方法的操作移到`+initializer`中

## WWDC2017-413-App Startup Time:Past,Present,and Future

重写了dyld，从dyld2升级到dyld3

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/dyld3.png?raw=true)

- 将一些耗时工作分离到了单独的守护进程(`dameon`)中去做
	- dyld2中这些工作是在启动过程中做的
- 这些耗时工作的成果就是`launch closure`，并写入磁盘
- 应用程序启动时直接拿来用，无需重复做
- 对于系统应用，这些耗时工作会准备好数据并存入缓存中
- 对于其他应用，在应用安装或更新时，这些准备工作会做好，启动时直接用
- instruments新增了检测静态初始化方法的item-static initializer

## 参考
- [Optimizing App Startup Time](https://developer.apple.com/videos/play/wwdc2016/406)
- [App Startup Time: Past, Present, and Future](https://developer.apple.com/videos/play/wwdc2017/413)