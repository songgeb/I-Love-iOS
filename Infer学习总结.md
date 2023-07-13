# Infer学习总结

近期(2023年4月-5月)，尝试安装使用了静态代码扫描工具Infer，扫描工程中Objective C存在的潜在问题，本文总结记录一下Infer的安装过程和遇到的问题，以供参考，方便自己也方便其他人

安装环境：

- 电脑：MacBook Pro，芯片：Apple M1 Pro
- 操作系统：macOS 13.3.1 (a) (22E772610a)
- Xcode版本：14.3 (14E222b)
- Infer版本：1.1.0


## Infer

Infer是Facebook开发的一个开源的静态代码扫描工具

- 目的是在代码进行扫描，分析代码中潜在的风险如内存泄漏，并支持多种方式输出给用户如html、json
- 支持：C、C++、C#、Java、Objective C语言编写的程序，并支持增量扫描，无需每次都全量扫描代

基本工作流程

1. 先通过编译工程，得到编译日志
2. 提取编译日志中的源文件信息，分析程序抽象语法树，根据规则判定是否存在风险代码

基本分析原理

该部分很有意思，借鉴了一些牛批的算法，怎奈我看不懂-- [翻译:Facebook Infer 基础原理](https://zhuanlan.zhihu.com/p/455279066)

使用举例

如果编写如下代码，则Infer在扫描中会发现有内存泄露问题

```
@interface ABC : NSObject
@property(nonatomic, strong) id<ABCDelegate> delegate;
@end
```

## 安装使用时遇到的问题

汇总一下安装和使用过程中遇到的问题，及对应的解决办法

### 安装相关

详细的安装教程官方readme中有介绍，理论上是比较简单的

一般有两种安装方式：安装binary或通过源码安装，Mac用户推荐使用`brew install infer`直接安装binary

但，大概是2022年下半年的某个时间开始，对于M1芯片的苹果电脑，使用`brew install infer`时会报错

**Error: infer has been disabled because it does not build!**

原因不清楚，解决办法是，有人将infer代码库fork后进行了修改并发了兼容的版本-- [Instabug/infer](https://github.com/Instabug/infer/releases/tag/v1.1.0)

> 要注意，安装Instabug/infer和官方Infer还是有区别的，后续使用时会提示找到不到某些文件或者命令，比如可能会提示找不到`clang_wrappers/global_defines.h`目录下的文件，其实这个文件是存在的，只是目录和要求的不一样，通常这种问题的解决方案就是将需要的文件和目录copy到要求的位置就可以了，毕竟我是没能力直接改源码，将要求的位置写正确

### 使用相关

主要用到命令如下

1. 清理工程目录

	```
	xcodebuild -workspace $myworkspace -scheme $myscheme  -configuration Debug -sdk iphones clean || (echo "clean failed")
	```

2. 编译工程生成编译日志xcodebuild.log文件

	```
	xcodebuild -workspace  $myworkspace -scheme $myscheme -configuration Debug -sdk iphoneos COMPILER_INDEX_STORE_ENABLE=NO | tee 	xcodebuild.log
	```

3. 根据编译日志生成编译数据compile_commands.json文件
	
	```
	xcpretty -r json-compilation-database -o $compileFile < xcodebuild.log > /dev/null
	```
	> 没安装xcpretty的可以通过`gem install xcpretty`安装 

4. 基于编译数据compile_commands.json文件进行静态分析
	
	```
	infer run  --no-xcpretty --skip-analysis-in-path Pods --keep-going --compilation-database-escaped $compileFile || (echo "infer run failed")
	```
5. 将分析结果生成html网页，方便查看
	
	```
	infer explore --html
	```

#### clang-15: error: unknown argument: '-ivfsstatcache'

在执行上面静态分析步骤时可能会有该错误，因为

## 如何选择检测问题类型

该部分将介绍下常见的可以检测的问题类型，以及选择哪些检测类型


### MULTIPLE_WEAKSELF

An Objective-C block uses weakSelf more than once. This could lead to unexpected behaviour. Even if weakSelf is not nil in the first use, it could be nil in the following uses since the object that weakSelf points to could be freed anytime. One should assign it to a strong pointer first, and then use it in the block.

以下代码经过扫描会给出警告，原因在于block中的逻辑可能涉及多出用到weakSelf，weakSelf可能在任意情况被置为nil，所以我们不确定block中哪些跟weakSelf相关的方法调用执行了哪些没有被执行，这种行为会给程序带来不确定性

```
@weakify(self);
[instance doSomething:^{
	[weakSelf doOtherThing];
}];
```

### DEAD_STORE

This error is reported in C++. It fires when the value assigned to a variables is never used.

e.g.

```
int i = 1; i = 2; return i;
```

- 实际使用中，对Objective C程序，会产生很多改问题数据，并且完全没有用处

### UNINITIALIZED_VALUE

未初始化变量就使用的情况

- 但误报太多

## 总结

- 相比于OCLint等其他静态代码扫描工具，Infer可用性上更佳
	- Infer比于OCLint，没那么多的扫描规则，更简便，且产生的无需修改的问题要比OCLint少很多，仅会输出较为严重的问题
	- Infer相比于Xcode自带的Analyze，功能有更丰富
- 维护成本高，Infer缺乏维护
	- 官方对该开源项目的维护频率并不高，目前Gihub上待解决的问题已经接近400个
	- 所以，一旦语言对应的编译器有变动时，Infer无法及时做适配工作，随时面临Infer无法工作的风险
	- 同时，在使用体验上发现，Infer同样也会产生很多无需修改、甚至是错误的问题结果，这可能跟内部的检测算法逐渐落后于对应语言的新特性有关
- 好在静态代码扫描工具的应用场景并不频繁
	- 一般一个版本开发中扫描几次就够了，不会像Code Review一样频繁
	- 同时，对于技术水平较高的团队，该工具同样使用频率很低，牛逼工程师写优雅的代码只是基础操作而已
- 对于iOS场景，建议逐渐抛弃Objective C，用Swift开发，同时使用SwiftLint进行静态代码扫描

> 忘了在哪看到一句话：很多团队连编译器提的warning都不处理，你还指望处理静态代码扫描的问题？

## 参考

- [infer](https://fbinfer.com/)
- [OCLint + Infer + Jenkins + SonarQube 搭建iOS代码静态分析系统](https://juejin.cn/post/7070041773900300318#comment)
- [infer 静态代码扫描学习 总结](https://testerhome.com/topics/30910)
- [jenkins 进行 infer 静态扫描，给工作群发送报告通知](https://testerhome.com/topics/30912)
- [07 | Clang、Infer 和 OCLint ，我们应该使用谁来做静态分析？](https://time.geekbang.org/column/article/87477)
- [not support Apple M1 ?](https://github.com/facebook/infer/issues/1410)
- [Instabug/infer](https://github.com/Instabug/infer/releases/tag/v1.1.0)
- [Support xctool as a build tool](https://github.com/facebook/infer/issues/9)
- [翻译:Facebook Infer 基础原理](https://zhuanlan.zhihu.com/p/455279066)