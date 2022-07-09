# Timer in iOS

The "timer" word in title represents the time-related technique in iOS, Timer, GCD Timer, CADidplayLink, say.

## Timer

Timer class in Swift(NSTimer in Objective c)

- based on Runloop
	- stopped when runloop stopped, such as in background state
	- not accurate, because there may be heavy task in runloop or system may introduce tolerance to reduce power usage
- For repeating timers, the next fire date is calculated from the original fire date regardless of tolerance applied at individual fire times, to avoid drift.
- General rule, set the tolerance to at least 10% of the interval, for a repeating timer
- runloop has astrong reference to timer
	- memory leak
	- invalidate() can remove reference
- can not be reused after invalidate()
- Prefer to utilize CADisplayLink for smooth animation

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/Timer_vs_CADisplayLink.png?raw=true)

## CADisplayLink

A timer object that allows your app to synchronize its drawing to the refresh rate of the display.

- bound to the display’s vsync
- also can be set rate(15, 20, 60 etc)
- more accurate than timer
- more sutiable for UI Refresh, animation etc

## GCD Timer

```
dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, aQueue);

dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, ti * NSEC_PER_SEC, ti * 0.1 * NSEC_PER_SEC);

dispatch_source_set_event_handler(timer, ^{
    //...
});

dispatch_resume(timer);
```

- based on dispatch_source, not runloop
- Note that some latency is to be expected for all timers, even when a leeway value of zero is specified.

## Q&A
- Is CADisplayLink accurate?
	- more than timer and GCD Timer, because timer and GCD Timer may introduce clock drift

## References
- [Timer](https://developer.apple.com/documentation/foundation/timer)
- [The secret world of NSTimer](https://danielemargutti.medium.com/the-secret-world-of-nstimer-708f508c9eb)
- [iOS Timer Tutorial](https://www.raywenderlich.com/113835-ios-timer-tutorial)
- [从NSTimer的失效性谈起（二）：关于GCD Timer和libdispatch](https://developer.aliyun.com/article/17709)