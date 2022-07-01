---
title: Spring Filter 学习
date: 2022-6-30
tags:
  - spring
  - springboot
  - Filter
  - Java
  - Interceptor
categories:
  - spring
  - springboot
  - springMVC
  - Filter
---

![](http://qiniu.zhouhongyin.top/2022/06/30/1656560442-68747470733a2f2f692e696d6775722e636f6d2f306f74457572762e706e67.png)

<!-- more -->

# 一、简介

## 1.1 执行顺序

![](http://qiniu.zhouhongyin.top/2022/06/30/1656560843-Snipaste_2022-06-30_11-45-57.png)

![](http://qiniu.zhouhongyin.top/2022/06/30/1656560875-Snipaste_2022-06-30_11-46-49.png)

# 二、使用

## 2.1 创建 Filter

实现 `Filter`接口后实现其三个方法，业务逻辑写在`doFilter()`方法内即可。

```java
public class MyFilter implements Filter {
    private FilterConfig filterConfig;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        Filter.super.init(filterConfig);
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        chain.doFilter(httpServletRequest, response);
    }

    @Override
    public void destroy() {
        Filter.super.destroy();
    }
}
```

## 2.2 将 Filter 注入到 Spring 中 

### 2.2.1 方式一：通过`@WebFilter` + `@ServletComponentScan`注入

步骤一：

在自定义 Filter 中添加 `@WebFilter`注解

> 该注解注释的类必须实现 `Filter` 接口

```java
@WebFilter(filterName = "filter", value = "/filter/path2")
public class MyFilter implements Filter {
 ....
{
```

> `@WebFilter` 常用属性属性：
>
> 1. 不指定属性：例如`@WebFilter("/filter/path2/**")`，等价于`value`，表示只过滤请求路径为`/filter/path2/**`的请求
> 2. value：`@WebFilter(value = "/filter/path2/**")`，表示只过滤请求路径为`/filter/path2/**`的请求
> 3. urlPatterns：`@WebFilter(urlPatterns = "/filter/path2/**")`，作用与`value`基本相同，两个属性至少声明一个，但不能同时声明两者，当URL模式是唯一设置的属性时，建议使用value属性，否则应该使用urlPattern属性
> 4. filterName：`@WebFilter(filterName= "filter")`，指定过滤器的名称，不指定则为类的完全限定名

步骤二：

在启动类上加上 `@ServletComponentScan` 注解，使 Spring 可以扫描到自己定义的 Filter。

```java
@SpringBootApplication
@ServletComponentScan(basePackages = "com.xxx")
public class JavaStudyApplication {
    public static void main(String[] args) {
        SpringApplication.run(JavaStudyApplication.class, args);
    }
}
```

> 可通过注解的 `basePackages` 和 `basePackageClasses` 属性指定需要扫描到的 Filter，可以不指定，默认扫描启动类下的包。

### 2.2.2 方式二：通过`@Component` + `@Configuration`的方式自己注入Filter

步骤一：

在 Filter 上添加 `@Component` 注解。

```java
@Component
public class MyFilter implements Filter {
    private FilterConfig filterConfig;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        Filter.super.init(filterConfig);
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        chain.doFilter(httpServletRequest, response);
    }

    @Override
    public void destroy() {
        Filter.super.destroy();
    }
}
```

> 如果你的这个过滤器是想过滤所有请求，方式二到步就够了。

步骤二：将该过滤器注入到 Spring 容器中

```java
@Configuration
public class FilterConfiguration {
    
    @Bean
    public FilterRegistrationBean<MyFilter> myFilterFilterRegistrationBean(MyFilter myFilter) {
        FilterRegistrationBean<MyFilter> myFilterRegistrationBean = new FilterRegistrationBean<>();
        // 设置需要注如的过滤器
        myFilterRegistrationBean.setFilter(myFilter);
        // 设置过滤器优先级
        myFilterRegistrationBean.setOrder(1);
        // 设置过滤器过滤的请求路径
        myFilterRegistrationBean.addUrlPatterns("/filter/path2");
        return myFilterRegistrationBean;
    }

}
```

> 踩坑：方式一和方式二，使用其中一种注入自定一过滤器即可，如果过滤器上同时加了 `@WebFilter` 和 `@Component` 注解，`@WebFilter`注解的配置信息会失效，并且该过滤器会被执行多次。

# 三、`OncePerRequestFilter`

## 3.1 `OncePerRequestFilter` 与 `Filter` 的区别

Spring 的过滤器都继承了`OncePerRequestFilter` 过滤器，这两个过滤器总体没有区别，但是更推荐`OncePerRequestFilter`，因为当使用`OncePerRequestFilter`过滤器时，一个请求只会走一遍该过滤器，但`Filter`可能会走多次，比如说转发、重定向。（但是分 servlet 版本，比如 servlet2.3 有可能`OncePerRequestFilter`也会走多次，所以在 spring 环境下用第一个过滤器就完事了）

![](http://qiniu.zhouhongyin.top/2022/06/30/1656576143-image-20220630160223621.png)

`OncePerRequestFilter`源码中实现了 `doFilter()` 方法并做了某些校验，使得某些请求直接放行了，不在重复走我们写的过滤器逻辑，为的就是请求只走一边我们的过滤器逻辑。

详细区别可查看这几篇博客：

- https://blog.51cto.com/u_3631118/3121386
- https://www.jianshu.com/p/de66fc745da8
- https://blog.csdn.net/yy_diego/article/details/110482447
- https://blog.csdn.net/zl1zl2zl3/article/details/79270664

## 3.2 使用

使用上和 Filter 一样，两种方式都可以，这里只演示第一种，唯一的区别就是，由于 `OncePerRequestFilter` 实现了 `doFilter()` 并在方法中调用了 `doFilterInternal()` 抽象方法，所以我们只需要实现该放法即可。

![](http://qiniu.zhouhongyin.top/2022/06/30/1656576544-image-20220630160904690.png)

![](http://qiniu.zhouhongyin.top/2022/06/30/1656576568-image-20220630160928139.png)

步骤一：

```java
@WebFilter(value = "/filter/path1")
public class MyOncePerRequestFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, FilterChain filterChain) throws ServletException, IOException {
        System.out.println("MyOncePerRequestFilter:filter/path1");
        filterChain.doFilter(httpServletRequest, httpServletResponse);
    }
}
```

步骤二：

```java
@SpringBootApplication
@ServletComponentScan(basePackages = "com.xxx")
public class JavaStudyApplication {
    public static void main(String[] args) {
        SpringApplication.run(JavaStudyApplication.class, args);
    }
}
```

# 四、Filter 的应用

## 4.1 自定义 HttpServletRequest

有时候我们希望在拦截器中对请求的请求体做一些处理后，将处理过的请求体在放回 request 中，但是由于流的特点能读一次，导致拦截器中读取完毕后，Controller 中就的 `@RequestBody` 就读取不到了，所以我们可以创建一个 `HttpServletRequest` 的子类，并重写其 `getInputStream()` 方法，使得请求体的流可以重复调用，`HttpServletRequestWrapper` 就可以满足我们的需求。

### 步骤一：自定义 `HttpServletRequest`

这里我们的思路时，在构造方法中将原 `HttpServletRequest request` 中的 body 流保存在 byte[] 类型的属性中，因为拦截器中获取请求体，和 Controller 中就的 `@RequestBody` 获取请求体都是通过 `getInputStream()` 获取的，所以我们重写`getInputStream()` ，每此调用该方法都从 `byte[] body` 属性中获取，这样就保证了多次调用该方法也可以获取到流。

```java
public class MyServletRequestWrapper extends HttpServletRequestWrapper {
    private byte[] body;
    
    public MyServletRequestWrapper(HttpServletRequest request) {
        super(request);

        try (ServletInputStream inputStream = request.getInputStream();
             ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream()) {
            if (inputStream != null) {
                IOUtils.copy(inputStream, byteArrayOutputStream);
                body = byteArrayOutputStream.toByteArray();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    @Override
    public ServletInputStream getInputStream() throws IOException {
        ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(body);
        return new ServletInputStream() {
            @Override
            public int read() throws IOException {
                return byteArrayInputStream.read();
            }

            @Override
            public boolean isFinished() {
                return false;
            }

            @Override
            public boolean isReady() {
                return false;
            }

            @Override
            public void setReadListener(ReadListener listener) {

            }
        };
    }

    public String getBody() {
        return new String(body);
    }

    public void setBody(byte[] body) {
        this.body = body;
    }
}
```

### 步骤二：在 Filter 中替换原`HttpServletRequest`

这里的操作就是将原来的 `ServletRequest request` 替换为我们的 `HttpServletRequestWrapper` 子类。

```java
@Override
public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
    HttpServletRequest httpServletRequest = (HttpServletRequest) request;
    String method = httpServletRequest.getMethod();
    String contentType = httpServletRequest.getContentType();
    if (StrUtil.isNotEmpty(contentType)) {
        contentType = contentType.toLowerCase();
    }

    // 该方法处理 POST请求并且contentType为application/json格式的
    if (HttpMethod.POST.name().equalsIgnoreCase(method) && StrUtil.isNotEmpty(contentType) && contentType.contains(MediaType.APPLICATION_JSON_VALUE)) {
        MyServletRequestWrapper myServletRequestWrapper = new MyServletRequestWrapper(httpServletRequest);
        httpServletRequest = myServletRequestWrapper;
    }

    chain.doFilter(httpServletRequest, response);
}
```

### 步骤三：在拦截器中使用

拦截器中直接将 `HttpServletRequest request` 强转为我们的 `HttpServletRequestWrapper` 子类，然后使用即可。

这里我做的业务逻辑就是，将 body 中的被 Base64 编码的属性值转换为原值，在放回去。

```java
@Component
public class MyHandlerInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

        String body = ((MyServletRequestWrapper) request).getBody();

        //System.out.println(body);

        JSONObject jsonObject = JSON.parseObject(body);
        for (Map.Entry<String, Object> entry : jsonObject.entrySet()) {
            String key = entry.getKey();
            String value = (String) entry.getValue();

            if (Base64.isBase64(value)) {
                jsonObject.put(key, Base64.decodeStr(value));
            }
        }


        byte[] bytes = jsonObject.toJSONString().getBytes(StandardCharsets.UTF_8);
        ((MyServletRequestWrapper) request).setBody(bytes);

        //System.out.println(((MyServletRequestWrapper) request).getBody());

        return true;
    }
}
```

> 配置拦截器：
>
> ```java
> @Order(1)
> @Component
> public class MyWebMvcConfigurer implements WebMvcConfigurer {
> 
>     @Resource
>     private MyHandlerInterceptor myHandlerInterceptor;
> 
>     @Override
>     public void addInterceptors(InterceptorRegistry registry) {
>         registry.addInterceptor(myHandlerInterceptor).addPathPatterns("/filter/path2");
>     }
> }
> ```