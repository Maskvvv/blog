---
title: springcloud学习(四)-Feign(服务间的调用)
date: 2021-1-20
tags:
  - 微服务
  - springcloud学习(四)-Feign(服务间的调用)
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - springcloud
  - springcloud学习(四)-Feign(服务间的调用)
---

![](http://qiniu.zhouhongyin.top/2022/06/14/1655221944-spring-cloud.png)

<!--more-->

## 一、Feign 的简介

Feign 可以帮助我们实现面向接口编程，就直接调用其他服务，简化开发。

Feign 是一个声明式的 REST 客户端，它能让 REST 调用更加简单。Feign 供了 HTTP 请求的模板，通过编写简单的接口和插入注解，就可以定义好 HTTP 请求的参数、格式、地址等信息。

而 Feign 则会完全代理 HTTP 请求，我们只需要像调用方法一样调用它就可以完成服务请求及相关处理。

Spring Cloud 对 Feign 进行了封装，使其支持 SpringMVC 标准注解和 HttpMessageConverters。Feign 可以与 Eureka 和 Ribbon 组合使用以支持负载均衡。

## 二、Feign 的简单使用

### 2.1 导入相关依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

### 2.2 添加 @EnableFeignClients 注解

在启动类上加 @EnableFeignClients 注解，如果你的 Feign 接口定义跟你的启动类不在同一个包名下，还需要制定扫描的包名 @EnableFeignClients（basePackages=“com.fangjia.api.client”），代码如下所示。

```java
@EnableEurekaClient
@SpringBootApplication
@EnableFeignClients
public class CustomerApplication {
    public static void main(String[] args) {
        SpringApplication.run(CustomerApplication.class,args);
    }
}
```

### 2.3 创建一个接口，并且和 search 模块做映射

@FeignClient 注解：这个注解标识当前是一个 Feign 的客户端，value 属性是对应的服务名称，也就是你需要调用哪个服务中的接口。

```java
//指定服务名称
@FeignClient("SEARCH")
public interface SearchClient {
    //value -> 目标服务的请求路径，method -> 映射请求方式
    @RequestMapping(value = "/search",method = RequestMethod.GET)
    public String search();
}
```

> 定义方法时直接复制接口的定义即可，当然还有另一种做法，就是将接口单独抽出来定义，然后在 Controller 中实现接口。

### 2.4 测试使用

定义之后可以直接通过注入 SearchClient 来调用。

```java
@Autowired
private SearchClient searchClient;

@GetMapping("/customer")
public String customer() {
    
    String result = searchClient.search();
    return result;
}
```

> **三种方式对比：**
>
> - RestTemplate 方式：
>
>   ```java
>   String result = restTemplate.getForObject(url+"search", String.class);
>   ```
>
> - RestTemplate 整合 Ribbon方式：
>
>   ```java
>   String result = restTemplate.getForObject("http://SEARCH/search", String.class);
>   ```
>
> - Feign 方式：
>
>   ```java
>   String result = searchClient.search();
>   ```

## 三、Feign 的传递参数方式

### 3.1 Feign 的注意事项

1. 如果你传递的参数，比较**复杂时**，**默认会采用 POST 的请求方式**。
2. 传递单个参数时，推荐使用 @PathVariable （Restful 风格），如果传递的单个参数比较多，这里也可以采用 @RequestParam ，不要省略 value 属性。
3. 传递对象信息时，统一采用 json 的方式，添加 @RequestBody 。
4. Client接口**必须采用 @RequestMapping** 。

### 3.2 使用

#### 3.2.1 给服务的提供者和消费者编写实体类

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class Customer {
    private Integer id;
    private String name;
    private Integer age;
}
```

#### 3.2.2 准备服务提供者的接口

在 Search 模块中编写三个接口。

```java
@GetMapping("/search/{id}")
public Customer findById(@PathVariable Integer id){
    return new Customer(id,"张三",23);
}

@GetMapping("/getCustomer")
public Customer getCustomer(@RequestParam Integer id, @RequestParam String name){
    return new Customer(id,name,23);
}

@PostMapping("/save")
public Customer save(@RequestBody Customer customer){
    return customer;
}
```

#### 3.2.3 在 Search 模块中映射服务提供者的接口

```java
@FeignClient(value = "SEARCH")
public interface SearchClient {

    @RequestMapping(value = "/search/{id}", method = RequestMethod.GET)
    public Customer findById(@PathVariable(value = "id") Integer id);

    @RequestMapping(value = "/getCustomer", method = RequestMethod.GET)
    public Customer getCustomer(@RequestParam(value = "id") Integer id, @RequestParam(value = "name") String name);
    
	//这里参数复杂，会自动转化成POST请求
    @RequestMapping(value = "/save", method = RequestMethod.GET)
    public Customer save(@RequestBody Customer customer);

}
```

## 四、Feign 的 Fallback

Fallback可以帮助我们在使用Feign去调用另一个服务时，如果出现了问题，走服务降级，返回一个错误的数据，避免功能因为一个服务出现问题，全部失效。

### 4.1 Fallback的使用

#### 4.1.1 创建一个POJO类，实现 自定义 FeignClient 接口

```java
@Component
public class SearchClientFallBack implements SearchClient {
    @Override
    public String search() {
        return "search出现问题了！！！";
    }

    @Override
    public Customer findById(Integer id) {
        return null;
    }

    @Override
    public Customer getCustomer(Integer id, String name) {
        return null;
    }

    @Override
    public Customer save(Customer customer) {
        return null;
    }
}
```

#### 4.1.2 指定自定义的POJO类

在 FeignClient 接口中，通过 @FeignClient 的 fallback 属性指定自定义的POJO类。

```java
@FeignClient(value = "SEARCH",fallback = SearchClientFallBack.class)
public interface SearchClient {
	.........
}
```

#### 4.1.3 修改配置文件

```yml
# fallback
feign:
  hystrix:
    enabled: true
```

### 4.2 遇到的问题（FallBackFactory）

当 Search 模块出现问题时，错误的信息会返回给前端，但是服务的调用者无法知道具体的错误信息是什么，通过 FallBackFactory 的方式去解决这个问题。

#### 4.2.1 创建 POJO 类实现 FallBackFactory 

1. 创建一个类实现 FallbackFactory ，并在泛型中指定自定义的 FeignClient 。
2. 注入自定义的 Fallback 。
3. 在重写的方法中返回自定义的 Fallback 。

```java
@Component
public class SearchClientFallBackFactory implements FallbackFactory<SearchClient> {

    //注入Fallback
    @Autowired
    private SearchClientFallBack searchClientFallBack;

    @Override
    public SearchClient create(Throwable throwable) {
        throwable.printStackTrace();
        return searchClientFallBack;
    }
}
```

#### 4.2.2 修改 FeignClient 中 @FeignClient 的属性

在 @FeignClient 的 fallbackFactory 属性中指定自定义的 fallbackFactory 。

```java
@FeignClient(value = "SEARCH",
        /*fallback = SearchClientFallBack.class*/
        fallbackFactory = SearchClientFallBackFactory.class
)
public interface SearchClient {
	.........
}
```