# Target, Project, Workspace, Scheme in Xcode

## Project

- Project就是一个仓库，存放着各种文件，如源码、library，build configuration、target等
- Project中可以有多个target
- Project可以有build configuration，可以应用于所有的target，target也可以自定义自己的configuration
- Project既可以独立存在，也可以加入到Worksapce中

### SubProject
- 可以在一个Project中嵌套Project

## Target

- 一个Target对应着一个product，这个product可以是很多类型，比如App, App Extension, library, framework等
- Target是build的基本单元
- 每个Target都有自己的build configuration，默认情况下也会继承Project的配置
- 在一个Poject或Workspace下，不同target之间是可以建立显式或隐式的依赖关系的

## Workspace

- Workspace是一个Xcode document，用来组织projects和其他documents
- 相关的Project可以放在一个Workspace下
- 一个Project也可以放到不同的Workspace下
- 所有Project的build结果都会在同一个目录下
- 因此Workspace中不同Project之间建立依赖关系，查看function definition，重命名等操作时都会因为自动indexing而受益

## Scheme

中文翻译为“方案”

An Xcode scheme defines a collection of targets to build, a configuration to use when building, and a collection of tests to execute.

翻译一下就是，target的build等操作时的配置信息，就当前Xcode版本(13.4.1)来说，这些操作有：

- Build, Run, Test, Profile, Analyze, Archive

所以，每个target都对应着一套配置信息

当然，每次只能选择一个Scheme进行build或其他操作

## 参考

- [Xcode Concepts](https://developer.apple.com/library/archive/featuredarticles/XcodeConcepts/Concept-Targets.html#//apple_ref/doc/uid/TP40009328-CH4-SW1)