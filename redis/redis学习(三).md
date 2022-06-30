---
title: Redis学习(三)-java连接Redis
date: 2020-10-08
tags:
  - Redis
  - Redis学习(三)-java连接Redis
categories:
  - Redis
  - Redis学习(三)-java连接Redis
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702084-download.png)

<!-- more -->

## 一、Java连接Redis

### 1.1 创建maven项目

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702087-image-20201019100851633.png)

### 1.2 导入相关依赖

```xml
<dependencies>
    <!--jedis依赖-->
    <dependency>
        <groupId>redis.clients</groupId>
        <artifactId>jedis</artifactId>
        <version>2.9.0</version>
    </dependency>
    <!--junit依赖-->
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.12</version>
    </dependency>
    <!--Lombok依赖-->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>1.18.12</version>
    </dependency>

</dependencies>
```

### 1.3 测试

```java
public class Demo1 {
    @Test
    public void test(){
        //1.连接Redis
        Jedis jedis = new Jedis("192.168.199.138", 6379);
        //2.操作Redis
        jedis.set("name","李四");
        //3.释放资源
        jedis.close();
    }
}
```

## 二、Jedis如何存储和获取一个对象到Redis以byte[]的形式

### 2.1 准备一个User实体类

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
public class User implements Serializable {
    private Integer id;
    private String name;
    private Date birthday;
}
```

### 2.2 导入spring-context依赖

```xml
<!--导入spring-context-->
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-context</artifactId>
    <version>4.2.8.RELEASE</version>
</dependency>
```

### 2.3 测试

```java
public class Demo2 {
    @Test
    public void setByteArray(){
        //1.连接Redis服务
        Jedis jedis = new Jedis("192.168.199.138", 6379);

        //2.1准备key(string)-value(User)
        String key = "user";
        User value = new User(1, "mike", new Date());
        //2.2将key和value转换为byte[]
        byte[] byteKey = SerializationUtils.serialize(key);
        byte[] byteValue = SerializationUtils.serialize(value);
        //2.3将饿key和value存储到Redis
        jedis.set(byteKey,byteValue);

        //3.释放资源
        jedis.close();
    }

    @Test
    public void getByteArray(){
        //1.连接Redis服务
        Jedis jedis = new Jedis("192.168.199.138", 6379);

        //2.1准备key
        String key = "user";
        //2.2将key转换为byte[]
        byte[] byteKey = SerializationUtils.serialize(key);
        //2.3jedis去Redis中获取value
        byte[] value = jedis.get(byteKey);
        //2.4将value反序列化为对象
        User user = (User) SerializationUtils.deserialize(value);
        //2.5输出
        System.out.println(user);

        //3.释放资源
        jedis.close();
    }
}
```

## 三、Jedis如何存储和获取一个对象到Redis以String的形式

### 3.1 导入fastJSON依赖

```xml
<!--导入fastJOSN-->
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.73</version>
</dependency>
```

### 3.2 测试

```java
public class Demo3 {
    @Test
    public void setString(){
        //1.连接Redis服务
        Jedis jedis = new Jedis("192.168.199.138", 6379);

        //2.1准备key(string)-value(User)
        String stringKey = "user";
        User value = new User(1, "mike", new Date());
        //2.2使用fastJSON转化为json字符串
        String stringValue = JSON.toJSONString(value);
        //2.3将饿key和value存储到Redis
        jedis.set(stringKey,stringValue);

        //3.释放资源
        jedis.close();
    }

    @Test
    public void getString(){
        //1.连接Redis服务
        Jedis jedis = new Jedis("192.168.199.138", 6379);

        //2.1准备key
        String stringKey = "user";
        //2.2获取value
        String value = jedis.get(stringKey);
        //2.3将value反序列化为User
        User user = JSON.parseObject(value, User.class);
        //2.4输出
        System.out.println(user);

        //3.释放资源
        jedis.close();
    }
}
```

## 四、Jedis连接池的操作

### 方式一：使用连接池默认配置方式

```java
@Test
public void pool(){
    //1.创建连接池
    JedisPool pool = new JedisPool("192.168.199.138", 6379);
    //2.通过连接池获取jedis对象
    Jedis jedis = pool.getResource();
    //3.操作
    String value = jedis.get("name");
    System.out.println(value);
    //4.释放资源
    jedis.close();
}
```

### 方式一：自定义连接池配置方式

```java
public void pool2(){
    //1.创建连接池的配置信息
    GenericObjectPoolConfig poolConfig = new GenericObjectPoolConfig();
    poolConfig.setMaxTotal(100); //连接池中最大的活跃数
    poolConfig.setMaxIdle(10);  //最大空闲数
    poolConfig.setMinIdle(5);  //最小空闲数
    poolConfig.setMaxWaitMillis(3000);  //当连接池空了之后，多久没获取到jedis对象就超时

    //2.创建连接池
    JedisPool pool = new JedisPool(poolConfig,"192.168.199.138", 6379);

    //3.通过连接池获取jedis对象
    Jedis jedis = pool.getResource();

    //4.操作
    String value = jedis.get("name");
    System.out.println(value);

    //4.释放资源
    jedis.close();

}
```

## 五、Redis的管道操作

> Redis 管道技术可以在服务端未响应时，客户端可以继续向服务端发送请求，并最终一次性读取所有服务端的响应。

```java
@Test
public void pipeline(){
    //1.创建连接池
    JedisPool pool = new JedisPool("192.168.199.138", 6379);

    //2.通过连接池获取jedis对象
    Jedis jedis = pool.getResource();

    //3.创建管道
    Pipeline pipelined = jedis.pipelined();

    //4.执行命令
    for (int i = 0; i < 10000; i++) {
        pipelined.incr("qq");
    }
    pipelined.syncAndReturnAll();//进行管道操作

    //5.
    jedis.close();

}
```

