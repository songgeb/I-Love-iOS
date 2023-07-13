# UIAppearance in iOS

看下UIAppearance的定义

```
@protocol UIAppearance <NSObject>
+ (instancetype)appearance;
+ (instancetype)appearanceWhenContainedIn:(nullable Class <UIAppearanceContainer>)ContainerClass, ... NS_REQUIRES_NIL_TERMINATION API_DEPRECATED_WITH_REPLACEMENT("appearanceWhenContainedInInstancesOfClasses:", ios(5.0, 9.0)) API_UNAVAILABLE(tvos);
+ (instancetype)appearanceWhenContainedInInstancesOfClasses:(NSArray<Class <UIAppearanceContainer>> *)containerTypes API_AVAILABLE(ios(9.0));
+ (instancetype)appearanceForTraitCollection:(UITraitCollection *)trait API_AVAILABLE(ios(8.0));
+ (instancetype)appearanceForTraitCollection:(UITraitCollection *)trait whenContainedIn:(nullable Class <UIAppearanceContainer>)ContainerClass, ... NS_REQUIRES_NIL_TERMINATION API_DEPRECATED_WITH_REPLACEMENT("appearanceForTraitCollection:whenContainedInInstancesOfClasses:", ios(8.0, 9.0)) API_UNAVAILABLE(tvos);
+ (instancetype)appearanceForTraitCollection:(UITraitCollection *)trait whenContainedInInstancesOfClasses:(NSArray<Class <UIAppearanceContainer>> *)containerTypes  API_AVAILABLE(ios(9.0));

@end
```

- UIAppearance是一个协议，继承自`NSObject`协议
- 该协议定义了一系列方法，都是用于获取`UIAppearance`示例对象的方法
- 注意每个方法的返回值都是`instancetype`，所以receiver有什么属性，receiver.appearance()就可以设置什么属性

UIAppearance的作用是：**通过UIAppearance这种代理对象的全局方式修改UIKit中各个UI控件的样式信息**

UIAppearance提供了两类方法来修改控件样式：

- 通过`+ (instancetype)appearance`方法，可以获得所有receiver对应的代理对象，所以可以用来修改所有receiver实例的样式，如下，所有的UINavigationBar示例的barTintColor都修改了
	
	```
	UINavigationBar.appearance().barTintColor = navBarTintColor
	```
- 通过其他方法，可以获取某些特定情况下的receiver对应代理对象。如下，只会修改所有在UINavigationController中的UINavationBar的背景图片
	
	```
	let navigationBarAppearance =
UINavigationBar.appearance(whenContainedInInstancesOf: [UINavigationController.self])
	navigationBarAppearance.setBackgroundImage(navBarBackgroundImage, for: .any, barMetrics: .default)
	```
	
> 注意UIAppearance仅对未加入到Window中的UI控件起作用，如果要应用于已经添加在Window中控件，可以移除重新添加