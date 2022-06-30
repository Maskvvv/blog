---
title: springboot中@PathVariable、@RequestParam和@RequestBody的区别和使用
date: 2020-11-02
tags:
  - spring
  - springboot
  - spring注解
  - 注解@RequestParam
  - 注解@PathVariable
  - restful风格
  - 注解@RequestBody
categories:
  - spring
  - spring注解
  - 注解@PathVariable、@RequestParam和@RequestBody的区别和使用
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041378-download.png)

<!--more-->

## 一、@PathVariable

### 1.1 restful风格

#### 1.1.1 概念

>  一种软件架构风格、设计风格，而**不是**标准，只是提供了一组设计原则和约束条件。它主要用于客户端和服务器交互类的软件。基于这个风格设计的软件可以更简洁，更有层次，更易于实现缓存等机制。

#### 1.1.2 特点

- REST：即 Representational State Transfer。（资源）表现层状态转化。是目前最流行的一种互联网软件架构。它结构清晰、符合标准、易于理解、扩展方便，所以正得到越来越多网站的采用
- 资源（**Resources**）：网络上的一个实体，或者说是网络上的一个具体信息。它可以是一段文本、一张图片、一首歌曲、一种服务，总之就是一个具体的存在。可以用一个URI（统一资源定位符）指向它，每种资源对应一个特定的 **URI** 。要获取这个资源，访问它的URI就可以，因此 **URI** 即为每一个资源的独一无二的识别符。
- 表现层（**Representation**）：把资源具体呈现出来的形式，叫做它的表现层（**Representation**）。比如，文本可以用 txt 格式表现，也可以用 HTML 格式、XML 格式、JSON 格式表现，甚至可以采用二进制格式。
- 状态转化（**State Transfer**）：每发出一个请求，就代表了客户端和服务器的一次交互过程。HTTP协议，是一个无状态协议，即所有的状态都保存在服务器端。因此，如果客户端想要操作服务器，必须通过某种手段，让服务器端发生**“**状态转化**”**（**State Transfer**）。而这种转化是建立在表现层之上的，所以就是 **“**表现层状态转化**”**。具体说，就是 **HTTP** 协议里面，四个表示操作方式的动词：**GET**、**POST**、**PUT**、**DELETE**。它们分别对应四种基本操作：**GET** 用来获取资源，**POST** 用来新建资源，**PUT** 用来更新资源，**DELETE** 用来删除资源。

#### 1.1.3 restful风格和传统操作方式的对比

| 功能 |               传统方式                |                restful风格                |
| :--: | :-----------------------------------: | :---------------------------------------: |
| 查询 | http://127.0.0.1/item/selectUser?id=1 |  GET http://127.0.0.1/item/selectUser/1   |
| 新增 |     http://127.0.0.1/item/addUser     |    POST http://127.0.0.1/item/addUser     |
| 更新 |   http://127.0.0.1/item/updateUser    |   PUT http://127.0.0.1/item/updateUser    |
| 删除 | http://127.0.0.1/item/deleteUser?id=1 | DELETE http://127.0.0.1/item/deleteUser/1 |

### 1.2 @PathVariable的介绍

> @PathVariable 映射 URL 绑定的占位符
>
> - 带占位符的 **URL** 是 **Spring3.0** 新增的功能，**该功能在SpringMVC 向 REST 目标挺进发展过程中具有里程碑的意义**
> - 通过 **@PathVariable** 可以将 **URL** 中占位符参数绑定到控制器（controller）处理方法的形参中：URL 中的 {**xxx**} 占位符可以通过@PathVariable(“**xxx**“) 绑定到操作方法的形参中。
> - 主要是根据请求方法进行类的区别

### 1.3 @PathVariable所具有的参数

> - String value：可指定占位符 { } 中的参数名，若只指定value这一个属性可省略属性名不写，若占位符中的参数名和处理方法中的参数名相同可省略此属性。
> - String name：等价与value，和value无本质上的差异，两个属性指定其一即可。
> - boolean required：是否必需，默认为 true，即 请求中必须包含该参数，如果没有包含，将会抛出异常（可选配置）

### 1.4 @PathVariable的使用

> **步骤：**
>
> 1. 通过@RequestMapping注解中的 { } 占位符来标识URL中的变量部分
> 2. 在控制器中的处理方法的形参中使用@PathVariable注解去获取@RequestMapping中 { } 中传进来的值，并绑定到处理方法定一的形参上。

```java
//请求路径：http://127.0.0.1/user/tom
@RequestMapping(value="/user/{name}")
public String username(@PathVariable(value="name") String username) {
    return username;
}
```

## 二、@RequestParam

### 2.1 @RequestParam定义

> @RequestParam （org.springframework.web.bind.annotation.RequestParam）用于将指定的请求参数赋值给方法中的形参。

### 2.2 @RequestParam的参数

> - String value：请求中传入参数的名称，如果不设置value值，则会默认为该变量名。
> - String name：等价与value，和value无本质上的差异，两个属性指定其一即可。
> - boolean required：是否必需，默认为 true，即 请求中必须包含该参数，如果没有包含，将会抛出异常（可选配置）
> - String defaultValue：参数的默认值，如果请求中没有同名的参数时，该变量默认为此值。

### 2.3 注意事项

> - **如果参数前写了@RequestParam(xxx)**，那么前端必须有对应的xxx名字才行(不管其是否有值，当然可以通 过设置该注解的required属性来调节是否必须传)，如果没有xxx名的话，那么请求会出错，报400。
> - **如果参数前不写@RequestParam(xxx)的话**，那么就前端可以有可以没有对应的xxx名字才行，如果有xxx名的话，那么就会自动匹配；没有的话，请求也能正确发送。

### 2.4 @RequestParam使用

>  在SpringMVC框架中，可以通过定义@RequestMapping来处理URL请求。和@PathVariable一样，需要在处理URL的控制方法中获取URL中的参数，也就是`?key1=value1&key2=value2`这样的参数列表。通过注解@RequestParam可以轻松地将URL中的参数绑定到处理函数方法的变量中。

```java
//请求路径：http://127.0.0.1/user/?name=tom
@RequestMapping(value="/user")
public String getUserBlog(@RequestParam(value="name") String username) {
    return name;
}
```

### 2.5 @RequestParam和@PathVariable的区别

>  @RequestParam和@PathVariable都能够完成类似的功能——因为本质上，它们都是用户的输入，只不过输入的部分不同，一个在URL路径部分，另一个在参数部分。要访问一篇博客文章，这两种URL设计都是可以的：
>
> - 通过@PathVariable，例如/blogs/1
> - 通过@RequestParam，例如blogs?blogId=1
>
> 那么究竟应该选择哪一种呢？建议：
>
> 1、当URL指向的是某一具体业务资源（或资源列表），例如博客，用户时，使用@PathVariable
>
> 2、当URL需要对资源或者资源列表进行过滤，筛选时，用@RequestParam
>
> 例如我们会这样设计URL：
>
> - /blogs/{blogId}
> - /blogs?state=publish而不是/blogs/state/publish来表示处于发布状态的博客文章

## 三、@RequestBody

### 3.1 @RequestBody简介

> @RequestBody主要用来接收前端传递给后端的json字符串中的数据的(请求体中的数据的)；GET方式无请求体，所以使用@RequestBody接收数据时，前端不能使用GET方式提交数据，而是用POST等方式进行提交。

### 3.2 注意事项

如果后端参数是一个对象，且该参数前是以@RequestBody修饰的，那么前端传递json参数时，必须满足以下要求：

- 后端@RequestBody注解对应的类在将HTTP的输入流(含请求体)装配到目标类(即：@RequestBody后面的类)时，会**根据json字符串中的key来匹配对应实体类的属性**，如果**匹配一致**且json中的该**key对应的值符合(或可转换为)**， 实体类的对应属性的类型要求时,会调用实体类的setter方法将值赋给该属性。
- json字符串中，如果**value为""的话**，后端对应属性如果是String类型的，那么**接受到的就是""**，如果是后端属性的**类型是Integer、Double等类型**，那么接收到的就**是null。**
- json字符串中，如果**value为null**的话，后端对应收到的就**是null**。
- 如果某个参数没有value的话，在传json字符串给后端时，要么干脆就**不把该字段写到json字符串中**；要么写value时， **必须有值，null 或""都行**。

### 3.3 @RequestBody使用

#### 3.3.1 编写实体类User

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class User {
    private String name;
    private int age;
    private String gender;
}
```

#### 3.3.2 编写controller

```java
@RestController
@RequestMapping("/user")
public class UserController {

    @PostMapping("/addUser")
    public void addUser(@RequestBody User user){
        System.out.println(user);

    }
}
```

#### 3.3.3 使用postman进行接口测试

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041384-image-20201102183322437.png)

#### 3.3.4 后台数据输出

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041387-image-20201102183429272.png)

### 3.4  @RequestParam和@RequestParam

> 当同时使用 @RequestParam 和 @RequestBody 时，@RequestParam指定的参数可以是普通元素、
> 数组、集合、对象等等(即:当，@RequestBody 与@RequestParam 可以同时使用时，原SpringMVC接收
> 参数的机制不变，只不过RequestBody 接收的是请求体里面的数据；而@RequestParam接收的是key-value
> 里面的参数，所以它会被切面进行处理从而可以用普通元素、数组、集合、对象等接收)。
>
> 即：如果参数时放在请求体中，传入后台的话，那么后台要用@RequestBody才能接收到；如果不是放在
> 请求体中的话，那么后台接收前台传过来的参数时，要用@RequestParam来接收，或则形参前什么也不写也能接收。

## 四、@RequestParam和@PathVariable的区别

 @RequestParam和@PathVariable都能够完成类似的功能——因为本质上，它们都是用户的输入，只不过输入的部分不同，一个在URL路径部分，另一个在参数部分。要访问一篇博客文章，这两种URL设计都是可以的：

- 通过@PathVariable，例如/blogs/1
- 通过@RequestParam，例如blogs?blogId=1

那么究竟应该选择哪一种呢？建议：

1、当URL指向的是某一具体业务资源（或资源列表），例如博客，用户时，使用@PathVariable

2、当URL需要对资源或者资源列表进行过滤，筛选时，用@RequestParam

例如我们会这样设计URL：

- /blogs/{blogId}
- /blogs?state=publish而不是/blogs/state/publish来表示处于发布状态的博客文章