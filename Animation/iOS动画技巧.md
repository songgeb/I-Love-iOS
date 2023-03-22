# iOS动画技巧

### 如何实现一个动画间隔n时间重复执行

默认情况下，一个重复执行的CoreAnimation动画，执行完一次，会立即执行下一次。如何做到两次执行之间间隔一定时间呢？

简单想了下，想到1种方案

- 通过监听单词动画的结束，重复创建添加动画

该方案可行，但问题是可能会出现两部分代码：动画本身的代码和监听、重复添加的代码，这多少会让动画显得不太高内聚

另一种更高内聚的实现是使用AnimationGroup，比如如下代码表示实际动画执行时长是0.5s，间隔1s中执行一次

```
let group = CAAnimationGroup()
group.duration = 1.5
group.repeatCount = Float(Int.max)
// 真正的动画内容
let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
// balabala
animation.duration = 0.5
group.animations = [animation]
layer.add(group, forKey: "key")
```