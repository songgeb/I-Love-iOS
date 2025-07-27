# UITableView in iOS

## 

## UITableViewCell

系统提供了四种UITableViewCell的样式，分别是

[![6jJfn1.md.png](https://z3.ax1x.com/2021/03/26/6jJfn1.md.png)](https://imgtu.com/i/6jJfn1)

### 如何使用cell的系统样式

两种方式

第一种方式是遵循正统的自定义cell套路

1. 创建自定义cell，比如`CustomCell`，重写`initWithStyle:reuseId`初始化方法，在其中指定要用的style
2. 通过`UITbleview.register`方法注册`CustomCell`
3. `cellForRow`中通过`dequeueCellWithIdForIndexPath`获取cell，并为cell相应属性赋值

第二种方法比较古老一些

1. 无需`register`cell
2. 直接在`cellForRow`中通过`dequeueCellWithId`获取cell，紧跟着需要判断如果cell为空，则使用`initWithStyle:reuseId`新建一个cell
3. 为cell相应的属性赋值

### UITableViewCell.imageView

不论使用自定义cell还是系统样式的cell，imageView都存在与cell中，如果给它赋值

- 它会显示
- 并且默认情况下，cell分割线会右移

[![6jwsbj.md.png](https://z3.ax1x.com/2021/03/26/6jwsbj.md.png)](https://imgtu.com/i/6jwsbj)

## cell之间的横线
1. 当设置了seperator样式后，tableview的cell之间就会显示横线
2. 但有个问题，多余的cell也会展示
3. 解决办法是给tableviewFooter设置一个空的view

## 动画

- `insertRows`等系列方法，默认情况是有动画地执行
- `reloadData`则是无动画的刷新

### tableviewHeader动画
可以通过如下代码实现tableViewHeader的动画

```
tableView.beginUpdates()
//header animation
tableView.endUpdates()
```

## automaticDimension

当UITableView+isPagingEnable配合使用时，比如短视频App的大屏视频feed流页面，滚动过程中会发现contentSize不准确问题，原因在于`UITableView.estimatedRowHeight`属性

- 该属性默认开启，值为`automaticDimension`
- 因为了能每一行高度都不同，为了避免每次load开启后表示`UIKit`会通过该值估算`contentSize`等属性
- 所以若需要精确的`contentSize`值，需要设置为0进行关闭

## UITableViewDelegate

## UITableViewCell

### prepareForReuse和cellForRow不一定是成对出现的