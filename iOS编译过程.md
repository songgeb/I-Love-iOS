# iOS编译过程

分前端和后端，前端编译器是Clang，后端是LLVM

- Clang是LVVM项目的一部分，都是由苹果开发
- 前端的编译工作是生成与机器无关的中间代码
- 后端的工作是对代码进行优化，根据不同架构产生不同机器码
- 如果要让编译器支持更多的语言，替换前端即可；若要增加支持的机器架构，替换后端即可

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/iOS_build_link.jpg?raw=true)

## 前端编译过程

### 预处理

预处理主要工作是一些替换工作，比如宏替换、头文件引入替换、条件编译指令(#if等)

### 词法分析（lexical anaysis）

对代码进行切词

### 语法分析（semantic analysis）

构建抽象语法树，对语法正确性进行验证，比如是否缺少括号

### 语义分析

语法分析只能根据语法树验证简单语法错误，具体的语义错误无法确认，比如类型检查，发送了一个未知的消息

### CodeGen

生成中间代码IR（intermediate representation）

ARC代码的插入、Property的自动合成在这一步进行

## 后端

### 代码优化

删除多余指令等

### 汇编（assemble）

经过汇编器，机器可以运行的机器码，产生`.o`目标文件

### 链接（link）

将所有目标文件和库文件链接，合并成可执行文件（Mach-O）

### 签名

## 运行

## 参考
- [点击 Run 之后发生了什么？](https://www.jianshu.com/p/d5cf01424e92)
- [iOS 编译知识小结](https://xiaozhuanlan.com/topic/2675849103)