---
title: springcloud学习(九)-Config(服务的动态配置)
date: 2021-1-31
tags:
  - 微服务
  - springcloud学习(九)-Config(服务的动态配置)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(九)-Config(服务的动态配置)
---

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222461-spring-cloud.png)

<!--more-->

## 一、Config 的介绍

**Config 可以解决的问题：**

- 配置文件分散在不同项目中的，不方便去维护。
- 配置文件的安全问题。
- 修改配置文件，无法立即生效。

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222465-image-20201112180552221.png)

## 二、搭建 Config Server

### 2.1 创建 Maven 工程

创建一个名为 07-config 的 Maven 子项目。

### 2.2 导入依赖

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-config-server</artifactId>
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

### 2.3 编写启动类

添加 @EnableConfigServer 注解来开启 Config 服务。

```java
@SpringBootApplication
@EnableConfigServer
public class ConfigApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConfigApplication.class,args);
    }
}
```

### 2.4 编写配置文件

```yml
#指定Eureka服务的地址
eureka:
  client:
    service-url:
      defaultZone: http://root:root@localhost:8761/eureka, http://root:root@localhost:8762/eureka

#指定服务的名称
spring:
  application:
    name: CONFIG
  cloud:
    config:
      server:
        git:
          basedir:     *:\**** # 本地仓库地址
          username:    xxxxxx #远程仓库的用户名
          password:    xxxxxxxx #远程仓库的密码
          uri: https://gitee.com/****/config-resp.git #远程仓库地址
server:
  port: 8083
```

### 2.5 测试

访问路径 http://localhost:8083/master/customer-xxx.yml。

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222470-image-20210201124403737.png)

> **访问规则如下：**
>
> - `/{application}/{profile}[/{label}]`
> - `/{application}-{profile}.yml`
> - `/{label}/{application}-{profile}.yml`
> - `/{application}-{profile}.properties`
> - `/{label}/{application}-{profile}.properties`

## 三、搭建 Config Client

修改 Coustomer ，使其连接 Config Server。

### 3.1 导入依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-config-client</artifactId>
</dependency>
```

### 3.2 编写配置文件

```yml
#指定Eureka服务的地址
eureka:
  client:
    service-url:
      defaultZone: http://root:root@localhost:8761/eureka, http://root:root@localhost:8762/eureka

version: v1

spring:
  application:
    name: CUSTOMER-${version}
  cloud:
    config:
      discovery:
        enabled: true # 开启 Config client
        service-id: CONFIG # 指定 Config Server 服务名
      profile: dev # 只当配置文件的环境名
```

> 这样就会去 Config Server 中去拉取名为 customer-v1-dev.yml （项目名-版本-开发环境）的配置文件。

### 3.3 修改配置文件名

将 Config Client 的配置文件名修改为 **bootstrap.yml**，目的是为了 让此配置文件先于 application.yml 加载，防止项目出错。

## 四、Config 动态配置

### 4.1 动态配置的简介

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222476-image-20201113103152115.png)

### 4.2 服务连接 RabbitMQ

#### 4.2.1 导入依赖

在 Config Server 和 Config Client 中都导入依赖，其它们都连接 RabbitMQ。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-bus-amqp</artifactId>
</dependency>
```

#### 4.2.2 编写配置文件

在 Config Server 和 Config Client 配置文件中编写 RabbitMQ 的连接信息。

```yml
spring:
  rabbitmq:
    host: 192.168.31.138
    port: 5672
    username: test
    password: test
    virtual-host: /test
```

#### 4.2.3 测试

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222480-image-20210202114243453.png)

### 4.3 实现手动刷新配置文件

#### 4.3.1 导入相关依赖

Config Server 和Config Client 中都需要导入。

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

#### 4.3.2 编写配置文件

Config Server 和Config Client 中都需要添加此配置。

```yml
management:
  endpoints:
    web:
      exposure:
        include: "*"
```

#### 4.3.3 编写测试接口

```java
@RestController
@RefreshScope
public class CustomerController {
    //Config
    @Value("${env}")
    private String env;

    @GetMapping("/env")
    public String env() {
        return env;
    }
}
```

> 需要在 Controller 上添加 **@RefreshScope** 注解使手动刷新生效。

#### 4.3.4 测试

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222484-image-20210202120222541.png)

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222489-image-20210202120230894.png)

> 当 gitee 上的配置文件发生变化时，Config Server是可以获取到最新的配置文件的，但 Config Client 不可以需要重启项目，所以需要我们来向 http://localhost:10000/actuator/bus-refresh 发送一个 POST请求，就可以不用重启项目就可以更新 Config Client 的配置文件。

### 4.4 内网穿透

由于 Config Server 是本地项目，所以我们需要做内网穿透，使 gitee 可以访问到 Config Server。

#### 4.4.1 注册账号

网址 https://natapp.cn/。

#### 4.4.2 购买免费的隧道

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222492-image-20210202122225344.png)

#### 4.4.3 修改隧道的配置

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222499-image-20210202122418159.png)

#### 4.4.4 下载客户端

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222502-image-20210202122513048.png)

#### 4.4.5 编写配置文件

在客户端的同级路径下编写名为 config.ini 配置文件，只需要添加上你隧道的 authtoken 即可。

```ini
#将本文件放置于natapp同级目录 程序将读取 [default] 段
#在命令行参数模式如 natapp -authtoken=xxx 等相同参数将会覆盖掉此配置
#命令行参数 -config= 可以指定任意config.ini文件
[default]
authtoken=你的authtoken                    #对应一条隧道的authtoken
clienttoken=                    #对应客户端的clienttoken,将会忽略authtoken,若无请留空,
log=none                        #log 日志文件,可指定本地文件, none=不做记录,stdout=直接屏幕输出 ,默认为none
loglevel=ERROR                  #日志等级 DEBUG, INFO, WARNING, ERROR 默认为 DEBUG
http_proxy=                     #代理设置 如 http://10.123.10.10:3128 非代理上网用户请务必留空
```

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222505-image-20210202123057114.png)

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222509-image-20210202122749539.png)

#### 4.4.6 测试

双击 natapp.exe 运行。

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222518-image-20210202122951023.png)

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222522-image-20210202123018735.png)

### 4.5 实现自动刷新配置

#### 4.5.1 配置 Gitee 中的 WebHooks

配置 WebHooks 后，当我们修改 git 中的配置文件时，git 就会自动向 `http://ConfigServer ip/actuator/bus-refresh`发送 PSOT 请求，来更行配置文件。

![配置 Gitee 中的 WebHooks 图1](http://qiniu.zhouhongyin.top/2022/06/15/1655222526-image-20210202142303721.png)

![配置 Gitee 中的 WebHooks 图2](http://qiniu.zhouhongyin.top/2022/06/15/1655222529-image-20210202142450948.png)

![配置 Gitee 中的 WebHooks 图3](http://qiniu.zhouhongyin.top/2022/06/15/1655222559-image-20210202142548394.png)

#### 4.5.2 编写过滤器

因为 WebHooks 发送请求时会携带参数，如果不把参数过滤掉会发生400异常，所以需要在 Config Server 中添加一个过滤器。

```java
@WebFilter("/*")
public  class UrlFilter implements Filter {
    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        HttpServletRequest httpServletRequest= (HttpServletRequest) servletRequest;
        String url=httpServletRequest.getRequestURI();
        System.out.println(url);
        if(!url.endsWith("/actuator/bus-refresh")){
            filterChain.doFilter(servletRequest,servletResponse);
            return;
        }
        String body=(httpServletRequest).toString();
        System.out.println("original body: "+ body);
        RequestWrapper requestWrapper=new RequestWrapper(httpServletRequest);
        filterChain.doFilter(requestWrapper,servletResponse);
    }
    private class RequestWrapper extends HttpServletRequestWrapper {
        public RequestWrapper(HttpServletRequest request) {
            super(request);
        }

        @Override
        public ServletInputStream getInputStream() throws IOException {
            byte[] bytes = new byte[0];
            ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(bytes);
            ServletInputStream servletInputStream = new ServletInputStream() {
                @Override
                public int read() throws IOException {
                    return byteArrayInputStream.read();
                }

                @Override
                public boolean isFinished() {
                    return byteArrayInputStream.read() == -1 ? true : false;
                }

                @Override
                public boolean isReady() {
                    return false;
                }

                @Override
                public void setReadListener(ReadListener listener) {

                }
            };
            return servletInputStream;
        }
    }
}
```

#### 4.5.3 编辑启动类

在启动类上添加 @ServletComponentScan("") 注解，使 filter 注入到 spring 中。

```java
@SpringBootApplication
@EnableConfigServer
@ServletComponentScan("com.zhy.filter")
public class ConfigApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConfigApplication.class,args);
    }

}
```

#### 4.5.4 测试

![](http://qiniu.zhouhongyin.top/2022/06/15/1655222540-image-20210202143117725.png)