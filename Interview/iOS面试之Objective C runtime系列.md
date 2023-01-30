# iOS面试之Objective C runtime系列

> 本文提到的runtime源码版本是--objc4-818.2

> 如果是因为兴趣了解底层原理则非常推荐参考一下，不建议作为日常开发中的重要依据，你不知道苹果后面会做怎样的修改

## 一个NSObject对象占多少内存

该问题没啥意思，有文章分析了runtime的源码，提到字节对齐、对象的大小是16的倍数之类的，我能力有限，来不了，因为涉及很多C或更底层的知识。我认为了解以下内容即可：

- 一个NSObject对象，在现有的runtime实现源码中，对应着C中的结构体，且其中仅有一个`isa`指针作为成员变量

```
/// An opaque type that represents an Objective-C class.
typedef struct objc_class *Class;

/// Represents an instance of a class.
struct objc_object {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
};
```
- 至于到底占多大内存，那就要看`isa`指针占多大了，我印象中这东西是个不固定值，可能当前值8字节，其他架构下或未来会不会变谁知道呢
- 另外，其他文章中老提，runtime代码中有字节对齐，所以一个NSObject实例的大小不是8字节，而是16字节（还是那句话，只能说当前runtime版本确实如此，这种Apple不建议关注就让你做参考的东西难道就成了标准答案了？）

## isa指针的作用

### 实现类继承关系，查找实例、类方法

一张图解释一切

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/instance_class_metaclass.png?raw=true)

### KVO

isa swizzling，具体参考KVO官方文档

## 关联对象存在哪里
- 和weak的原理类似，关联对象也是存在全局map中
- 是一个两级map，第一级<ObjectRef, map>，第二级<key, value>

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/runtime_associatedobject.png?raw=true)

- 何时销毁？对象dealloc时会清空销毁map

## Category中覆盖原类方法

> 字节老爱问类似问题

问题

- category的方法存在哪里
- category方法如何工作，何时存何时取

category在runtime源码中的数据结构是这样的

```
struct category_t {
    const char *name;
    classref_t cls;
    WrappedPtr<method_list_t, PtrauthStrip> instanceMethods;
    WrappedPtr<method_list_t, PtrauthStrip> classMethods;
    struct protocol_list_t *protocols;
    struct property_list_t *instanceProperties;
    // Fields below this point are not always present on disk.
    struct property_list_t *_classProperties;

    method_list_t *methodsForMeta(bool isMeta) {
        if (isMeta) return classMethods;
        else return instanceMethods;
    }

    property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);
    
    protocol_list_t *protocolsForMeta(bool isMeta) {
        if (isMeta) return nullptr;
        else return protocols;
    }
};
```

- 这能够间接反映，category中不能存成员变量
- 因为底层的category结构中根本没有为成员变量预留存储空间

category何时加载到内存中？

- 程序启动时需要初始化objc runtime环境，会调用过`map_images`方法

```
void _objc_init(void)
{    
    // fixme defer initialization until an objc-using image is found?
    environ_init();
    tls_init();
    static_init();
    runtime_init();
    exception_init();
#if __OBJC2__
    cache_t::init();
#endif
    _imp_implementationWithBlock_init();

    _dyld_objc_notify_register(&map_images, load_images, unmap_image); //注意这里的map_images方法
	// 省略部分代码
}
```

- 沿着map_images方法一直找下去，会发现`attachCategories`

```
static void
attachCategories(Class cls, const locstamped_category_t *cats_list, uint32_t cats_count,
                 int flags)
{
    constexpr uint32_t ATTACH_BUFSIZ = 64;
    method_list_t   *mlists[ATTACH_BUFSIZ];
    property_list_t *proplists[ATTACH_BUFSIZ];
    protocol_list_t *protolists[ATTACH_BUFSIZ];

    uint32_t mcount = 0;
    uint32_t propcount = 0;
    uint32_t protocount = 0;
    bool isMeta = (flags & ATTACH_METACLASS);
    auto rwe = cls->data()->extAllocIfNeeded();

    for (uint32_t i = 0; i < cats_count; i++) {
        auto& entry = cats_list[i];
        method_list_t *mlist = entry.cat->methodsForMeta(isMeta);
        if (mlist) {
            mlists[ATTACH_BUFSIZ - ++mcount] = mlist;
        }
    }
    if (mcount > 0) {
        rwe->methods.attachLists(mlists + ATTACH_BUFSIZ - mcount, mcount);
    }
    rwe->properties.attachLists(proplists + ATTACH_BUFSIZ - propcount, propcount);
    rwe->protocols.attachLists(protolists + ATTACH_BUFSIZ - protocount, protocount);
}
```

- 会发现系统将所有分类的属性、协议方法、类方法、实例方法收集起来最终通过attachList方法加入到原类中

```
void attachLists(List* const * addedLists, uint32_t addedCount) {
    if (addedCount == 0) return;

    if (hasArray()) {
        // many lists -> many lists
        uint32_t oldCount = array()->count;
        uint32_t newCount = oldCount + addedCount;
        array_t *newArray = (array_t *)malloc(array_t::byteSize(newCount));
        newArray->count = newCount;
        array()->count = newCount;
        // 注意这里的逻辑
        for (int i = oldCount - 1; i >= 0; i--)
            newArray->lists[i + addedCount] = array()->lists[i];
        for (unsigned i = 0; i < addedCount; i++)
            newArray->lists[i] = addedLists[i];
        free(array());
        setArray(newArray);
        validate();
    }
}
```

- attachList中，将收集好的category实例方法或其他列表添加到原类中（也是用一个数组表示），并且原来已有的方法在数组中的位置靠后

所以，

- category的若干内容存在哪里？
	- 存在类对象和元类对象中
- category方法如何工作，何时存何时取
	- App启动，初始化runtime环境时

### +(void)load vs +(void)initialize

#### 相同点
- 都是类方法，都是NSObject中定义的方法
- 都存储在NSObject的元类对象中

#### 不同点
- 方法执行时机不同
	- +load方法时机很早，在初始化runtime环境时就执行了
	- 而且官方也明确提到，会确保所有的分类、原类的+load方法都会执行到（Invoked whenever a class or category is added to the Objective-C runtime; ）

- 方法执行原理不同

```
void
load_images(const char *path __unused, const struct mach_header *mh)
{
    if (!didInitialAttachCategories && didCallDyldNotifyRegister) {
        didInitialAttachCategories = true;
        loadAllCategories();
    }

    // Return without taking locks if there are no +load methods here.
    if (!hasLoadMethods((const headerType *)mh)) return;

    recursive_mutex_locker_t lock(loadMethodLock);

    // Discover load methods
    {
        mutex_locker_t lock2(runtimeLock);
        prepare_load_methods((const headerType *)mh);
    }

    // Call +load methods (without runtimeLock - re-entrant)
    call_load_methods();
}

void call_load_methods(void)
{
    void *pool = objc_autoreleasePoolPush();
    do {
        // 1. Repeatedly call class +loads until there aren't any more
        while (loadable_classes_used > 0) {
            call_class_loads();
        }

        // 2. Call category +loads ONCE
        more_categories = call_category_loads();

        // 3. Run more +loads if there are classes OR more untried categories
    } while (loadable_classes_used > 0  ||  more_categories);
    objc_autoreleasePoolPop(pool);
}

static void call_class_loads(void)
{
    // Call all +loads for the detached list.
    for (i = 0; i < used; i++) {
        Class cls = classes[i].cls;
        load_method_t load_method = (load_method_t)classes[i].method;
        (*load_method)(cls, @selector(load));
    }
}

// category中的load方法调用同上类似
```
- +load方法的执行是直接通过函数调用

而+initialize方法的执行时机是类第一次使用(第一次像该类发送消息时)，所以是通过`objc_msgSend`方法来查询类方法找到的

## 消息转发


## Runtime在实践中的应用

### Method-Swzzling

本人日常开发中很少用到（也就用过2、3次），通常用作基础组件中的一个底层逻辑，比如监控每个ViewController的消失出现逻辑

具体内容就不提了，说一下可能的坑吧

#### 当在+load方法中时是否需要dispatch_once

建议加上dispatch_once

因为这种交换Imp的行为就是一种全局、危险的动作，如果不小心执行了多次，那结果就不符合预期了。当然，按照目前runtime源码来看，一个类或分类的+load方法系统只会执行一次

#### 类继承中谨慎使用

如下代码会因为找不到方法而崩溃

```
@Inerface Person: NSObject 
- (void)personMethod;
@end
@Inerface Student: Person 
@end

@implementation Student
+ (void)load {
	// 使用exchange直接交换两个方法实现
	exchange(personMethod, subMethod);
}

- (void)subMethod {
	// custom logic
	[self subMethod]; // 触发崩溃的根本原因在这
}
@end

int main() {
	Person *person = [Person new];
	[person personMethod]; // 该句触发崩溃
}
```

- 原因是，执行到`[self subMethod]`时，此时self表示一个Person的实例，无法响应subMethod消息
- 所以
	- 进行Method-Swizzling时建议使用class_replaceMethod方法
	- 对父类继承下来的方法进行Method-Swizzling要慎重

### CTMediator


## 个人对runtime的看法

- runtime有着上帝视角
	- 能够轻松获取和修改每个类、对象的属性、方法，不管在不在我们当前代码执行的作用域下都能搞定
	- 这帮助我们比较容易做到解耦
- 同样因为上帝视角
	- 太多的灵活性带来了一定的代码修改风险，一旦改错或者忽略某种边界情况，将带来严重的后果
	- 个人倾向于通过设计模式和架构技术来解决耦合等问题，不去过分依赖runtime

## 参考
- [D4-006-runtime Asssociate方法关联的对象，需要在dealloc中释放_](https://www.bilibili.com/video/BV1Yz4y197YC/?spm_id_from=333.999.0.0)
- [hubupc/objc4-818.2](https://github.com/hubupc/objc4-818.2)
- [182 Category的本质02 分类的底层结构](https://www.youtube.com/watch?v=81SeTWEXPXY&list=PLwIrqQCQ5pQkz3WKI26GLYxJZANAceALJ&index=182)
- [Method Swizzling](https://nshipster.com/method-swizzling/)