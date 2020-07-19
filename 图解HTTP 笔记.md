# HTTP协议 & 《图解HTTP》笔记

## TCP/IP

1. HTTP协议是TCP/IP协议族中的一个协议
2. TCP/IP是互联网相关各类协议族的总称
3. TCP/IP协议族是分层管理的：应用层、传输层、网络层和数据链路层
4. 应用层决定了面向用户提供应用服务时通信的活动，FTP、DNS和HTTP属于该层
5. 传输层，提供网络中两个计算机间数据传输，TCP和UDP协议属于该层
	- TCP协议保证数据的完整和传输可靠
6. 网络层，计算机间传输数据可能有很多路径，网络层的作用是通过各种策略选择其中一条
	- IP协议属于该层
	- 有了IP协议数据就可以在不同的局域网中传输
7. 数据链路层，连接网络的硬件部分
	- 以太网协议属于该层
	- 该协议可以让数据可以在局域网中传输
8. 开发者所写的应用程序代码都在应用层中
9. HTTP/1.1默认都是持久连接（TCP连接持久），早期的HTTP是非持久的，随着发展这样效率太低，就改成持久了

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/tcpip.png?raw=true)


### TCP

- 面向**连接**的，**可靠**的传输协议
- TCP协议位于传输层

#### 三次握手

在TCP建立连接时，为了保证可靠性，和性能考虑，需要进行三次握手通信，才能建立稳定的连接

1. 假设A要向B发送建立连接请求，A首先发送`SYN`的握手报文给B
2. B收到报文后，发送`ACK+SYN`的报文给A，`ACK`意思是，我收到你的请求了，可以建立连接。`SYN`则表示，你那边能收到我的消息吗？
3. A收到后，再向B发送一个`ACK`报文，表示我也收到你的了

三次握手成功后，A和B就要真正的为接下来的数据传输开辟资源（比如内存空间等）了

三次握手一次也不能少，如果2次的话，仅能确保A到B是畅通的，B到A是否畅通不能确定；如果超过4次，就多余了，没必要

#### 四次挥手

四次挥手是指TCP断开连接时的通信逻辑

1. 还是以A向B发送断开TCP请求为例，A向B发送`FIN`结束通信请求报文，同时A不会再给B发送数据了
2. B收到后并不会立即同意结束通信，因为有可能B还有给A的消息未发完，所以就只回复给A一个`ACK`报文，表示我知道你想结束通信这件事了
3. B要等待剩余给A的数据传输结束后，再向A发送一个`FIN`报文，表示我这边也准备好结束了
4. A这边收到后，再发送`ACK`告知B知道了。至此，完成断开连接，两边可以释放资源了

为什么是四次挥手？能不能像三次握手一样，将2、3两步合成一步呢？

不行，因为B收到A的`FIN`后，必须及时告知A，否则A可能会因为超时未收到回复而重发`FIN`

### TCP和UDP区别

- UDP不是面向连接的，可以想发就发
- UDP几乎不对上层数据做特殊处理，加个UDP头就交给下层
- UDP无法保证数据的完整有序，没有重发等机制
- 对实时性要求强的如电话会议，可以使用UDP

## HTTP报文

- HTTP报文是多行字符串文本
- 由首部和报文主体构成，通过空行分隔开
- 首部字段分为四种：通用首部、请求首部、响应首部和实体首部
- 首部字段中也可能出现RFC中未规定的字段，比如Cookie

### 报文结构

一个HTTP**请求**报文包括

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/http%E7%BB%84%E6%88%90.png?raw=true)

- 请求首部字段和内容实体是可选的

一个响应报文

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/http%E5%93%8D%E5%BA%94%E6%8A%A5%E6%96%87.png?raw=true)

## 状态码
### 2XX
- 206，Partial Content

### 4XX
客户端错误

- 400，BadRequest
- 401，Unauthorized
	- 说明访问的资源需要HTTP认证信息，或者认证信息失败
- 403，Forbidden，无访问权限

### 5XX

服务器内部错误
- 500，Internal Server Error
	- 服务器执行请求时错误
- 503，Service Unavailable
	- 服务器暂时处于超负荷或停机维护，无法处理请求

## 与http协作的web服务器

除了要访问数据的目的web服务器外，在整个HTTP请求当中，还可能有一些其他的应用程序和服务器参与协作

### 代理服务器
- 介于客户端和目的服务器之间
- 请求和响应都会经过代理服务器
- 可能还会经过多个代理服务器
- 代理服务器的目的可以是
	- 缓存代理服务器，将目的服务器上的资源缓存到代理服务器，之后客户端再次访问时可以直接用，提高访问效率
	- 进行特定URI的访问控制或访问日志管理

### 网关

### 隧道
建立一条与服务器的通信线路，一般用于SSL等安全通信

### 资源的缓存

1. 代理服务器可以对资源进行缓存
2. 客户端也可以进行缓存

### 疑问
1. 网关的作用和原理不明白

## HTTP首部

![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/http%E9%A6%96%E9%83%A8.jpeg?raw=true)

> 除了HTTP/1.1(RFC2616)列出的首部字段外，还有一些使用频率很高的字段，统一归纳在RFC4229中了

### 通用首部
### 请求首部
- Range
	- 可以向请求部分资源，可以用于断点续传
	- 服务器需要配合实现部分资源下载功能，如果实现了相应状态码为206，若未实现则返回200，同时返回整个数据
- Referer
	- 表示发起当前请求时所在的URI
	- 注意，此处`Referer`是拼写错误的，正确的拼写是`Referrer`，但标准中一直在沿用错误写法
- User-Agent
	- 浏览器和用户代理信息
### 响应首部
### Cookie
- 在请求首部中的字段名是`Cookie`
- 在响应首部字段名为`Set-Cookie`
- 可以往cookie中写入自定义的cookie内容，以`Name=Value`形式
- 另外cookie中也可以包括path、domain、secure、exipres这些属性
### 疑问
1. Cache-Control的no cache，有点懵

## HTTPS
用SSL建立安全通信后，同时也有认证机制和内容完整性保护，这就是HTTPS

- SSL与TLS的关系
	- 最早网景公司开发了SSL的1.0、2.0和3.0版本
	- 后序交给了别的组织，基于3.0继续开发出了TLS1.0以及之后的版本
- HTTPS并非新协议，而是在HTTP的部分接口用SSL和TLS协议代替
- HTTP是直接和TCP交互，而HTTPS则是和SSL交互
![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/https-http.png?raw=true)
### HTTPS采用混合加密机制

- 分为两个阶段，先用非对称加密方式安全地交换密钥
- 再使用密钥进行堆成加密方式的数据传输
	![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/https%E5%8A%A0%E5%AF%86%E8%BF%87%E7%A8%8B.png?raw=true)
- 为了保证服务器的公钥的正确性，所以借助CA机构对服务器的公钥又加密了一把
	![](https://github.com/songgeb/I-Love-iOS/blob/master/Images/CA%E8%AE%A4%E8%AF%81%E6%9C%8D%E5%8A%A1%E5%99%A8%E5%85%AC%E9%92%A5%E8%BF%87%E7%A8%8B.png?raw=true)



## 参考
- [作为前端的你了解多少tcp的内容](https://juejin.im/post/5c078058f265da611c26c235)
- [牛皮了，头一次见有清华大佬把TCP/IP三次握手四次挥手解释的这么明白](https://www.bilibili.com/video/BV1ai4y1s7sG?from=search&seid=5280087529499942417)