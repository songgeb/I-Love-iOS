# 《iOS开发高手课》Note-App启动速度如何优化与监控


## Launch Process

From the WWDC, there are three iOS launch types: Cold、Warm、Resume

- Cold: App is not in memory. No App process exists.
- Warm: App is partly in memory. No App process exists.
- Resume: App is in memory. App process exists.

> Launch Process below is referred to Cold Launch Process

The Cold launch process can be divided into three parts in sequence:

- pre-main
- from main method to welcome page shown
- after welcome page shown

### pre-main

pre-main refers to the time period from the time when the user taps the App icon to the execution of `main` method

- load executable file 
- load dynamic libraries
- initialize runtime(Objective C and Swift)
	- `+load` method

What can we do to optimize this part?

- avoid linking unused frameworks 
- limit the number of dynamic library
	- Apple
- avoid unecessary `+load` codes  or move codes from `load` to `initialize`
	- `initialize` is called after `main`

### Main to Welcome Page Shown

- system creates UIApplication, UIAppDelegate and call relative callback method, for example, `didFinishLaunching`
- prepare welcome page data
- display welcome page

How to optimize?

- only prepare for welcome page, avoid other tasks

### After welcome page

The main task is initialization, such as initializing SDK, database, etc

In order to optimize the time

- defer these tasks as much as possible

## How to monitor or measure the time of launch 

- Time Profiler


## Q&A
- 什么是动态库？启动时都要加载哪些动态库？
- 如何合并动态库，合并就能提高速度了？

## References
- [02 | App 启动速度怎么做优化与监控？](https://time.geekbang.org/column/article/85331)
- [Optimizing App Launch](https://developer.apple.com/videos/play/wwdc2019/423/)
- [grab
/
cocoapods-pod-merge](https://github.com/grab/cocoapods-pod-merge)
- [iOS 性能优化 - TimeProfiler分析代码耗时](https://blog.csdn.net/Hello_Hwc/article/details/84311933)
- [如何精确度量 iOS App 的启动时间](https://www.jianshu.com/p/c14987eee107)
- [美团外卖iOS App冷启动治理](https://tech.meituan.com/2018/12/06/waimai-ios-optimizing-startup.html)