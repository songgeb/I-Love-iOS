# iOS笔记

记录简单了解类型的知识点

## 热修复

### Native Language

早期iOS热修复框架，JSPatch比较有名。原理如下：

- 依赖Objective C runtime特性
- 服务端将要热修复的JavaScript补丁包下发到客户端
- 客户端通过iOS系统内置的JavaScriptCore执行补丁包代码，利用runtime特性动态创建类、替换、修改某个方法的实现，以达到热修复支持

缺点有：

- 后序JSPatch由于未知原因可能导致上架审核无法通过
- 必须依赖Objective C的runtime特性。无法直接热修复Swift、C、C++代码

后来，也出现了可以支持对纯Swift App的热修复方案：[Rollout](https://www.cloudbees.com/)和[SOT](https://www.sotvm.com/)

- SOT支持Swift、OC、C、C++的热修复，但收费，且不直到底层的实现原理
- Rollout仅支持Swift、OC的热修复
	- 根据其官方介绍和自己的猜测，其热修复原理大致是这样
	- 接入Rollout SDK后，根据配置信息，在App编译、链接过程中就会通过解析AST的方式在代码中（如某个方法）插入一些通用热修复代码
	- 这些热修复代码作用就是拉取相应的JavaScript代码，并执行

#### 参考
- [深入理解 iOS 热修复原理](https://www.jianshu.com/p/399f4a1212e9)
- [移动端热更新方案（iOS+Android）](https://www.jianshu.com/p/739c5c5160f1)
- [Rollout Swift Support - Under The Hood](https://www.cloudbees.com/blog/swift-method-swizzling)