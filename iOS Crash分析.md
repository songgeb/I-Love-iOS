# iOS Crash

大致分为三类crash:

- 上层NSException，可以通过NSExceptionCaughtHandler捕获到
- 通过Unix内核信号捕获到的crash
- 无法捕获到崩溃

信号捕获不到的崩溃有：

- 进入后台时，由于某些原因被系统强杀
- OOM导致系统强杀
- 主线程卡顿时间过长导致系统强杀

### 异常编码

- 0x8badf00d，表示 App 在一定时间内无响应而被 watchdog 杀掉的情况。
- 0xdeadfa11，表示 App 被用户强制退出。
- 0xc00010ff，表示 App 因为运行造成设备温度太高而被杀掉。

## Q&A

1. 系统在后台杀死App的原因是什么？
	- 是因为后台任务在规定时间内无法完成导致的吗？
	- 如果是后台一些关键数据读写出了问题，很可能导致后序App的更严重体验问题

## 参考
- [12 | iOS 崩溃千奇百怪，如何全面监控？](https://time.geekbang.org/column/article/88600)
- [深入iOS系统底层之crash解决方法](https://www.jianshu.com/p/cf0945f9c1f8)
- [深入iOS系统底层系列文章目录](https://www.jianshu.com/p/139f0899335d)
- [深入iOS系统底层之XCODE对汇编的支持介绍](https://cloud.tencent.com/developer/article/1192667)