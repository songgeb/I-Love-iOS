# Compatibility in Swift

作为一个对Swift历史不太了解的开发者，如何才能清晰的理解Swift中compatibility问题，比如

- 什么是ABI 稳定
- Swift编译器与Clang区别是啥
- 啥是Swift编译器兼容模式

粗看了几篇文章，不甚理解，正好一次面试中被问到了，于是想记录一下

## 编译器(compiler)

- 编译iOS程序的编译器是llvm
	- llvm是一个编译器和编译过程的项目，llvm不仅支持OC和Swift
	- 当然，编译不同的语言，需要用到不同的编译前端，编译前端是llvm的组成部分
	- OC对应的编译前端程序是clang
	- Swift对应的编译前端程序也叫Swift
- 编译器或者说前面提到的编译器前端的作用是什么
	-  预处理代码，比如将macro, import, include展开
	-  校验我们写的程序是否存在语法错误，并进行相应的错误，警告提醒
- Swift编译器(前端)版本是跟随Xcode的版本在更新的，且一个Xcode中只有一个Swift编译器

## Swift编译器兼容模式(compatibility mode)

Swift 4之前，Swift编译器(前端)只能编译对应版本的Swift语言开发的程序，简言之，就是Swift 3的编译器只能用来编译Swift 3开发的程序，如果是Swift 2开发的程序，是无法用Swift 3编译器来编译的，原因在于Swift 3的编译器在进行语法检查时是根据Swift 3语法标准执行的，Swift 3与Swift 2之间语法不兼容

自Swift 4和Swift 4编译器开始，引入了兼容模式

- 当选择使用兼容模式时，Swift编译器可以支持更早版本的Swift语法
- 比如Swift 4的编译器仍然可以编译Swift 3.2的程序
- 当然即使在兼容模式下，Swift 4的编译器仍然支持Swift 4的语法特性
- 这一选项就是通过Xcode->build setting->Swift Language Version控制的

## ABI稳定(ABI Stability)

ABI是Application Binary Interface的缩写，深入了解它确实需要汇编、操作系统等深入的知识储备。本文仅做简单描述

ABI顾名思义，应用程序二进制接口。可以和API对比着来理解，API是一个程序或SDK提供的一些函数、方法，ABI也是类似作用，只不过是更底层的函数，方法，协议或约定

ABI描述更底层的协议约定，比如我们程序中的对象如何在内存中申请空间，运行时系统包含哪些方法等，下面列出ABI包含的内容：

- Data Layout
- Type Metadata
- Mangling
- Calling Convention
- Runtime
- Standard Library

一个新的语言，除了要有基本的语法，还要有支持它运行的编译器和运行时等条件

所以，Swift 5之前，Swift的ABI一直不稳定，其中内容在不同的版本差异是比较大的

- 那时，一个用Swift开发的程序，打包后是需要将ABI内容打包进这个App包中的
- 也就是说，可能一个iPhone上，有多个App，每个App对应的Swift的ABI是不同的

自Swift 5开始，ABI则稳定了，由此带来的好处是

- 就是说只要是Swift 5或之后版本的编译器编译打包出来的App，都是ABI稳定的
- 所以也无需再将ABI程序、内容打包到App中，可以直接集成到iPhone的操作系统iOS中了，App的包体积会有明显的减少
- 因为所有App都将使用同一个Swift运行时、standard library，所以内存占用和启动耗时上也会有优化
- 官方给了一个例子，一个Swift 5编译器打包的App可以运行在Swift 5的运行时下，也可以运行在Swift 6的运行时环境下

## 参考
- [What is the "Swift Language Version" Xcode setting for? Because it still builds newer Swift code with an older version set](https://stackoverflow.com/questions/60177016/what-is-the-swift-language-version-xcode-setting-for-because-it-still-builds)
- [Swift 4.0 Released!](https://www.swift.org/blog/swift-4.0-released/)
- [Swift ABI 稳定对我们到底意味着什么](https://onevcat.com/2019/02/swift-abi/)
- [ABI Stability and More](https://www.swift.org/blog/abi-stability-and-more/)