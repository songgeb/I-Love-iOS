# App's lifecycle in iOS

> 写本文时，最新iOS系统版本为15

App的生命周期中可能会有一些事件，比如点击App图标进入App时、按Home（上推HomeIndicator虚拟键）退出后台、使用APP
过程中有电话进入、点击App的通知时等，这时App可能需要处理一些事情，比如暂停播放中的音乐

本文便来介绍如何接收、处理这些事件

- iOS 13之后新增了基于场景(scene)的生命周期管理方式
- iOS12及更早App则只能用基于App的声明周期管理方式（App-Based Life-Cycle）

## Respond to App-Based Life-Cycle Events

该种生命周期管理方式的核心是`UIAppDelegate`对象，它会接收各种事件，并需要在其中进行响应任务处理

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/app-state_dark.png?raw=true)

### State

- NotRunning
- Inactive
	- 一个短暂的临时状态，比如App处在Active时有电话进入、系统弹窗等
	- 该状态下App是不能接收和处理用户的各种操作的
	- 该状态的意义在于，进入该状态时可能需要做些数据存储、资源释放等工作
- Active
	- App可以接收处理用户操作
	- Active和Inactive可以说都属于Foreground状态（虽然官方没有明确列出Foreground状态）
- Background
	- 通常是用户按下Home触发
	- Background状态是为后台任务准备的一个状态
	- 如果没有后台任务要执行，那在Background状态短暂停留就会进入Suspended状态
	- 如果有任务就执行，但官方不建议执行耗时太久的任务。除了必须持续执行的，比如导航
- Suspended
	- 此处状态下App不执行任何代码
	- 当设备内存紧张时，App可能在这个状态下被系统干掉，变为NotRunning

### State Transitions
大部分状态之间的转换容易理解，也有几个转换让人费解

- NotRunning -> Background
	- 官方说法：If your app requested specific events, the system might also launch your app in the background to handle those events.
- Suspended -> Background
	- The system may also launch an app directly into the background state, or move a suspended app into the background, and give it time to perform important tasks.
- Background -> NotRunning
	- Yes, iOS can and will kill an application in the background if it requires resources. Not to mention the app can crash on it's own, or the device can be restarted. from [this](https://developer.apple.com/forums/thread/696275)
- NotRunning -> Suspended
	- dont know

### Responding to App Life-Cycle Events

有以下几个回调方法构成

```
//Tells the delegate that the app has become active.
func applicationDidBecomeActive(UIApplication)

// Tells the delegate that the app is about to become inactive.
func applicationWillResignActive(UIApplication)

// Tells the delegate that the app is now in the background.
func applicationDidEnterBackground(UIApplication)

// Tells the delegate that the app is about to enter the foreground.
func applicationWillEnterForeground(UIApplication)

// Tells the delegate when the app is about to terminate.
func applicationWillTerminate(UIApplication)
```

同时以上事件也有对应的通知，可以在App中任意位置接收、处理这些通知

```
class let didBecomeActiveNotification: NSNotification.Name

class let didEnterBackgroundNotification: NSNotification.Name

class let willEnterForegroundNotification: NSNotification.Name

class let willResignActiveNotification: NSNotification.Name

class let willTerminateNotification: NSNotification.Name
```

### applicationWillTerminate
- 首先该方法执行时表示，App即将被系统干掉，回收内存
- 该时机下，有大约5s的时间处理事情
- 一个典型调用时机是，如果没有后台任务时，用户强制杀死App时会执行

## Respond to Scene-Based Life-Cycle Events

- 自iOS 13开始，Apple推出了multiple window(scene)的技术；简言之就是一个App进程可以有多个Window了；当然，目前该技术只支持在iPad系统上
- 代码层面上与iOS 13之前的工程相比，最直观的区别就是多了一个SceneDelegate的东西（实质上不仅如此）

> 本人没做过iPad应用的开发，只是通过一个tutorial简单的了解了一下

## 参考
- [Managing Your App's Life Cycle](https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle)
- [Adopting Scenes in iPadOS](https://www.raywenderlich.com/5814609-adopting-scenes-in-ipados#toc-anchor-007)
- [Architecting Your App for Multiple Windows](https://developer.apple.com/videos/play/wwdc2019/258/)