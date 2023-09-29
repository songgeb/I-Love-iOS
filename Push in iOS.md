# Push in iOS

> 深入理解代替单纯记忆

时间节点：写本文时（2023年09月17日），当前稳定版本是iOS 16，最新的iOS 17正式版本即将上线

本文重点内容是iOS中的Push（推送），本文尝试回顾Push的发展过程以及Framework、API的演进。期望通过综述这些发展过程，能帮助自己和其他开发者

- 从宏观视角看待iOS中Push的能力范围
- 了解不同API的使用方式，更容易上手工程

写本文时的一些疑惑：

- Push分为本地推送和远端推送
- Push自iOS ？开始就存在
- iOS 10之前，推送部分的API属于UIKit？
- 从iOS 10开始，Apple推出了一个新的Framework--User Notifications，来支持推送的能力


## API

### `application(_:didReceiveRemoteNotification:)`

- 目前已经废弃，应用与iOS 3- iOS 10
- 执行时机
	- 根据官方说明，当App在前台运行时，收到Remote Notification时调用该方法
	- 当App没有运行时，收到通知后，用户点击了通知，会在application:willFinishLaunchingWithOptions: o和application:didFinishLaunchingWithOptions:中携带通知内容启动App；同时该方法依然会执行
	- **但是**，经过测试，至少在iOS 15.7.3中，后台情况下发送Remote Notification，该方法依然会执行

### `application:didReceiveRemoteNotification:fetchCompletionHandler:`

- iOS 7引入的API

## 疑问
1. Push从iOS几开始支持？
2. PushKit Framework是做什么的？
3. 什么是 notification center history、Scheduled Summary
4. App在前台时到底能不能收到通知，能收到什么样的通知，屏幕顶部的可以吗？
	- 在前台可以收到通知，并且可以通过自定义来显示顶部通知
5. 什么是actionable notification
6. 远程推送触发的application:willFinishLaunchingWithOptions:，是什么时候执行？推送到来时？还是用户点击时


## 参考
- [Human Interface Guidelines-Managing notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications)