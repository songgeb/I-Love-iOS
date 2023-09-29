# Background Execution in iOS

> 深入理解代替单纯记忆

> 本文写于2022年07月01日，此时iOS最新版本是15

## 历史
- iOS 4(WWDC 2010)首次引入multitasking的概念
- iOS 7(WWDC 2013)调整了后台任务的执行策略，同时这才是真正的后台多任务
- iOS 13(WWDC 2019)引入了新的Framework--Background Tasks

## iOS 7之前

此时的后台任务功能还很单一，比如通过`beginBackgroundTaskWithExpirationHandler `方法也只能在后台执行短暂的任务，如果任务一直不完成会被系统自动挂起或杀死

仅支持如下几种后台任务

- Background Task Completion
	- 通过`- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;`方法可以后台执行代码
- Background Audio
- 后台持续接收定位信息更新--Location updates
- Voice over IP，IP电话服务，也是持续的，就是前几年流行的网络免费电话
- Newsstand，后台更新杂志信息。iOS 13之后已经废弃，建议改用Remote Notification完成

### 参考
- [Background Modes Tutorial: Getting Started](https://www.raywenderlich.com/5817-background-modes-tutorial-getting-started)

## iOS 7

### Background Task changs

自iOS 7开始，后台执行任务从策略上进行了一次大的调整，该小节简述整个后台任务的核心策略思想（注意：此时Background Task并不是一个框架或者一个专有名词）

- iOS 7之前，进入后台后，App会保持一定的时间仍在运行
- iOS 7之后，进入后台后，App将会很快让App进行休眠，回收网络等资源，尽可能节省电量。但为了能够完成BackgroundTask，会在更合适的时机（比如下次系统应用Email尝试后台拉取邮件时）尝试给我们App的BackgroundTask资源和时间来执行任务

下图展示这个改变

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios-multitask-backgroundtask-ios6.png?raw=true)

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios-multitask-backgroundtask-ios7.png?raw=true)

> 如果在后台任务中，要执行网络传输工作的话，建议使用新引入的`NSURLSession`的background session。该部分后面会提到

### Background Fetch

- 系统提供了一个新的API，支持在后台拉取数据，并且可以更新UI
- 这一特性很适合用于内容消费类型的App
	- 传统的内容刷新可能是有个定时器，在每次用户从后台切换到前台时检查是否刷新
	- 刷新时用户需要等待
	- 其实刷新时机可以使用该特性进行提前，这样下次用户进入App时，内容就自动刷新了
- 对于Social Media、Weather、News、Finance、Blog类型App比较合适
- 系统会通过学习用户使用手机的习惯，在合适的时机执行BackgroundFetch逻辑

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios7-backgroundfetch.png?raw=true)

#### How to use Background Fetch

1. select Background Fetch Mode in project setting
2. set minmum background fetch interval
	- `application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)`
	- 默认值是`UIApplication.backgroundFetchIntervalNever`，表示不开启Background Fetch
	- 在AppDelegate的didFinishLaunch中调用即可
	- 该数值只是给系统的一个参考值，真正的执行Background Fetch的间隔由系统决定
3. implement AppDelegate中的`func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)`
	- 就是核心的数据获取和UI更新逻辑
	- 任务结束后要执行一些completion告知系统，以使得系统尽快回收资源

#### How to debug Background Fetch

因为Background Fetch由系统管理，调试问题不可忽视。苹果提供了两种方法

1. 可以修改the option of target's scheme，开启Background Fetch，则启动App后将会执行Background Fetch逻辑
2. Xcode的debug菜单中可以模拟一次Background Fetch

### Remote Notification

也是新增的一个特性

- 支持当有远程推送到达时，系统将应用启动，进入后台，并执行一些逻辑
- 同时也可以支持silent remote notification
	- App会收到推送事件，也会进入后台执行逻辑，但并不会有推送信息告知用户
	- 此时apns消息中需要移除alert字段

> silent remote notification的发送频率是受系统限制的，不能太频繁

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios-background-remotenotification.png?raw=true)

#### 应用场景

场景1：TV App下载Video

1. App通过silent remote notification在后台下载video
2. 下载ok后发送local notification告知用户
3. 用户打开App直接观看

### Backround Fetch vs Remote Notification

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios-backgroundfetch-vs-remotenotification.png?raw=true)

### Background Transfer service

- 其实就是NSURLSession提供了一个专门用于后台下载的类型
- 使用上和Background Fetch、Remote Notification挺像
- 也可以与其他的后台技术配合使用

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios-background-transfer-service.png?raw=true)

## Background Tasks

WWDC2019中引入了执行后台任务（Background execution）的新框架`BackgroundTasks`

- 引入新框架原因大概是，之前后台任务的API比较离散，使用起来不够统一
- `BackgroundTasks`则是对不同的后台任务进行了梳理分类，统一了统一的API和使用套路

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/ios-backgroundtasks-structure.png?raw=true)

- 整体上分为两类任务：BGAppRefreshTask和BGProcessingTask
	- BGAppRefreshTask是指那些需要获取数据刷新UI的
	- BGProcessingTask倾向于数据清理等操作
	- 新增了与BGProcessingTask对应的Background Mode
	- 对于BGAppRefreshTask，还是使用原来的Background fetch mode即可
- 工作流程大致如此
	1. 向BGTaskScheduler注册一个task，提供具体的任务逻辑
	2. 在合适的时机（一般是进入后台时），创建一个TaskRequest，提交到BGTaskScheduler
	3. BGTaskScheduler便会根据用户使用手机的习惯，在合适的位置执行这些任务

## 其他

其实我们在Xcode的配置中能发现，还有几个Background mode本文并未提及，这是因为与Background execution的关联不是太大，或者分散在了其他Framework中了。

此处做简要介绍

- Picture in Picture，翻译为画中画，是一个可以让视频以悬浮窗形式，离开App在Home页也播放的特性

## Q&A
1. iOS开发中支持的后台任务，与iPhone系统设置中的Background App Refresh区别是什么
	- 经过简单的测试发现，在代码中开启BackgroundModes中的Background fetch、Remote notification或Background processing时，系统设置中就会出现该App对应的Background App Refresh选项了
	- 所以Background App Refresh的意思应该是指那些可能在后台执行任务的总开关

## 参考
- [User Notifications](https://developer.apple.com/documentation/usernotifications)
- [WWDC 2013 Session笔记 - iOS7中的多任务](https://onevcat.com/2013/08/ios7-background-multitask/)
- [WWDC 2013 PPT-What’s New with Multitasking](https://devstreaming-cdn.apple.com/videos/wwdc/2013/204xex2xvpdncz9kdb17lmfooh/204/204.pdf)
- [Why is my app getting killed?](https://developer.apple.com/videos/play/wwdc2020/10078/)
- [Advances in App Background Execution](https://developer.apple.com/videos/play/wwdc2019/707/)