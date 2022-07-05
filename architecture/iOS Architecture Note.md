# iOS Architecture Note

- ViewController不要有private method
	- private method是指除了View创建、delegate等逻辑之外的方法，比如图片裁剪，日期转换等小功能
	- private method应放到相应的模块，比如某个具体业务中，如果是通用的可以放入分类或工具类中。ViewController中逻辑已经很多了，不适合再加入这种小逻辑

## 参考
- [iOS应用架构谈 开篇](https://casatwy.com/iosying-yong-jia-gou-tan-kai-pian.html)