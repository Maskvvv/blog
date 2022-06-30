---
title: springcloud学习(二)-Eureka(服务的注册与发现)
date: 2021-1-16
tags:
  - 微服务
  - springcloud学习(二)-Eureka(服务的注册与发现)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(二)-Eureka(服务的注册与发现)
---

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221817-spring-cloud.png)

<!--more-->

## 一、Eureka 简介

Spring Cloud Eureka 是 Spring Cloud Netflix 微服务套件的一部分，基于 Netflix Eureka 做了二次封装，主要负责实现微服务架构中的服务治理功能。

Eureka可以帮助我们维护所有服务的信息，以便服务之间的相互调用。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221821-1605019839175.png)

## 二、Eureka 的快速入门

创建一个 springboot 父工程，并命名为 first-springcloud 。

### 2.1 修改它的 pom.xml

1. 添加\<packaging>pom\</packaging>
2. 指定springcloud版本

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.4.1</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.zhy</groupId>
    <artifactId>first-springcloud</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>first-springcloud</name>
    <description>Demo project for Spring Boot</description>

    <packaging>pom</packaging>

    <properties>
        <java.version>1.8</java.version>
    </properties>

    <!--指定spring cloud版本-->
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>Hoxton.SR4</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>

</project>
```

### 2.2创建 Eureka 的 Server（服务注册中心）

创建一个  Maven 子工程，并命名为 01-eureka。

#### 2.2.1 编写 pom.xml 文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>first-springcloud</artifactId>
        <groupId>com.zhy</groupId>
        <version>0.0.1-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>01-eureka</artifactId>

    <dependencies>
        <!--Eureka server依赖 -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>


</project>
```

#### 2.2.2 编写启动类

需要在启动类上加上 @EnableEurekaServer 注解，示开启 Eureka Server。

```java
@SpringBootApplication
@EnableEurekaServer
public class EurekaApplication {
    public static void main(String[] args) {
        SpringApplication.run(EurekaApplication.class,args);
    }
}
```

#### 2.2.3 编写配置文件

```yml
server:
  port: 8761
eureka:
  instance:
    hostname: localhost
  #当前的eureka是单机版的
  client:
    # 由于该应用为注册中心, 所以设置为false, 代表不向注册中心注册自己
    registerWithEureka: false
    # 由于注册中心的职责就是维护服务实例, 它并不需要去检索服务, 所以也设置为 false
    fetchRegistry: false
    serviceUrl:
      defaultZone: http://${eureka.instance.hostname}:${server.port}/eureka/
```

#### 2.2.4 测试

访问 http://localhost:8761/ ，然后便会看到 Eureka 提供的 Web 控制台。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221826-image-20210118132736240.png)

### 2.3 创建Eureka的服务消费者（EurekaClient）

创建一个 Maven 子工程，命名为02-Customer。

#### 2.3.1 编写pom.xml文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <parent>
        <artifactId>first-springcloud</artifactId>
        <groupId>com.zhy</groupId>
        <version>0.0.1-SNAPSHOT</version>
    </parent>
    <modelVersion>4.0.0</modelVersion>

    <artifactId>02-customer</artifactId>

    <dependencies>
	 	<!--Eureka client依赖 -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
    </dependencies>

</project>
```

#### 2.3.2 创建启动类

添加 @EnableEurekaClient ，表示当前服务是一个 Eureka 的客户端。

```java
@SpringBootApplication
@EnableEurekaClient
public class CustomerApplication {
    public static void main(String[] args) {
        SpringApplication.run(CustomerApplication.class,args);
    }
}
```

#### 2.3.3 编写配置文件

```yml
#指定Eureka服务地址
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka

#指定服务名称
spring:
  application:
    name: CUSTOMER
```

### 2.4 创建Eureka的服务提供者（EurekaClient）

创建一个 Maven 子工程，命名为03-Search。

#### 2.4.1 编写pom.xml文件

同2.3.1。

#### 2.4.2 创建启动类

```java
@SpringBootApplication
@EnableEurekaClient
public class SearchApplication {
    public static void main(String[] args) {
        SpringApplication.run(SearchApplication.class,args);
    }
}
```

#### 2.4.3 编写配置文件

```yml
# 指定Eureka服务地址
eureka:
  client:
    service-url:
      defaultZone: http://localhost:8761/eureka

# 指定服务名称
spring:
  application:
    name: SEARCH
# 指定服务端口号
server:
  port: 8081
```

### 2.5 测试 Eureka

#### 2.5.1 编写 Search 模块

在 Search 模块中创建接口提供服务。

```java
@RestController
public class SearchController {
    @GetMapping("search")
    public String search(){
        return "search";
    }
}
```

#### 2.5.2 编写 Customer 模块

#### 2.5.1 注入RestTemplate 

在 customer 项目的启动类中编写。

```java
@Bean
public RestTemplate restTemplate(){
    return new RestTemplate();
}
```

#### 2.5.2 创建 CustomerController 接口

创建 CustomerController  ，通过 RestTemplate 去调用 Search 提供的服务。

```java
@RestController
public class CustomerController {

    @Autowired
    private RestTemplate restTemplate;

    @Resource
    private EurekaClient eurekaClient;

    @GetMapping("customer")
    public String customer(){
        //1.通过eurekaCilent获取search服务的信息，参数1：指定服务名 参数2：指定请求时http或https（false表示http）
        InstanceInfo info = eurekaClient.getNextServerFromEureka("SEARCH", false);

        //2.获取到访问地址
        String url = info.getHomePageUrl();
        System.out.println(url);

        //3.通过restTemplate访问
        String result = restTemplate.getForObject(url+"search", String.class);
        
        return result;
    }
```

## 三、 Eureka的安全性

通过整合 spring Security 来实现需要输入密码才能查看 Eureka 的管理后台。

### 3.1 编写 Eureka Server

#### 3.1.1 添加 Security 依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

####  3.1.2 创建 Security 配置类

```java
@EnableWebSecurity
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().ignoringAntMatchers("/eureka/**");
        super.configure(http);
    }
}
```

#### 3.1.3 修改配置文件

设置账号密码。

```yml
spring:
  security:
    user:
      name: root
      password: root
```

### 3.2 修改 Eureka Client

在 url 上添加上 Eureka Server 的账号密码，否则会无法注册和拉取服务。

```yml
#指定Eureka服务地址
eureka:
  client:
    service-url:
      defaultZone: http://用户名:密码@localhost:8761/eureka
```

## 四、Eureka的高可用性

搭建集群，保证当 Eureka 宕机时，还有一台 Eureka 可以使用，确保服务可以正常运行。

> 如果程序正在运行，突然Eureka宕机了
>
> 1. 如果调用方访问过一次被调用方，Eureka的宕机就不会影响到功能
>
> 2. 如果调用方没有访问过被调用方，Eureka的宕机就会造成当前功能的不可用到功能

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221832-image-20201111110217411.png)

### 4.1 创建 一个 Eureka Server

创建一个新的 Maven 项目 04-high-availability，配置跟 01-eureka 一样，端口为8762。

### 4.2 让多台 Eureka 之间相互通讯

```yml
server:
  port: 8762
  
eureka:
  client:
    #当前的eureka是单机版的 false单机版  true集群
    registerWithEureka: true
    fetchRegistry: true
    serviceUrl:
      # 需要通讯的另一台Eureka的url
      defaultZone: http://root:root@localhost:8761/eureka/
```

```yml
server:
  port: 8761
  
eureka:
  client:
    #当前的eureka是单机版的 false单机版  true集群
    registerWithEureka: true
    fetchRegistry: true
    serviceUrl:
      # 需要通讯的另一台Eureka的url
      defaultZone: http://root:root@localhost:8762/eureka/
```

> 当我们的注册中心有多个节点后，就需要修改 eureka.client.serviceUrl.defaultZone 的配置为多个节点的地址，**多个地址用英文逗号隔开**即可。

### 4.3 让服务注册到多台Eureka上

修改 Eureka Client ，使其可以注册到多台 Eureka 上。

```yml
#指定Eureka服务的地址
eureka:
  client:
    service-url:
      defaultZone: http://root:root@localhost:8761/eureka, http://root:root@localhost:8762/eureka
```

## 五、Eureka的其他细节

### 5.1 Eureka Client失效

在实际开发过程中，我们可能会不停地重启服务，由于 Eureka 有自己的保护机制，故节点下线后，服务信息还会一直存在于 Eureka 中。

1. EurekaClient启动时，将自己的信息注册到EurekaServer上，EurekaServer就会储存EurekaClient的注册信息。

2. 当EurekaClient调用服务时，本地没有注册信息的缓存时，去EurekaServer中获取注册信息

3. EurekaClient会通过心跳的方式去和EurekaServer进行连接。（默认30s EurekaClient就会发送一次心跳请求，如果超过了90s还没有发送心跳信息的话，EurekaSevrer就认为你宕机了，将当前的EurekaClient从注册表中移除）

在**Eureka Client 配置文件**中添加相关配置。

```yml
eureka:
  client:
    # 表示多久去更新本地注册表，EurekaClient会每个30s去EurekaServer中去更新本地的注册表
    registry-fetch-interval-seconds: 30
  instance:
    # 向eurekaServer发送消息标识eurekaClient没有宕机
    lease-expiration-duration-in-seconds: 90
    lease-renewal-interval-in-seconds: 30
```

### 5.2 Eureka 的自我保护机制

保护模式主要在一组客户端和 Eureka Server 之间存在网络分区场景时使用。一旦进入保护模式，Eureka Server 将会尝试保护其服务的注册表中的信息，不再删除服务注册表中的数据。当网络故障恢复后，该 Eureka Server 节点会自动退出保护模式。

> Eureka的自我保护机制，统计15分钟内，如果一个服务的心跳发送比例低于85%，EurekaServer就会开启自我保护机制
>
> 1. 不会从EurekaServer中去移除长时间没有收到心跳的服务
>
> 2. EurekaServer还是可以正常提供服务的
>
> 3. 网络稳定时，EurekaServer才会开始将自己的信息被其他节点同步过去

如果在 Eureka 的 Web 控制台看到下图所示的内容，就证明 Eureka Server 进入保护模式了。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221836-image-20201111132523595.png)

在**Eureka Server 配置文件**中添加相关配置。

```yml
eureka:
  # Eureka保护机制配置
  server:
  	#true 开启  false关闭
    enable-self-preservation: true  
```

### 5.3 CAP定理

CAP定理，C-一致性 A-可用性 P-分区容错性，这三个特新在分布是环境下，只能满足2个，而且分区容错性在分布式环境下，时必须要满足的。只能在AC之间进行权衡。

1. 如果选择CP，保证了一致性，可能会造成你系统在一定时间内是不可以的，如果你同步数据的时间比较长，造成的损失就越大。

2. 如果选择AP的效果，高可用的集群，Eureka集群是无中心，Eureka即便宕机几个也不会影响系统的使用，不需要重新去枚举一个master，也会导致一定时间内数据是不一致。