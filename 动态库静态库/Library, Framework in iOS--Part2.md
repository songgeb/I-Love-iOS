# Library, Framework in iOS Part2

## Cocoapods中如何管理不同的library

前置条件：project, scheme, target, workspace

首次执行pod install后Cocoapods会产生ProjectName.xcworkspace，打开后发现有两个project：ProjectName和Pods

那Cocoapods是如何将App与Podfile中依赖的library建立依赖关系的呢？

我以一个叫做**Test-OC**的工程为例来展示，Podfile如下所示：

```
source 'https://github.com/CocoaPods/Specs.git'
#use_frameworks!
target "Test-OC" do
pod 'lottie-ios'
pod 'MJRefresh'
pod 'AFNetworking', '3.2.0'
end
```

通过观察工程的Target--Test-OC的依赖关系可以看到：

Test-OC依赖于`libPods-Test-OC.a`

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/Libraries/pod_app_link_staticpod.png?raw=true)

在Pods这个Project中可以找到`Pods-Test-OC`这个target

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/pod_staticlibrary.png?raw=true)

可以看出`Pods-Test-OC`是一个static library（mach-O type是static library且没有framework目录），所以是通过静态链接的方式与Test-OC链接的

再来看一下Pods的其他target

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/Libraries/pod_staticpods.png?raw=true)

- 发现Podfile中依赖的所有library都在Pods的Project中
- 且每个Pod都是static library

到这里我们能够了解到：Cocoapods创建了一个`Pods-Test-OC.a`，然后主工程依赖于该static library

但，现在我们还不清楚主工程是如何链接具体的Pod，而且还多了一个问题：

1. 主工程的`Link libraries`配置中并没有具体的Pod。主工程只是`link`了`Pods-Test-OC.a`，但`Pods-Test-OC`这个target中并没有继续去`link`每一个具体的Pod。所以主工程最终是如何`link`具体Pod的
2. `Pods-Test-OC`target的作用是什么

我们在主工程的`Build Settings`找到了答案：

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/Libraries/pod_app_otherlinkflag.png?raw=true)

可以看到`Other Linker Flags`部分添加了对所有Pod的链接命令

原来是在这里链接Pod的，可主工程怎么才能找到每个Pod对应的library呢？

一次偶然的机会让我大致找到了答案：

在一次执行`pod install`时，pod给出了一个警告：

```
[!] The `Test-OC [Debug]` target overrides the `LIBRARY_SEARCH_PATHS` build setting defined in `Pods/Target Support Files/Pods-Test-OC/Pods-Test-OC.debug.xcconfig'. This can lead to problems with the CocoaPods installation

- Use the `$(inherited)` flag, or
- Remove the build settings from the target.
```

意思是我的主工程build settings->library search path的配置覆盖了`Pods-Test-OC.debug.xcconfig`中library search path的配置。既然这样，那就看下`Pods-Test-OC.debug.xcconfig`中library search path的内容吧

```
LIBRARY_SEARCH_PATHS = $(inherited) "${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" "${PODS_CONFIGURATION_BUILD_DIR}/AFNetworking" "${PODS_CONFIGURATION_BUILD_DIR}/MJRefresh" "${PODS_CONFIGURATION_BUILD_DIR}/lottie-ios" /usr/lib/swift
```

所以，主工程是通过上面的路径来寻找具体的Pod对应的library的

至此，我们大概也就猜到了Cocoapods的工作流程：

- Cocoapods将每个Pod创建为一个static library的target
- 构建主工程时，通过修改`Other Linker Flags`和`Library Search Path`找到每个static library进行链接

至于另一个问题：Cocoapods为什么要创建了一个名为`Pods-ProductName`的target呢？

其实是为了对所有Pod进行统一配置和管理，比如：

- 为主工程配置`Library Search Path`提供数据来源
- 为每个Pod支持模块导入能力(modular)

### 其他

#### use_frameworks!
默认情况下Cocoapods是将每个Pod都创建为`static library`的target

Podfile中使用use_frameworks!后，变可以将每个Pod创建为`dynamic framework`

在Xcode 9之前，Xcode不支持将用Swift编写的Pod创建为`static library`。所以开发者不得不使用use_frameworks!。但如果太多的dynamic framework，可能大概率影响到启动速度

#### PodName-dummy.m

我们会在每个Pod的目录下都发现一个Cocoapods为它创建的PodName-dummy.m，其中仅创建了一个名为`PodsDummy_PodName`的空类，为什么这么做？

曾经出现过这样一个Apple的bug--[Building Objective-C static libraries with categories
](https://developer.apple.com/library/archive/qa/qa1490/_index.html)：当一个library只有category而没有具体的类时，主工程链接library时会出问题，导致运行时调用相应方法时找不到对应实现

对于该问题有两种解决方案：

1. 主工程的`Other Link Flags`中加入`-ObjC`（其实Cocoapods中也会通过`Pods-ProductName`这个target的配置文件为主工程加入）
2. 另一种就是可以在library中创建一个dummy class，主工程中无需初始化该类的对象，就能让链接正确。但个人测试后发现必须初始化对象才能work

所以，既然苹果建议使用`-ObjC`来解决，同时Cocoapods也添加了该标记，为什么仍然要创建dummy class呢？

暂时没搞明白

#### umbrella header

> 关于什么是Umbrella Framework/Header，可以参考下文

此部分我想对一个有争议的概念聊一下个人看法

当开启use_frameworks!时，发现每个pod的目录下都会有一个PodName-umbrella.h文件

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/Libraries/pod_dynamiclibrary_umbrellaheader.png?raw=true)

我在参考资料中了解到，添加该头文件的主要目的是为了让该pod支持模块导入(modular)能力，即Cocoapods会为该pod创建一个modular.map文件，其中会用到该文件

本文不会对modular进行详细介绍，简单来讲就是让主工程在使用pod时可以通过`@import ModuleName`的方式（而非`#import <Library/Library.h>`）引入，这种方式更好一些，那这个`umbrella.h`就是一个映射--在遇到`@import ModuleName`时就会自动关联`umbrella.h`中的所写的头文件

争议点在于，有人通过这个命名来得出该pod就是一个umbrella framework，我并不认同，因为umbrella framework是嵌套了其他framework的framework，此处显然不是。我认为只是一个普通的头文件，只是它包含了该pod中所有的公共头文件引入信息，所以用了一个umbrella单词而已

## Umbrella Framework or header



## 如何让library同时支持多个架构

## App Size, App start time

## target membership
1. 对于工程中的每个文件，这是Xcode的一个选项
2. 这个选项和target一一对应，如果选中则表示该文件是某个target的成员
3. 成为某个target成员，表示编译运行的时候，这个文件要作为源文件、资源文件（比如image），放到最终的app bundle中
4. 之所以header文件不能选择放到membership中，是因为头文件都是要在.m文件中引用的，在正式编译的时候其实头文件内容已经到.m文件中了。就没有必要重复的再往membership中放一次了

https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/XcodeBuildSystem/000-Introduction/Introduction.html#//apple_ref/doc/uid/TP40006904

## 疑问
2. 在接入一些代码库时，需要配置`header search path`或`Framework search path`，为什么？
4. 动态库相比静态库的优势在哪
4. 如何使用系统Framework
	- 为什么像`UIKit`这种动态库不需要在Xcode中额外链接
5. target membership是什么？为什么头文件、info.plist等文件不属于target membership.
11. 如何判断一个framework是否为umbrella framework还是standard framework
12. @import的使用，实践中如何用

## 参考
- [Clang Module](http://chuquan.me/2021/02/11/clang-module/#more)
- [系统理解 iOS 库与框架](http://chuquan.me/2021/02/14/understand-ios-library-and-framework/)
- [Objective-C categories in static library](https://stackoverflow.com/a/2615407/5792820)