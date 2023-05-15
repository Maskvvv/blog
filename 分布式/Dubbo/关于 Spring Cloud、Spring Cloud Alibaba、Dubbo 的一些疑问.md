# 问题一：

1、目前的微服务框架：springCloud 体系、阿里的 springCloudAlibaba 体系、以 dubbo 为主的微服务框架 

2、对微服务框架的疑惑点一：国内主流微服务栈基本是springCloudAlibaba，我看阿里官方的描述，dubbo也是springCloudAlibaba的组成部分，那dubbo现在也有服务治理能力，是可以替代springCloudAlibaba吗 

3、对微服务框架的疑惑点二：springCloudAlibaba技术栈包括nacos、springCloud gateway、sentinel、Sleuth、Seata等，那末duboo微服务治理包括哪些，还是说跟pringCloudAlibaba是重叠的 

4、对微服务框架的疑惑点三：springCloudAlibaba、dubbo各自的定位是什么 

5、对微服务框架的疑惑点四：springCloudAlibaba、dubbo各自的使用场景是什么

## 答：

对于大众化普通诉求，使用任何一款都行。 

然而，若对一些停更的组件比较在意的话，SpringCloudAlibaba主要对SpringCloud中的一些停更组件进行了延续，通过扩展或者替换的方式，使得SpringCloudAlibaba变相成为了SpringCloud的增强版本，阿里在增强版本中新增了Nacos、Gateway、Sentinel等等组件来扩展或替换那些停更的组件。 

既然是增强版本的话，那么SpringCloudAlibaba和SpringCloud在进行服务调用时首选的是大众化的RestAPI形式，通过Feign来发起HTTP调用。 

但是，微服务体系也存在不少的内部服务之间的调用，若对远程调用有极致的性能追求，毕竟HTTP是走在7层协议之上，而Dubbo发起的RPC调用走在4层协议上，就单纯从拆包解包来说，数据走在4层与走在7层来说，当然是走在4层的数据包会小一些。 

所以 Dubbo 在远程调用上会有极致的追求，但也有人们想在 SpringCloudAlibaba 和 SpringCloud 之上，对于服务之间的调用也想使用4层的TCP发起调用的话，那么就衍生出了 SpringCloudAlibabaDubbo 微服务框架。

# 问题二：

Dubbo 究竟是 RPC 框架还是 微服务框架？

## 答：

Dubbo以前官网介绍定位是一个高性能 RPC 框架，现在官网介绍已经定位是一个微服务框架。不但具备远程调用与服务发现，同时还在此基础上提供了一系列的治理能力。

大多数情况下可以混为一谈。但必须清楚，rpc 这个名词重点在于通信。而微服务更多注重的是一整套成熟生态体系，包含不仅仅是通信，还有容错，流量治理，路由，链路追踪，监控，此外还有发布，升级等等。服务框架是基础，提供了扩展点，整合了整套技术栈。