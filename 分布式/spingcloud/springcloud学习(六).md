---
title: springcloud学习(六)-Zuul(网关)
date: 2021-1-26
tags:
  - 微服务
  - springcloud学习(六)-Zuul(网关)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(六)-Zuul(网关)
---

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222069-spring-cloud.png)

<!--more-->

## 一、Zuul 的介绍

Zuul 是 Netflix OSS 中的一员，是一个基于 JVM 路由和服务端的负载均衡器。提供路由、监控、弹性、安全等方面的服务框架。Zuul 能够与 Eureka、Ribbon、Hystrix 等组件配合使用。

Zuul 的核心是过滤器，通过这些过滤器我们可以扩展出很多功能，比如：

1. **动态路由**

   动态地将客户端的请求路由到后端不同的服务，做一些逻辑处理，比如聚合多个服务的数据返回。

2. **请求监控**

   可以对整个系统的请求进行监控，记录详细的请求响应日志，可以实时统计出当前系统的访问量以及监控状态。

3. **认证鉴权**

   对每一个访问的请求做认证，拒绝非法请求，保护好后端的服务。

4. **压力测试**

   压力测试是一项很重要的工作，像一些电商公司需要模拟更多真实的用户并发量来保证重大活动时系统的稳定。通过 Zuul 可以动态地将请求转发到后端服务的集群中，还可以识别测试流量和真实流量，从而做一些特殊处理。

5. **灰度发布**

   灰度发布可以保证整体系统的稳定，在初始灰度的时候就可以发现、调整问题，以保证其影响度。

> - 客户端维护大量的 ip 和 port 信息，直接访问指定服务
> - 认证和授权操作，解决需要在每一个模块中添加认证和授权操作
> - 项目迭代，服务拆分，服务要合并，需要客户端镜像大量的变化
> - 统一的把安全性校验都放在Zuul中

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222073-image-20201112110708902.png)

## 二、Zuul 快速入门

### 2.1 创建 Maven 工程

创建一个名为 05-Zuul 的Maven项目

### 2.2 导入相关依赖

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-zuul</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
</dependencies>
```

### 2.3 编写启动类

```java
@SpringBootApplication
@EnableEurekaClient
@EnableZuulProxy
public class ZuulApplication {

    public static void main(String[] args) {
        SpringApplication.run(ZuulApplication.class,args);
    }
}
```

> 开启 Zuul，只需要在启动类上添加 @EnableZuulProxy 注解即可。

### 2.4 编写配置文件

```yml
eureka:
  client:
    service-url:
      defaultZone: http://root:root@localhost:8761/eureka, http://root:root@localhost:8762/eureka

spring:
  application:
    name: ZUUL

server:
  port: 80
```

### 2.5 测试

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222076-image-20210126121343138.png)

## 三、Zuul 中常用的配置信息

### 3.1 Zuul的监控界面

#### 3.1.1 导入依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

#### 3.1.2 修改配置文件

```yml
#查看zuul的监考界面（开发时，配置为*，上线，不要配置）
management:
  endpoints:
    web:
      exposure:
        include: "*"
```

> 开发时配置方便查看 Zuul，实际上线时不需要配置。

#### 3.1.3 测试

访问路径 `http://localhost/actuator/routes`

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222079-image-20210126134743818.png)

### 3.2 忽略服务配置

两种忽略方式：

- **通过服务名忽略：**`ignored-services: 服务名`

  基于服务名忽略服务，无法通过监控界面查看。如果要忽略全部的服务，可以通过 `"*"`，这样默认配置的全部路径都会被忽略掉（自定义路由配置，通过这种方式是无法忽略的）。

- **通过请求路径忽略：**`ignored-patterns: /**/请求路径/**`

  监考界面依然可以查看，在访问的时候，404无法访问。（可以忽略自定义的路由配置）

```yml
# zuul的配置
zuul:
  #基于服务名忽略服务，无法查看,如果要忽略全部的服务，"*",默认配置的全部路径都会被忽略掉（自定义服务配置，通过这种方式是无法忽略的）
  ignored-services: eureka
  #监考界面依然可以查看，在访问的时候，404无法访问
  ignored-patterns: /**/search/**
```

### 3.3 自定义路由

#### 方式一

```yml
zuul:
  ignored-services: "*"
  ignored-patterns: /**/search/**
  # 自定义路由配置
  # 方式一
  routes:
    # 服务名: 映射路径
    search: /ss/**
    customer: /cc/**
```

#### 方式二

```yml
zuul:
  ignored-services: "*"
  ignored-patterns: /**/search/**
  # 自定义路由配置
  # 方式二
  routes:
    kehu: #自定义名称
      path: /ccc/** # 请求路径
      serviceId: customer # 服务名
```

### 3.4 灰度发布

可以为用户提供两个版本的服务，只需要在访问时指定服务的版本号。

#### 3.4.1 添加配置类

在 Zuul 中添加配置类，使灰度发布生效。

```java
@Bean
public PatternServiceRouteMapper serviceRouteMapper() {
    return new PatternServiceRouteMapper(
        "(?<name>^.+)-(?<version>v.+$)",
        "${version}/${name}");
    //命名规则
    //    服务名-v版本
    //    /v版本/路径
}
```

> - **服务的命名规则：**`服务名-v版本`
> - **访问路径：**`/v版本/路径`

#### 3.4.2 修改 Zuul 的配置

```yml
zuul:
  #基于服务名忽略服务，无法查看,如果需要用到-v的方式，一定要忽略掉
#  ignored-services: "*"
```

#### 3.4.3 准备连个服务，提供两个版本

```yml
version: v1

#指定服务的名称
spring:
  application:
    name: CUSTOMER-${version}
```

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222085-image-20210126143921860.png)

#### 3.4.4 编写测试接口

```java
//Zuul灰度发布
@Value("${version}")
private String version;

@GetMapping("/version")
public String version(){
    return version;
}
```

#### 3.4.5 测试

![image-20210126144532409](http://qiniu.zhouhongyin.top/2022/06/14/1655222183-image-20210126144532409.png)

-----

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222089-image-20210126144636706.png)

## 四、Zuul 的过滤器

### 4.1 Zuul 的过滤器的简介

客户端请求发送到Zuul服务商，首先通过PreFilter,如果正常放行，会把请求再次转发给RoutingFilter，请求转发到一个指定的服务，在指定的服务响应一个结果之后，再次走一个PostFilter的过滤器链，最终将响应信息返回给客户端。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222092-image-20201112140312697.png)

### 4.2 过滤器的快速入门

创建一个 POJO 类，继承 ZuulFilter 抽象类，并实现它的四个抽象方法。

-  **public String filterType()：**指定此过滤器的类型通过。
- **public int filterOrder()：**指定该过滤器的执行顺序（值越小，优先级越高）。
- **public boolean shouldFilter()：**指定是否开启过滤器。
- **public Object run() throws ZuulException：**指定过滤器中的具体业务代码。

```java
@Component
public class TestZuulFilter2 extends ZuulFilter {

    //指定过滤器的类型
    @Override
    public String filterType() {
        return FilterConstants.PRE_TYPE;
    }

    //指定执行顺序
    @Override
    public int filterOrder() {
        return FilterConstants.PRE_DECORATION_FILTER_ORDER + 1;
    }

    //指定过滤器是否开启
    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() throws ZuulException {
        System.out.println("prefix过滤器2已经在执行！");

        return null;
    }
}
```

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222099-image-20210127134203143.png)

### 4.3 PreFilter 实现 token 校验

#### 4.3.1 编写过滤器

```java
@Component
public class AuthenticationFilter extends ZuulFilter {
    @Override
    public String filterType() {
        return FilterConstants.PRE_TYPE;
    }

    @Override
    public int filterOrder() {
        return FilterConstants.PRE_DECORATION_FILTER_ORDER - 2;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() throws ZuulException {
        return null;
    }
}
```

#### 4.3.2 实现具体业务

```java
@Override
public Object run() throws ZuulException {

    //1.获取Request对象
    RequestContext requestContext = RequestContext.getCurrentContext();
    HttpServletRequest request = requestContext.getRequest();

    //2.获取token
    String token = request.getParameter("token");

    //3.校验token
    if (token == null || !"123".equalsIgnoreCase(token)) {
        //4.校验失败，返回响应数据
        requestContext.setSendZuulResponse(false);
        requestContext.setResponseStatusCode(HttpStatus.UNAUTHORIZED.value());
    }

    return null;
}
```

> 通过 `requestContext.setSendZuulResponse(false);`方法可以终止当前的请求，但不会影响其后面的过滤器，只会终止将此请求转发到其他的服务上。

#### 4.3.3 测试

访问路径 http://localhost/v1/customer/version?token=234。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222105-image-20210127161915284.png)

## 五、Zuul 的降级

### 5.1 创建 POJO 类，实现 FallbackProvider 接口

```java
@Component
public class ZuulFallBack implements FallbackProvider {
    //指定当前的fallback所要针对哪一个服务
    @Override
    public String getRoute() {
        return null;
    }
    
	//指定返回数据，或日志和其他业务实现
    @Override
    public ClientHttpResponse fallbackResponse(String route, Throwable cause) {
		return null;
    }
}
```

### 5.2 实现该接口的两个方法

```java
@Component
public class ZuulFallBack implements FallbackProvider {

    //指定当前的fallback所要针对哪一个服务
    @Override
    public String getRoute() {
        //所有服务
        return "*";
    }

    @Override
    public ClientHttpResponse fallbackResponse(String route, Throwable cause) {

        System.out.println("降级服务："+route);
        cause.printStackTrace();

        return new ClientHttpResponse() {
            @Override
            public HttpStatus getStatusCode() throws IOException {
                //指定具体的HttpStates
                return HttpStatus.INTERNAL_SERVER_ERROR;
            }

            @Override
            public int getRawStatusCode() throws IOException {
                //返回状态码
                return HttpStatus.INTERNAL_SERVER_ERROR.value();
            }

            @Override
            public String getStatusText() throws IOException {
                return HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase();
            }

            @Override
            public void close() {

            }

            @Override
            public InputStream getBody() throws IOException {
                //给用户相应的信息
                String msg = "当前服务：" + route + "出现问题！！！！";

                return new ByteArrayInputStream(msg.getBytes());
            }

            @Override
            public HttpHeaders getHeaders() {
                //指定响应头信息
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                return headers;
            }
        };
    }
}
```

### 5.3 测试

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222111-image-20210127164515151.png)

## 六、Zuul 的动态路由

当我需要修改映射路径时，需要去修改 Zuul 的配置文件，并重启项目，如果是一个上线的项目会有非常高的代价，所以我们可以通过动态路由来解决这个问题。

### 6.1 创建一个过滤器

创建一个普通的 POJO 类，继承并实现 ZuulFilter 接口。

```java
@Component
public class DynamicRoutingFilter extends ZuulFilter {
    @Override
    public String filterType() {
        return FilterConstants.PRE_TYPE;
    }

    @Override
    public int filterOrder() {
        return FilterConstants.PRE_DECORATION_FILTER_ORDER + 2;
    }

    @Override
    public boolean shouldFilter() {
        return true;
    }

    @Override
    public Object run() throws ZuulException {

        //1.获取Request对象
        RequestContext context = RequestContext.getCurrentContext();
        HttpServletRequest request = context.getRequest();

        //2.获取参数，redisKey ( 模拟使用redis )
        String redisKey = request.getParameter("redisKey");

        //3.判断
        if (redisKey != null && redisKey.equalsIgnoreCase("customer")){
            //http://localhost:8080/customer
            //指定服务名
            context.put(FilterConstants.SERVICE_ID_KEY,"customer-v1");  // localhost:8080
            //指定映射路径
            context.put(FilterConstants.REQUEST_URI_KEY,"/customer");   // /customer

        }else if (redisKey != null && redisKey.equalsIgnoreCase("search")){
            //http://localhost:8081/search/1
            context.put(FilterConstants.SERVICE_ID_KEY,"search");  // localhost:8080
            context.put(FilterConstants.REQUEST_URI_KEY,"/search/1");   // /customer
        }


        return null;
    }
}
```

### 6.2 测试

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222115-image-20210130125304937.png)

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222119-image-20210130125315690.png)