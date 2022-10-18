# 《Coding Guidelines for Cocoa》笔记

## 一般原则

### Clarity(清晰)

|code|commentary|
|:-:|:-:|
|`insertObject:atIndex:`|good|
|`insert:at:`|not clear|

通常，不用简写

|code|commentary|
|:-:|:-:|
|`setBackgroundColor`|good|
|`setBkgdColor`|not clear|

但也有一些简写是经过历史检验，已经约定俗成了的

[Acceptable Abbreviations and Acronyms](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/Articles/APIAbbreviations.html#//apple_ref/doc/uid/20001285-BCIHCGAE)

定义api时，避免歧义

|code|commentary|
|:-:|:-:|
|`sendPort`|歧义，是想表示发送端口数据还是表示获取发送方的端口信息呢|
|`displayName`|同上|

### Consistency(一致)

有一些方法、属性名贯穿多个不同的类，使用同一个名称，会让编程更清晰

|code|commentary|
|:-:|:-:|
|- (NSInteger)tag|Defined in NSView, NSCell, NSControl.|

### No Self Reference

|code|commentary|
|:-:|:-:|
|NSString|good|
|NSStringObject|self reference|

但也有例外，比如Mask常量和通知名称

|code|commentary|
|:-:|:-:|
| NSUnderlineByWordMask |good|
| NSTableViewColumnDidMoveNotification |good|

## 前缀

- 因为OC没有命名空间的概念，所以为了避免与三方库或系统库发生冲突，需要使用前缀
- 当给类、协议、函数、常量、typdef命名时，需要用到前缀，这些数据结构可能产生冲突
- 但当命名类中的方法、属性时，则不需要

## 书写约定

- 通常，方法(Method)的命名以小写字母开始，中间每个单词的开始使用大写，即小驼峰写法
- 也有例外，比如方法名的开头是以常见的缩写开始的--如`TIFFRepresentation `
- 对类、协议、函数、常量、typdef的命名，除了使用前缀，要使用大驼峰写法

## 类与协议名

- 大多数协议中的方法跟某一类没有具体关系，这时候协议命名时可能会在最后加上`ing`，比如`NSLocking`
- 也有与某个类关联很大的协议，此时可以用类名作为协议名，比如`NSObject`协议

## 方法命名规范(Method)

### 一般规则

- 小驼峰，不需要前缀
- 两种情况下可以不用小驼峰
	- 以经典缩写开头，比如PDFXXXX、TIFFXXXX
	- 一些我们类内部的私有方法，可以加前缀；但不要以下划线开始，以防与系统私有方法冲突
- 若方法返回一个属性，直接写属性名称即可，无需加get之类
- 方法每个入参之前都应该有关键词
- 入参数之间不要用and连接
- 方法中独立的行为可以用and连接，如`- (BOOL)openFile:(NSString *)fullPath withApplication:(NSString *)appName andDeactivate:(BOOL)flag;`

### Accessor Methods

- 不要试图用过去分词形式，将动词改为形容词形式

	|code||
	|:-:|:-:|
	|- (BOOL)acceptsGlyphInfo;|right|
	|- (BOOL)glyphInfoAccepted;|wrong|
- get的使用仅限于一个方法获取多个参数的形式，即通过指针来获取额外返回值时
	- `- (void)getLineDash:(float *)pattern count:(int *)count phase:(float *)phase;`

### Delegate Methods

该小节为代理方法的命名规范，该规范也适用于数据源对象(datasource)

- 要以发送代理方法的对象的类名开头，小写字母开头，且没有前缀
	- `- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;`
- 一般是在类名后面加冒号，第一个参数就是被代理的对象；但当只有一个参数，且参数就是被代理的对象时，就不是在类名后面加冒号了，而是如下
	- `- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender;`
- 关于上面的一条，也有例外，比如发送了某个通知，触发了代理方法，这种情况下唯一的参数就是通知对象
	- `- (void)windowDidChangeScreen:(NSNotification *)notification;`
- did、will、should在代理方法中也很常用
	- `- (void)browserDidScroll:(NSBrowser *)sender;`
	- `- (BOOL)windowShouldClose:(id)sender;`

### Method Arguments

下面这些参数名称和方法名经常搭配使用

```
...action:(SEL)aSelector
...alignment:(int)mode
...atIndex:(int)index
...content:(NSRect)aRect
...doubleValue:(double)aDouble
...floatValue:(float)aFloat
...font:(NSFont *)fontObj
...frame:(NSRect)frameRect
...intValue:(int)anInt
...keyEquivalent:(NSString *)charCode
...length:(int)numBytes
...point:(NSPoint)aPoint
...stringValue:(NSString *)aString
...tag:(int)anInt
...target:(id)anObject
...title:(NSString *)aString
```
## Tips and Techniques for Framework Developers

未完待续


## 参考
- [Coding Guidelines for Cocoa](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CodingGuidelines/Articles/NamingBasics.html#//apple_ref/doc/uid/20001281-BBCHBFAH)