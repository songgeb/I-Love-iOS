# UnitTesting in iOS

## 什么是单元测试

单元测试是代码层面的测试，由研发自己来编写，用于测试“自己”编写的代码的逻辑的正确性。单元测试顾名思义是测试一个“单元”，有别于集成测试，这个“单元”一般是类或函数，而不是模块或者系统。

## 为什么要写单元测试？
写单元测试的过程本身就是代码 Code Review 和重构的过程，能有效地发现代码中的 bug 和代码设计上的问题。除此之外，单元测试还是对集成测试的有力补充，还能帮助我们快速熟悉代码，是 TDD 可落地执行的改进方案。

## 如何编写单元测试？

写单元测试就是针对代码设计各种测试用例，以覆盖各种输入、异常、边界情况，并将其翻译成代码。我们可以利用一些测试框架来简化单元测试的编写。除此之外，对于单元测试，我们需要建立以下正确的认知：

- 编写单元测试尽管繁琐，但并不是太耗时；
- 我们可以稍微放低对单元测试代码质量的要求；
- 覆盖率作为衡量单元测试质量的唯一标准是不合理的；
- 单元测试不要依赖被测代码的具体实现逻辑；
- 单元测试框架无法测试，多半是因为代码的可测试性不好。

### FIRST原则

引用自Raywenderlich

- Fast: Tests should run quickly.
- Independent/Isolated: Tests shouldn’t share state with each other.
- Repeatable: You should obtain the same results every time you run a test. External data providers or concurrency issues could cause intermittent failures.
- Self-validating: Tests should be fully automated. The output should be either “pass” or “fail”, rather than relying on a programmer’s interpretation of a log file.
- Timely: Ideally, you should write your tests before writing the production code they test. This is known as test-driven development.

## 单元测试为何难落地执行？

一方面，写单元测试本身比较繁琐，技术挑战不大，很多程序员不愿意去写；另一方面，国内研发比较偏向“快、糙、猛”，容易因为开发进度紧，导致单元测试的执行虎头蛇尾。最后，关键问题还是团队没有建立对单元测试正确的认识，觉得可有可无，单靠督促很难执行得很好。

## 什么情况下适合单元测试

该问题其实不仅限于单元测试，换做其他测试类型，都存在该问题，比如集成测试、UI测试、自动化测试

客户端的开发有时（但有些基础SDK则并非如此）比较侧重于UI/UX，这种功能原本编写测试就不太容易。再加上可能UI的变动比较频繁，所以编写测试的收益就比较低。因此，国内其实编写测试的团队很少

客户端与后端开发不同，后端更侧重于业务逻辑、算法等较容易验证的代码，所以更容易写测试代码

所以可以看到

- 后端开发语言的测试生态（如测试框架）相比客户端更完善
- Apple在iOS测试框架方面投入较少

由此，我们可以大致了解到哪些情况更适合编写测试

- 成熟的业务，用户量很大，稳定性要求很高，变动不频繁，不涉及过多的UI/UX，比如底层SDK

哪些情况不适合单元测试？

- 初创公司的初创产品，还没有多少用户，产品的研发速度高于质量时；正在做A/B试验的feature

## 专业术语
- sut：system under testing
	- 待测系统，被测对象
- fake object
	- 伪造对象，也可叫做mock object或stub object
	- 通常用于模拟某些场景所需的对象，但又不能真的修改源代码中的逻辑。可以通过继承创建一个只用于测试的类。也可通过一些编程原则来完成，比如依赖注入

## 举例

阅读了SDWebImage的测试用例，下面举几个例子，用于展示如何编写单元测试用例

- 简单的同步测试代码

```
- (void)test01ThatSharedDownloaderIsNotEqualToInitDownloader {
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    expect(downloader).toNot.equal([SDWebImageDownloader sharedDownloader]);
    [downloader invalidateSessionAndCancel:YES];
}
```

- 异步测试代码

```
XCTestExpectation *expectation = [self expectationWithDescription:@"Simple download"];
NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
[[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
      if (image && data && !error && finished) {
          [expectation fulfill];
      } else {
          XCTFail(@"Something went wrong: %@", error.description);
      }
}];
[self waitForExpectationsWithCommonTimeout];
```

- 需要自己创建Mock对象的情况。因为SDWebImage支持自定义ImageLoader，所以此处mock一个imageloader，验证protocol设计的是否合理，以及功能是否正常

```
- (void)test30CustomImageLoaderWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom image not works"];
    SDWebImageTestLoader *loader = [[SDWebImageTestLoader alloc] init];
    NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
    expect([loader canRequestImageForURL:imageURL]).beTruthy();
    expect([loader canRequestImageForURL:imageURL options:0 context:nil]).beTruthy();
    NSError *imageError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    expect([loader shouldBlockFailedURLWithURL:imageURL error:imageError]).equal(NO);
    
    [loader requestImageWithURL:imageURL options:0 context:nil progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        expect(targetURL).notTo.beNil();
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}
```

## 参考
- [28 | 理论二：为了保证重构不出错，有哪些非常能落地的技术手段？](https://time.geekbang.org/column/article/185684)
- [29 | 理论三：什么是代码的可测试性？如何写出可测试性好的代码？](https://time.geekbang.org/column/article/186691)
- [Why You Shouldn’t Write Tests (Yes, We’re Going There) - Dave Schukin](https://vimeo.com/235002959)
- [iOS Unit Testing and UI Testing Tutorial](https://www.raywenderlich.com/21020457-ios-unit-testing-and-ui-testing-tutorial)

