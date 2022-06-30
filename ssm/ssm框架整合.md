---
title: ssm框架整合
date: 2019-07-10
tags:
  - ssm
  - spring
  - mybatis
categories:
  - spring
  - ssm框架整合
---

# ssm框架整合

![](http://qiniu.zhouhongyin.top/2022/06/12/1655042153-%E7%94%BB%E6%9D%BF%201.png)

<!--more-->

## 一、搭建数据库

创建一个存放书籍数据的数据库表

```sql
CREATE DATABASE ssmbuild;
USE ssmbuild;
CREATE TABLE `books`(
`bookID` INT NOT NULL AUTO_INCREMENT COMMENT '书id',
`bookName` VARCHAR(100) NOT NULL COMMENT '书名',
`bookCounts` INT NOT NULL COMMENT '数量',
`detail` VARCHAR(200) NOT NULL COMMENT '描述',
KEY `bookID`(`bookID`)
)ENGINE=INNODB DEFAULT CHARSET=utf8;

INSERT INTO `books`(`bookID`,`bookName`,`bookCounts`,`detail`)VALUES
(1,'Java',1,'从入门到放弃'),
(2,'MySQL',10,'从删库到跑路'),
(3,'Linux',5,'从进门到进牢')
```



## 二、基本环境搭建

### 1. 创建一个Maven项目！ssmbuild，添加web的支持。

### 2. 导入相关的pom依赖

```xml
<dependencies>
    <!--junit-->
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.13</version>
        <scope>test</scope>
    </dependency>

    <!--数据库驱动-->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <version>8.0.19</version>
    </dependency>

    <dependency>
        <groupId>log4j</groupId>
        <artifactId>log4j</artifactId>
        <version>1.2.17</version>
    </dependency>

    <!--数据库连接池 c3p0-->
    <dependency>
        <groupId>com.mchange</groupId>
        <artifactId>c3p0</artifactId>
        <version>0.9.5.2</version>
    </dependency>

    <!--Servlet JSP-->
    <dependency>
        <groupId>javax.servlet</groupId>
        <artifactId>servlet-api</artifactId>
        <version>2.5</version>
    </dependency>
    <dependency>
        <groupId>javax.servlet.jsp</groupId>
        <artifactId>jsp-api</artifactId>
        <version>2.2</version>
    </dependency>
    <dependency>
        <groupId>javax.servlet</groupId>
        <artifactId>jstl</artifactId>
        <version>1.2</version>
    </dependency>

    <!--Mybatis-->
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis</artifactId>
        <version>3.5.2</version>
    </dependency>
    <dependency>
        <groupId>org.mybatis</groupId>
        <artifactId>mybatis-spring</artifactId>
        <version>2.0.2</version>
    </dependency>

    <!--Spring-->
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-webmvc</artifactId>
        <version>5.1.9.RELEASE</version>
    </dependency>
    <dependency>
        <groupId>org.springframework</groupId>
        <artifactId>spring-jdbc</artifactId>
        <version>5.1.9.RELEASE</version>
    </dependency>

    <!--Lombok-->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>1.18.12</version>
    </dependency>

</dependencies>


<!--maven资源过滤设置-->
<build>
    <resources>
        <resource>
            <directory>src/main/resources</directory>
            <includes>
                <include>**/*.properties</include>
                <include>**/*.xml</include>
            </includes>
            <filtering>false</filtering>
        </resource>
        <resource>
            <directory>src/main/java</directory>
            <includes>
                <include>**/*.properties</include>
                <include>**/*.xml</include>
            </includes>
            <filtering>false</filtering>
        </resource>
    </resources>
</build>
```

### 3. 创建基本结构和配置框架

#### 创建各层需要的包（pojo、dao、service、controller）

![image-20200715224247526](ssm%E6%A1%86%E6%9E%B6%E6%95%B4%E5%90%88/image-20200715224247526.png)

#### 创建mybatis-config.xml

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>

</configuration>
```



#### 创建applicationContext.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">


</beans>
```



## 三、Mybatis层编写

### 1. 编写数据库配置文件 database.properties

```properties
driver=com.mysql.cj.jdbc.Driver
#如果使用的Mysql8.0+,增加一个时区设置serverTimezone=Asia/Shanghai
url=jdbc:mysql://localhost:3306/ssmbuild?serverTimezone=Asia/Shanghai&useSSL=false&useUnicode=true&characterEncoding=utf8
jdbc.username=root
jdbc.password=root
```

### 2. 编写mybatis-config.xml文件

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
    <!--    日志-->
    <settings>
        <setting name="logImpl" value="STDOUT_LOGGING"/>
<!--        <setting name="logImpl" value="LOG4J"/>-->
    </settings>


    <!--配置别名-->
    <typeAliases>
        <package name="com.zhy.pojo"/>
    </typeAliases>

    
    <!--    绑定接口-->
    <mappers>
        <!--<mapper resource="com/zhy/dao/StudentMapper.xml"/>-->
        <!--<mapper resource="com/zhy/dao/TeacherMapper.xml"/>-->
<!--        <mapper class="com.zhy.dao.BookMapper"/>-->
        <package name="com.zhy.dao"/>

    </mappers>
</configuration>
```

### 3. 编写数据库表对应的pojo包下的实体类Books.java

```java
package com.zhy.pojo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Books {
    private int bookID;
    private String bookName;
    private int bookCounts;
    private String detail;

}
```

### 4. 编写dao包下的BookMapper接口

```java
package com.zhy.dao;

import com.zhy.pojo.Books;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

import java.util.List;

public interface BookMapper {

    //增加一本书
    int addBook(Books books);
    @Update("alter table books auto_increment = 1;")
    void addBookPlus();

    //删除一本书
    int deleteBookById(@Param("bookId") int id);

    //更新一本书
    int updateBook(Books books);

    //查询一本书
    Books queryBookById(@Param("bookId") int id);

    //查询全部书
    List<Books> queryAllBook();

    //根据名称查询书籍
//    Books queryBookByName(@Param("bookName") String bookName);#{bookName}
//    @Select("select * from ssmbuild.books where bookName like concat('%',#{bookName},'%');")
    List<Books> queryBookByName(@Param("bookName") String bookName);

}
```

### 5. 编写BookMapper接口对应的BookMapper.xml

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.zhy.dao.BookMapper">
    <insert id="addBook" parameterType="Books">
        insert into ssmbuild.books (bookName,bookCounts,detail)
        values (#{bookName},#{bookCounts},#{detail});
    </insert>

    <delete id="deleteBookById" parameterType="int">
        delete from ssmbuild.books where bookID = #{bookId}
    </delete>

    <update id="updateBook" parameterType="Books">
        update ssmbuild.books
        set bookName = #{bookName},bookCounts = #{bookCounts},detail = #{detail}
        where bookID = #{bookID};
    </update>
    
    <select id="queryBookById" resultType="Books" parameterType="int">
        select * from ssmbuild.books where bookID = #{bookId};
    </select>

    <select id="queryAllBook" resultType="Books">
        select * from ssmbuild.books;
    </select>

    <!--like “%” #{bookName} "%"-->
<!--    <select id="queryBookByName" parameterType="String" resultType="Books">-->
<!--        select * from ssmbuild.books where bookName = #{bookName};-->
<!--    </select>-->

    <select id="queryBookByName" parameterType="String" resultType="Books">
        select * from ssmbuild.books
        <where>
            <if test="bookName != null and bookName != ''">
                bookName like concat('%',#{bookName},'%');
            </if>
        </where>
    </select>

</mapper>
```



## 四、 Spring层编写

### 1. 整合dao层，编写spring-dao.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/context
       https://www.springframework.org/schema/context/spring-context.xsd">

    <!--1.关联数据库的配置文件-->
    <context:property-placeholder location="classpath:database.properties"/>


    <!--2.连接数据库
            连接池：
            dbcp：半自动化操作
            c3p0:自动加载配置文件，并且可以自动配置到对象中
            druid：
            hikari:
    -->
    <bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource">
        <property name="driverClass" value="${driver}"/>
        <property name="jdbcUrl" value="${url}"/>
        <property name="user" value="${jdbc.username}"/>
        <property name="password" value="${jdbc.password}"/>

        <!--c3p0连接池的私有属性-->
        <property name="maxPoolSize" value="10"/>
        <property name="minPoolSize" value="5"/>
        <!--关闭连接后不自动提交-->
        <property name="autoCommitOnClose" value="false"/>
        <property name="checkoutTimeout" value="10000"/>
        <!--当获取连接失败重试次数-->
        <property name="acquireRetryAttempts" value="2"/>

    </bean>


    <!--3.sqlSessionFactory-->
    <bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
        <property name="dataSource" ref="dataSource"/>

        <!--绑定Mybatis配置文件-->
        <property name="configLocation" value="classpath:mybatis-config.xml"/>
    </bean>


    <!--配置dao接口扫描包动态地实现了dao接口可以注入到spring的容器中-->
    <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
        <!--注入sqlsessionfactory-->
        <property name="sqlSessionFactoryBeanName" value="sqlSessionFactory"/>
        <!--要扫描的dao包-->
        <property name="basePackage" value="com.zhy.dao"/>
    </bean>
</beans>
```

### 2. 整合service层

#### 编写service层的接口和实现类：

```java
public interface BookService {
    //增加一本书
    int addBook(Books books);

    //删除一本书
    int deleteBookById(int id);

    //更新一本书
    int updateBook(Books books);

    //查询一本书
    Books queryBookById(int id);

    //查询全部书
    List<Books> queryAllBook();

    //Books queryBookByName(String bookName);

    List<Books> queryBookByName(String bookName);
}
```

```java

public class BookServiceImpl implements BookService {

    //service调dao层：组合Dao
    private BookMapper bookMapper;

    public void setBookMapper(BookMapper bookMapper) {
        this.bookMapper = bookMapper;
    }

    public int addBook(Books books) {
        bookMapper.addBookPlus();
        return bookMapper.addBook(books);
    }

    public int deleteBookById(int id) {
        int flag = bookMapper.deleteBookById(id);
        bookMapper.addBookPlus();
        return flag;
    }

    public int updateBook(Books books) {
        return bookMapper.updateBook(books);
    }

    public Books queryBookById(int id) {
        return bookMapper.queryBookById(id);
    }

    public List<Books> queryAllBook() {
        return bookMapper.queryAllBook();
    }

//    public Books queryBookByName(String bookName) {
//        return bookMapper.queryBookByName(bookName);
//    }

    public List<Books> queryBookByName(String bookName) {
        return bookMapper.queryBookByName(bookName);
    }
}

```

#### 编写spring-service.xml，将service层的实现类注入到spring

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context https://www.springframework.org/schema/context/spring-context.xsd">

<!--    1.扫描service下的包-->
<!--    <context:component-scan base-package="com.zhy.service"/>-->

<!--    2.将我们的所有业务层类，注入到spring，可以通过配置或者注解实现-->
    <bean id="BookServiceImpl" class="com.zhy.service.BookServiceImpl">
        <property name="bookMapper" ref="bookMapper"/>
    </bean>

<!--    3.声明事务配置-->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/>
    </bean>
</beans>
```



## 五、spring-MVC层编写

### 1. 编写web.xml

```xml
<!--    DispatchServlet-->
    <servlet>
        <servlet-name>springmvc</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>classpath:applicationContext.xml</param-value>
        </init-param>

        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>springmvc</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>


<!--    乱码过滤-->
    <filter>
        <filter-name>encodingFilter</filter-name>
        <filter-class>org.springframework.web.filter.CharacterEncodingFilter</filter-class>
        <init-param>
            <param-name>encoding</param-name>
            <param-value>utf-8</param-value>
        </init-param>
    </filter>
    <filter-mapping>
        <filter-name>encodingFilter</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>


<!--    session-->
    <session-config>
        <session-timeout>15</session-timeout>
    </session-config>
```

### 2. 编写controller层

```java
@Controller
@RequestMapping("/book")
public class BookController {
    //controller 调 service层
    @Autowired
    @Qualifier("BookServiceImpl")
    private BookService bookService;
}
```

### 3.编写spring-mvc.xml，使controller层对象注入到spring中

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:mvc="http://www.springframework.org/schema/mvc"
       xmlns:context="http://www.springframework.org/schema/context"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
       http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.springframework.org/schema/mvc
       http://www.springframework.org/schema/mvc/spring-mvc.xsd
       http://www.springframework.org/schema/context
       https://www.springframework.org/schema/context/spring-context.xsd">

<!--    1.注解驱动-->
    <mvc:annotation-driven/>

<!--    2.静态资源过滤，过滤jpg，MP4，MP3等静态资源-->
    <mvc:default-servlet-handler/>

<!--    3。扫描包：controller,使controller注入到spring(注解注入)-->
    <context:component-scan base-package="com.zhy.controller"/>

<!--    4.视图解析器-->
    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
        <property name="prefix" value="/WEB-INF/jsp/"/>
        <property name="suffix" value=".jsp"/>
    </bean>
    
    <!--    JSON乱码问题-->
    <mvc:annotation-driven>
        <mvc:message-converters register-defaults="true">
            <bean class="org.springframework.http.converter.StringHttpMessageConverter">
                <constructor-arg value="UTF-8"/>
            </bean>
            <bean class="org.springframework.http.converter.json.MappingJackson2HttpMessageConverter">
                <property name="objectMapper">
                    <bean class="org.springframework.http.converter.json.Jackson2ObjectMapperFactoryBean">
                        <property name="failOnEmptyBeans" value="false"/>
                    </bean>
                </property>
            </bean>
        </mvc:message-converters>
    </mvc:annotation-driven>

    
<!--    拦截器-->
    <mvc:interceptors>
        <mvc:interceptor>
            <mvc:mapping path="/**"/>
            <bean class="com.zhy.config.MyInterceptor"/>
        </mvc:interceptor>
    </mvc:interceptors>

</beans>
```

## 六、具体业务实现

### 1. 图书查询功能 