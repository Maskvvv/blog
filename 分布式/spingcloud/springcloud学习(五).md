---
title: springcloud学习(五)-Hystrix(服务的隔离及熔断器)
date: 2021-1-25
tags:
  - 微服务
  - springcloud学习(五)-Hystrix(服务的隔离及熔断器)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(五)-Hystrix(服务的隔离及熔断器)
---

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221982-spring-cloud.png)

<!--more-->

## 一、Hystrix 的简介

Hystrix 是 Netflix 针对微服务分布式系统采用的熔断保护中间件，相当于电路中的保险丝。

在分布式环境中，许多服务依赖项中的一些必然会失败。Hystrix 是一个库，通过添加延迟容忍和容错逻辑，帮助你控制这些分布式服务之间的交互。Hystrix 通过隔离服务之间的访问点、停止级联失败和提供回退选项来实现这一点，所有这些都可以提高系统的整体弹性。

在微服务架构下，很多服务都相互依赖，如果不能对依赖的服务进行隔离，那么服务本身也有可能发生故障，Hystrix 通过 HystrixCommand 对调用进行隔离，这样可以阻止故障的连锁效应，能够让接口调用快速失败并迅速恢复正常，或者回退并优雅降级。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221986-image-20201111162630381.png)

## 二、降级机制

当你的某一个服务出现超时、资源不足或异常时，可以执行一个降级方法，返回一个托底数据。

### 2.1 导入相关依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
</dependency>
```

### 2.2 在启动类上添加注解

在启动类上添加 @EnableCircuitBreaker 注解。

```java
@SpringBootApplication
@EnableEurekaClient
@EnableFeignClients
@EnableCircuitBreaker
public class CustomerApplication {
    public static void main(String[] args) {
        SpringApplication.run(CustomerApplication.class,args);
    }
}
```

### 2.3 编写降级方法

针对一个接口去编写降级方法（注意编写的降级方法，方法的描述需要与接口一致）。

```java
//降级方法，方法的描述要与接口一至
public Customer findByIdFallBack(@PathVariable Integer id){
    return new Customer(-1,"",0);
}
```

### 2.4 在接口上添加注解

在降级方法针对的接口上添加 @HystrixCommand(fallbackMethod ="降级方法名" ) 注解，并在他的 fallbackMethod 属性中指定降级方法的名称。

```java
@GetMapping("/search/{id}")
@HystrixCommand(fallbackMethod = "findByIdFallBack")
public Customer findById(@PathVariable Integer id){
    int i = 1/0;
    return searchClient.findById(id);
}

//降级方法，方法的描述要与接口一至
public Customer findByIdFallBack(@PathVariable Integer id){
    return new Customer(-1,"",0);

}
```

### 2.5 测试

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221990-image-20210125131100858.png)

## 三、线程隔离

### 3.1 引言

如果使用 Tomcat 的线程池去接收用户的请求，使用当前线程去执行其他服务的功能，如果某一个服务出现了故障，导致 tomcat 的线程大量的堆积，导致 tomcat 无法处理其他业务功能。

### 3.1 线程隔离的方式

1. **Hystrix线程池（默认）：**接收用户请求采用tomcat的线程池，执行业务代码，调用其他服务时，采用Hystrix的线程池。

2. **信号量：**使用的还是Tomcat的线程池，但是可以帮助我们去管理Tomcat的线程池。

### 3.2 [线程池和信号量的配置](https://github.com/Netflix/Hystrix/wiki/Configuration)

#### 3.2.1 线程池配置项

- 线程隔离策略：name = `hystrix.command.default.execution.isolation.strategy`,value = `THREAD`,`SEMAPHORE`
- 指定超时时间（只针对线程池）：name = `hystrix.command.default.execution.isolation.thread.timeoutInMilliseconds` ,value = `1000`
- 是否开启超时时间配置：name = `hystrix.command.default.execution.timeout.enabled`,value = `true`
- 超时之后是否中断线程：name = `hystrix.command.default.execution.isolation.thread.interruptOnTimeout`,value = `true`
- 取消任务之后是否中断线程：name = `hystrix.command.default.execution.isolation.thread.interruptOnCancel`,value = `false`

#### 3.2.2 信号量配置项

- 线程隔离策略：name = `hystrix.command.default.execution.isolation.strategy`,value = `THREAD`,`SEMAPHORE`
- 指定信号量的最大并发请求数：name = `hystrix.command.default.execution.isolation.semaphore.maxConcurrentRequests`,value = `10`

#### 3.2.3 使用

> @HystrixProperty 注解 name 属性的值具体要在 HystrixCommandProperties 类中查看。

```java
@GetMapping("/search/{id}")
@HystrixCommand(fallbackMethod = "findByIdFallBack",commandProperties = {
        @HystrixProperty(name = "execution.isolation.strategy",value = "THREAD"),
        @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds",value = "3000")
})
·    //int i = 1/0;
    return searchClient.findById(id);
}
```

## 四、断路器

### 4.1 断路器的介绍

当调用指定服务时，如果说这个服务的失败率达到你指定的阈值，断路器就会从 closed 状态，转变为 open 状态，指定服务时无法被访问的，如果你访问就直接走 fallback 方法。在一定时间内，open 状态会转变为 half open 状态，此时允许一个请求发送到我指定服务，如果成功，则转变为 closed ；如果失败，服务再次转变为 open 状态。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221995-image-20201111181650929.png)

### 4.2 配置熔断器的监控界面

#### 4.2.1 导入相关依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-hystrix-dashboard</artifactId>
</dependency>
```

#### 4.2.2 在启动类上添加注解

在启动类上添加熔断器的注解 @EnableHystrixDashboard。

```java
@SpringBootApplication
@EnableEurekaClient
@EnableFeignClients
@EnableCircuitBreaker
@EnableHystrixDashboard
@ServletComponentScan("com.zhy.servlet")
public class CustomerApplication {
    public static void main(String[] args) {
        SpringApplication.run(CustomerApplication.class,args);
    }

    //@LoadBalanced 将RestTemplate和Robbin整合
    @Bean
    @LoadBalanced
    public RestTemplate restTemplate(){
        return new RestTemplate();
    }

    //配置robbinRule策略
    @Bean
    public IRule robbinRule(){
        return new RandomRule();
    }
}
```

#### 4.2.3 编写一个 Servlet 路径

编写一个 类 Servlet 并继承 HystrixMetricsStreamServlet ，并通过 @WebServlet("/hystrix.stream") 注解指定映射路径。

```java
@WebServlet("/hystrix.stream")
public class HystrixServlet extends HystrixMetricsStreamServlet {
}
```

在启动类上添加 @ServletComponentScan("com.zhy.servlet") 注解，是 spring boot 可以扫描到我们编写的 Servlet。

#### 4.2.4 测试

在浏览器输入 http://localhost:8080/hystrix/ 路径，进入起始页面。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222000-image-20210125145218065.png)

输入刚才编辑的 Servlet 映射路径。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222007-image-20210125145513678.png)

查看当前线程

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222010-image-20210125145647040.png)

### 4.3 配置断路器的属性

#### 4.3.1 断路器的属性

- 断路器的开关：name = `hystrix.command.default.circuitBreaker.enabled`，value = `true`
- 失败阈值的总请求数（10s内）：name = `hystrix.command.default.circuitBreaker.requestVolumeThreshold`，value = `20`
- 10s内，请求总数失败率达到%多少时打开断路器：name = `hystrix.command.default.circuitBreaker.errorThresholdPercentage`，value = `50`
- 断路器open状态后，多少秒是拒绝请求的：name = `hystrix.command.default.circuitBreaker.sleepWindowInMilliseconds`，value = `5000`
- 强制让服务拒绝请求：name = `hystrix.command.default.circuitBreaker.forceOpen`，value = `false`
- 强制让服务接收请求：name = `hystrix.command.default.circuitBreaker.forceClosed`，value = `false`

#### 4.3.2使用

```java
@GetMapping("/search/{id}")
@HystrixCommand(fallbackMethod = "findByIdFallBack",commandProperties = {
        @HystrixProperty(name = "execution.isolation.strategy",value = "THREAD"),
        @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds",value = "3000"),
        @HystrixProperty(name = "circuitBreaker.enabled",value="true"),
        @HystrixProperty(name = "circuitBreaker.requestVolumeThreshold",value="10"),
        @HystrixProperty(name = "circuitBreaker.errorThresholdPercentage",value="70"),
        @HystrixProperty(name = "circuitBreaker.sleepWindowInMilliseconds",value="5000")
})
public Customer findById(@PathVariable Integer id){
    //int i = 1/0;
    return searchClient.findById(id);
}
```

## 五、请求缓存

### 5.1 请求缓存介绍

1. 请求缓存的声明周期是一次请求。

2. 请求缓存是缓存当前线程中的一个方法，将方法参数作为 key，方法的返回结果作为 value。

3. 在一次请求中，目标方法被调用过一次以后就都会被缓存 。

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222014-1605104987931.png)

### 5.2 请求缓存的实现

#### 5.2.1 创建一个 Service

创建一个Service，在Service中调用Search服务。

```java
@Service
public class CustomerService {

    @Resource
    private SearchClient searchClient;

    @CacheResult
    @HystrixCommand(commandKey = "findById")
    public Customer findById(@CacheKey Integer id){

        return searchClient.findById(id);
    }

    @CacheRemove(commandKey = "findById")
    @HystrixCommand
    public void clearFindById(@CacheKey Integer id){
        System.out.println("findById缓存被清空！");
    }

}
```

> 使用请求缓存的注解`@CacheResult` `CacheRemove`
>
> 1. @CacheResult：帮助我们缓存当前方法的返回结果（必须配合@HystrixCommand使用）
> 2. @CacheRemove：帮助我们清除某一个缓存信息（基于commandKey）
> 3. @CacheKey：指定那个方法参数作为缓存标识，如果有多个参数时，可以通过 @CacheKey 注解指定缓存哪个参数。

#### 5.2.2 修改 Search 模块

修改Search模块的结果返回值。

```java
@GetMapping("/search/{id}")
public Customer findById(@PathVariable Integer id){
    return new Customer(id,"张三", (int) (Math.random() * 10000));
}
```

#### 5.2.3 创建 Filter

编写Filter，去构建HystrixRequestContext，来拦截请求。

```java
@WebFilter("/*")
public class HystrixRequestContextFilter implements Filter {
    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        HystrixRequestContext.initializeContext();
        filterChain.doFilter(servletRequest,servletResponse);
    }
}
```

#### 5.2.4 修改原 Controller

```java
//请求缓存
@Autowired
private CustomerService customerService;

@GetMapping("/search/{id}")
@HystrixCommand(fallbackMethod = "findByIdFallBack",commandProperties = {
        @HystrixProperty(name = "execution.isolation.strategy",value = "THREAD"),
        @HystrixProperty(name = "execution.isolation.thread.timeoutInMilliseconds",value = "3000"),
        @HystrixProperty(name = "circuitBreaker.enabled",value="true"),
        @HystrixProperty(name = "circuitBreaker.requestVolumeThreshold",value="10"),
        @HystrixProperty(name = "circuitBreaker.errorThresholdPercentage",value="70"),
        @HystrixProperty(name = "circuitBreaker.sleepWindowInMilliseconds",value="5000")
})
public Customer findById(@PathVariable Integer id){
    //int i = 1/0;

    //请求缓存
    System.out.println(customerService.findById(id));
    System.out.println(customerService.findById(id));
    customerService.clearFindById(id);
    System.out.println(customerService.findById(id));
    System.out.println(customerService.findById(id));


    return searchClient.findById(id);
}
```

#### 5.2.5 测试

![](http://qiniu.zhouhongyin.top/2022/06/14/1655222019-image-20210126104020833.png)