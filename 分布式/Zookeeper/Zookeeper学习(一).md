---
title: Zookeeper学习(一)-Zookeeper简介
date: 2021-2-4
tags:
  - 微服务
  - Zookeeper学习(一)-Zookeeper简介
  - springcloud
  - spring
  - springboot
categories:
  - 微服务
  - Zookeeper学习(一)-Zookeeper简介
---

![](Zookeeper%E5%AD%A6%E4%B9%A0(%E4%B8%80)/Apache_ZooKeeper.png)

<!--more-->

## 一、引言

　　Hadoop 集群当中 N 多的配置信息如何做到全局一致并且单点修改迅速响应到整个集群？ --- 配置管理

　　Hadoop 集群中的 namonode 和 resourcemanager 的单点故障怎么解决？ --- 集群的主节点的单点故障

## 二、分布式协调技术

　　在给大家介绍ZooKeeper之前先来给大家介绍一种技术——分布式协调技术。那么什么是分布式协调技术？那么我来告诉大家，其实分布式协调技术 主要用来解决分布式环境当中多个进程之间的同步控制，让他们有序的去访问某种临界资源，防止造成"脏数据"的后果。这时，有人可能会说这个简单，写一个调 度算法就轻松解决了。说这句话的人，可能对分布式系统不是很了解，所以才会出现这种误解。如果这些进程全部是跑在一台机上的话，相对来说确实就好办了，问 题就在于他是在一个分布式的环境下，这时问题又来了，那什么是分布式呢？这个一两句话我也说不清楚，但我给大家画了一张图希望能帮助大家理解这方面的内 容，如果觉得不对尽可拍砖，来咱们看一下这张图，如图1.1所示。

![](Zookeeper%E5%AD%A6%E4%B9%A0(%E4%B8%80)/1228818-20180321183326491-1621444258.png)

　　给大家分析一下这张图，在这图中有三台机器，每台机器各跑一个应用程序。然后我们将这三台机器通过网络将其连接起来，构成一个系统来为用户提供服务，对用户来说这个系统的架构是透明的，他感觉不到我这个系统是一个什么样的架构。那么我们就可以把这种系统称作一个**分布式系统**。

　　那我们接下来再分析一下，在这个分布式系统中如何对进程进行调度，我假设在第一台机器上挂载了一个资源，然后这三个物理分布的进程都要竞争这个资源，但我们又不希望他们同时进行访问，这时候我们就需要一个**协调器**，来让他们有序的来访问这个资源。这个协调器就是我们经常提到的那个**锁**，比如说"进程-1"在使用该资源的时候，会先去获得锁，"进程1"获得锁以后会对该资源保持**独占**，这样其他进程就无法访问该资源，"进程1"用完该资源以后就将锁释放掉，让其他进程来获得锁，那么通过这个锁机制，我们就能保证了分布式系统中多个进程能够有序的访问该临界资源。那么我们把这个分布式环境下的这个锁叫作**分布式锁**。这个分布式锁也就是我们**分布式协调技术**实现的核心内容，那么如何实现这个分布式呢，那就是我们后面要讲的内容。

## 三、分布式锁的实现

### 3.1 面临的问题

　　在看了图1.1所示的分布式环境之后，有人可能会感觉这不是很难。无非是将原来在同一台机器上对进程调度的原语，通过网络实现在分布式环境中。是的，表面上是可以这么说。但是问题就在网络这，在分布式系统中，所有在同一台机器上的假设都不存在：因为网络是不可靠的。

　　比如，在同一台机器上，你对一个服务的调用如果成功，那就是成功，如果调用失败，比如抛出异常那就是调用失败。但是在分布式环境中，由于网络的不可靠，你对一个服务的调用失败了并不表示一定是失败的，可能是执行成功了，但是响应返回的时候失败了。还有，A和B都去调用C服务，在时间上 A还先调用一些，B后调用，那么最后的结果是不是一定A的请求就先于B到达呢？ 这些在同一台机器上的种种假设，我们都要重新思考，我们还要思考这些问题给我们的设计和编码带来了哪些影响。还有，在分布式环境中为了提升可靠性，我们往往会部署多套服务，但是如何在多套服务中达到一致性，这在同一台机器上多个进程之间的同步相对来说比较容易办到，但在分布式环境中确实一个大难题。

　　所以分布式协调远比在同一台机器上对多个进程的调度要难得多，而且如果为每一个分布式应用都开发一个独立的协调程序。一方面，协调程序的反复编写浪费，且难以形成通用、伸缩性好的协调器。另一方面，协调程序开销比较大，会影响系统原有的性能。所以，急需一种高可靠、高可用的通用协调机制来用以协调分布式应用。

### 3.2 分布式锁的实现者

　　目前，在分布式协调技术方面做得比较好的就是Google的Chubby还有Apache的ZooKeeper他们都是分布式锁的实现者。有人会问既然有了Chubby为什么还要弄一个ZooKeeper，难道Chubby做得不够好吗？不是这样的，主要是Chbby是非开源的，Google自家用。后来雅虎模仿Chubby开发出了ZooKeeper，也实现了类似的分布式锁的功能，并且将ZooKeeper作为一种开源的程序捐献给了Apache，那么这样就可以使用ZooKeeper所提供锁服务。而且在分布式领域久经考验，它的可靠性，可用性都是经过理论和实践的验证的。所以我们在构建一些分布式系统的时候，就可以以这类系统为起点来构建我们的系统，这将节省不少成本，而且bug也 将更少。

![](Zookeeper%E5%AD%A6%E4%B9%A0(%E4%B8%80)/1228818-20180321183640661-941556187.png)

![](Zookeeper%E5%AD%A6%E4%B9%A0(%E4%B8%80)/1228818-20180321183649854-1229808958.png)

## 四、ZooKeeper概述

　　ZooKeeper 是一个分布式的，开放源码的分布式应用程序协调服务，是 Google 的 Chubby 一个开源的实现。它提供了简单原始的功能，分布式应用可以基于它实现更高级的服务，比 如**分布式同步，配置管理，集群管理，命名管理，队列管理**。它被设计为易于编程，使用文 件系统目录树作为数据模型。服务端跑在 java 上，提供 java 和 C 的客户端 API 众所周知，协调服务非常容易出错，但是却很难恢复正常，例如，协调服务很容易处于 竞态以至于出现死锁。我们设计 ZooKeeper 的目的是为了减轻分布式应用程序所承担的协 调任务 ZooKeeper 是集群的管理者，监视着集群中各节点的状态，根据节点提交的反馈进行下 一步合理的操作。最终，将简单易用的接口和功能稳定，性能高效的系统提供给用户。

　　前面提到了那么多的服务，比如分布式锁、配置维护、组服务等，那它们是如何实现的呢，我相信这才是大家关心的东西。ZooKeeper在实现这些服务时，首先它设计一种新的**数据结构——Znode**，然后在该数据结构的基础上定义了一些**原语**，也就是一些关于该数据结构的一些操作。有了这些数据结构和原语还不够，因为我们的ZooKeeper是工作在一个分布式的环境下，我们的服务是通过消息以网络的形式发送给我们的分布式应用程序，所以还需要一个**通知机制**——Watcher机制。那么总结一下，ZooKeeper所提供的服务主要是通过：数据结构+原语+watcher机制，三个部分来实现的。

> **[原文地址](https://www.cnblogs.com/qingyunzong/p/8618965.html)**

## 五、Zookeeper 的安装

通过 docker-compose 安装 Zookeeper.

```yml
version: "3.1"
services:
  zk:
    image: daocloud.io/daocloud/zookeeper:latest
    restart: always
    container_name: zookeeper
    ports:
      - 2181:2181
```

#### 验证是否安装成功

![](Zookeeper%E5%AD%A6%E4%B9%A0(%E4%B8%80)/image-20210204114555940.png)