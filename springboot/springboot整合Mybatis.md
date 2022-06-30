---
title: springboot整合Mybatis
date: 2020-10-7
tags:
  - spring
  - springboot
  - Mybatis
categories:
  - spring
  - springboot
  - springboot-Mybatis
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041449-download.png)

<!--more-->

## 概览

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041452-image-20201007203125456.png)

## 一、导入pom.xml依赖

```xml
<!--web依赖-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>2.1.3</version>
</dependency>

<!--热加载-->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>

<!--mysql驱动-->
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
    <scope>runtime</scope>
</dependency>
<!--mybatis-->
<dependency>
    <groupId>org.mybatis.spring.boot</groupId>
    <artifactId>mybatis-spring-boot-starter</artifactId>
    <version>1.3.2</version>
</dependency>
<!--druid数据源-->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>druid-spring-boot-starter</artifactId>
    <version>1.1.10</version>
</dependency>


<!--lombok插件-->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

## 二、编写entity实体类

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PhoneNumber {

  private long orderNumber;
  private String name;
  private long id;
  private String phoneNumber;
  private String classNumber;

}
```

## 三、编写dao层

### 3.1 编写mapper接口

```java
@Repository
public interface PhoneNumberMapper {
    List<PhoneNumber> findAll();
}
```

### 3.2 编写mapper.xml文件

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.zhy.dao.PhoneNumberMapper">
    <select id="findAll" resultType="PhoneNumber">
        select * from phone_number;
    </select>
</mapper>

```

### 3.3 在springboot启动类上添加mapper扫描注解

```java
@SpringBootApplication
@MapperScan(basePackages = "com.zhy.dao")
public class SpringbootMybatisApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringbootMybatisApplication.class, args);
    }
}
```

## 四、编写application.yml配置文件

```yml
# datasource
spring:
  datasource:
    password: root
    username: root
    driver-class-name: com.mysql.cj.jdbc.Driver
    type: com.alibaba.druid.pool.DruidDataSource
    url: jdbc:mysql://localhost:3306/softwareclass2?serverTimezone=UTC

# mybatis
mybatis:
  mapper-locations: classpath:mapper/*.xml  # mapper.xml配置地址
  type-aliases-package: com.zhy.entity  # 起别名
  configuration:
    map-underscore-to-camel-case: true  # 下划线转驼峰
logging:
  level:
    com.zhy.dao: debug

```

## 五、编写service层

### 5.1  添加分页助手

> **PageInfo的属性表：**
>
> `private int pageNum`：当前页 
>
> `private int pageSize`：每页的数量   
>
> `private int size`：当前页的数量    //由于startRow和endRow不常用，这里说个具体的用法   //可以在页面中"显示startRow到endRow 共size条数据"   
>
> `private int startRow`：当前页面第一个元素在数据库中的行号
>
> `private int endRow`：当前页面最后一个元素在数据库中的行号   
>
> `private long total`：总记录数   
>
> `private int pages`：总页数
>
> `private List<T> list`：结果集   
>
> `private int firstPage`：第一页   
>
> `private int prePage`：前一页   
>
> `private boolean isFirstPage = false`：是否为第一页   
>
> `private boolean isLastPage = false`：是否为最后一页   
>
> `private boolean hasPreviousPage` = false：是否有前一页   
>
> `private boolean hasNextPage = false`：是否有下一页   
>
> `private int navigatePages`：导航页码数   
>
> `private int[] navigatepageNums`：所有导航页号   

#### 5.1.1 添加分页助手的相关依赖

```xml
<!--分页助手-->
<dependency>
    <groupId>com.github.pagehelper</groupId>
    <artifactId>pagehelper-spring-boot-starter</artifactId>
    <version>1.2.10</version>
</dependency>
```

#### 5.1.2 编写service接口及其实现类

```java
public interface PhoneNumberService {
    public PageInfo changePage(int page,int limit);
}
```

#### 5.1.3 编写service的实现类

```java
@Service
public class PhoneNumberServiceImpl implements PhoneNumberService {

    @Resource
    private PhoneNumberMapper phoneNumberMapper;

    @Override
    public PageInfo changePage(int pageNum, int pageSize) {
        //开启分页
        PageHelper.startPage(pageNum,pageSize);
        List<PhoneNumber> list = phoneNumberMapper.findAll();

        PageInfo<PhoneNumber> pageInfo = new PageInfo<>(list);
        return  pageInfo;
    }
}
```

## 六、测试

```java
@SpringBootTest
class SpringbootMybatisApplicationTests {
    @Resource
    private PhoneNumberMapper phoneNumberMapper;

    @Test
    void contextLoads() {
        List<PhoneNumber> all = phoneNumberMapper.findAll();
        for (PhoneNumber phoneNumber : all) {
            System.out.println(phoneNumber);
        }
    }
    
    @Test
    void pageHelper() {

        PageHelper.startPage(1,5);
        List<PhoneNumber> list = phoneNumberMapper.findAll();

        PageInfo<PhoneNumber> pageInfo = new PageInfo<>(list);
        System.out.println(pageInfo);
    }
}
```

