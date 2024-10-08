# KVO Crash in iOS

## KVO Crash for NSURLSessionTask.state

- NSURLSessionTask.state中的cancel不一定仅执行一次

## 问题

### kvo只要发生在子线程是否都可能存在问题？

```
- (IBAction)buttonAction:(id)sender
{
    #pragma unused(sender)
    [self performSelectorInBackground:@selector(recalculate) withObject:nil];
}

- (void)recalculate
{
    while ( ! self.cancelled ) {
        [... calculate ...]
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.cancelled = YES;
    // race starts here
}
```

> Similar problems can arise when you use key-value observing (KVO) to observe the isFinished property of an NSOperation. While KVO does not retain either the observer or the observee, it's still possible that, even if you remove the observer in your -viewWillDisappear: method, a KVO notification might already be in flight for your object. If that happens, the thread running the notification could end up calling a deallocated object!

- 以上代码和内容摘自苹果官方文档-[The Deallocation Problem](https://developer.apple.com/library/archive/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11)
- 上面的代码想要说明的是
	- recalculate中访问了self，且在子线程中执行，viewWillDisappear在主线程中执行
	- 如果后者先结束，前者后结束，那self即当前ViewController则最终会在子线程中释放，导致其dealloc在子线程中执行，如果dealloc中写了使用UIKit的代码，则可能有问题
- 内容部分的意思是，类似的问题也可能发生在kvo场景下
- 比如，如果我们通过kvo对NSOperation的isFinished属性进行监听

## 参考
- [KVO background threads](https://stackoverflow.com/questions/9154721/kvo-background-threads)
- [Receptionist Pattern](https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/ReceptionistPattern/ReceptionistPattern.html)
- [99% 的 iOS 开发都不知道的 KVO 崩溃](https://juejin.cn/post/7193677784097488933)