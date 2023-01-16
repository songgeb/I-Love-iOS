# Library, Framework in iOS--Part1

> 深入理解代替单纯记忆

本文示例使用的Xcode版本为13.4.1 

发现该部分内容还挺多的，先写第一部分，后序的有时间再搞：

- part1：主要介绍基本的概念
- 后序：尝试利用第一部分的基础概念
	- XCFramework
	- 理解Cocoapods对library的做了什么处理
	- 编译加速

> 强烈推荐阅读参考文献的第一篇

## 问题与目标

关于库(library)相关的知识的学习，可以深入到操作系统层面，但本文受作者能力所限，仅在日常开发的应用层面对一些常见且容易忽略或者难以理解的问题做记录

以下将列出几个常见的问题，本文将围绕这些问题展开讨论

- 常见的几个专业术语的含义和区别：library、framework、动态库、静态库
	- framework与两种库的区别是什么
	- 什么是Swift static library
	- 什么是umbrella framework
	- Xcode中的embed是什么意思
- Cocoapods、SPM(Swift Package Manager)是如何管理依赖库的
- 各大公司所提到的编译加速、组件静态化是指什么？

其实，关于上面这些问题，日常开发中还是比较常见的，只是绝大部分情况下都有专门的人为我们配置好了，我无需过多关注

但一旦其中出现问题，如果不了解的话，或者理解的不深入时，可能就很难解决问题或者无法找到更优的解法

## Library(库文件)

library翻译成中文可以叫做“代码库”或“库文件”

那些能够完成一些独立任务，并且这些代码是可以抽离为独立的模块的代码，比如常用的第三方代码库--SDWebImage、AFNetwork都是library

因为是独立的代码库，通常需要将主程序与library进行link(链接)建立联系后才能使用，根据链接形式的不同，library可分为dynamic library(动态链接库)和static library(静态链接库)

- 静态库在编译期间，会和程序其他源文件一并链接，最终合并到最后的可执行文件
- 所以，主程序是可以直接调用library中的逻辑
- 动态库则不会与主程序可执行文件打包在一起，是用到library时才会去加载library，比如可以在App启动时加载，也可以在运行时加载
- 因为动态库的特性，多个App可以共享一个动态库，事实上不论是Mac OS还是iOS，系统库就是通过这种形式来共享的
- 同时，因为iOS中App各自有自己私有的沙盒空间，基于安全的考虑，iOS 8之前是不允许开发者自己创建dynamic library的
- 但因为在iOS 8中引入了App Extension，所以出现了一个App中有多个程序的需要共享资源或代码的场景了。也就开始支持创建dynamic library了
- 在iOS中，static library的文件后缀名一般是`.a`，比如`libGoogleAnalytics.a`
- dynamic library文件后缀名则有`.dylib`或`.tbd`
- 不管是静态库还是动态库，都只是编译后的代码库，其中不包含任何资源文件，比如图片等，并且也没有办法将资源打包进去。（当然，如果将资源通过字符串的形式写死到代码中是可行的）

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/static_link.png?raw=true)

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/dynamic_link.png?raw=true)

### Create custom static library

简单说一下流程和容易出错的点，详细过程可以看[How to Create a Static Library using Xcode 11 - Objective-C](https://www.youtube.com/watch?v=WQI02KR9kQw)

1. 在Xcode新建工程页面选择`static library`类型，创建工程
2. 添加代码
3. 选择合适的架构，编译构建
4. 在编译结果目录找到`.a`和头文件，拷贝到主App中
5. 检查主App的targt配置是否正确
	1. Target-General下，`.a`是否拖入`Frameworks, Libraries, and Embedded Content`中
	2. Build Settings-library search path是否正确填写

#### 如何添加资源

因为无法像library中添加资源，通常当library自身需要用到资源时，我们可以在library的工程中添加一个bundle的target，将资源添加到bundle中。library中通过Bundle类获取资源

- 主要创建bundle时只有macos目录下有该选项，所以添加完后，记得将bundle的base sdk改为iOS

### Create custom dynamic library

- 前面提到，处于安全考虑，iOS 8之前其实苹果是不允许开发者创建dynamic library的，只有苹果自己可以创建
- 其实严格地讲，从iOS 8开始开发者仍然不能创建dynamic library
- 但是可以创建dynamic framework，而且必须将该framework嵌入(embed)到最终app包中才能让其他target（比如app extension）来共享该framework

> 关于dynamic framework，后文会讲到

## Framework

- 在iOS中，Framework是一个目录结构，其中可以包含动态或静态library，还可以包含各种资源文件
- 同时Framework也是个bundle，即这个目录结构必须满足bundle的要求，比如必须要有version等子目录
- 既然满足bundle的要求，就可以在代码中使用Bundle类来读取内容

既然Framework可以包含不同的library，所以也就分为static framework和dynamic framework了

- static framework是包含了static library的framework，dynamic framework则包含了dynamic library
- 注意一点，前面提到我们没办法创建dynamic library，但这里却可以创建dynamic framework

关于dynamic framework，要多说一点

- 在iOS中创建dynamic framework一般是想在一个App内不同target（比如App extension）共享library，而不是让设备中多个App共享library（事实上开发者也做不到，只有苹果系统的代码库才可以）
- 所以，为了在运行时能够动态地加载dynamic library，开发者必须告知App在哪里寻找这个dynamic framework
- 具体做法是，要将dynamic framework embed到app包中
- 这也就是Xcode中embed选项的作用，看下图

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/xcode_embed.png?raw=true)

- embed的选项只能决定，在构建时是否将framework或library嵌入到app包中，跟具体如何链接无关
- 换句话说，对于一个dynamic framework，开发者也可以选择不embed到app包中，结果就是运行时需要用到framework时发现找不到，崩崩崩

### Create custom dynamic framework

具体实现细节和示例代码建议参考--[Creating a Framework for iOS](https://www.kodeco.com/17753301-creating-a-framework-for-ios)

### Create custom static framework

关于framework, library部分，苹果官方的文档确实组织的不太方便查询。我发现官方文档中提到framework时，会说是用来包装dynamic shared library的，而并没有提到也可以包装static library

为了验证确实有static framework，我利用前面dynamic framework的代码示例，做了如下修改：

- 将framework的project->build setting->Mach-O type，改为Static Library
- 重新编译framework，得到static framework
- 主App中选择不将framework embed到App中

运行App观察结果

- 发现即使不将framework embed到App中，但framework中的功能依然可以正常运行
- 观察App包目录下，已经不存在framework的目录了，说明embed选项工作正常
- 同时观察主App可执行文件的大小，发现改为Static Library后，文件增大接近一倍
- 可以验证static library已经合并到可执行文件中了

## Library vs Framework

- 虽然理论上存在static library, dynamic library, static framework, dynamic framework，但实际可以使用或者常用的是static library, static framework和dynamic framework(embed)
- Framework相比于Library，它只是一种特殊的文件组织形式的目录，并不影响内部Library的链接方式

## 工具

#### 如何查看一个framework或library是静态库还是动态库

```
file CalendarControl.framework/CalendarControl

// 动态库
CalendarControl.framework/CalendarControl: Mach-O 64-bit dynamically linked shared library x86_64

// 静态库
CalendarControl.framework/CalendarControl: current ar archive
```

#### 如何查看一个framework或library支持的架构

`xcrun -sdk iphoneos lipo -info $(FILENAME)`

```
xcrun -sdk iphoneos lipo -info CalendarControl.framework/CalendarControl 

Non-fat file: CalendarControl.framework/CalendarControl is architecture: x86_64
```

## Debug

[Embedding Frameworks In An App](https://developer.apple.com/library/archive/technotes/tn2435/_index.html)文档列出了创建和配置自定义Framework时常见的一些错误和解决方案

# 参考文档
- [Introduction to static and dynamic, libraries and frameworks on iOS (and macOS)](https://bpoplauschi.github.io/2021/10/24/Intro-to-static-and-dynamic-libraries-frameworks.html)
- [Dynamic Library Programming Topics](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/OverviewOfDynamicLibraries.html)
- [Embedding Frameworks In An App](https://developer.apple.com/library/archive/technotes/tn2435/_index.html)
- [Library? Static? Dynamic? Or Framework? Project inside another project](https://stackoverflow.com/questions/15331056/library-static-dynamic-or-framework-project-inside-another-project)
- [Framework Bundles](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html#//apple_ref/doc/uid/10000123i-CH101-SW1)
- [Framework Programming Guide-Mac OS](https://developer.apple.com/library/archive/MacOSX/Conceptual/BPFrameworks/Frameworks.html#//apple_ref/doc/uid/10000183i)
- [Creating a Framework for iOS](https://www.kodeco.com/17753301-creating-a-framework-for-ios)
