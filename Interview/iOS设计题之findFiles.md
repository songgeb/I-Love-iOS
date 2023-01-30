# iOS设计题之findFiles

项目中有这么一个方法func findfile(dir: String suffix: String) -> [String] ，可以通过输入文件夹目录，和后缀检索出所需的文件。

例如需要在某个文件中检索txt文件或者mp4文件，那就传入dir和suffix就行了。现在又有一些需求，例如需要检索utf8格式的txt或者h264编码的mp4，也会有一些例如查找最近一周更新过的文件这样的需求，你如何优化这个类，让它满足这些情况？

本题目来自--[zhangferry-快手iOS面经](https://zhangferry.com/2020/03/28/interview_kuaishou/)

## 解题思路

阅读题目，经过短暂的思考：

- 显然该题目的关键点在于，要不断为该方法丰富满足各种条件的检索能力
- 简单直白的做法无非是遇到一个检索条件就向该方法添加一个相应的参数，比如该题目中提到的文件格式和更新时间
- 用脚指头也能猜到这肯定不是一个好方案
	- 如果单纯的增加方法的参数，那该方法就破坏了职责单一原则，调用方使用起来会产生困惑，不知道如何传递参数
-  进一步分析，该方法的核心逻辑肯定是通过遍历目的目录下所有的文件（可能是递归地遍历），如果符合条件就添加到结果集中
-  所以，如果我们将是否符合条件的判断交给调用方，那方法所做的事情就职责单一了
-  其实很自然就能想到类似Swift中集合的`sort`方法的实现--将判断逻辑封装为一个closure传入方法中进行排序

根据分析，下面是优化后的方法伪代码：

```
func findfiles(by shouldBeInclude: (FileInfo) -> Bool) -> [String] {
  var files: [String] = []
  // iterate all files and find the target file
  let fileInfo = FileInfo(filename: "abc", suffix: "txt", encodeFormat: .utf8)
  if shouldBeInclude(fileInfo) {
    files.append(fileInfo.filename)
  }
  return files
}

let txtAndmp4Files = findfiles(dir: "dir") {
  $0.suffix == "txt" || $0.suffix == "mp4"
}

let utf8Andh264Files = findfiles(dir: "dir") {
  $0.encodeFormat == .utf8 || $0.encodeFormat == .h264
}
```

优点：

1. 方法职责单一
2. 符合开闭原则，当需要添加新的判断逻辑时编写新的closure即可，无需修改方法本身逻辑

简单总结下：

- 该题主要考察了是否有用block做逻辑抽象的经验
- 对block或closure比较感兴趣或者用的多的朋友感觉这题目很简单，反之可能想不到
- 所以该题目针对性有点强，且规模不大，算不上较通用的设计题目