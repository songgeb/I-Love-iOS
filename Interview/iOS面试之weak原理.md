# iOS面试之weak原理

> 拒绝八股文，用理论知识+刻意练习碾压面试

面试题：weak属性是如何实现？

> 个人认为这个题真的没啥意思，能考察候选人什么能力？看没看过runtime代码？还不切换Swift，都什么年代了。。。

提了三个问题，以这三个问题展开：

1. 看源码，了解weak的实现原理
2. 聊一下自己对该设计的感觉
3. 查一下有没有公司或个人受weak原理的启发而将其应用到项目实践中

## weak原理

起初，看了几篇讲解源码的文章，实在看不下去，源码虽不多，但细节很多，其实还是不太容易理清楚作者设计的初衷的，所以以下会用更通俗易懂的语言来描述weak的底层实现

- `SideTable`封装了一个`weak_table_t`
- `SideTable`是全局的

```
struct SideTable {
    spinlock_t slock; // 锁
    RefcountMap refcnts; // 引用计数表
    weak_table_t weak_table; // weak 表
};
```

- `weak_table_t`，weak表是真正存数据的哈希表
- 其中有多个entry，每个entry表示一个对象地址和多个弱引用(弱引用数组)之间的关系，\<object, [weak_reference]>

```
struct weak_table_t {
    weak_entry_t *weak_entries; // hash数组，用来存储弱引用对象的相关信息
    size_t    num_entries;
    uintptr_t mask;
    uintptr_t max_hash_displacement;
};
```

```
struct weak_entry_t {
    DisguisedPtr<objc_object> referent;
    union {
        struct {
            weak_referrer_t *referrers;
            uintptr_t        out_of_line_ness : 2;
            uintptr_t        num_refs : PTR_MINUS_2;
            uintptr_t        mask;
            uintptr_t        max_hash_displacement;
        };
        struct {
            weak_referrer_t  inline_referrers[WEAK_INLINE_COUNT];
        };
    };
};
```

### 弱引用添加移除逻辑

在两个重要的时机，对`SideTable`的数据做操作：声明弱引用或给若引用赋值时、被引用的对象dealloc时

- 声明弱引用或给弱引用赋值时
	- 通过对象的地址，在`SideTable`中找到对应entry，在弱引用数组中将旧的不再需要弱引用数据移除
	- 将新声明的弱引用加入到数组中
- 被引用的对象dealloc时
	- 类似，找到对应entry，直接清除

## 如何看该设计

全局哈希表，检索效率高，换作我也这么设计。没了

我认为更优价值的东西，比如系统中为什么存储多个而不是一个`SideTable`，处于什么考量？

## weak原理在项目中的实践

这是唐巧之前提过的一个有意思的面试题（勉强算与weak有点关系吧）：

我们知道, 从 Storyboard 往编译器拖出来的 UI 控件的属性是 weak 的, 如下所示:

```
@property (weak, nonatomic) IBOutlet UIButton *myButton;
```

如果有一些 UI 控件我们要用代码的方式来创建, 那么它应该用 weak 还是 strong 呢? 为什么?

分析及答案
这是一道有意思的问题, 这个问题是我当时和 Lancy 一起写猿题库 App 时产生的一次小争论. 简单来说, 这道题并没有标准答案, 但是答案背后的解释却非常有价值, 能够看出一个人对于引用计数, 对于 view 的生命周期的理解是否到位.

从昨天的评论上, 我们就能看到一些理解非常不到位的解释, 例如:

> @spume 说：Storyboard 拖线使用 weak 是为了规避出现循环引用的问题。

这个理解是错误的, Storyboard 拖出来的控件即使是 strong 的, 也不会有循环引用问题.

我认为 UI 控件用默认用 weak, 根源还是苹果希望只有这些 UI 控件的父 View 来强引用它们, 而 ViewController 只需要强引用 ViewController.view 成员, 则可以间接持有所有的 UI 控件. 这样有一个好处是: 在以前, 当系统收到 Memory Warning 时, 会触发 ViewController 的 viewDidUnload 方法, 这样的弱引用方式, 可以让整个 view 整体都得到释放, 也更方便重建时整体重新构造.

但是首先 viewDidUnload 方法在 iOS 6 开始就被废弃掉了, 苹果用了更简单有效地方式来解决内存警告时的视图资源释放, 具体如何做的呢? 总之就是, 除非你特殊地操作 view 成员, ViewController.view 的生命期和 ViewController 是一样的了.

所以在这种情况下, 其实 UI 控件是不是 weak 其实关系并不大. 当 UI 控件是 weak 时, 它的引用计数是 1, 持有它的是它的 superview, 当 UI 控件是 strong 时, 它的引用计数是 2, 持有它的有两个地方, 一个是它的 superview, 另一个是这个 strong 的指针. UI 控件并不会持有别的对象, 所以, 不管是手写代码还是 Storyboard, UI 控件是 strong 都不会有循环引用的.

那么回到我们的最初的问题, 自己写的 view 成员, 应该用 weak 还是 strong? 我个人觉得应该用 strong, 因为用 weak 并没有什么特别的优势, 加上上一篇面试题文章中, 我们还看到, 其实 weak 变量会有额外的系统维护开销的, 如果你没有使用它的特别的理由, 那么用 strong 的话应该更好.

另外有读者也提到, 如果你要做 Lazy 加载, 那么你也只能选择用 strong.

当然, 如果你非要用 weak, 其实也没什么问题, 只需要注意在赋值前, 先把这个对象用 addSubView 加到父 view 上, 否则可能刚刚创建完, 它就被释放了.

在我心目中, 这才是我喜欢的面试题, 没有标准答案, 每种方案各有各的特点, 面试者能够足够分清楚每种方案的优缺点, 结合具体的场景做选择, 这才是优秀的面试者.

## Q&A

- 如何单步调试到runtime源码

## 参考
- [[iOS底层] - weak原理](https://www.ljcoder.com/486aa82fd77f.html)
- [iOS 面试题（六）：自己写的 view 成员，应该用 weak 还是 strong？](https://mp.weixin.qq.com/s/Tul94tyc_qYGjn3bXaPlmg)
- [iOS 面试题（五）：weak 的内部实现原理](https://mp.weixin.qq.com/s/5nYZXi1ZPNm0_f95CYx0SA)