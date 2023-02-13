# iOS设计题之设计消息发送模块

> 该题目改编自[iOS应用架构谈 view层的组织和调用方案](https://casatwy.com/iosying-yong-jia-gou-tan-viewceng-de-zu-zhi-he-diao-yong-fang-an.html)中的一个内容

> 本文代码基于Swift 5

## 题目

当前有个聊天页面，需要支持发送文字、图片功能，文本直接发送即可，但图片发送功能有不同，需要：

1. 先从服务端获取一个资源ID
2. 然后通过该ID将图片上传到服务器
3. 最后将图片发送给对方

目前以上功能代码（如准备文字、图片，发送网络请求等逻辑）都写在聊天页面的ViewController中，后序可能还要支持发送音频、视频等功能，为防止后序页面代码膨胀不好维护，请给出优化方案

## 解题思路

该题目想考察的点在于，

- 有多个功能，且每个功能的实现细节不太一样，如何将他们从ViewController里拆分出去
- 如何做到好的扩展性，使得新增的音频视频功能可以无缝加入，尽量少地降低对已有代码的修改以保持较高的质量


### 将发消息逻辑抽离ViewController

这一步最容易想到，我们可以简单地将发消息逻辑抽离到一个单独类--MessageSender中，大致代码如下

```
class MessageSender {
  func sendText(_ message: TextMessage, completion: (Bool) -> Void) {
  }
  
  func sendImage(_ message: ImageMessage, completion: (Bool) -> Void) {
  }
  
  // MARK: - Image helper functions
  /// 申请资源ID
  /// - Parameter completion:
  private func applyResourceID(_ completion: (Result<String, Error>) -> Void) {
  }
  
  /// 上传图片，获得资源地址
  /// - Parameters:
  ///   - image: 图片
  ///   - completion:
  private func uploadImage(_ image: UIImage, completion: (Result<String, Error>) -> Void) {
  }
}
```

- 增加了对应的send方法来抽离发送逻辑
- 但，不满足扩展性的要求
	- 假设后序加入发送音视频逻辑，势必要在MessageSender中加逻辑
	- 这一方面导致MessageSender膨胀，同时也违背了开闭原则，增加了该类引发bug的风险

### 封装发送逻辑

那接下来的设计思路是，想办法将不同发送逻辑封装起来

```
class MessageSender {
  func sendText(_ message: TextMessage, completion: (Bool) -> Void) {
    let operation = TextOperation(message)
    operation.completion = { error in
      
    }
    operation.execute()
  }
  
  func sendImage(_ message: ImageMessage, completion: (Bool) -> Void) {
    let operation = ImageOperation(message)
    operation.completion = { error in
      
    }
    operation.execute()
  }
}

/// 不同类型消息发送逻辑的抽象基类
class MessageSendOperation {
  func execute() {}
}

class TextOperation: MessageSendOperation {
  private let message: TextMessage
  var completion: ((Error?) -> Void)?
  
  init(_ message: TextMessage) {
    self.message = message
  }
  
  override func execute() {
    print("send text message!")
    completion?(nil)
  }
}

class ImageOperation: MessageSendOperation {
  private let message: ImageMessage
  var completion: ((Error?) -> Void)?
  init(_ message: ImageMessage) {
    self.message = message
  }

  override func execute() {
    // apply resource ID
    // upload image
    print("send image!")
    completion?(nil)
  }

  // MARK: - Image helper functions
  /// 申请资源ID
  /// - Parameter completion:
  private func applyResourceID(_ completion: (Result<String, Error>) -> Void) {
  }

  /// 上传图片，获得资源地址
  /// - Parameters:
  ///   - image: 图片
  ///   - completion:
  private func uploadImage(_ image: UIImage, completion: (Result<String, Error>) -> Void) {
  }
}
```

在此方案基础上，如果需要新增一个发送视频的逻辑，需要做以下步骤：

1. 新增一个发送视频的Operation
2. MessageSender中加入sendVideo方法
3. ViewController中调用sendVideo

虽然仍然没办法做到完全符合开闭原则（对MessageSender做了修改），但毕竟都是新增代码，且在MessageSender中增加的代码比之前要少，所以出错概率也小

其实该方案中的MessageSendOperation，和iOS中的Operation是类似的，所以此处使用Operation也是完全ok甚至更好的选择

该方案的目的就是将发送逻辑通过某种形式封装起来，方便独立维护和复用

这个设计就有点像命令模式了

### 还有什么问题

有人可能发现上面代码存在问题：

- operation.execute()结束后operation会释放，导致任务执行后不能成功回调

确实有该问题，但为何还这样写？

因为真正的MessageSender其实远比上面代码要复杂，比如要考虑

- 支持多条消息并发
- 支持取消发送
- 支持发送失败后重试功能
- 消息过多时要考虑使用队列等类似逻辑避免内存爆炸

上面代码仅是在设计层面给出一个方向和示例，具体还有许多细节需要继续设计

## 为何不建议使用策略模式

[iOS应用架构谈 view层的组织和调用方案](https://casatwy.com/iosying-yong-jia-gou-tan-viewceng-de-zu-zhi-he-diao-yong-fang-an.html)中建议使用策略模式，经过一番查阅和思考，我对该思路有不同看法

先贴一下策略模式的定义

> Define a family of algorithms, encapsulate each one, and make them interchangeable. Strategy lets the algorithm vary independently from clients that use it.

策略模式核心思路是将同一个功能的不同策略封装起来，不同的策略在外部看来是同样的抽象（即可以无缝的替换）

这里面很重要的一点是--**针对同一个功能的不同策略**，暗含的意思是，不同的策略的输入和输出是一样的，比如卖同一个商品，但不同的活动对应着不同的折扣

而该问题中，不同消息的发送的逻辑，不能看做是发送功能的不同策略，不同消息的发送逻辑可能天差地别。

在代码层面上，不同消息的发送逻辑很难做到无缝的替换。就比如文章中给出的MessageSener的代码示例

```
@property (nonatomic, strong) NSArray *strategyList;

self.strategyList = @[TextSenderInvocation, ImageSenderInvocation, VoiceSenderInvocation, VideoSenderInvocation];

// 然后对外提供一个这样的接口，同时有一个delegate用来回调

- (void)sendMessage:(BaseMessage *)message withStrategy:(MessageSendStrategy)strategy;

@property (nonatomic, weak) id<MessageSenderDelegate> delegate;

@protocol MessageSenderDelegate<NSObject>

  @required
      - (void)messageSender:(MessageSender *)messageSender
      didSuccessSendMessage:(BaseMessage *)message
                   strategy:(MessageSendStrategy)strategy;

      - (void)messageSender:(MessageSender *)messageSender
         didFailSendMessage:(BaseMessage *)message
                   strategy:(MessageSendStrategy)strategy
                      error:(NSError *)error;
@end
```

- 由于使用了策略模式，所以就假定了不同发送逻辑（策略）的输入和输出一样了，所以sendMessage:withStrategy:方法使用了一个基类BaseMessage来将不同的消息进行抽象
- 那带来的问题是，执行具体的发送逻辑时，就不得不通过强制类型转换，转为具体的Message类型
- 另外，潜在的风险是，如果几个消息的发送逻辑的输入输出在后序基本保持一致那还好，一旦变动较大时，那可能MessageSender的send方法就得进行大的调整以适配这种变动

## 参考

- [71 | 命令模式：如何利用命令模式实现一个手游后端架构？](https://time.geekbang.org/column/article/224549)
- [iOS应用架构谈 view层的组织和调用方案](https://casatwy.com/iosying-yong-jia-gou-tan-viewceng-de-zu-zhi-he-diao-yong-fang-an.html)