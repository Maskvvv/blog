---
title: springcloud学习(七)-Sidecar(多语言支持)
date: 2021-1-28
tags:
  - 微服务
  - springcloud学习(七)-Sidecar(多语言支持)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(七)-Sidecar(多语言支持)
---

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222241-spring-cloud.png)

<!--more-->

## 一、Sidecar 的介绍

### 1.1 引言

在 SpringCloud 的项目中，需要接入一些非 java 程序或第三方接口（无法接入eureka，hystrix，feign等组件的程序）。所以我们可以通过启动一个代理的微服务去和非 java 的程序或第三方接口进行交流，然后再把代理的微服务计入 SpringCloud 的相关组件中。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222244-image-20201112160258956.png)

> 应用程序和服务通常需要相关的功能，例如监控、日志、集中化配置和网络服务等。这些外围任务可以作为单独的组件或服务来实现。
>
> 如果它们紧密集成到应用程序中，它们可以在与应用程序相同的进程中运行，从而有效地使用共享资源。但是，这也意味着它们没有很好地隔离，并且其中一个组件的中断可能会影响其他组件或整个应用程序。此外，它们通常需要使用与父应用程序相同的语言或者技术栈来实现。因此，组件和应用程序彼此之间具有密切的相互依赖性。
>
> 如果将应用程序分解为服务，则可以使用不同的语言和技术构建每个服务。虽然这提供了更大的灵活性，但这意味着每个组件都有自己的依赖关系，并且需要特定于语言的库来访问底层平台以及与父应用程序共享的任何资源。此外，将这些功能部署为单独的服务可能会增加应用程序的延迟。管理这些特定于语言的接口的代码和依赖关系也会增加相当大的复杂性，尤其是对于托管、部署和管理服务。

### 1.2 什么是 Sidecar（边车）模式

将一组紧密结合的任务与主应用程序共同放在一台主机（Host）中，但会将它们部署在各自的进程或容器中。这种方式也被称为“Sidecar（边车）模式”。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222248-20190128-sidecar.png)

边车服务不一定是应用程序的一部分，而是与之相关联。它适用于父应用程序的任何位置。Sidecar 支持与主应用程序一起部署的进程或服务。这就像是如下图所示的边三轮摩托车那样，将边车安装在一辆摩托车上，就变成了边三轮摩托车。每辆边三轮摩托车都有自己的边车。类似同样的方式，边车服务共享其父应用程序的主机。对于应用程序的每个实例，边车的实例被部署并与其一起托管。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222251-20190128-sidecar-bike.jpg)

### 1.3 边车模式的优点

- 在运行时环境和编程语言方面，边车独立于其主要应用程序，因此不需要为每种语言开发一个边车。
- 边车可以访问与主应用程序相同的资源。例如，边车可以监视边车和主应用程序使用的系统资源。
- 由于它靠近主应用程序，因此在它们之间进行通信时没有明显的延迟。
- 即使对于不提供可扩展性机制的应用程序，也可以使用边车通过将其作为自己的进程附加到与主应用程序相同的主机或子容器中来扩展功能。

> Sidecar模式通常与容器一起使用，并称为边车容器。

## 二、Sidecar 的实现

### 2.1 创建一个 springboot 项目

创建一个名为 06-other-service 的 springboot 项目，**当作一个第三方的项目**。

#### 编写其测试接口

```java
@RestController
public class TestController {

    @GetMapping("list")
    public String list(){
        return "other-service:list";
    }

}
```

#### 编写配置文件

```yml
server:
  port: 7001
```

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222259-image-20210130171206113.png)

### 2.2 创建一个 Maven 项目

创建一个名为 06-sidecar 的 Maven 子项目，用来实现 Sidecar。

### 2.3 编写导入相关依赖

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-netflix-sidecar</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-netflix-eureka-client</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

> 因为 Sidecar 要注册到 Eureka 上所以要导入 Eureka Client 的注解。

### 2.4 编写配置类

通过 @EnableSidecar 注解，来开启 Side 功能。

```java
@SpringBootApplication
@EnableSidecar
public class SideCarApplication {
    public static void main(String[] args) {
        SpringApplication.run(SideCarApplication.class,args);
    }
}
```

### 2.5 编写配置文件

```yml
server:
  port: 81

#指定Eureka服务的地址
eureka:
  client:
    service-url:
      defaultZone: http://root:root@localhost:8761/eureka, http://root:root@localhost:8762/eureka


#指定服务的名称
spring:
  application:
    name: OTHER-SERVICE

# 指定所代理的服务的端口号
sidecar:
  port: 7001
```

> Sidecar 只能代理本地的服务，所以不需要指定 ip只需要指定所代理的服务的端口号即可。

### 2.6 测试

在 Customer 中通过 Feign 的方式去调用此第三方服务。

#### 2.6.1 编写 client

```java
@FeignClient(value = "OTHER-SERVICE")
public interface OtherServiceClient {
    @RequestMapping("list")
    public String list();

}
```

#### 2.6.2 编写 controller

```java
//sideCar
@Autowired
private OtherServiceClient otherServiceClient;

@GetMapping("list")
public String list(){
    String list = otherServiceClient.list();
    return list;
}
```

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222266-image-20210130171127940.png)

