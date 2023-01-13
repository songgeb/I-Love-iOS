# KeyChain in iOS

- KeyChain是2013年iOS 7引入的技术
- 类似于一个内置在系统中的一个加密数据库
- 适合存放比较隐私且体量较小的数据，比如密码、token等
- 通常情况下一个App只能访问自己添加到KeyChain的item（当然，一个公司或group下的其他App，通过配置也能共享）

## 疑问
1. 

## 参考
- [WWDC 2013 Session 709 PDF-Protecting Secrets with the Keychain](https://docs.huihoo.com/apple/wwdc/2013/session_709__protecting_secrets_with_the_keychain.pdf)
- [Adding a Password to the Keychain](https://developer.apple.com/documentation/security/keychain_services/keychain_items/adding_a_password_to_the_keychain)
- [OSStatus.com](https://osstatus.com/search/results?platform=all&framework=all&search=-50)