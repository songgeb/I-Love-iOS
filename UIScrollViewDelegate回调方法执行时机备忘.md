```
    // 开始拖拽时执行    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print(#function)
        开始拖拽
    }
    // 抬起手指时执行，可以修改滚动结束时的位置
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        print(#function)
    }
    // 抬起手指时执行，decelerate为true表示还会滚动一会儿
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        print(#function)
        print("decelerate->\(decelerate)")
    }
    //当抬起手指时，还要继续滚动时执行
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        print(#function)
    }
    //停止滚动时执行
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print(#function)
    }
    // 当通过`setContentOffset/scrollRectVisible:animated:`方法通过动画方式使得滚动，且滚动停止时执行
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print(#function)
    }
    // 询问delegate，是否支持点击顶部状态栏让距离状态栏最近的scrollView滚动到top
    // 若scrollView.scrollToTop和该方法有一个是false，那点击状态栏都不会滚动
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        print(#function)
    }
```
