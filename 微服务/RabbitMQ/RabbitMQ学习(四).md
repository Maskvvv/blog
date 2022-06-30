---
title: RabbitMQ学习(四)-RabbitMQ的其它操作
date: 2021-1-12
tags:
  - 微服务
  - RabbitMQ学习(四)-RabbitMQ的其它操作
  - RabbitMQ
  - spring
  - springboot
categories:
  - 微服务
  - RabbitMQ
  - RabbitMQ学习(四)-RabbitMQ的其它操作
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044810-1_UnYL-2r54_7AnEwQv0cVxA.png)

<!--more-->

## 一、消息可靠性

RabbitMQ的事务：事务可以保证消息的100%传递，可以通过事务回滚去记录日志，后面定时再发送当前消息。但是事务的操作效率太低，加入事务后效率比不加事务慢至少100倍。

> 生成者在发送消息过程中也可能出现错误或者网络延迟灯故障，导致消息未成功发送到交换机或者队列，或重复发送消息，为了解决这个问题，rabbitmq中有多个解决办法。
>
> RabbitMQ除了事务，还提供了Confirm的确认机制，这种机制的效率比事务高很多。

## 二、Confirm机制

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044814-RabbitMQ%E5%8F%AF%E9%9D%A0%E6%80%A7-eba4bf1515614e0eb0c1dd862525a061.jpg)

可以确保生产者将消息发动到exchange中，但并不能保证消息发送到queue中。

### 2.1 普通Confirm方式

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        //2. 创建channel
        //3. 发布消息到exchange,同时指定路由规则
		..........
        
        String msg = "Hello-Word"+(new Date());
       
        
        //开启confirm
        channel.confirmSelect();

        channel.basicPublish("","HelloWord",null,msg.getBytes());
		
        //对是否发送成功进行处理
        if(channel.waitForConfirms()){
            System.out.println("send message success！");
        }else {
            System.out.println("send message failure！");
        }

   
        //4.释放资源
      	......
    }

}
```

### 2.2 批量Confirm方式

channel.waitForConfirmsOrDie()：当你发送的全部消息，有一个失败时，则直接全部失败，并抛出异常。

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        //2. 创建channel
        //3. 发布消息到exchange,同时指定路由规则
        ............

            
        //开启confirm
        channel.confirmSelect();

        for (int i = 0; i < 10; i++) {
            String msg = "Hello-Word"+i;
            channel.basicPublish("","HelloWord",null,msg.getBytes());
        }
        //当你发送的全部消息，有一个失败时，则直接全部失败，并抛出异常。
        channel.waitForConfirmsOrDie();


        //4.释放资源
		........
    }

}
```

### 2.3 异步Confirm方式

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        //2. 创建channel
        
        ...............
   
        //3. 发布消息到exchange,同时指定路由规则

        //开启confirm
        channel.confirmSelect();

        for (int i = 0; i < 10; i++) {
            String msg = "Hello-Word"+i;
            channel.basicPublish("","HelloWord",null,msg.getBytes());
        }
        
		//开启异步回调
        channel.addConfirmListener(new ConfirmListener() {
            public void handleAck(long deliveryTag, boolean multiple) throws IOException {
                System.out.println("send message success!标识："+deliveryTag+"是否批量操作："+multiple);
            }

            public void handleNack(long deliveryTag, boolean multiple) throws IOException {
                System.out.println("send message failure!标识："+deliveryTag+"是否批量操作："+multiple);
            }
        });

        //4.释放资源
   
    }

}
```

## 三、return机制

### 3.1 介绍

> - Confirm只能保证到exchange，无法保证可以被exchange分发到queue
> - 而且exchange不能持久化消息，queue才可以持久化消息
> - 采用Return机制来监听消息是否从exchange发送到queue中

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044818-RabbitMQ%E5%8F%AF%E9%9D%A0%E6%80%A7return-0c5726ce3d154f19a1647718f74e9768.jpg)

### 3.2 实现

1. 通过  channel 的 addReturnListener() 方法开启return机制
2. 在addReturnListener()的形参中创建一个 ReturnListener 类型的接口，并实现它的 handleReturn() 方法（ 当消息没有被送达到queue时此才会执行）。
3. 再通过 basicPublish() 发送消息时将他的第三个形参mandatory(受托者 ;强制性的)设置为true。

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        //2. 创建channel
        //3. 发布消息到exchange,同时指定路由规则
        
		.........
            
        //开启return机制
        channel.addReturnListener(new ReturnListener() {
            public void handleReturn(int replyCode, String replyText, String exchange, String routingKey, AMQP.BasicProperties properties, byte[] body) throws IOException {
                //当消息没有被送达到queue时才会执行
                System.out.println(new String(body,"UTF-8")+" message not send queue!");
            }
        });

        //开启confirm
        channel.confirmSelect();

        //发送消息
        for (int i = 0; i < 10; i++) {
            String msg = "Hello-Word"+i;
            channel.basicPublish("","xxxxxx",true,null,msg.getBytes());
        }
        
		//异步confirm回调
        channel.addConfirmListener(new ConfirmListener() {
            public void handleAck(long deliveryTag, boolean multiple) throws IOException {
                System.out.println("send message success!标识："+deliveryTag+"是否批量操作："+multiple);
            }

            public void handleNack(long deliveryTag, boolean multiple) throws IOException {
                System.out.println("send message failure!标识："+deliveryTag+"是否批量操作："+multiple);
            }
        });
        

        System.out.println("发布消息成功！");


        //4.释放资源
		...........
    }

}
```

## 四、在spring boot中开启Confirm和return机制

### 4.1 编辑springboot配置文件

开启Confirm和return机制，需要在配置文件中添加两个属性：

1. publisher-confirm-type: simple
2. publisher-returns: true

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
    publisher-confirm-type: simple
    publisher-returns: true
```

### 4.2 编写配置类

1. 创建名为 PublisherConfirmAndReturnConfig 的配置类并实现 RabbitTemplate 接口的两个抽象方法：
   - RabbitTemplate.ConfirmCallback.confirm
   - RabbitTemplate.ReturnsCallback.returnedMessage
2. 通过 @PostConstruct 注解在服务器运行时就告诉Rabbit我开启了Confirm和return机制。
3. 重写并实现confirm和returnedMessage方法。

```java
@Component
public class PublisherConfirmAndReturnConfig implements RabbitTemplate.ConfirmCallback,RabbitTemplate.ReturnsCallback {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @PostConstruct  //init-method
    public void initMethod(){
        rabbitTemplate.setConfirmCallback(this);
        rabbitTemplate.setReturnsCallback(this);
    }


    //confirm回调
    @Override
    public void confirm(CorrelationData correlationData, boolean b, String s) {
        if (b){
            System.out.println("send message success to exchange");
        } else{
            System.out.println("send message failure to exchange");
        }
    }

    //return回调
    @Override
    public void returnedMessage(ReturnedMessage returnedMessage) {
        //只有在消息没有送达到queue时执行
        System.out.println("send message failure to queue!");

    }
}
```

> **@PostConstruct 注解：**
>
> @PostConstruct该注解被用来修饰一个非静态的 void() 方法。被@PostConstruct修饰的方法会在**服务器加载Servlet的时候**运行，并且只会被服务器**执行一次**。PostConstruct在构造函数之后执行， init() 方法之前执行。
>
> 通常我们会是在Spring框架中使用到@PostConstruct注解 该注解的方法在整个Bean初始化中的执行顺序：Constructor(构造方法) -> @Autowired(依赖注入) -> @PostConstruct(注释的方法)

### 4.3 测试

```java
@SpringBootTest
class SpringbootRabbitmqApplicationTests {
    @Autowired
    private RabbitTemplate rabbitTemplate;
    @Test
    void publish() throws IOException {
        rabbitTemplate.convertAndSend("springboot-topic-exchange","slow.white.dog","慢红狗");
        System.in.read();
    }
}
```

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044823-image-20210112152947666.png)

## 五、消息的重复消费

### 5.1 介绍

当消费者消费完消息后发生了异常没有给 RabbitMQ 返回一个 ACK 就可能导致消息的重复消费。

> 重复消费消息，会对非幂等操作造成问题（幂等性操作：执行多次操作不影响最终结果，例如删除操作）

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044826-RabbitMQ%E9%87%8D%E5%A4%8D%E6%B6%88%E8%B4%B9-709a1f3ebca54c38ab43c87b0cb3f3a7.png)

为了解决消息被重复消费的问题，可以采用 Redis ，在消费者消费之前，将消息 id 放到 redis 中。

- id : 0(正在执行业务)
- id : 1(执行业务成功)

如果 ack 失败，在RabbitMQ将消息交给其他消费者时，消费者先执行 setnx (redis方法)，如果 key 已经存在则获取 key 的值，当获取到的值为0时，消费者什么都不做，当获取到的值为1时，消费者直接 ack。

极端情况：第一个消费者执行业务时出现了死锁，在setnx基础上，再给key设置一个生存时间。

### 5.2 实现

#### 5.2.1 导入Redis依赖

```xml
<dependency>
    <groupId>redis.clients</groupId>
    <artifactId>jedis</artifactId>
    <version>2.9.0</version>
</dependency>
```

#### 5.2.2 编写生产者

在发送消息时，在 BasicProperties 中指定消息的 id 。

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        //2. 创建channel
        ..........

        //3. 发布消息到exchange,同时指定路由规则

        //开启confirm
        channel.confirmSelect();
        AMQP.BasicProperties properties = new AMQP.BasicProperties().builder()
                .deliveryMode(1)
                .messageId(UUID.randomUUID().toString())
                .build();

        String msg = "Hello-Word";
        channel.basicPublish("","HelloWord",properties,msg.getBytes());


        channel.addConfirmListener(new ConfirmListener() {
            public void handleAck(long deliveryTag, boolean multiple) throws IOException {
                System.out.println("send message success!标识："+deliveryTag+"是否批量操作："+multiple);
            }

            public void handleNack(long deliveryTag, boolean multiple) throws IOException {
                System.out.println("send message failure!标识："+deliveryTag+"是否批量操作："+multiple);
            }
        });

        System.out.println("发布消息成功！");
        
        //4.释放资源
        channel.close();
        connection.close();
    }
}
```

#### 5.2.3 编写消费者

在消费消息时，获取 消息的 id 并放入 Redis 中。

```java
public class Customer {

    @Test
    public void customer() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        final Channel channel = connection.createChannel();

        //3.声明队列（HelloWord）

        channel.queueDeclare("HelloWord",false,false,false,null);

        //4.开启监听指定Queue
        //回调方法
        DefaultConsumer consumer = new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {

                Jedis jedis = new Jedis("192.168.31.138",6379);

                //获取消息的唯一标识id
                String messageId = properties.getMessageId();

                //1.setnx到Redis中，默认指定value为0，表示正在消费消息。
                String result = jedis.set(messageId, "0", "NX", "EX", 10);

                //2.判断此消息是否存在在Redis内
                if (result != null && result.equalsIgnoreCase("OK")){
                    //如果消费成功，设置Redis中该消息的值为1
                    System.out.println("接收到的消息："+new String(body,"UTF-8"));
                    jedis.set(messageId,"1");
                    //jedis.expire(messageId,5);
                    channel.basicAck(envelope.getDeliveryTag(),false);

                }else {//当该消息已经存在在Redis内似的情况
                    //判断该消息的值，如果为 1 ，手动ack；如果为 0 ，return 0 ；

                    String s = jedis.get(messageId);
                    if ("1".equalsIgnoreCase(s)){
                        channel.basicAck(envelope.getDeliveryTag(),false);
                    }
                }
            }
        };

        channel.basicConsume("HelloWord",false,consumer);

        System.out.println("正在监听队列！");
        //避免程序运行完自动停止，方便测试
        System.in.read();

        //5.释放资源
        channel.close();
        connection.close();
    }

}
```

## 六、spring boot 实现消息的重复消费

### 6.1 导入 Redis 相关依赖

```java
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
```

### 6.2 编写生产者

发送消息时设置上消息的 ID。

```java
@SpringBootTest
class SpringbootRabbitmqApplicationTests {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Test
    void publish() throws IOException {
        CorrelationData messageId = new CorrelationData(UUID.randomUUID().toString());

        rabbitTemplate.convertAndSend("springboot-topic-exchange","slow.red.dog","慢红狗",messageId);
        System.in.read();
    }

}
```

### 6.3 编写消费者

```java
@Component
public class Consumer {

    @Autowired
    private StringRedisTemplate redisTemplate;

    @RabbitListener(queues = "springboot-queue")
    public void getMessage(String msg, Channel channel, Message message) throws IOException {
        //1.获取id，并放入redis中
        String messageId = message.getMessageProperties().getHeader("spring_returned_message_correlation");
        if (redisTemplate.opsForValue().setIfAbsent(messageId,"0",10, TimeUnit.SECONDS)) {
            //2.消费消息
            System.out.println("接收到的消息：" + msg);

            //3.设置此消息的值为 1
            redisTemplate.opsForValue().set(messageId,"1");

            //手动ack
            channel.basicAck(message.getMessageProperties().getDeliveryTag(),false);
        }else {
            //4.获取redis中的值，如果值为 1 ，则手动ack，如果为 0 ，则什么都不做。
            if ("1".equalsIgnoreCase(redisTemplate.opsForValue().get(messageId))){
                //手动Ack
                channel.basicAck(message.getMessageProperties().getDeliveryTag(),false);
            }
        }
    }

}
```