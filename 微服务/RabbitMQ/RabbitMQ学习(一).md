---
title: RabbitMQ学习(一)-介绍与安装
date: 2020-12-13
tags:
  - 微服务
  - RabbitMQ学习(一)-介绍与安装
  - RabbitMQ
  - spring
  - springboot
  - docker
categories:
  - 微服务
  - RabbitMQ
  - RabbitMQ学习(一)-介绍与安装
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043743-1_UnYL-2r54_7AnEwQv0cVxA.png)

<!--more-->

## 一、引言

Rabbit的使用解决了两个问题：

- 模块之间的耦合度高，导致其中一个模块宕机后，全部功能都不能使用
- 同步通讯的成本问题

## 二、介绍

### 2.1 消息队列（MQ）介绍

#### **2.1.1 什么是消息队列**

消息（Message）是指在应用之间传送的数据，消息可以非常简单，比如只包含文本字符串，也可以更复杂，可能包含嵌入对象。
消息队列（Message Queue）是一种应用间的通信方式，消息发送后可以立即返回，有消息系统来确保信息的可靠专递，消息发布者只管把消息发布到MQ中而不管谁来取，消息使用者只管从MQ中取消息而不管谁发布的，这样发布者和使用者都不用知道对方的存在。

#### **2.1.2 为何使用消息队列**

从上面描述中可以看出消息队列是一种应用间的异步协作机制，那什么时候需要使用MQ呢？
以常见的订单系统为例子，用户点击【下单】按钮后的业务逻辑包括：扣减库存、生成相应的单据、发红包、发短信通知‘在业务发展初期这些逻辑可能放在一起同步执行，随着业务订单量增长，需要提升系统服务的性能，这时候可以将一些不需要立即生效的操作拆分出来异步执行，，比如发红包、发短信通知等。这种场景就可以用MQ，在下单的主流程（比如扣减库存、生成相应的单据）完成之后发送一条消息到MQ让主流程快速完结，而由另外的单独线程拉取MQ的消息（或者由MQ推送消息），当发现MQ中有发红包或者发短信之类的消息，执行相应的业务逻辑。
以上是用于业务解耦的情况，其他常见场景包括最终一致性、广播、错峰流控等等。

#### 2.1.3 使用消息队列个好处

- **多系统协作需要分布式** 

  例如消息队列的数据需要在多个系统之间共享，所以需要提供分布式通信机制、协同机制

- **可靠**

   消息会被持久化到分布式存储中，这样避免了单台机器存储的消息由于机器问题导致消息丢失

- **可扩展**

   分布式消息队列，会随着访问量的增加而方便的增加处理服务器

> 目前市面上常见的MQ：
>
> - ActiveMQ：基于JMS
> - RabbitMQ：基于AMQP协议，erlang语言开发，稳定性好
> - RocketMQ：基于JMS，阿里巴巴产品，目前交由Apache基金会
> - Kafka：分布式消息系统，高吞吐量

### 2.2 RabbitMQ介绍

RabbitMQ是一个开源的AMQP实现，服务器端用Erlang语言编写，支持多种客户端，如：Python、Ruby、.NET、Java、JMS、C、PHP、ActionScript、XMPP、STOMP等，支持AJAX。用于在分布式系统中存储转发消息，在易用性、扩展性、高可用性等方面表现不俗。

> AMQP，即Advanced Message Queuing Protocol，高级消息队列协议，是应用层协议的一个开放标准，为面向消息的中间件设计。消息中间件主要用于组件之间的解耦，消息的发送者无需知道消息使用者的存在，反之亦然。
>
> AMQP的主要特征是面向消息、队列、路由（包括点对点和发布/订阅）、可靠性、安全。

## 三、RabbitMQ的概念模型

### **3.1 消息模型**

> 所有 MQ 产品从模型抽象上来说都是一样的过程：
>
> 消费者（consumer）订阅某个队列。生产者（producer）创建消息，然后发布到队列（queue）中，最后将消息发送到监听的消费者。

![消息模型](http://qiniu.zhouhongyin.top/2022/06/12/1655043747-image-20201213184027363.png)

### **3.2 RabbitMQ 基本概念**

1. **Message-消息：**消息是不具名的，它由消息头和消息体组成。消息体是不透明的，而消息头则由一系列的可选属性组成，这些属性包括routing-key（路由键）、priority（相对于其他消息的优先权）、delivery-mode（指出该消息可能需要持久性存储）等。
2. **Publisher-生产者：**发布消息到RabbitMQ中的Exchange
3. **Consumer-消费者**：监听RabbitMQ中的Queue的消息
4. **Exchange-交换机**：用来接收生产者发送的消息并将这些消息路由给服务器中的队列。
5. **Queue-队列**：用来保存消息直到发送给消费者。它是消息的容器，也是消息的终点。一个消息可投入一个或多个队列。消息一直在队列里面，等待消费者连接到这个队列将其取走，Exchange会将消息分发到指定的Queue，然后Queue和消费者进行交互
6. **Routes-路由**：交换机以什么样的策略将消息发布到Queue
7. **Binding-绑定：**用于消息队列和交换器之间的关联。一个绑定就是基于路由键将交换器和消息队列连接起来的路由规则，所以可以将交换器理解成一个由绑定构成的路由表。
8. **Connection-网络连接：**就是一个TCP的连接，Producer和Consumer都是通过TCP连接到RabbitMQ Server的
9. **Channel-信道：**多路复用连接中的一条独立的双向数据流通道。信道是建立在真实的TCP连接内地虚拟连接，AMQP 命令都是通过信道发出去的，不管是发布消息、订阅队列还是接收消息，这些动作都是通过信道完成。因为对于操作系统来说建立和销毁 TCP 都是非常昂贵的开销，所以引入了信道的概念，以复用一条 TCP 连接。Channel是我们与RabbitMQ打交道的最重要的一个接口，我们大部分的业务操作是在Channel这个接口中完成的，包括定义Queue、定义Exchange、绑定Queue与Exchange、发布消息等
10. **Virtual Host-虚拟主机：**表示一批交换器、消息队列和相关对象。虚拟主机是共享相同的身份认证和加密环境的独立服务器域。每个 vhost 本质上就是一个 mini 版的 RabbitMQ 服务器，拥有自己的队列、交换器、绑定和权限机制。vhost 是 AMQP 概念的基础，必须在连接时指定，RabbitMQ 默认的 vhost 是 / 
11. **Broker：**表示消息队列服务器实体

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043751-image-20201213184239950.png)

![官方简单架构图](http://qiniu.zhouhongyin.top/2022/06/12/1655043753-hello-world-example-routing.webp)



![完整架构图](http://qiniu.zhouhongyin.top/2022/06/12/1655043756-rabbitMQ%E6%9E%B6%E6%9E%84%E5%9B%BE-bc7cd3b72ba8449295757dbaaa17a1fa.jpg)

## 四、RabbitMQ的安装（Docker）

### 使用docker-compose安装

```yml
version: "3.1"
services:
  rabbitmq:
    image: daocloud.io/library/rabbitmq:management
    restart: always
    container_name: rabbitmq
    ports:
      - 5672:5672
      - 15672:15672
    volumes:
      - ./data:/var/lib/rabbitmq
```

> 执行命令`docker-compose up -d`

### 五、图形化界面的使用

### 5.1 登录图形化界面

> 登录地址：ip:15672
>
> 账号：guest
>
> 账密码：guest

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043759-image-20201214095643102.png)

### 5.2 创建一个用户

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043761-image-20201214100538920.png)

### 5.3 创建一个virtual host

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043764-image-20201214100124286.png)

### 5.4 给新创建的用户添加一个virtual host

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043766-image-20201214100704719.png)

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043769-image-20201214100745498.png)