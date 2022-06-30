---
title: springcloud学习(十)-Sleuth(服务的追踪)
date: 2021-2-2
  - 微服务
  - springcloud学习(十)-Sleuth(服务的追踪)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(十)-Sleuth(服务的追踪)
---

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222640-spring-cloud.png)

<!--more-->

## 一、Sleuth 的介绍

在整个微服务架构中，微服务很多，一个请求可能需要调用很多很多的服务，最终才能完成一个功能，如果说，整个功能出现了问题，在这么多的服务中，很难定位到问题的所在点，出现问题的原因是什么，所以我们可以通过 Sleuth 来解决这个问题。

- Sleuth 可以获取得到整个服务链路的信息
- 可以通过 Zipkin 的图形化界面去看到信息。
- Sleuth 将日志信息存储到数据库中。

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222643-image-20201113131325996.png)

### 二、Sleuth 的使用

Zipkin 官网 https://zipkin.io/pages/quickstart。

### 2.1 导入依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
```

### 2.2 编写配置文件

```yml
logging:
  level:
    org.springframework.web.servlet.DispatcherServlet: DEBUG
```

### 2.3 测试

`[CUSTOMER-v1,4fcb8ee02acac7c9,4fcb8ee02acac7c9,false]`

`[服务名称,总链路id,当前服务的链路id,(不会将当前的日志信息，输出到其他系统中)]`

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222787-1655222646-image-20210202150426574.png)

## 三、Zipkin 的使用

### 3.1 通过 docker-compose 安装 Zipkin

```yml
version: "3.1"
services:
  zipkin:
    image: daocloud.io/daocloud/zipkin:latest
    restart: always
    container_name: zipkin
    ports:
      - 9411:9411
```

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222649-image-20210203103103174.png)

### 3.2 导入相关依赖

在项目中导入 Zipkin 的依赖，使其连接上 Zipkin。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-zipkin</artifactId>
</dependency>
```

### 3.3 编写配置文件

```yml
spring:
  sleuth:
    sampler:
      probability: 1 #百分之多少的sleuth信息需要输出到zipkin（1代表全部100%）
  zipkin:
    base-url: http://127.0.0.1:9411/  #指定zipkin的地址
```

### 3.4 测试

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222655-image-20210203103342618.png)

## 四、整合 RabbitMQ

### 4.1 导入 RabbitMQ 依赖

zipkin 依赖中已经包含了了 RabbitMQ 了。

### 4.2 添加配置信息

zipkin 默认使 HTTP 的方式，需要修改为 RabbitMQ 的方式。

```yml
spring:
  zipkin:
    sender:
      type: rabbit
```

### 4.3 修改 docker-compose 的配置文件

```yml
version: "3.1"
services:
  zipkin:
    image: daocloud.io/daocloud/zipkin:latest
    restart: always
    container_name: zipkin
    ports:
      - 9411:9411
    environment:
      - RABBIT_ADDRESSES=192.168.31.138:5672 #本地ipv4地址:端口
      - RABBIT_USER=test
      - RABBIT_PASSWORD=test
      - RABBIT_VIRTUAL_HOST=/test
```

### 4.4 测试

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222660-image-20210203105431133.png)

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222665-image-20210203105444277.png)

## 五、将 Zipkin 中的数据持久化到 ES

修改 docker-compose.yml 文件。

```yml
version: "3.1"
services:
  zipkin:
    image: daocloud.io/daocloud/zipkin:latest
    restart: always
    container_name: zipkin
    ports:
      - 9411:9411
    environment:
      - RABBIT_ADDRESSES=192.168.31.138:5672 #本地ipv4地址:端口
      - RABBIT_USER=test
      - RABBIT_PASSWORD=test
      - RABBIT_VIRTUAL_HOST=/test
      - STORAGE_TYPE=elasticsearch
      - ES_HOSTS=http://192.168.31.138:9200
```

> 启动时 zipkin 报了 `java.io.UncheckedIOException: java.net.NoRouteToHostException: No route to host`的异常，原因：**服务器没有放开 9200 端口。**