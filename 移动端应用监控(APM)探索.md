# 移动端应用监控体系探索

## 崩溃率

查阅了一些资料，崩溃率有几种表述形式

- PV崩溃率 = 应用发生崩溃次数 / 启动次数
	- 来自友盟
- crash users = 应用发生崩溃的用户数 / 总用户数
	- 来自Firebase Crashlytics
	- 友盟SDK中也称称为UV崩溃率

> 也搜到更详细的崩溃指标，比如参考文档中《一款代码质量好iOS应用，其崩溃率应该在多少之下？》提到通过更多角度的统计数据，可以得到用户更精确的感受

### 崩溃率达到多少才算合格呢？

根据有限的查阅，将崩溃率保持在万分之十(千分之一)以内，是比较优秀的

> 此处所说的崩溃率是指PV崩溃率

### 八卦

- 游戏应用崩溃率要明显高于其他行业应用
- 阅读类崩溃较少

### 参考
- [Crashlytics 故障排除和常见问题解答](https://firebase.google.com/docs/crashlytics/troubleshooting?platform=android#cfu-calculation)
- [扫盲贴|如何评价一款App的稳定性和质量？](https://info.umeng.com/detail?id=430&cateId=1)
- [一款代码质量好的iOS应用，其崩溃率应该在多少之下？](https://www.zhihu.com/question/46919352/answer/105375897)

## 参考
- [微信客户端团队负责人技术访谈：如何着手客户端性能监控和优化](http://www.52im.net/thread-921-1-1.html)
- [微信读书 iOS 质量保证及性能监控](http://wereadteam.github.io/2016/12/12/Monitor/)
- [移动端 APM 性能监控](https://my.oschina.net/u/4582626/blog/4384997)
- [Tencent/matrix](https://github.com/Tencent/matrix)