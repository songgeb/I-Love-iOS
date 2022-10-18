# 《RxSwift, Reactive Programing with Swift》笔记

读完第一章节(31页)，脑子中是满满的疑惑：似懂非懂的感觉，感觉概念不容易理解，可能实践太少了


## Operators

### skipWhile

> There’s a small family of skip operators. Like filter, skipWhile lets you include a predicate to determine what is skipped. However, unlike filter, which filters elements for the life of the subscription, skipWhile only skips up until something is not skipped, and then it lets everything else through from that point on.

![]()

### flatMap

### combineLatest

This has many concrete applications, such as observing several text fields at once and combining their values, watching the status of multiple sources, and so on.

### withLatestFrom

Simple and straightforward! withLatestFrom(_:) is useful in all situations where you want the current (latest) value emitted from an observable, but only when a particular trigger occurs.

## Q&A
1. 为何一订阅就
2. shared observable purpose
	- 如何验证