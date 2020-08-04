# Implementing a Custom Gesture Recognizer

核心的工作就是

1. 自定义`GestureRecognizer`继承自`UIGestureRecognizer`
2. 明确要实现类型是`Dicrete`还是`Continous`
3. 根据类型利用好不同`Gesture Recognizer State Machine`机制
3. 重写`UIGestureRecognizer`的`touchBegan:`等一系列touch方法，在合适的时机为`state`赋值合适的状态
4. 处理`Cancellation`情况，即重写`touchCancel`方法
5. 重写`reset`方法（每次手势识别器识别结束（不论成功与否）后，下次新的手势识别前都会执行该方法，并将`state`置为`possible`），重置自定义属性的状态

## 参考
- [Implementing a Custom Gesture Recognizer](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/implementing_a_custom_gesture_recognizer)
- [About the Gesture Recognizer State Machine
](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/implementing_a_custom_gesture_recognizer/about_the_gesture_recognizer_state_machine)
