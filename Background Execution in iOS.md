# Background Execution in iOS

> 本文写于2022年07月01日，此时iOS最新版本是15

## 为何要写这篇笔记

最近面试了一家公司，其中就问到了iOS中后台任务。

很惭愧，过去工作中几乎没接触过，所以没回答上来

事后复盘，发现过去的学习有一个问题：

- 对于通识性的知识了解不够
- 通识性的内容并不要求理解特别深入，但要知道能做哪些事情，比如AVFoundation大致能做哪些事情--拍照、录音、录像、视频剪辑
- 通识性的内容还有不少，列了几个，想到就加一点
	- App status，为什么要有这些状态，这些状态之间可以怎样切换
	- 后台下载，能不能一直在后台运行，一直在后台下载内容可以吗。iOS对权限控制的很严格，大致允许在后台做哪些事情
	- APNs，iOS的APNs能做到哪些事情
	- 什么是Extension，有哪些常见的Extension应用。Extension有哪些限制
	- iOS中的网页上的视频播放时看上去是打开了一个原生的播放器？
	- UIKit中的Dynamic是啥
	- App退出后视频还能播放是什么技术

> 也有人说，真正对iOS开发热爱的话，上面这些问题根本不需要记下来专门找时间去学。而是每次WWDC开会时就兴奋地熬夜看了
> 
> 不错，我很赞同。但
> 
> 不是每个iOS开发者都如此的热爱，很多人接受了十几年教育后可能都不清楚自己到底对什么感兴趣，这是教育的问题，扯远了。总之，有一句话叫做：如果能做到学我所爱那是最好不过，如不然，爱我所学同样也会有所成就

## 历史
- iOS 4(WWDC 2010)首次引入multitasking的概念
- iOS 7(WWDC 2013)调整了后台任务的执行时机，同时这才是真正的后台多任务
- iOS 9(WWDC 2015)中BackgroundModes中加入了Audio,  Airplay, and Picture in Picture
- iOS 13(WWDC 2019)引入了新的Framework--Background Tasks

### iOS 7之前

此时的后台任务功能还很单一，比如通过`beginBackgroundTaskWithExpirationHandler `方法也只能在后台执行短暂的任务，如果任务一直不完成会被系统自动挂起或杀死

仅支持如下几种后台任务

- 通过`- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;`方法可以后台执行代码
- 后台持续播放音乐--Audio
- 后台持续接收定位信息更新--Location updates
- Voice over IP，IP电话服务，也是持续的，就是前几年流行的网络免费电话
- Newsstand，后台更新杂志信息。iOS 13之后已经废弃，建议改用Remote Notification完成

#### 参考
- [Background Modes Tutorial: Getting Started](https://www.raywenderlich.com/5817-background-modes-tutorial-getting-started)

### iOS 7

### iOS 9

### iOS 13, Background Tasks

## 总结

## 参考
- [WWDC 2013 Session笔记 - iOS7中的多任务](https://onevcat.com/2013/08/ios7-background-multitask/)
- [Why is my app getting killed?](https://developer.apple.com/videos/play/wwdc2020/10078/)