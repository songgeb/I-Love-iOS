# Bundler in iOS project浅析

> 深入理解代替单纯记忆

## 前置知识

gem是一个软件库，提供了像`Cocoapods`、`Fastlane`等常用软件

Bundler就是gem提供的一个用于**统一gem软件版本**的工具

## Bundler工作原理

作为iOS开发，对`Podfile`和`Podfile.lock`肯定是有些了解的。其实`Bundler`也是基于同样的思想，而且`Podfile`的思路其实是有借鉴`Bundler`的

`Bundler`需要两个文件的支持，分别是`Gemfile`和`Gemfile.lock`
- `Gemfile`中用于指定所使用的的gem软件的版本信息和软件下载源
- `Gemfile.lock`则用于锁定当前使用的软件版本信息，需要提交到代码仓库，用于不同开发者不同电脑上使用gem软件对项目工程操作时进行统一版本协同

### 使用方法

iOS项目A，需要使用1.5.0版本的Cocoapods进行库依赖管理，但开发者a电脑上用的1.4.3的Cocoapods，而开发者b电脑上用的是高版本1.8.0的Cocoapods

不同版本的Cocoapods在执行依赖安装或更新时，很容易出现冲突情况。最好的版本肯定是大家统一Cocoapods版本。但`Bundler`则给了更好的解决方案

我们新创建一个`Gemfile`文件，写入

```
source 'https://rubygems.org' do
  gem 'cocoapods', '1.5.0'
end
```

然后执行`bundle install`，`bundler`会根据`Gemfile`内容创建`Gemfile.lock`文件，此文件要放入git等版本控制中；同时会下载安装`Gemfile`中指定版本的软件

最后执行`bundle exec pod install`命令，`bundler`会检查按需下载安装相应版本的`Cocoapods`并进行`pod install`操作

> 官方建议最好用`bundle exec xx xx`形式，虽然有时候直接`pod install`也可以work，但在不同机器不同环境下直接执行`pod install`是没办法保证`Cocoapods`版本的

## 参考

- [Bundler](https://bundler.io/v2.1/#getting-started)