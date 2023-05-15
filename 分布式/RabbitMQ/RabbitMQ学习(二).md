---
title: RabbitMQ学习(二)-Rabbit的使用
date: 2020-12-14
tags:
  - 微服务
  - RabbitMQ学习(二)-Rabbit的使用
  - RabbitMQ
  - spring
  - springboot
categories:
  - 微服务
  - RabbitMQ
  - RabbitMQ学习(二)-Rabbit的使用
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044656-1_UnYL-2r54_7AnEwQv0cVxA.png)

<!--more-->

## 一、Rabbit常见的六种通信方式



![](http://qiniu.zhouhongyin.top/2022/06/12/1655044659-rotue.png)

## 二、Java连接RabbitMQ

### 2.1 创建一个Maven项目

### 2.2 导入RabbitMQ相关依赖

```xml
<dependencies>
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.12</version>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>com.rabbitmq</groupId>
        <artifactId>amqp-client</artifactId>
        <version>5.10.0</version>
    </dependency>
</dependencies>
```

### 2.3 创建工具类连接RabbitMQ

```java
public class RabbitMQClient {
    public static Connection getConnection(){
        //1. 创建connection工厂
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("192.168.199.138");//设置ip
        factory.setPort(5672);             //设置端口号
        factory.setUsername("test");       //设置用户名
        factory.setPassword("test");       //设置密码
        factory.setVirtualHost("/test");   //设置VirtualHost
        //2. 通过工厂创建connection
        Connection connection = null;
        try {
            connection = factory.newConnection();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        }
        return connection;
    }
}
```

### 2.4 测试

```java
public class Demo1 {
    @Test
    public void testConnection() throws IOException {
        Connection connection = RabbitMQClient.getConnection();
        System.out.println(connection);
        connection.close();
    }
}
```

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044665-image-20201214110551858.png)

## 三、Hello-world 基本消息模型

**最简单的消息模型：**

一个生产者、一个默认交换机、一个队列和一个消费者。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044668-image-20201214111933140.png)

### 3.1 创建生产者

#### 步骤：

1. 通过getConnection静态方法获取连接对象
2. 通过连接对象获取channel管道
3. 通过channel管道的basicPublish()将消息发布到管道中，此方法需要四个参数：
   - 参数1 指定exchange，这里使用“”表示使用默认的交换机
   - 参数2 指定要发布到哪个队列（在使用默认exchange时）；
   - 参数3 指定传递的消息所携带的properties，这里使用null
   - 参数4 指定发布的具体消息，byte[]类型
4. 释放资源

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        Channel channel = connection.createChannel();

        //3. 发布消息到exchange,同时指定路由规则
        String msg = "Hello-Word"+(new Date());
        //basicPublish需要的四个参数：
        //参数1 指定exchange，这里使用“”表示使用默认的交换机
        //参数2 指定要发布到哪个队列
        //参数3 指定传递的消息所携带的properties，这里使用null
        //参数4 指定发布的具体消息，byte[]类型
        channel.basicPublish("","HelloWord",null,msg.getBytes());
        //ps:exchange是不会帮你将你的消息持久化本地的，Queue才能帮你持久化消息

        System.out.println("发布消息成功！");

        //4.释放资源
        channel.close();
        connection.close();
    }
}
```

### 3.2 创建消费者

#### 步骤：

1. 通过getConnection静态方法获取连接对象
2. 通过连接对象获取channel管道
3. 通过channel的queueDeclare()方法创建一个队列，此方法需要五个参数：
   - 参数1 String queue 指定要创建的队列的名称
   - 参数2 boolean durable 指定当前队列是否需要持久化（指定为true后消息会自动存储到本地）
   - 参数3 boolean exclusive 指定是否排外（当connection.close，后当前队列会被自动删除，并且当前队列只允许一个消费者进行消费）
   - 参数4 boolean autoDelete 如果此队列没有消费者在消费，则自动删除
   - 参数5 Map<String, Object> arguments 指定当前队列的其他信息
4. 回调方法：通过重写DefaultConsumer对象中的handleDelivery方法来接收管道中的消息
5.  通过channel的basicConsume方法来消费管道中的消息，此方法需要三个参数：
   - 参数1 String queue 指定要消费哪个队列
   - 参数2 DeliverCallback deliverCallback 指定是否自动ACK（当设置为true时，消费者接受到消息，会自动告诉RabbitMQ）
   - 参数3 CancelCallback cancelCallback 指定回调方法
6. 释放资源

```java
public class Customer {

    @Test
    public void customer() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        Channel channel = connection.createChannel();

        //3.声明队列（HelloWord）
        //queueDeclare所需要的五个参数：
        //参数1 String queue 指定要创建的队列的名称
        //参数2 boolean durable 指定当前队列是否需要持久化（指定为true后消息会自动存储到本地）
        //参数3 boolean exclusive 指定是否排外（当connection.close，后当前队列会被自动删除，并且当前队列只允许一个消费者进行消费）
        //参数4 boolean autoDelete 如果此队列没有消费者在消费，则自动删除
        //参数5 Map<String, Object> arguments 指定当前队列的其他信息
        channel.queueDeclare("HelloWord",false,false,false,null);

        //4.开启监听指定Queue
        //回调方法
        DefaultConsumer consumer = new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                System.out.println("接收到的消息："+new String(body,"UTF-8"));
            }
        };
        //basicConsume所需要的三个参数：
        //参数1 String queue 指定要消费哪个队列
        //参数2 DeliverCallback deliverCallback 指定是否自动ACK（当设置为true时，消费者接受到消息，会自动告诉RabbitMQ）
        //参数3 CancelCallback cancelCallback 指定回调方法
        channel.basicConsume("HelloWord",true,consumer);

        System.out.println("正在监听队列！");
        //避免程序运行完自动停止，方便测试
        System.in.read();

        //5.释放资源
        channel.close();
        connection.close();
    }
}
```

> **注：**
>
> - 队列的声明可以在publish中、可以在customer中也可以都创建（创建队列时，有相同队列则不创建，没有则创建），但需要注意的是，发布消息时或者消费消息前需要存在一个声明好的队列
> - exchange是不会帮你将你的消息持久化本地的，Queue才能帮你持久化消息

## 四、Work Queues工作队列模型

在基本消息模型中，一个生产者对应一个消费者，而实际生产过程中，往往消息生产会发送很多条消息，如果消费者只有一个的话效率就会很低，因此rabbitmq有另外一种消息模型，这种模型下，一个生产发送消息到队列，允许有多个消费者接收消息，但是一条消息只会被一个消费者获取。

> 一个生产者，一个默认交换机，一个队列，两个消费者。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044673-image-20210110171109976.png)

### 4.1 创建生产者

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        Channel channel = connection.createChannel();

        //3. 发布消息到exchange,同时指定路由规则
        for (int i = 0; i < 10; i++) {
            String msg = "Hello-Word"+i;
            channel.basicPublish("","work",null,msg.getBytes());
        }

        System.out.println("发布消息成功！");

        //4.释放资源
        channel.close();
        connection.close();
    }

}
```

### 4.2 创建消费者

> ACK (Acknowledge character）即是确认字符，在数据通信中，接收站发给发送站的一种传输类控制字符。表示发来的数据已确认接收无误。

#### 手动ACK：

1.  channel的**basicConsume()**方法的第二个参数设为**false**，表示**不使用自动ACK**。
2. 通过channel的**basicQos(int n)** 方法指定一次**消费多少条消息**。
3. 在DefaultConsumer重写的handleDelivery方法中进行手动ACK（因为在手动ACK前已经通过body属性获取到了消息，相当于消费了消息，所以可以在他的后面可以进行ACK）：通过channel的**basicAck()**方法进行**手动ACK**，第**二个参数设为false**表示**不进行批量操作**。

**消费者1**

```java
public class Customer1 {

    @Test
    public void customer() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        final Channel channel = connection.createChannel();

        //3.声明队列（HelloWord）
        channel.queueDeclare("work",false,false,false,null);

        //4.指定当前消费者一此消费多少条消息
        channel.basicQos(1);

        //5.开启监听指定Queue
        //回调方法
        DefaultConsumer consumer = new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("消费者1号接收到的消息："+new String(body,"UTF-8"));
                channel.basicAck(envelope.getDeliveryTag(),false);
            }
        };
        channel.basicConsume("work",false,consumer);

        System.out.println("消费者1号正在监听队列！");
        //避免程序运行完自动停止，方便测试
        System.in.read();

        //6.释放资源
        channel.close();
        connection.close();
    }

}
```

**消费者2**

```java
public class Customer1 {
    @Test
    public void customer() throws Exception {
        ........
    }
}
```
### 测试

![publisher](http://qiniu.zhouhongyin.top/2022/06/12/1655044679-image-20210110175628344.png)

![customer1](http://qiniu.zhouhongyin.top/2022/06/12/1655044681-image-20210110175651036.png)

![customer2](http://qiniu.zhouhongyin.top/2022/06/12/1655044683-image-20210110175709357.png)

## 五、 Publish/Subscribe（FANOUT） 订阅模型

在之前的模型中，一条消息只能被一个消费者获取，而在订阅模式中，可以实现一条消息被多个消费者获取。在这种模型下，消息传递过程中比之前多了一个exchange交换机，生产者不是直接发送消息到队列，而是先发送给交换机，经由交换机分配到不同的队列，而每个消费者都有自己的队列。

> 一个生产者，一个自己创建的交换机，两个队列，两个消费者：
>
> 1. 1个生产者，多个消费者
>
> 2. 每一个消费者都有自己的一个队列
>
> 3. 生产者没有将消息直接发送到队列，而是发送到了交换机
>
> 4. 每个队列都要绑定到交换机
>
> 5. 生产者发送的消息，经过交换机到达队列，实现一个消息被多个消费者获取的目的
>
> ps：生产者发布消息，所有消费者都可以获取所有消息。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044686-image-20210111104531003.png)

### 5.1 创建生产者

创建自己的exchange交换机：

1. 通过channel的exchangeDeclare()方法声明一个exchange，该方法需要两个参数：
   - 参数1 exchange的名称
   - 参数2 指定exchange的类型  FANOUT(Publish/Subscribe)、DIRECT(Routing)、TOPIC(Topics)
2. 通过channel的queueBind()将声明好的exchange和存在的queue进行绑定（**绑定的事情可以在生产者里进行也可以在消费者里进行**），改方法需要三个参数：
   - 参数1 队列的名称
   - 参数2 exchange的名称
   - 参数3 规则
3. 在basicPublish()中将默认的exchange更改为自己定义的exchange，**此时第二个参数routingKey变为路由的规则。**

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        Channel channel = connection.createChannel();

        //3. 创建exchange - 绑定一个队列
        //参数1 exchange的名称
        //参数2 指定exchange的类型  FANOUT(Publish/Subscribe)  DIRECT(Routing)  TOPIC(Topics)
        channel.exchangeDeclare("pubsub-exchange", BuiltinExchangeType.FANOUT);
        //将交换机和队列进行绑定
        channel.queueBind("pubsub-queue1","pubsub-exchange","");
        channel.queueBind("pubsub-queue2","pubsub-exchange","");

        //4. 发布消息到exchange,同时指定路由规则
        for (int i = 0; i < 10; i++) {
            String msg = "Hello-Word"+i;
            channel.basicPublish("pubsub-exchange","",null,msg.getBytes());
        }

        System.out.println("发布消息成功！");

        //5.释放资源
        channel.close();
        connection.close();
    }

}
```

### 5.2 创建消费者

**消费者1**

```java
public class Customer1 {

    @Test
    public void customer() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        final Channel channel = connection.createChannel();

        //3.声明队列（HelloWord）
        channel.queueDeclare("pubsub-queue1",false,false,false,null);

        //4.指定当前消费者一此消费多少条消息
        channel.basicQos(1);

        //5.开启监听指定Queue
        //回调方法
        DefaultConsumer consumer = new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("消费者1号接收到的消息："+new String(body,"UTF-8"));
                channel.basicAck(envelope.getDeliveryTag(),false);
            }
        };
        channel.basicConsume("pubsub-queue1",false,consumer);


        System.out.println("消费者1号正在监听队列！");
        //避免程序运行完自动停止，方便测试
        System.in.read();

        //6.释放资源
        channel.close();
        connection.close();
    }

}
```

**消费者2**

```java
public class Customer2 {
    @Test
    public void customer() throws Exception {
       ..........
    }

}
```

### 测试

![customer1](http://qiniu.zhouhongyin.top/2022/06/12/1655044690-image-20210111112538675.png)

![customer2](http://qiniu.zhouhongyin.top/2022/06/12/1655044693-image-20210111112555889.png)

> 注意：exchange与队列一样都需要提前声明，**如果未声明就使用交换机，则会报错**。如果不清楚生产者和消费者谁先声明，为了保证不报错，生产者和消费者都声明交换机，同样的，交换机的创建也会保证幂等性。

## 六、Routing（Direct） 订阅模型

在fanout模型中，生产者发布消息，所有消费者都可以获取所有消息。在路由模式（Direct）中，可以实现不同的消息被不同的队列消费，在Direct模式下，交换机不再将消息发送给所有绑定的队列，而是根据Routing Key将消息发送到指定的队列，队列在与交换机绑定时会设定一个Routing Key，而生产者发送的消息时也需要携带一个Routing Key。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044697-image-20210111113445410.png)

> 如图所示，消费者C1的队列与交换机绑定时设置的Routing Key是“error”， 而C2的队列与交换机绑定时设置的Routing Key包括三个：“info”，“error”，“warning”，假如生产者发送一条消息到交换机，并设置消息的Routing Key为“info”，那么交换机只会将消息发送给C2的队列。

### 6.1 创建生产者

使用步骤：

1. 将exchangeDeclare()的第二个参数改为“BuiltinExchangeType.DIRECT”，这样路由规则就变为了Routing
2. 将queueBind()的三个参数，指定为所需的routingKey
3. basicPublish()的第二个参数中指定routingKey

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        Channel channel = connection.createChannel();

        //3. 创建exchange - 绑定一个队列
        //参数1 exchange的名称
        //参数2 指定exchange的类型  FANOUT(Publish/Subscribe)  DIRECT(Routing)  TOPIC(Topics)
        channel.exchangeDeclare("routing-exchange", BuiltinExchangeType.DIRECT);
        //将交换机和队列进行绑定
        channel.queueBind("routing-queue-error","routing-exchange","ERROR");
        channel.queueBind("routing-queue-info","routing-exchange","INFO");

        //4. 发布消息到exchange,同时指定路由规则
        channel.basicPublish("routing-exchange","ERROR",null,"ERROR1".getBytes());
        channel.basicPublish("routing-exchange","INFO",null,"INFO3".getBytes());
        channel.basicPublish("routing-exchange","INFO",null,"INFO1".getBytes());
        channel.basicPublish("routing-exchange","INFO",null,"INFO2".getBytes());
        
        System.out.println("发布消息成功！");

        //5.释放资源
        channel.close();
        connection.close();
    }

}
```

### 6.2 创建消费者

**消费者1**

```java
public class Customer1 {

    @Test
    public void customer() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        final Channel channel = connection.createChannel();

        //3.声明队列（HelloWord）
        channel.queueDeclare("routing-queue-error",false,false,false,null);

        //4.指定当前消费者一此消费多少条消息
        channel.basicQos(1);

        //5.开启监听指定Queue
        //回调方法
        DefaultConsumer consumer = new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("消费者ERROR接收到的消息："+new String(body,"UTF-8"));
                channel.basicAck(envelope.getDeliveryTag(),false);
            }
        };
        channel.basicConsume("routing-queue-error",false,consumer);
        
        System.out.println("消费者ERROR正在监听队列！");
        //避免程序运行完自动停止，方便测试
        System.in.read();

        //6.释放资源
        channel.close();
        connection.close();
    }

}
```

**消费者2**

```java
public class Customer2 {
    @Test
    public void customer() throws Exception {
       ........
    }

}
```

### 测试

![error](http://qiniu.zhouhongyin.top/2022/06/12/1655044701-image-20210111132949483.png)

![info](http://qiniu.zhouhongyin.top/2022/06/12/1655044705-image-20210111133009771.png)

## 七、Topics（topic） 发布订阅

Topic类型的Exchange与Direct相比，都是可以根据RoutingKey把消息路由到不同的队列。只不过Topic类型Exchange可以让队列在绑定Routing key 的时候使用通配符。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044707-image-20210111134805609.png)

> Routingkey 一般都是有一个或多个单词组成，多个单词之间以”.”分割，例如：fast.red.monkey
>
> routingKey通配符规则：
>
> -  \#：匹配一个或多个词 
> -  *：匹配不多不少恰好1个词

### 7.1 创建生产者

```java
public class Publisher {
    @Test
    public void publish() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        Channel channel = connection.createChannel();

        //3. 创建exchange - 绑定一个队列
        //参数1 exchange的名称
        //参数2 指定exchange的类型  FANOUT(Publish/Subscribe)  DIRECT(Routing)  TOPIC(Topics)
        channel.exchangeDeclare("topic-exchange", BuiltinExchangeType.TOPIC);
        //将交换机和队列进行绑定
        //动物信息<speed>,<color>,<what>
        //*.red.*       -> *展位符
        //fast.#        -> 通配符
        //*.*.rabbit
        channel.queueBind("topic-queue-1","topic-exchange","*.red.*");
        channel.queueBind("topic-queue-2","topic-exchange","fast.#");
        channel.queueBind("topic-queue-2","topic-exchange","*.*.rabbit");

        //4. 发布消息到exchange,同时指定路由规则
        channel.basicPublish("topic-exchange","fast.red.monkey",null,"快红侯".getBytes());
        channel.basicPublish("topic-exchange","slow.blue.rabbit",null,"慢蓝兔".getBytes());
        channel.basicPublish("topic-exchange","fast.orange.dog",null,"快橙狗".getBytes());

        System.out.println("发布消息成功！");

        //5.释放资源
        channel.close();
        connection.close();
    }

}
```

### 7.2 创建消费者

**消费者1**

```java
public class Customer1 {

    @Test
    public void customer() throws Exception {
        //1.获取connection
        Connection connection = RabbitMQClient.getConnection();

        //2. 创建channel
        final Channel channel = connection.createChannel();

        //3.声明队列（HelloWord）
        channel.queueDeclare("topic-queue-1",false,false,false,null);

        //4.指定当前消费者一此消费多少条消息
        channel.basicQos(1);

        //5.开启监听指定Queue
        //回调方法
        DefaultConsumer consumer = new DefaultConsumer(channel){
            @Override
            public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("消费者1接收到的消息："+new String(body,"UTF-8"));
                channel.basicAck(envelope.getDeliveryTag(),false);
            }
        };
        channel.basicConsume("topic-queue-1",false,consumer);

        System.out.println("消费者1正在监听队列！");
        //避免程序运行完自动停止，方便测试
        System.in.read();

        //6.释放资源
        channel.close();
        connection.close();
    }

}
```

**消费者2**

```java
public class Customer1 {
    @Test
    public void customer() throws Exception {
        ........
    }

}
```

### 测试

![customer1](http://qiniu.zhouhongyin.top/2022/06/12/1655044712-image-20210111143030959.png)

![customer2](http://qiniu.zhouhongyin.top/2022/06/12/1655044714-image-20210111143007350.png)