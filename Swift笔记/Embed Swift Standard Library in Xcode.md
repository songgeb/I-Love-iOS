# Embed Swift Standard Library in Xcode 1

## Swift Standard Library

首先要了解什么是Swift Standard Library

感受一下来自官方[Standard Library](https://www.swift.org/documentation/standard-library/)原汁原味的说法：

> The Swift standard library encompasses a number of data types, protocols and functions, including fundamental data types (e.g., Int, Double), collections (e.g., Array, Dictionary) along with the protocols that describe them and algorithms that operate on them, characters and strings, and low-level primitives (e.g., UnsafeMutablePointer). The implementation of the standard library resides in the stdlib/public subdirectory within the Swift repository, which is further subdivided into:
> 
> Standard library core: ...
> 
> Runtime: ...
> 
> SDK Overlays: ...

简单总结一下，Swift 	Standard Library是支持Swift程序运行的基础代码库，包含三部分：

- Standard library core，包含了Swift语法中的基础数据类型、协议、方法的定义
- Runtime，运行时环境代码，用于支持Swift中的一些运行时特性，比如as、reflection、memory management。使用C++和Objective C语言开发实现
- SDK Overlays，针对苹果系统平台的中间层，比如用于处理OC和Swift相同数据类型的映射工作

有一张图能够比较清晰的描述Swift、Swift standard library还有Foundation代码库的关系

![](https://cdn.jsdelivr.net/gh/songgeb/picx-images-hosting@master/swiftstandardlibrary.2yy8pwlov5.webp)

## Embed Swift Standard Library

将`Swift Standard Library`embed到哪？---当然是App包中了

为什么要embed到App包中呢？----因为Swift在5.0版本之前ABI不稳定

### 什么是ABI
ABI(Application binary interface)

>In computer software, an application binary interface (ABI) is an interface between two binary program modules. Often, one of these modules is a library or operating system facility, and the other is a program that is being run by a user.

> An ABI defines how data structures or computational routines are accessed in machine code, which is a low-level, hardware-dependent format. In contrast, an application programming interface (API) defines this access in source code, which is a relatively high-level, hardware-independent, often human-readable format. A common aspect of an ABI is the calling convention, which determines how data is provided as input to, or read as output from, computational routines. Examples of this are the x86 calling conventions.

> Adhering to an ABI (which may or may not be officially standardized) is usually the job of a compiler, operating system, or library author. However, an application programmer may have to deal with an ABI directly when writing a program in a mix of programming languages, or even compiling a program written in the same language with different compilers.

![](https://cdn.jsdelivr.net/gh/songgeb/picx-images-hosting@master/Linux_API_and_Linux_ABI.svg.3d4ogsze65.webp)

- 与API定义类似，API是两个library之间互相调用时源码层面的interface，ABI是源码经过编译后的二进制数据的interface
- ABI更底层，它定义了在机器码层面的数据结构、执行规范，甚至是与硬件相关的数据格式
- ABI通常是编译器、操作系统或者代码库开发者所要考虑的事情，因为这些代码比较底层，上层应用程序依赖它们，它们的设计和稳定性影响到所有上层应用
- 注意这句话(compatible ABI can be guaranteed, machine code becomes portable)，一旦ABI的兼容性可以保证了，那机器码就变得可移植了

Swift作为一门语言，也是一个庞大的library，也有ABI，也存在ABI兼容性是否稳定的问题

### ABI不稳定会怎样
- Swfit 5.0之前的版本，是ABI不稳定，即不兼容的
- 简单讲就是使用Swift 3.0开发和编译的程序，到了Swift 4.0（先不考虑4.0和3.0语法层面不兼容的问题），Swift 4.0下的编译器无法编译3.0的程序，也无法使用在4.0下的Swift Standard Library中的代码、runtime等
- 简单讲3.0的程序无法在4.0环境下运行


这个对于开发者来讲其实不希望的，我用iOS 10 sdk开发的一个iOS App，结果没办法运行在iOS 11、12系统上，这太崩溃了

那怎么解决呢？

终于引出了Embed Swift Standard Library的概念：

- 不兼容不要紧，我直接把所有依赖的代码库都打包的App中，安装到用户设备上，这样总可以运行了吧
- 这就是embed xxx的含义了

如何实现的呢？

在Xcode->Build Setting中，有一个选项叫做"Always Embed Swift Standard Library"，开启这个选项后，最终打出的安装包中就包含了Swift Standard Library

- 当然，这会增加安装包体积

理想情况应该是怎样呢？

### ABI稳定

自Swift 5.0/iOS 12.2开始，ABI稳定，那则意味着：

> ABI stability for Apple OSes means that apps deploying to upcoming releases of those OSes will no longer need to embed the Swift standard library and “overlay” libraries within the app bundle, shrinking their download size; the Swift runtime and standard library will be shipped with the OS, like the Objective-C runtime.

- Swift 5.0开始，Swift Standard Library其实是会内嵌到操作系统中，所有程序使用它就好了

![](https://www.swift.org/assets/images/abi-stability-blog/abi-stability.png)

- 如图所示，一个Swift 5编译的程序，可以运行在5.1和6.0的standard library上

## 还有什么？
- 还想再做试验验证"Always Embed Swift Standard Library"选项对于包体积影响


## 参考
- [Standard Library](https://www.swift.org/documentation/standard-library/)
- [ABI Stability and More](https://www.swift.org/blog/abi-stability-and-more/)
- [Evolving Swift On Apple Platforms After ABI Stability](https://www.swift.org/blog/abi-stability-and-apple/)
- [Build settings reference](https://help.apple.com/xcode/mac/11.4/#/itcaec37c2a6)
- [Application binary interface](https://en.wikipedia.org/wiki/Application_binary_interface)
- [Swift foundation vs standard library?](https://stackoverflow.com/questions/62119815/swift-foundation-vs-standard-library/73843146#73843146)
- [Swift Run Time Library vs. Swift Standard Library](https://stackoverflow.com/questions/43622223/swift-run-time-library-vs-swift-standard-library)
- [Please explain the purpose of Always Embed Swift Standard Libraries](https://stackoverflow.com/questions/63859267/please-explain-the-purpose-of-always-embed-swift-standard-libraries)