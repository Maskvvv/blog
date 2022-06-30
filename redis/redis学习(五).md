---
title: Redis学习(五)-集群
date: 2020-10-20
tags:
  - Redis
  - Redis学习(五)-集群
categories:
  - Redis
  - Redis学习(五)-集群
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702190-download.png)

<!-- more -->

## 一、Redis的主从架构

> 单机版Redis存在读写瓶颈的问题

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702193-image-20201023083505333.png)

### 1.1 配置3台Redis

#### 1.1.1 docker-compose文件配置

```yml
version: '3.1'
services:
  redis1:
    image: daocloud.io/library/redis:5.0.7
    restart: always
    container_name: redis1
    environment:
      - TZ=Asia/Shanghai
    ports:
      - 7001:6379
    volumes:
      - ./conf/redis1.conf:/usr/local/redis/redis.conf
    command: ["redis-server","/usr/local/redis/redis.conf"]
    
  redis2:
    image: daocloud.io/library/redis:5.0.7
    restart: always
    container_name: redis2
    environment:
      - TZ=Asia/Shanghai
    ports:
      - 7002:6379
    volumes:
      - ./conf/redis2.conf:/usr/local/redis/redis.conf
    links:
      - redis1:master
    command: ["redis-server","/usr/local/redis/redis.conf"]
    
  redis3:
    image: daocloud.io/library/redis:5.0.7
    restart: always
    container_name: redis3
    environment:
      - TZ=Asia/Shanghai
    ports:
      - 7003:6379
    volumes:
      - ./conf/redis3.conf:/usr/local/redis/redis.conf
    links:
      - redis1:master
    command: ["redis-server","/usr/local/redis/redis.conf"]

```

#### 1.1.2 编写从节点配置文件

```
# replicaof <masterip> <masterport>
  replicaof master 6379
```

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702198-image-20201023090212028.png)

**docker搭建集群式遇到无法关联docker配置文件的问题，待续**