# Swift Package Manager(Swift PM)笔记

- `Package.swift`定义了Package或Module的源码、依赖等信息
- `Package.resolved`中是最终工程依赖库的版本信息，类似于Cocoapods中的Podfile.lock
- 添加Package Dependency的方式
	- 通过Xcode添加

## Q&A
1. SPM的工程能否进行混编？
	- 可以
2. SPM的工程能否使用OC的library
3. SPM工程和Cocoapods工程能否共同存在
	- 实测可以

## 参考
- [Package Manager](https://www.swift.org/package-manager/)
- [Adding package dependencies to your app](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)