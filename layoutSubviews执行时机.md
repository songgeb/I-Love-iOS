> 深入理解代替单纯记忆

## 执行时机

> 官方并没有明确说`UIView`的`layoutSubviews`方法执行时机，文中说的执行时机是总结自参考文章中，主要来自实际测试

- `view.bounds`发生变化变化时
    - 所以，当`view.frame.size`变化时，方法会被执行，因为实际上改变的是`view.bounds.size`
    - 注意`bounds`发生变化意味着除了`size`，`origin`的变化也会导致方法执行，比如`UIScrollView`的滚动原理就是改变`bounds.origin`
    - 当然也包括size间接被修改的情况，比如subview设置了autoresizingMask，superview'size改变触发subview的size变化的情况
    - 如果设置前后，`bounds`的值并没有变，方法也不会被执行
- direct subviews' size改变时会触发执行，注意，是直接子view
- 执行`addSubview`方法时，`targetView.addSubview(subView)`，`subView`和`targetView`的`layoutSubviews`方法会执行
- 通过`setNeedsLayout`或`layoutIfNeed`方法触发视图更新时
    - `layoutIfNeed`执行时不一定会触发`layoutSubviews`执行，需要有`layout updates`时

> 再注意一点，当同时进行多层级视图的`layoutSubviews`调用时，顺序是从上层到下层

## 一点思考

根据上面触发时机很容易能看出来
> `layoutSubviews`是在那些需要执行的时候执行

从事一段时间iOS开发之后就能发现，苹果的设计思路（其他机构应该也是如此）就是，尽量只在有必要的时候才增加逻辑，能不增加系统额外消耗就不增加

- 就拿`addSubview`时机来说，对于`targetView`，有子视图加入了，如果我想做一些精细化的布局调整，那就得依靠`targetView`的`layoutSubviews`时机；同时，`subView`加入到新的视图体系里面，也可能有些需要依赖`superView`才能完成的逻辑，此时也是通过`layoutSubviews`时机

## 参考
- [When is layoutSubviews called?](https://stackoverflow.com/questions/728372/when-is-layoutsubviews-called)
