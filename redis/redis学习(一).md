---
title: Redis学习(一)-简介和安装
date: 2020-10-06
tags:
  - Redis
  - Redis学习(一)-简介和安装
categories:
  - Redis
  - Redis学习(一)-简介和安装
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701883-download.png)

<!-- more -->

## 一、Redis简介

### 1.1 引言

> 1. **由于用户量增大,请求数量也随之增大,数据压力过大。**
> 2. **多台服务器之间,数据不同步**
> 3. **多台服务器之间的锁,已经不存在互斥性了。**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701887-image-20201006171153149.png)

### 1.2 NoSQL简介

> **NoSQL最常见的解释是“non-relational”， “Not Only SQL”也被很多人接受。NoSQL仅仅是一个概念，泛指非关系型的数据库，区别于关系数据库，它们不保证关系数据的ACID特性。**
>
> **NoSQL有如下优点：易扩展，NoSQL数据库种类繁多，但是一个共同的特点都是去掉关系数据库的关系型特性。数据之间无关系，这样就非常容易扩展。无形之间也在架构的层面上带来了可扩展的能力。大数据量，高性能，NoSQL数据库都具有非常高的读写性能，尤其在大数据量下，同样表现优秀。这得益于它的无关系性，数据库的结构简单。**

#### 分类：

| **分类**              | **Examples举例**                                      | 典型应用场景                                                 | 数据模型                                        | 优点                                                         | 缺点                                                         |
| --------------------- | ----------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **键值（key-value）** | Tokyo Cabinet/Tyrant， Redis， Voldemort， Oracle BDB | 内容缓存，主要用于处理大量数据的高访问负载，也用于一些日志系统等等。 | Key 指向 Value 的键值对，通常用hash table来实现 | 查找速度快                                                   | 数据无结构化，通常只被当作字符串或者二进制数据               |
| **列存储数据库**      | Cassandra， HBase， Riak                              | 分布式的文件系统                                             | 以列簇式存储，将同一列数据存在一起              | 查找速度快，可扩展性强，更容易进行分布式扩展                 | 功能相对局限                                                 |
| **文档型数据库**      | ElasticSearch，Solr， MongoDb，                       | Web应用（与Key-Value类似，Value是结构化的，不同的是数据库能够了解Value的内容） | Key-Value对应的键值对，Value为结构化数据        | 数据结构要求不严格，表结构可变，不需要像关系型数据库一样需要预先定义表结构 | 查询性能不高，而且缺乏统一的查询语法。                       |
| **图形(Graph)数据库** | Neo4J， InfoGrid， Infinite Graph                     | 社交网络，推荐系统等。专注于构建关系图谱                     | 图结构                                          | 利用图结构相关算法。比如最短路径寻址，N度关系查找等          | 很多时候需要对整个图做计算才能得出需要的信息，而且这种结构不太好做分布式的集群方案。 |

### 1.3 Redies的特点

> **Redis 是完全开源免费的，遵守BSD协议，是一个高性能的key-value数据库。**
>
> **Redis 与其他 key - value 缓存产品有以下三个特点：**
>
> - **Redis支持数据的持久化，可以将内存中的数据保持在磁盘中，重启的时候可以再次加载进行使用。**
> - **Redis不仅仅支持简单的key-value类型的数据，同时还提供list，set，zset，hash等数据结构的存储。**
> - **Redis支持数据的备份，即master-slave模式的数据备份。**

### 1.4 Redies的优势

> - **性能极高 – Redis能读的速度是`110000次/s`,写的速度是`81000次/s` 。**
> - **丰富的数据类型 – Redis支持二进制案例的 Strings, Lists, Hashes, Sets 及 Ordered Sets 数据类型操作。**
> - **原子 – Redis的所有操作都是原子性的，同时Redis还支持对几个操作全并后的原子性执行。**
> - **丰富的特性 – Redis还支持 publish/subscribe, 通知, key 过期等等特性。**

## 二、Redis的安装

### 2.1 通过docker-compose安装Redis

```yml
version: '3.1'
services:
  redis:
    image: daocloud.io/library/redis:5.0.7
    restart: always
    container_name: redis
    environment:
      - TZ=Asia/Shanghai
    ports:
      - 6379:6379
```



### 2.2 使用redis-cli连接Redis

> 1. 进入 Redis容器的内部`docker exec -it容器 id bash`
> 2. 在容器内部,使用 `dredis-cli`命令连接

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701894-image-20201006182104056.png)

### 2.3 使用图形化界面连接 Redis

> **[图形化管理界面下载地址](https://github.com/lework/RedisDesktopManager-Windows/releases)**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701902-image-20201006182457064.png)