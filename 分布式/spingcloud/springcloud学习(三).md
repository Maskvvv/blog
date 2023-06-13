---
title: springcloud学习(三)-Ribbon(负载均衡器)
date: 2021-1-18
tags:
  - 微服务
  - springcloud学习(三)-Ribbon(负载均衡器)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(三)-Ribbon(负载均衡器)
---

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221890-spring-cloud.png)

<!--more-->

## 一、Ribbon的简介

### 1.1 简介

Spring Cloud Ribbon 是一个基于 HTTP 和 TCP 的客户端负载均衡工具，它基于 Netflix Ribbon 实现。通过 Spring Cloud 的封装，可以让我们轻松地将面向服务的 REST 模版请求自动转换成客户端负载均衡的服务调用。

> 目前主流的负载方案分为以下两种：
>
> - 集中式负载均衡，在消费者和服务提供方中间使用独立的代理方式进行负载，有硬件的（比如 F5），也有软件的（比如 Nginx）。
> - 客户端自己做负载均衡，根据自己的请求情况做负载，Ribbon 就属于客户端自己做负载。

### 1.2 引言

Robbin是帮助我们实现服务与服务之间的负载均衡。

> **客户端负载均衡：**customer客户端模块，将2个Search模块信息全部拉取到本地的缓存，在customer中自己做一个负载均衡的策略，选中某一个服务。
>
> **服务端负载均衡：**在注册中心中，直接根据你指定的负载均衡策略，帮你选中一个指定的服务器信息，并返回。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221893-image-20201111134022333.png)

## 二、快速入门

### 2.1 启动两个Search模块

通过 Run/Debug Configurations 启动两个 Search模块。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221896-image-20210119125229710.png)

### 2.2 导入Ribbon相关依赖

在 customer 中导入 Ribbon 相关依赖。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-ribbon</artifactId>
</dependency>
```

### 2.3 整合 RestTemplate 和 Ribbon

在注入 RestTemplate 的方法上添加 @LoadBalanced 注解，即可整合 RestTemplate 和 Ribbon 。

```java
//@LoadBalanced 将RestTemplate和Robbin整合
@Bean
@LoadBalanced
public RestTemplate restTemplate(){
    return new RestTemplate();
}
```

### 2.4 访问 Search

通过整合了 Ribbon 的 RestTemplate 去访问Search （**原来的 ip:port 现在可以用服务名代替**）。

```java
@GetMapping("/customer")
public String customer() {
    String result = restTemplate.getForObject("http://SEARCH/search", String.class);
    return result;
}
```

## 三、Ribbon 的负载均衡

Ribbon 作为一款**客户端负载均衡框架**，**默认**的负载策略是**轮询**，同时也提供了很多其他的策略，能够让用户根据自身的业务需求进行选择。

### 3.1 Ribbon负载均衡简介

1. **BestAvailabl**

   选择一个最小的并发请求的 Server，逐个考察 Server，如果 Server 被标记为错误，则跳过，然后再选择 ActiveRequestCount 中最小的 Server。

2. AvailabilityFilteringRule

   过滤掉那些一直连接失败的且被标记为 circuit tripped 的后端 Server，并过滤掉那些高并发的后端 Server 或者使用一个 AvailabilityPredicate 来包含过滤 Server 的逻辑。其实就是检查 Status 里记录的各个 Server 的运行状态。

3. ZoneAvoidanceRule

   使用 ZoneAvoidancePredicate 和 AvailabilityPredicate 来判断是否选择某个 Server，前一个判断判定一个 Zone 的运行性能是否可用，剔除不可用的 Zone（的所有 Server），AvailabilityPredicate 用于过滤掉连接数过多的 Server。

4. **RandomRule（随机策略）**

   随机选择一个 Server。

5. **RoundRobinRule（轮询策略）**

   轮询选择，轮询 index，选择 index 对应位置的 Server。

6. RetryRule

   对选定的负载均衡策略机上重试机制，也就是说当选定了某个策略进行请求负载时在一个配置时间段内若选择 Server 不成功，则一直尝试使用 subRule 的方式选择一个可用的 Server。

7. ResponseTimeWeightedRule

   作用同 WeightedResponseTimeRule，ResponseTime-Weighted Rule 后来改名为 WeightedResponseTimeRule。

8. **WeightedResponseTimeRule**

   默认会采用轮询的策略，，根据响应时间会自动分配一个 Weight（权重），响应时间越长，Weight 越小，被选中的可能性越低。

### 3.2 Ribbon负载均衡的使用

#### 3.2.1 采用注解的方式实现负载均衡

在 Ribbon Client 端注入策略的对象即可。

```java
//配置robbinRule策略
@Bean
public IRule robbinRule(){
    return new RandomRule();
}
```

#### 3.2.2 采用配置文件的方式实现负载均衡

```yml
#指定具体服务的负载均衡策略
SEARCH:        #编写服务名称
  ribbon:
    NFLoadBalancerRuleClassName: com.netflix.loadbalancer.WeightedResponseTimeRule  #具体负载均衡使用的类
```

