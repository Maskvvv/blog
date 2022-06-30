---
title: Spring Cloud-Gateway(网关)
date: 2021-4-28
tags:
  - 微服务
  - Spring Cloud-Gateway(网关)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - Spring Cloud
  - Spring Cloud-Gateway(网关)
---

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222796-spring-cloud.png)

<!--more-->

## 一、Spring Cloud Gateway 简介

SpringCloud Gateway 是 Spring Cloud 的一个全新项目，该项目是基于 Spring 5.0，Spring Boot 2.0 和 Project Reactor 等技术开发的网关，它旨在为微服务架构提供一种简单有效的统一的 API 路由管理方式。

SpringCloud Gateway 作为 Spring Cloud 生态系统中的网关，目标是**替代 Zuul**，在Spring Cloud 2.0以上版本中，没有对新版本的Zuul 2.0以上最新高性能版本进行集成，仍然还是使用的Zuul 2.0之前的非Reactor模式的老版本。而为了提升网关的性能，SpringCloud Gateway是**基于WebFlux框架**实现的，而WebFlux框架底层则使用了高性能的**Reactor模式通信框架Netty。**

Spring Cloud Gateway 的目标，不仅提供统一的路由方式，并且基于 Filter 链的方式提供了网关基本的功能，例如：**安全，监控/指标，和限流。**

> 注：**Spring Cloud Gateway 底层使用了高性能的通信框架Netty**。

### 1.1 Spring Cloud Gateway 特征

SpringCloud官方，对SpringCloud Gateway 特征介绍如下：

（1）基于 Spring Framework 5，Project Reactor 和 Spring Boot 2.0

（2）集成 Hystrix 断路器

（3）集成 Spring Cloud DiscoveryClient

（4）Predicates 和 Filters 作用于特定路由，易于编写的 Predicates 和 Filters

（5）具备一些网关的高级功能：动态路由、限流、路径重写

从以上的特征来说，和Zuul的特征差别不大。SpringCloud Gateway和Zuul主要的区别，还是在底层的通信框架上。

> **（1）Filter（过滤器）：**
>
> 和Zuul的过滤器在概念上类似，可以使用它拦截和修改请求，并且对上游的响应，进行二次处理。过滤器为org.springframework.cloud.gateway.filter.GatewayFilter类的实例。
>
> **（2）Route（路由）：**
>
> 网关配置的基本组成模块，和Zuul的路由配置模块类似。一个**Route模块**由一个 ID，一个目标 URI，一组断言和一组过滤器定义。如果断言为真，则路由匹配，目标URI会被访问。
>
> **（3）Predicate（断言）：**
>
> 这是一个 Java 8 的 Predicate，可以使用它来匹配来自 HTTP 请求的任何内容，例如 headers 或参数。**断言的**输入类型是一个 ServerWebExchange。

### 1.2 Spring Cloud Gateway和架构

Spring在2017年下半年迎来了Webflux，Webflux的出现填补了Spring在响应式编程上的空白，Webflux的响应式编程不仅仅是编程风格的改变，而且对于一系列的著名框架，都提供了响应式访问的开发包，比如Netty、Redis等等。

Spring Cloud Gateway 使用的Webflux中的reactor-netty响应式编程组件，底层使用了Netty通讯框架。

### 1.3 Spring Cloud Zuul的IO模型

Springcloud中所集成的Zuul版本，采用的是Tomcat容器，使用的是传统的Servlet IO处理模型。

大家知道，servlet由servlet container进行生命周期管理。container启动时构造servlet对象并调用servlet init()进行初始化；container关闭时调用servlet destory()销毁servlet；container运行时接受请求，并为每个请求分配一个线程（一般从线程池中获取空闲线程）然后调用service()。

**弊端：**servlet是一个简单的网络IO模型，**当请求进入servlet container时，servlet container就会为其绑定一个线程**，在**并发不高的场景下这种模型是适用**的，但是一旦并发上升，线程数量就会上涨，而线程资源代价是昂贵的（上线文切换，内存消耗大）严重影响请求的处理时间。在一些简单的业务场景下，**不希望为每个request分配一个线程，只需要1个或几个线程就能应对极大并发的请求，**这种业务场景下servlet模型没有优势。

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222800-19816137-bb466f6b0135bb71.jpg)

所以**Springcloud Zuul 是基于servlet之上的一个阻塞式处理模型**，即spring实现了处理所有request请求的一个servlet（DispatcherServlet），并由该servlet阻塞式处理处理。所以Springcloud Zuul无法摆脱servlet模型的弊端。虽然Zuul 2.0开始，使用了Netty，并且已经有了大规模Zuul 2.0集群部署的成熟案例，但是，Springcloud官方已经没有集成改版本的计划了。

### 1.4 Webflux 服务器

Webflux模式替换了旧的Servlet线程模型。**用少量的线程处理request和response io操作**，这些线程称为**Loop线程**，而业务交给响应式编程框架处理，响应式编程是非常灵活的，用户可以将业务中阻**塞的操作提交到响应式框架的work线程中执行**，而**不阻塞的操作依然可以在Loop线程中进行处理**，大大提高了Loop线程的利用率。官方结构图：

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222806-19816137-dad0e43fc31f4536.jpg)

Webflux虽然可以兼容多个底层的通信框架，但是一般情况下，**底层使用的还是Netty**，毕竟，Netty是目前业界认可的最高性能的通信框架。而Webflux的Loop线程，正好就是著名的Reactor 模式IO处理模型的Reactor线程，如果使用的是高性能的通信框架Netty，这就是Netty的EventLoop线程。

### 1.5 Spring Cloud Gateway的处理流程

客户端向 Spring Cloud Gateway 发出请求。然后在 Gateway Handler Mapping 中找到与请求相匹配的路由，将其发送到 Gateway Web Handler。Handler 再通过指定的过滤器链来将请求发送到我们实际的服务执行业务逻辑，然后返回。**过滤器之间用虚线分开是因为过滤器可能会在发送代理请求之前（“pre”）或之后（“post”）执行业务逻辑。**

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222809-spring_cloud_gateway_diagram.png)

## 二、路由的配置方式

### 2.1 基于配置文件配置

```yml
server:
  port: 8080
spring:
  application:
    name: gateway
  cloud:
    gateway:
      routes:
        - id: products_route
          uri: http://localhost:9999/
          predicates:
            - Path=/product/**
            - After=2021-04-24T16:52:42.375+08:00[Asia/Shanghai]
            # - Cookie=username, mask
            # - Before=2021-04-24T16:54:42.375+08:00[Asia/Shanghai]
            
        - id: user_route
          uri: http://localhost:9999/
          predicates:
            - Path=/feign/**
```

> 各字段含义如下：
>
> - **id：**我们自定义的路由 ID，保持唯一
> - **uri：**要跳转的目标服务地址
> - **predicates：**路由条件，Predicate 接受一个输入参数，返回一个布尔值结果。该接口包含多种默认方法来将 Predicate 组合成其他复杂的逻辑（比如：与，或，非）。

### 2.2 基于代码的路由配置方式

```java
@SpringBootApplication
public class GatewayApplication {
 
    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }
 
    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("path_route", r -> r.path("/product")
                        .uri("http://localhost:9999/"))
                .build();
    }
 
}
```

### 2.3 和注册中心相结合的路由配置方式

```yml
server:
  port: 8080
spring:
  application:
    name: gateway
  cloud:
    gateway:
      routes:
        - id: products_route
          #uri: http://localhost:9999/
          uri: lb://products
          predicates:
            - Path=/product/**
            - After=2021-04-24T16:52:42.375+08:00[Asia/Shanghai]
            
        - id: user_route
          # uri: http://localhost:9999/
          uri: lb://users
          predicates:
            - Path=/feign/**
```

## 三、路由配置规则

Spring Cloud Gateway 的功能很强大，我们仅仅通过 Predicates 的设计就可以看出来，前面我们只是使用了 predicates 进行了简单的条件匹配，其实 Spring Cloud Gataway 帮我们内置了很多 Predicates 功能。

Spring Cloud Gateway 是通过 Spring WebFlux 的 HandlerMapping 做为底层支持来匹配到转发路由，Spring Cloud Gateway 内置了很多 Predicates 工厂，这些 Predicates 工厂通过不同的 HTTP 请求参数来匹配，多个 Predicates 工厂可以组合使用。

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222816-20200527213652534.png)

gateWay的主要功能之一是转发请求，转发规则的定义主要包含三个部分：

|          属性           | 简介                                                         |      |
| :---------------------: | :----------------------------------------------------------- | ---- |
|      Route（路由）      | 路由是网关的基本单元，由ID、URI、一组Predicate、一组Filter组成，根据Predicate进行匹配转发。 |      |
| Predicate（谓语、断言） | 路由转发的判断条件，目前SpringCloud Gateway支持多种方式，常见如：Path、Query、Method、Header等，写法必须遵循 key=vlue的形式 |      |
|    Filter（过滤器）     | 过滤器是路由转发请求时所经过的过滤逻辑，可用于修改请求、响应内容 |      |

### 3.1 Predicate 断言条件(转发规则)介绍

Predicate 来源于 Java 8，是 Java 8 中引入的一个函数，Predicate 接受一个输入参数，返回一个布尔值结果。该接口包含多种默认方法来将 Predicate 组合成其他复杂的逻辑（比如：与，或，非）。可以用于接口请求参数校验、判断新老数据是否有变化需要进行更新操作。

在 Spring Cloud Gateway 中 Spring 利用 Predicate 的特性实现了各种路由匹配规则，有通过 Header、请求参数等不同的条件来进行作为条件匹配到对应的路由。

![ Spring Cloud 内置的几种 Predicate 的实现](http://qiniu.zhouhongyin.top/2022/06/15/1655222821-19816137-bb046dbf19bee1b4.gif)

Predicate 就是为了实现一组匹配规则，方便让请求过来找到对应的 Route 进行处理，下面是 Spring Cloud GateWay 内置几种 Predicate 的使用。

| 规则    | 实例                                                         | 说明                                                         |
| :------ | :----------------------------------------------------------- | :----------------------------------------------------------- |
| Path    | - Path=/gate/**,/rule/**                                     | ## 当请求的路径为gate、rule开头的时，转发到http://localhost:9023服务器上 |
| Before  | - Before=2017-01-20T17:42:47.789-07:00[America/Denver]       | 在某个时间之前的请求才会被转发到 http://localhost:9023服务器上 |
| After   | - After=2017-01-20T17:42:47.789-07:00[America/Denver]        | 在某个时间之后的请求才会被转发                               |
| Between | - Between=2017-01-20T17:42:47.789-07:00[America/Denver],2017-01-21T17:42:47.789-07:00[America/Denver] | 在某个时间段之间的才会被转发                                 |
| Cookie  | - Cookie=chocolate, ch.p                                     | 名为chocolate的表单或者满足正则ch.p的表单才会被匹配到进行请求转发 |
| Header  | - Header=X-Request-Id, \d+                                   | 携带参数X-Request-Id或者满足\d+的请求头才会匹配              |
| Host    | - Host=www.hd123.com                                         | 当主机名为www.hd123.com的时候直接转发到http://localhost:9023服务器上 |
| Method  | - Method=GET                                                 | 只有GET方法才会匹配转发请求，还可以限定POST、PUT等请求方式   |

## 四、过滤器规则（Filter）

| 过滤规则             | 实例                                                         | 说明                                                         |
| :------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| PrefixPath           | - PrefixPath=/app                                            | 在请求路径前加上app                                          |
| RewritePath          | - RewritePath=/test, /app/test                               | 访问localhost:9022/test,请求会转发到localhost:8001/app/test  |
| SetPath              | - SetPath=/app/{path}                                        | 通过模板设置路径，转发的规则时会在路径前增加app，{path}表示原请求路径 |
| RedirectTo           | - RedirectTo=302, https://acme.org                           | 重定向，配置包含重定向的返回码和地址                         |
| RemoveRequestHeader  | \- RemoveRequestHeader=X-Request-Foo                         | 去掉某个请求头信息                                           |
| RemoveResponseHeader | - RemoveResponseHeader=X-Request-Foo                         | 去掉某个响应头信息                                           |
| SetStatus            | - SetStatus=401                                              | 设置回执状态码。                                             |
| StripPrefix          | \- StripPrefix=2                                             | predicates:        - Path=/name/**        filters:        - StripPrefix=2：请求/name/blue/red会转发到/red。 |
| RequestSize          | ![](http://qiniu.zhouhongyin.top/2022/06/15/1655222834-image-20210428103242164.png) | 超过5M的请求会返回413错误。                                  |
| Default-filters      | ![](http://qiniu.zhouhongyin.top/2022/06/15/1655222842-image-20210428103329749.png) | 对所有请求添加过滤器                                         |

**例子：**

```yml
spring:
  cloud:
    gateway:
      routes:
      - id: prefixpath_route
        uri: https://example.org
        filters:
        - PrefixPath=/mypath
```

## 五、跨域问题

```yml
spring:
  cloud:
    gateway:
      globalcors:
        cors-configurations:
          '[/**]':
          allowedOrigins: "*"
          allowedHeaders: "*"
          allow-credentials: true
          allowedMethods: "*"
        add-to-simple-url-handler-mapping: true
```

## 六、Gatway 网关的过滤器开发

Spring-Cloud-Gateway 基于过滤器实现，同 zuul 类似，有**pre**和**post**两种方式的 filter,分别处理**前置逻辑**和**后置逻辑**。客户端的请求先经过**pre**类型的 filter，然后将请求转发到具体的业务服务，收到业务服务的响应之后，再经过**post**类型的 filter 处理，最后返回响应到客户端。

过滤器执行流程如下，**order 越大，优先级越低**

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222860-spring-cloud-gateway-fliter-order.png)

### 7.1定义 GlobalFilter

```java
@Configuration
public class FilterConfig
{

    @Bean
    @Order(-1)
    public GlobalFilter a()
    {
        return new AFilter();
    }

    @Bean
    @Order(0)
    public GlobalFilter b()
    {
        return new BFilter();
    }

    @Bean
    @Order(1)
    public GlobalFilter c()
    {
        return new CFilter();
    }


    @Slf4j
    public class AFilter implements GlobalFilter, Ordered
    {

        @Override
        public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain)
        {
            log.info("AFilter前置逻辑");
            return chain.filter(exchange).then(Mono.fromRunnable(() ->
            {
                log.info("AFilter后置逻辑");
            }));
        }

        //   值越小，优先级越高
//    int HIGHEST_PRECEDENCE = -2147483648;
//    int LOWEST_PRECEDENCE = 2147483647;
        @Override
        public int getOrder()
        {
            return HIGHEST_PRECEDENCE + 100;
        }
    }

    @Slf4j
    public class BFilter implements GlobalFilter, Ordered
    {
        @Override
        public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain)
        {
            log.info("BFilter前置逻辑");
            return chain.filter(exchange).then(Mono.fromRunnable(() ->
            {
                log.info("BFilter后置逻辑");
            }));
        }


        //   值越小，优先级越高
//    int HIGHEST_PRECEDENCE = -2147483648;
//    int LOWEST_PRECEDENCE = 2147483647;
        @Override
        public int getOrder()
        {
            return HIGHEST_PRECEDENCE + 200;
        }
    }

    @Slf4j
    public class CFilter implements GlobalFilter, Ordered
    {

        @Override
        public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain)
        {
            log.info("CFilter前置逻辑");
            return chain.filter(exchange).then(Mono.fromRunnable(() ->
            {
                log.info("CFilter后置逻辑");
            }));
        }

        //   值越小，优先级越高
//    int HIGHEST_PRECEDENCE = -2147483648;
//    int LOWEST_PRECEDENCE = 2147483647;
        @Override
        public int getOrder()
        {
            return HIGHEST_PRECEDENCE + 300;
        }
    }
}
```

