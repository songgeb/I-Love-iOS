# App's lifecycle in iOS

App的生命周期中可能会有一些事件，比如点击App图标进入App时、按Home（上推HomeIndicator虚拟键）退出后台、使用APP
过程中有电话进入、点击App的通知时等，这时App可能需要处理一些事情，比如暂停播放中的音乐

本文便来介绍如何接收、处理这些事件

- iOS 13之后新增了基于场景(scene)的生命周期管理方式
- iOS12及更早App则只能用基于App的声明周期管理方式（App-Based Life-Cycle）

## Respond to App-Based Life-Cycle Events

该种生命周期管理方式的核心是`UIAppDelegate`对象，它会接收各种事件，并需要在其中进行响应任务处理

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/app-state_dark.png?raw=true)

- suspend状态，是在进入background状态一段时间后可能进入的状态。background状态是允许执行一部分任务的（如短暂的后台下载任务），suspend则不允许执行任务

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


## Respond to Scene-Based Life-Cycle Events
