# dealloc in Objective-C该怎么写

> 深入理解代替单纯记忆

本文编写时间为：2023年10月07日，此时最新iOS 系统版本为iOS 17

最近发现出现了因为重写dealloc书写不规范导致的线上问题，于是想扫除一下该知识盲点。

> 关于dealloc的话题，网上资料有不少。本文是参考并将相关知识点进行汇总和列举，没有自己创造的新观点和知识

## 关于dealloc必须要了解的知识点

- dealloc是当对象从内存中释放时执行的方法，由系统调用，开发者禁止主动执行
- 官方要求重写dealloc时中需要对对象类型的`instance variable`进行释放(如执行release方法)，且必须在方法最后执行父类的dealloc方法（ARC中编译器已自动完成这些工作）
	- 可以看出对象的释放过程是从子类到父类，最后到达`NSObject`
- dealloc可能执行在任何线程
	- 源码层面的分析可以参考[iOS摸鱼周报 第三十八期](https://mp.weixin.qq.com/s/a1aOOn1sFh5EaxISz5tAxA)
- 不能保证，在程序运行期间dealloc一定会被执行
	- 官方解释: **When an application terminates, objects may not be sent a dealloc message. Because the process’s memory is automatically cleared on exit, it is more efficient simply to allow the operating system to clean up resources than to invoke all the memory management methods.**

## dealloc中可以做什么 ✅

综合官方文档和[[Effective Objective-C 2.0](https://www.amazon.com/Effective-Objective-C-2-0-Specific-Development/dp/0321917014)，dealloc中**能且仅能**做的事有如下几个：

- 释放当前对象持有的支持ARC对象的引用(ARC已自动处理，开发者无需添加逻辑)
- 释放当前对象持有的不支持ARC的对象，比如CoreFoundation对象
- 若当前对象对其他内容注册为了观察者，需要移除观察者，如KVO、NSNotificationCenter等

## dealloc中不可以做什么 ❌

其实，除了上面**dealloc中可以做什么**部分提到的，其余的逻辑尽量都不要去尝试。下面列举几个易犯错的地方

- 不要使用accessor操作`instance variable`
- 尽量不要执行异步任务
- 不要释放系统的、稀缺的资源，如file descriptors, network connections, and buffers or caches 
- 尽量避免执行除**dealloc中可以做什么**以外的方法调用

以下部分对上面几点做详细解释

### 不要使用accessor操作`instance variable`

根本原因在于，accessor只是语法糖，其背后会触发方法调用（消息发送），消息发送在dealloc中存在各种不确定性

- 比如很可能有的类重写了set或get方法，里面的逻辑可能做了其他不允许在dealloc中做的事情
- 比如有的类会在get方法中使用懒加载方式初始化一个`instance variable`，那如果dealloc不消息执行到了懒加载方法，则会执行无意义的初始化工作，且还会增加代码出错风险

经典案例如下：

```
@interface HWObject : NSObject
@property(nonatomic) NSString* info;
@end
    
@implementation HWObject
- (void)dealloc {
    self.info = nil;
}
- (void)setInfo:(NSString *)info {
    if (info)
    {
        _info = info;
        NSLog(@"%@",[NSString stringWithString:info]);
    }
}
@end

@interface HWSubObject : HWObject
@property (nonatomic) NSString* debugInfo;
@end

@implementation HWSubObject
- (void)setInfo:(NSString *)info {
    NSLog(@"%@",[NSString stringWithString:self.debugInfo]);
}
- (void)dealloc {
    _debugInfo = nil;
}
- (instancetype)init {
    if (self = [super init]) {
        _debugInfo = @"This is SubClass";
    }
    return self;
}
@end
```

- HWSubObject实例释放时执行其dealloc方法，`_debuginfo = nil`之后`_debugiinfo`就被释放掉了
- HWSubObject的dealloc方法执行到最后，会执行父类HWObject的dealloc，`self.info`会走到子类的`setInfo:`
- `NSString stringWithString:self.debuginfo]`方法要求，string参数必须不为nil，但此时_debugInfo已经是nil，所以崩溃

### 尽量不要执行异步任务

dealloc方法结束后当前对象就释放掉了，此时如果异步任务还未结束，异步任务中但凡尝试访问释放掉的对象就crash

- 即使通过类似block等技术（如GCD中async系列方法）尝试捕获当前对象，也无法阻止对象被释放

> Note: 有的资料给出建议，可以使用一些同步方法（如performSelector）来完成异步的任务，这样就能避免当前对象被释放了。后面`GPUImage`的源码中有类似使用

### 不要释放系统的、稀缺的资源

- 因为dealloc的执行时机、执行线程都是由系统控制，而并不是我们能够控制和清晰了解的，所以对于稀缺资源，我们不能依赖于对象的生命周期来控制
- 如仍坚持这样做，那可能会导致系统资源延迟释放甚至一直无法释放，进而对整个应用产生影响

此时合理的做法是：提供主动释放稀缺的方法，外部使用者在资源使用结束时主动调用

### 尽量避免执行除**dealloc中可以做什么**以外的方法调用

查阅各种资料时，其实可以看出，dealloc执行过程中，其实系统已经进入对当前对象数据结构的清理过程了，此时的方法调用需要格外慎重，因为任何方法调用背后可能隐藏着各种业务逻辑，我们很难保证，这些逻辑都仅做了**dealloc中可以做什么**的事情


## dealloc中能否直接访问`instance variable`

先说个人观点：可以，但要注意间接影响

理由如下：

LLVM-Clang10官方[ARC文档](https://releases.llvm.org/10.0.0/tools/clang/docs/AutomaticReferenceCounting.html)明确表示：

> The instance variables for an ARC-compiled class will be destroyed at some point after control enters the dealloc method for the root class of the class. The ordering of the destruction of instance variables is unspecified, both within a single class and between subclasses and superclasses.

即`instance variable`的释放被延迟到了根类-`NSObject`的dealloc中

但，还是可能带来的间接影响，比如当对`instance variable`发送消息`[_xx someMethod]`时

- 如果`someMethod`做了一些不该在当前时机做的事情，那也会增加出问题风险

## 开源项目中dealloc是怎么写的

看一下几个优秀开源项目中，dealloc是如何写的，作为参考

### AFNetworking

```
// AFHTTPBodyPart
- (void)dealloc {
    // close方法为NSInputStream系统类所提供
    if (_inputStream) {
        [_inputStream close];
        _inputStream = nil;
    }
}

// AFNetworkActivityIndicatorManager
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_activationDelayTimer invalidate];
    [_completionDelayTimer invalidate];
}
```

### GPUImage

```
// GLProgram
// 几个shader都是instance variable
- (void)dealloc
{
    if (vertShader)
        glDeleteShader(vertShader);
        
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (program)
        glDeleteProgram(program);
       
}

// GPUImageToneCurveFilter
- (void)dealloc
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];

        if (toneCurveTexture)
        {
            glDeleteTextures(1, &toneCurveTexture);
            toneCurveTexture = 0;
            free(toneCurveByteArray);
        }
    });
}
```

### SDWebImage

```
// SDWebImageDownloader
- (void)dealloc {
    [self.session invalidateAndCancel];
    self.session = nil;

    [self.downloadQueue cancelAllOperations];
}

// SDWebImageImageIOCoder
- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
}
```

## Swift类的deinit是否也需要注意这些问题

Swift中在重写deinit时，要比OC简单一些

- 首先，Swift中没有accessor语法糖，所以就不存在直接、间接访问`instance variable`的问题。而且官方明确提到，deinit中property都是可以直接访问的
- Swift也是应用ARC，所以无需主动释放支持ARC对象类型；同样需要释放不支持ARC类型的对象
- 同样不建议执行异步任务，closure不会捕获当前对象
- 不要释放系统的、稀缺的资源

## 参考

- [Advanced Memory Management Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/MemoryMgmt.html)
- [Effective Objective-C 2.0: 52 Specific Ways to Improve Your IOS and OS X Programs-Item 31: Release References and Clean Up Observation State Only in dealloc](https://www.amazon.com/Effective-Objective-C-2-0-Specific-Development/dp/0321917014)
- [Effective Objective-C 2.0-Item 31中文翻译](https://www.cnblogs.com/chmhml/p/7337055.html)
- [LLVM-AutomaticReferenceCounting](https://releases.llvm.org/10.0.0/tools/clang/docs/AutomaticReferenceCounting.html)
- [iOS摸鱼周报 第四十四期-Dealloc 使用注意事项及解析](https://juejin.cn/post/7070009346070937636#heading-11)
- [ARC下，Dealloc还需要注意什么？](https://gitkong.github.io/2019/10/24/ARC%E4%B8%8B-Dealloc%E8%BF%98%E9%9C%80%E8%A6%81%E6%B3%A8%E6%84%8F%E4%BB%80%E4%B9%88/)
- [ARC中dealloc过程以及.cxx_destruct的探究](https://juejin.cn/post/7127581541567299615)