# iOS EditMenuInteracton组件

# 背景

所谓EditMenu，就是如下图所示的菜单

![](https://raw.githubusercontent.com/songgeb/picx-images-hosting/master/20230929/editmenu_demo1.7hndw6obi2g0.webp)

这样的效果，既可以自己实现也可以用系统提供的组件

iOS系统UIKit库提供的组件有`UIMenuController`和`UIEditMenuInteraction`

UIEditMenuInteraction是iOS 16中引入的，从该版本开始UIMenuController被废弃

本文所要讲的，就是基于系统的`UIMenuController`和`UIEditMenuInteraction`封装了一个EditMenu样式的组件

# 为什么要封装组件

简单说，封装EditMenu就是使用前面提到的两个系统的EditMenu组件，封装成一个组件使用
为什么？原因很简单：

**UIMenuController太难用，希望替换为UIEditMenuInteraction，但仍要兼容iOS 16之前的系统，又不想每个用到的地方都写两套代码**

# UIMenuController vs UIEditMenuInteraction

本小节通过讲解`UIMenuController`的使用方式和工作原理，对比与`UIEditMenuInteraction`的区别来说明为什么`UIMenuController`难用

在说封装后的EditMenu之前，先简述一下老组件--`UIMenuController`的工作原理
网上搜一下会发现，有不少文章在讲怎么使用`UIMenuController`，且发现其中要注意的细节还不少。其实这已经从侧面说明这个组件不好用了（对比一下有多少文章来介绍怎么使用`UILabel`、`UIButton`呢）
`UIMenuController`的使用流程比较简单，如下：

1. UIMenuController是个单例，直接获取实例
2. 通过设置menuItems属性，配置额外的、需要显示的自定义的菜单选项（注意，是额外的选项，因为系统也会默认提供一些选项，如copy、paste等）
3. 通过setTargetRect(_:in:)设置菜单显示位置
4. 通过setMenuVisible(_:animated:)显示、隐藏菜单

难用的地方，同时也是网上问的最多的是：

- 菜单无法正常显示
- 菜单显示的选项包含了不希望出现的系统提供的选项

这两个问题的原因是一个：**`UIMenuController`决定显示哪些选项的原理不易理解**

## UIMenuController如何决定显示哪些选项

最关键的是：`UIMenuController`通过询问`UIResponder`对象构成的responder chain来决定最终显示的选项

我们想象在一个聊天页面中，需要长按某条消息显示菜单选项的场景，通过该场景简述一下UIMenuController的工作原理：

- Responder Chain大致是这样：UIlabel -> UIView(cell.contentView) -> UICollectionViewCell -> UICollectionView -> UIViewController
- 执行`setTargetRect(_:in:)`方法时，in参数传的是最上层的UILabel
- 那么，当执行`setMenuVisible(_:animated:)`时，对于Responder Chain中的每个对象，系统都会通过`canPerformAction(_:withSender:)`来确定某个action（Selector）能否被处理，如果返回true，则最终会显示出来
- 但如果false，并不意味着一定不会显示。因为只要有一个responder返回true，最终就会显示，只有所有responder都返回false，才不会显示

正是这样的设计---**单例+多个数据源**（多个responder）决定最终的状态，导致不易用且难以调试

- 单例，意味着多个场景下使用一份组件和数据，那么在场景1中决定哪些菜单要显示时，还得考虑其他场景的菜单选项会不会干扰到场景1
- 多数据源决定一个状态，多一个数据源就增加问题复杂度，调试复杂度

这还不算完

> canPerformAction(_:withSender:)有自己的默认实现：如果当前UIResponder实现了该方法参数中提到的action对应的方法，则返回true，否则继续执行nextResponder.canPerformAction(_:withSender:)

- 还是前面的Responder Chain，如果只是执行`setTargetRect(_:in:)`和`setMenuVisible(_:animated:)`，我们根本看不到任何菜单选项出现。因为整个Responder Chain的`canPerformAction(_:withSender:)`都返回false
- 为了能够显示，我们在`UICollectionViewCell`中添加了每个菜单action对应的实现
- 很可能最终的事件处理要在`UIViewController`中处理，所以要通过delegate等方式将事件传递到外面

以上，就是`UIMenuController`工作原理的解释，总结一下：

- 从API角度来看，使用不复杂；但真的应用起来，稍微复杂一些的场景，就很容易出现显示不出来的问题
- 只有对它的工作原理有熟悉的理解后，才能不易出错。（其实系统还会执行`UIResponder.target(forAction:withSender:)`，使用复杂度还会进一步增加）
- 文中没有展示因为单例共享数据带来的问题，其实时机开发中是遇到过的。比如聊天页面场景下，文本输入框中可以长按出现菜单，长按消息也可以出现菜单，两边场景下的菜单选项不同，但其实都存在同一单例中，是会有影响的

## UIEditMenuInteraction

反观新的系统组件-`UIEditMenuInteraction`，设计就好用很多

- 不是单例，哪里需要哪里创建。不用考虑其他场景对当下的影响
- 不用遍历多个数据源（UIResponder）来决定展示哪些菜单，为`UIEditMenuInteraction`实例提供哪些菜单，最终就显示哪些
- 不需要再UIResponder提供action的默认实现进行事件处理，事件处理统一在回调中

## EditMenu in UITableViewDelegate or UICollectionViewDelegate

`UITableViewDelegate`和`UICollectionViewDelegate`中也有EditMenu相关的方法，以`UICollectionView`为例

```
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath API_DEPRECATED_WITH_REPLACEMENT("collectionView:contextMenuConfigurationForItemsAtIndexPaths:point:", ios(6.0, 13.0));
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender API_DEPRECATED_WITH_REPLACEMENT("collectionView:contextMenuConfigurationForItemsAtIndexPaths:point:", ios(6.0, 13.0));
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender API_DEPRECATED_WITH_REPLACEMENT("collectionView:contextMenuConfigurationForItemsAtIndexPaths:point:", ios(6.0, 13.0));
```

根据测试发现，

- 在iOS 16之前，通过上述`UICollectionViewDelegate`的API实现的EditMenu效果，本质上系统还是通过`UIMenuController`来显示EditMenu
- iOS 16中，则是使用的`UIEditMenuInteraction`

另外，最重要的一点是：

无论iOS 16之前还是iOS 16版本，以上API都不太容易实现自定义EditMenu要显示的位置。EditMenu的显示位置是基于整个Cell的尺寸和位置，并由系统来控制。所以以上API的适用场景是，对整个Cell进行Menu显示和操作的场景。比如下面这个场景

![](https://raw.githubusercontent.com/songgeb/picx-images-hosting/master/20230929/image.75r9iqfcbq40.webp)

![](https://raw.githubusercontent.com/songgeb/picx-images-hosting/master/20230929/image-(1).1o04bjtjj5b4.webp)

> 需要注意的是，以上API从iOS 14开始废弃，取而代之的collectionView:contextMenuConfigurationForItemsAtIndexPaths:point:系列。注意新的API其实就不是EditMenu的样式了，而是下图所示的样子（在苹果官方叫做ContextMenu）

# EditMenuInteraction组件

基于上面分析的问题，我们设计了`EditMenuInteraction`组件，它能够：

- 封装了`UIMenuController`和`UIEditMenuInteraction`的能力，所以兼容iOS 16之前和之后的系统
- 统一了输入数据源和事件回调逻辑，解决冗余代码问题，提供易用性
  - 因为这两个系统组件的输入（即菜单选项）和事件回调处理逻辑各不相同，如果项目中多出用到EditMenu样式，那输入和事件回调处理就要写多次，代码冗余
  - 无需编写不易理解的Action方法。使用`UIMenuController`时，大概率要去实现每个菜单选项对应的actioin方法，这并不易用

## 使用方式

```
- (void)collectionView:(UICollectionView *)collectionView didLongPress:(Model *)msg indexPath:(NSIndexPath *)indexPath {
    NSArray<MessageCellMenuItem *> *cellMenuItems = [self menuItemsForIndexPath:indexPath];
    NSArray<EditMenuInteractionItem *> *menuItems = [self editMenuItemsWithCellMenuItems:cellMenuItems indexPath:indexPath];
    MessageCell *cell = (MessageCell *)[collectionView cellForItemAtIndexPath:indexPath];
    CGRect targetRect = [cell.contentView convertRect:cell.messageContainerView.frame toView:cell];
    [self.menuInteraction showMenu:menuItems at:indexPath targetRect:targetRect relativeTo:cell];
}

- (NSArray<EditMenuInteractionItem *> *)editMenuItemsWithCellMenuItems:(NSArray<MessageCellMenuItem *> *)cellMenuItems
                                                                indexPath:(NSIndexPath *)indexPath {
    NSMutableArray<EditMenuInteractionItem *> *items = [NSMutableArray array];
    for (MessageCellMenuItem *cellItem in cellMenuItems) {
        EditMenuInteractionItem *item = [[EditMenuInteractionItem alloc] initWithTitle:cellItem.title callback:nil];
        @weakify(self);
        switch (cellItem.type) {
            case MessageCellMenuTypeCopy: {
                item.callback = ^{ [weak_self copyMsgAtIndexPath:indexPath]; };
                break;
            }
            case MessageCellMenuTypeDelete: {
                item.callback = ^{ [weak_self deleteMsgAtIndexPath:indexPath]; };
                break;
            }
        }
        [items addObject:item];
    }
    return items;
}
```

- `(void)collectionView:didLongPress:indexPath:`方法是collectionviewcell长按时的回调
- `(NSArray<EditMenuInteractionItem > *)editMenuItemsWithCellMenuItems:indexPath:`方法，用于构建`EditMenuInteraction`所需要的菜单选项，仅有两个信息：title和callback
- `[self.menuInteraction showMenu:menuItems targetRect:targetRect for:cell]`，显示菜单选项
  - for参数表示要在哪个视图显示菜单选项
  - targetRect用于控制菜单选项的位置，比如长按一条聊天消息时，可以传入表示文本的label的rect
  - 注意：targetRect是基于for参数中的视图的坐标系的

# 源码

源码包含三个类：

- `EditMenuInteraction`，核心类，Swift编写，集成了`UIMenuController`和`UIEditMenuInteraction`能力
- `EditMenuInteractionItem`，Swift编写，表示菜单选项的数据源
- `EditMenuInteractionDummy`，Objective C编写，组件内部私有类。通过OC Runtime的消息转发机制实现无需新增菜单选项action的情况下仍可以显示希望的菜单选项目的

[源码地址](https://github.com/songgeb/I-Love-iOS/tree/master/Opensource/EditMenu)
> 觉得好用给点个star

