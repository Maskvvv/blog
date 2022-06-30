---
title: RabbitMQ-延迟队列
date: 2021-1-15
tags:
  - 微服务
  - RabbitMQ-延迟队列
  - RabbitMQ
  - spring
  - springboot
categories:
  - 微服务
  - RabbitMQ
  - RabbitMQ-延迟队列
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044952-1655043743-1_UnYL-2r54_7AnEwQv0cVxA.png)

<!--more-->

# 一、引言

## 1.1 什么是延迟队列

`延时队列`，首先，它是一种队列，队列意味着内部的元素是`有序`的，元素出队和入队是有方向性的，元素从一端进入，从另一端取出。

其次，`延时队列`，最重要的特性就体现在它的`延时`属性上，跟普通的队列不一样的是，`普通队列中的元素总是等着希望被早点取出处理，而延时队列中的元素则是希望被在指定时间得到取出和处理`，所以延时队列中的元素是都是带时间属性的，通常来说是需要被处理的消息或者任务。

简单来说，延迟队列存储的对象是对应的延时消息，所谓“延时消息”是指当消息被发送以后，并不想让消费者立即拿到消息，而是等待指定时间后，消费者才拿到这个消息进行消费。

## 1.2 延迟队列的引用场景

1. 支付订单在30分钟内未支付则自动取消订单。
2. 创建一个会议后需要在指定时间修改其状态，如：进行中 -> 已结束

> 通常处理这些业务会使用定时任务，但确定很明显，一是没法做到实时性，二是过于消耗性能。

## 1.3 RabbitMQ 实现延迟队列两种方式

- 利用 RabbitMQ 通过 **DLX（死信交换机）+ TTL（消息超时时间）**，实现定时任务。
- 使用 RabbitMQ 的 **rabbitmq_delayed_message_exchange 插件**来实现定时任务。

# 二、DLX + TTL 实现延迟队列

## 2.1 TTL 是什么

`TTL（Time To Live）`是 RabbitMQ 中一个消息或者队列的属性，表明`一条消息或者该队列中的所有消息的最大存活时间`，单位是毫秒。换句话说，如果一条消息设置了 TTL 属性或者进入了设置 TTL 属性的队列，那么这条消息如果在 TTL 设置的时间内没有被消费，则会成为**“死信”**。如果同时配置了队列的 TTL 和消息的 TTL，那么**较小的那个值将会被使用**。

> 对于给队列设置 TTL 方式，当消息队列设置过期时间的时候，那么消息过期了就会被删除，因为消息进入 RabbitMQ 后是存在一个消息队列中，**队列的头部是最早要过期的消息**，所以 RabbitMQ 只需要一个定时任务，从头部开始扫描是否有过期消息，有的话就直接删除。
>
> 对于给消息设置 TTL 方式，当消息过期后并**不会立马被删除**，而是当消息要投递给消费者的时候才会去删除，因为第二种方式，每条消息的过期时间都不一样，想要知道哪条消息过期，必须要遍历队列中的所有消息才能实现，当消息比较多时这样就比较耗费性能，因此对于第二种方式，当消息要投递给消费者的时候才去删除。

### 2.1.1 实现

#### 2.1.1.1 给单条消息设置 TTL

在发送消息的时候设置

```java
public void hello() {
    // 构建消息
    Message message = MessageBuilder.withBody("hello javaboy".getBytes())
        // 设置过期时间
        .setExpiration("10000")
        .build();
    // 发送消息
    rabbitTemplate.convertAndSend("queue_name", message);
}
```
#### 2.1.1.2 给队列设值 TTL

在创建队列的时候设置

```java
@Bean
Queue queue() {
    Map<String, Object> args = new HashMap<>();
    // 设置整个队列消息过期时间
    args.put("x-message-ttl", 10000);
    return new Queue(JAVABOY_QUEUE_DEMO, true, false, false, args);
}
```

> 还有一种特殊情况，就是将消息的**过期时间 TTL 设置为 0**，这表示如果消息**不能立马消费则会被立即丢掉**，这个特性可以部分替代 RabbitMQ3.0 以前支持的 immediate 参数，之所以所部分代替，是因为 immediate 参数在投递失败会有 basic.return 方法将消息体返回（这个功能可以利用死信队列来实现）。

## 2.2 什么是 DLX

死信交换机，`Dead-Letter-Exchange` 即 DLX。

死信交换机用来接收死信消息（`Dead Message`）的，那什么是死信消息呢？一般消息变成死信消息有如下几种情况：

- 消息被拒绝(`Basic.Reject()`/`Basic.Nack()`) ，井且设置 requeue 参数为false
- 消息过期
- 队列达到最大长度

当消息在一个队列中变成了死信消息后，此时就会被发送到 DLX，绑定 DLX 的消息队列则称为死信队列。

DLX 本质上也是一个普普通通的交换机，我们可以为任意队列指定 DLX，当该队列中存在死信时，RabbitMQ 就会自动的将这个死信发布到 DLX 上去，进而被路由到另一个绑定了 DLX 的队列上（即死信队列）。

### 2.2.1 实现 DLX

```java
@Bean
Queue queue() {
    Map<String, Object> args = new HashMap<>();
    //设置消息过期时间
    args.put("x-message-ttl", 0);
    // 设置死信交换机
    args.put("x-dead-letter-exchange", DLX_EXCHANGE_NAME);
    // 设置死信 routing_key
    args.put("x-dead-letter-routing-key", DLX_ROUTING_KEY);
    return new Queue(JAVABOY_QUEUE_DEMO, true, false, false, args);
}
```

> 添加两个参数即可
>
> - **x-dead-letter-exchange**：配置死信交换机。
> - **x-dead-letter-routing-key**：配置死信 `routing_key`。

将来发送到这个消息队列上的消息，如果发生了 **nack**、**reject** 或者**过期**等问题，**就会被发送到 DLX 上**，进而进入到与 DLX 绑定的消息队列上。

## 2.3 实现延迟队列

### 2.3.1 实现流程

![](http://qiniu.zhouhongyin.top/2022/06/12/1655045009-1642321507396-1642321507403.png)

### 2.3.2 创建一个 Spring Boot项目

**配置 RabbitMQ 配置信息**

```properties
spring.rabbitmq.host=localhost
spring.rabbitmq.username=guest
spring.rabbitmq.password=guest
spring.rabbitmq.port=5672
```

### 2.3.3 创建一个普通队列和普通交换机

```java
@Configuration
public class RabbitConfig {

    public static final String DLX_EXCHANGE = "dlxExchange";
    public static final String DLX_QUEUE = "dlxQueue";
    public static final String DLX_ROUTING_KEY = "dlxRoutingKey";
    
    /**
     * 创建普通交换机
     */
    @Bean
    public DirectExchange normalExchange() {
        return new DirectExchange(NORMAL_EXCHANGE, true, false);
    }

    /**
     * 创建普通队列
     */
    @Bean
    public Queue normalQueue() {
        Map<String, Object> args = new HashMap<>();
        //设置队列消息过期时间
        //args.put("x-message-ttl", 1000 * 10);
        // 设置死信交换机
        args.put("x-dead-letter-exchange", DLX_EXCHANGE);
        // 设置死信 routing_key
        args.put("x-dead-letter-routing-key", DLX_ROUTING_KEY);

        return new Queue(NORMAL_QUEUE, true, false, false, args);
    }

    /**
     * 绑定普通队列和普通交换机
     */
    @Bean
    public Binding normalBinding() {
        return BindingBuilder.bind(normalQueue()).to(normalExchange()).with(NORMAL_ROUTING_KEY);
    }
{
```

### 2.3.4 创建一个死信队列和死信交换机

```java
@Configuration
public class RabbitConfig {

    public static final String NORMAL_EXCHANGE = "normalExchange";
    public static final String NORMAL_QUEUE = "normalQueue";
    public static final String NORMAL_ROUTING_KEY = "normalRoutingKey";
    
    /**
     * 创建死信交换机
     */
    @Bean
    public DirectExchange dlxExchange() {
        return new DirectExchange(DLX_EXCHANGE, true, false);
    }

    /**
     * 创建死信队列
     */
    @Bean
    public Queue dlxQueue() {

        return new Queue(DLX_QUEUE, true);
    }

    /**
     * 绑定死信队列和死信交换机
     */
    @Bean
    public Binding dlxBinding() {
        return BindingBuilder.bind(dlxQueue()).to(dlxExchange()).with(DLX_ROUTING_KEY);
    }
{
```

### 2.3.5 创建一个死信队列消息的消费者

```java
@Component
public class MsgReceiver {
    @RabbitListener(queues = RabbitConfig.DLX_QUEUE)
    @RabbitHandler
    public void onLazyMessage(Message msg, Channel channel) throws IOException {
        long deliveryTag = msg.getMessageProperties().getDeliveryTag();
        //channel.basicAck(deliveryTag, true);
        System.out.println("消费时间："+LocalDateTime.now());
        System.out.println("dlx_queue receive " + new String(msg.getBody()));

    }
}
```

### 2.3.6 发送消息

```java
@SpringBootTest
class RabbitDemo03DlxApplicationTests {

    @Resource
    RabbitTemplate rabbitTemplate;

    @Test
    void contextLoads() {
        // 构建消息1
        Message message = MessageBuilder.withBody(("延迟消息1应该被消费时间："+ LocalDateTime.now().plusSeconds(7)).getBytes()).build();
        // 设置 7 秒后过期
        message.getMessageProperties().setDelay(7000);

        rabbitTemplate.convertAndSend(RabbitConfig.NORMAL_EXCHANGE, RabbitConfig.NORMAL_ROUTING_KEY, message);

        // 构建消息2
        Message message2 = MessageBuilder.withBody(("延迟消息2应该被消费时间："+ LocalDateTime.now().plusSeconds(1)).getBytes()).build();
        // 设置 1 秒后过期
        message.getMessageProperties().setDelay(1000);

        rabbitTemplate.convertAndSend(RabbitConfig.NORMAL_EXCHANGE, RabbitConfig.NORMAL_ROUTING_KEY, message2);
    }
}
```

### 2.3.7 结果

![](http://qiniu.zhouhongyin.top/2022/06/12/1655045056-1642388625921-1642388625927.png)

### 2.3.8 存在问题

虽然第二条消息比第一条消息先过期，但是由于第一条消息先进入队列，并且没有过期，所以队列会阻塞在该消息这，知道该消息过期才会消费后面的消息，这就导致了明明第二条消息先过期但最终两条消息同时被消费的情况。

所以该方式适合，消息过期时间固定的情况，如订单30分钟后未支付取消。

# 三、通过插件实现延迟队列

虽然 RabbitMQ 本身没有延迟队列，但是官方提供了插件，安装即可实现延迟队列。

## 3.1 安装插件

### 3.1.1 下载

选择适合自己 RabbitMQ 版本的插件。https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases

![](http://qiniu.zhouhongyin.top/2022/06/12/1655045223-1642384019067-1642384019077.png)

### 3.1.2 安装

将安装包拷贝到容器的 `plugins` 目录

```shell
docker cp ./rabbitmq_delayed_message_exchange-3.9.0.ez rabbit01:/plugins
```

进入容器

```shell
docker exec -it some-rabbit /bin/bash
```

启动插件

```shell
# 启动
rabbitmq-plugins enable rabbitmq_delayed_message_exchange

# 关闭
rabbitmq-plugins disable rabbitmq_delayed_message_exchange
```

查看是否安装成功

```
rabbitmq-plugins list
```

![](http://qiniu.zhouhongyin.top/2022/06/12/1655045092-image-20220117095431460.png)

## 3.2 实现

### 3.2.1 配置交换机和队列

```java
@Configuration
public class RabbitConfig {

    public static final String LAZY_EXCHANGE = "Ex.LazyExchange";
    public static final String LAZY_QUEUE = "MQ.LazyQueue";
    public static final String LAZY_KEY = "lazy.#";

    @Bean
    public TopicExchange lazyExchange(){
        //Map<String, Object> pros = new HashMap<>();
        //设置交换机支持延迟消息推送
        //pros.put("x-delayed-message", "topic");
        /*
         * 参数：
         * 1.交换机的名字
         * 2.交换机是否持久话
         * 3.是否自动删除（如果没有队列绑定改交换机那么自动删除）
         */
        TopicExchange exchange = new TopicExchange(LAZY_EXCHANGE, true, false);
        exchange.setDelayed(true);
        return exchange;
    }

    @Bean
    public Queue lazyQueue(){

        /*
         * 参数：
         * 1.队列的名字
         * 2.队列里的消息否持久话（true mq重启后为被消费的消息还会存在队列中）
         * 3.排他性（只能由创建队列的那个 connection 处理）
         * 4.是否自动删除（如果该队列没有消费者，那么自动删除改队列）
         */
        return new Queue(LAZY_QUEUE, true, false, false);
    }

    @Bean
    public Binding lazyBinding(){
        return BindingBuilder.bind(lazyQueue()).to(lazyExchange()).with(LAZY_KEY);
    }
}
```

> 设置交换机支持延迟消息推送
>
> - 方式一：`pros.put("x-delayed-message", "topic")`
> - 方式二：`exchange.setDelayed(true);`

### 3.2.2 接收消息

```java
@Component
public class MsgReceiver {

    @RabbitListener(queues = RabbitConfig.LAZY_QUEUE)
    @RabbitHandler
    public void onLazyMessage(String msg, Message message, Channel channel) throws IOException {
        long deliveryTag = message.getMessageProperties().getDeliveryTag();
        //channel.basicAck(deliveryTag, true);
        System.out.println(LocalDateTime.now());
        System.out.println(new String(message.getBody()));
        System.out.println(msg);
    }
}
```

### 3.2.3 发送消息

```java
@SpringBootTest
class RabbitDemo02DelaymqApplicationTests {
    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Test
    void contextLoads() {
        Message message = MessageBuilder.withBody(("延迟消息创建时间:"+ LocalDateTime.now() + "\n应该被消费时间："+ LocalDateTime.now().plusSeconds(6)).getBytes()).build();
        message.getMessageProperties().setDelay(6000);
        //message.getMessageProperties().setDelay(6 * 1000);
        rabbitTemplate.convertAndSend(RabbitConfig.LAZY_EXCHANGE, "lazy.boot", message);

    }

}
```

### 3.2.4 运行结果

![](http://qiniu.zhouhongyin.top/2022/06/12/1655045129-1642387698836-1642387698844.png)