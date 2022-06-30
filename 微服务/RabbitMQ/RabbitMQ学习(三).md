---
title: RabbitMQ学习(三)-springboot整合RabbitMQ
date: 2021-1-11
tags:
  - 微服务
  - RabbitMQ学习(三)-springboot整合RabbitMQ
  - RabbitMQ
  - spring
  - springboot
categories:
  - 微服务
  - RabbitMQ
  - RabbitMQ学习(三)-springboot整合RabbitMQ
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044767-1_UnYL-2r54_7AnEwQv0cVxA.png)

<!--more-->

## 一、环境搭建

### 1.1 创建一个简单的springboot项目

创建一个名为springboot-rabbitmq的springboot项目。

### 1.2 导入相关依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

### 1.3 编写配置文件

```yml
spring:
  rabbitmq:
    host: 192.168.31.138
    port: 5672
    username: test
    password: test
    virtual-host: /test
```

## 二、具体实现

### 2.1 编写RabbitMQ的配置类

编写一个名为RabbitMQConfig的配置类，进行exchange和queue的声明和绑定。

```java
@Configuration
public class RabbitMQConfig {

    //1.创建exchange - topic
    @Bean
    public TopicExchange topicExchange(){
        return new TopicExchange("springboot-topic-exchange",true,false);
    }

    //2.创建queue
    @Bean
    public Queue queue(){
        return new Queue("springboot-queue",true,false,false,null);
    }

    //3.将exchange和queue绑定在一起
    @Bean
    public Binding binding(TopicExchange topicExchange,Queue queue){
        return BindingBuilder.bind(queue).to(topicExchange).with("*.red.*");

    }

}
```

### 2.1 发布消息

通过rabbitTemplate的convertAndSend()方法进行消息的发布，他需要三个参数：

1. 参数1 指定交换机exchange
2. 参数2 指定routingKey
3. 参数3 指定具体要发布的消息

```java
@SpringBootTest
class SpringbootRabbitmqApplicationTests {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Test
    void publish() {
        rabbitTemplate.convertAndSend("springboot-topic-exchange","slow.red.dog","慢红狗");
    }

}
```

### 2.2 监听消息

通过@RabbitListener( )的queues属性指定要监听的队列。

```java
@Component
public class Consumer {
    @RabbitListener(queues = "springboot-queue")
    public void getMessage(Object message){
        System.out.println("接收到的消息："+message);
    }
}
```

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044763-image-20210111150809466.png)

## 三、手动ACK

### 3.1 修改配置文件

```yml
spring:
  rabbitmq:
    host: 192.168.31.138
    port: 5672
    username: test
    password: test
    virtual-host: /test
    listener:
      direct:
        acknowledge-mode: manual
```

### 3.2 修改监听者

在消费消息的地方进行通过basicAck()方法进行手动ACK

```java
@Component
public class Consumer {
    @RabbitListener(queues = "springboot-queue")
    public void getMessage(String msg, Channel channel, Message message) throws IOException {
        System.out.println("接收到的消息："+msg);
        //手动Ack
        channel.basicAck(message.getMessageProperties().getDeliveryTag(),false);
    }
}
```