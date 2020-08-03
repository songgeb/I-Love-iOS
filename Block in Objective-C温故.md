# Block in Objective-C温故

又看了一遍《Pro Multithreading and Memory Management for iOS and OS X》对Block实现的一章

对Block的理解有了些加深

## Block类型

关于Block的类型，我觉得可以从block的**用途**上去区分

> 如果全局定义的block，或者block没有捕获局部自动变量，说明该block不依赖内存栈上的上下文环境（自动变量在栈上存储），一个独立的存在于内存的全局数据区的全局block就可以搞定

下面代码因为没有捕获自动变量，所以block是全局block，且内存中只有一份

```
typedef int (^blk_t)(int);
for (int i = 0; i < 10; i++) {
	blk_t blk = ^(int count){ return count; };
	NSLog(@"blk->%@", blk);
}
```

而下面的代码，由于捕获了栈上的局部（自动）变量`i`，所以是栈block

```
typedef int (^blk_t)(int);
for (int i = 0; i < 10; i++) {
	__weak blk_t blk = ^(int count){ return count * i; };
	NSLog(@"blk->%@", blk);
}
```
> 除了全局block，为了便于理解，其实其他形式的block刚创建时都是栈block。只不过有些情况下将栈block拷贝到了堆上，成了堆block

## block捕获变量

理解捕获变量原理的前提是了解block的内部结构

### 捕获`static`局部变量

由于`static`的变量在全局数据区，block内部其实可以访问和修改该变量，起内部的结构如下

```
int main() {
	static int static_val = 3; 
	void (^blk)(void) = ^{
		static_val *= 3;
	};
	return 0; 
}

struct __main_block_impl_0 {
	struct __block_impl impl;
	struct __main_block_desc_0* Desc;
	int *static_val;
	__main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,
int *_static_val, int flags=0) : static_val(_static_val) 		{ 
		impl.isa = &_NSConcreteStackBlock;
		impl.Flags = flags;
		impl.FuncPtr = fp;
		Desc = desc; 
	}
};

```

实际上，通过`static_val`这个指针就可以修改、访问被捕获的变量了

### 捕获自动变量

> 鉴于上面捕获局部static变量的经验，对于自动变量是否也可以这样做呢，不行！

- 可以看出，block是一个结构体(\__main\_block\_impl\_0)
- 捕获变量的过程，其实是给该结构体添加了一个成员变量，并初始化为被捕获变量的内容
- 之所以这样做呢，主要还是因为，很多情况下block要从栈上拷贝到堆上，而block的生命周期可能也要大于当前作用域，而自动变量的生命周期在离开当前作用域时就结束被释放了，为了block还能访问到捕获变量所以才这样做
- 这也说明为什么捕获的自动变量无法被修改，因为在block内部所看到的变量其实是自己的成员变量，而非外部被捕获的变量，内部的修改无法同步到外部

```
int main() {
	int dmy = 256;
	int val = 10;
	const char *fmt = "val = %d\n";
	void (^blk)(void) = ^{printf(fmt, val);}; return 0;
}

struct __block_impl { 
	void *isa;
	int Flags;
	int Reserved; 
	void *FuncPtr;
};

struct __main_block_impl_0 {
	struct __block_impl impl;
	struct __main_block_desc_0* Desc; 
	const char *fmt;
	int val;
	
	__main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, const char *_fmt, int _val, int flags=0) : fmt(_fmt), val(_val) {
		impl.isa = &_NSConcreteStackBlock; impl.Flags = flags;
		impl.FuncPtr = fp;
		Desc = desc;
	}
}
```

`static`的局部变量可以，因为block始终能访问到它，但自动变量却不可以

### 捕获`__block`变量

`__block`声明的变量不再只是单纯的一个变量了，而是一个新的结构体

```
_block int val = 10;
void (^blk)(void) = ^{val = 1;};

// _block int val = 10;一句翻译成C++代码如下
struct __Block_byref_val_0 { 
	void *__isa;
	__Block_byref_val_0 *__forwarding; 
	int __flags;
	int __size;
	int val;
};

struct __main_block_impl_0 {
	struct __block_impl impl;
	struct __main_block_desc_0* Desc;
	__Block_byref_val_0 *val;
	__main_block_impl_0(void *fp, struct __main_block_desc_0 *desc,
__Block_byref_val_0 *_val, int flags=0) : val(_val->__forwarding) { 
		impl.isa = &_NSConcreteStackBlock;
		impl.Flags = flags;
		impl.FuncPtr = fp;
		Desc = desc; 
	}
};

static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
	__Block_byref_val_0 *val = __cself->val;
	(val->__forwarding->val) = 1; 
}
```

- `__block`修饰的变量是一个`__Block_byref_val_0`结构体
- 捕获到的变量值存在`__Block_byref_val_0`结构体中
- block内部持有这个结构体的指针
- 所以`__block`是可以在不同block中共享的
- `__Block_byref_val_0`通过`__forwarding`指针对数据进行修改、访问--(后面还会说`__forwarding`)

### 捕获`__block`和非`__block`修饰的对象类型

前面说了捕获基本数据类型变量的过程，那么对于OC对象，有什么不同呢？

其实对于`__block`捕获原理是一样的，差别只是在对象有内存管理问题

以下就是捕获了一个`NSArray`对象的例子

```
struct __main_block_impl_0 {
	struct __block_impl impl;
	struct __main_block_desc_0* Desc;
	id __strong array;
	__main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, id __strong _array, int flags=0) : array(_array) {
		impl.isa = &_NSConcreteStackBlock; 
		impl.Flags = flags;
		impl.FuncPtr = fp;
		Desc = desc;
	} 
};
```

- 成员变量`array`是`__strong`的，说明block对array强持有，block要对array的生命周期负责
- 当然，如果`array`是`__weak`的，block捕获后的变量相应的也是弱引用
- 不论是否是`__block`变量，block会执行类似`retain`或`release`的方法，为的就是让block持有捕获的对象，不至于对象被意外释放
- 但执行`retain`、`release`的时机是在从栈拷贝到堆上时

## 栈block拷贝到堆上

之所以要拷贝到堆上，主要是因为

- 栈上的变量的生命周期是由系统管理，当离开当前代码块（作用域）时，栈上的变量会自动回收
- 而一些情况下，期望block生命周期能更长，所以才要进行拷贝操作

### 非`__block`变量拷贝到堆上时

这个比较简单，因为是非`__block`变量，所以可以认为拷贝发生时，只是将block的结构体拷贝一份到堆上

如果捕获的是对象类型，根据对象的生命周期`attribute`，若是强引用block还会对对象进行一次类似`retain`的操作

### `__block`变量拷贝到堆上

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/block_copy__block.png?raw=true)

- block拷贝到堆上的同时，`__block`结构体也会被拷贝到堆上
- block引用着`__block`对其生命周期负责
- `__block`对其内部持有的被捕获对象生命周期负责
- `__block`变量的生命周期管理也类似于引用计数


## `__forwarding`如何起作用的

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/block_forwarding.png?raw=true)

`__forwarding`是实现变量在block内部可被修改的关键

- 对于变量在栈上的情况，`__block`结构体中的`__forwarding`指向自己，所以修改val时，就是修改自己的val
- 当`__block`变量被拷贝到堆上时，堆上的`__block`变量的`__forwarding`指向自己，而栈上的`__forwarding`则指向堆上的`__block`结构体
- 所以不论栈上还是堆上的`__block`变量，实际修改的都是堆上的`__block`结构体

所以下面的代码可以顺利work

```
__block int val = 0;
void (^blk)(void) = [^{++val;} copy];
++val;
blk();
NSLog(@"%d", val);
```

## Block何时拷贝到堆上

关于拷贝的时机，不建议死记硬背，最好还是能从更高层面上理解

除了全局block的情况，初始化的block都是在栈上，根据不同需要，编译器或系统会自动帮我们将block拷贝到堆上

目前大多数情况下我们用的block都是在堆上，栈block很少

- block赋值给`__strong`变量时
- GCD中接收block的api中，方法内部会对block自动进行拷贝
- OC中`usingBlock`的api也会自动拷贝
- 一个方法中，返回一个block时

关于方法返回block时的拷贝，具体看下如下代码

```
typedef int (^blk_t)(int);
blk_t func(int rate) {
	return ^(int count){return rate * count;}; 
}

// 翻译后
blk_t func(int rate) {
	blk_t tmp = &__func_block_impl_0(
__func_block_func_0, &__func_block_desc_0_DATA, rate);
	tmp = objc_retainBlock(tmp);
	// 上面两句相当于
	// tmp = _Block_copy(tmp);
	return objc_autoreleaseReturnValue(tmp); 
}

```
- 刚创建的block在栈上
- 为避免离开方法后block被释放，将block拷贝到了堆上
- 并将block的内存管理交给了autoreleasePool