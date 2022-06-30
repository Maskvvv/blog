---
title: Redis学习(四)-其他配置及持久化
date: 2020-10-19
tags:
  - Redis
  - Redis学习(四)-其他配置及持久化
categories:
  - Redis
  - Redis学习(四)-其他配置及持久化
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702135-download.png)

<!-- more -->

## 一、Redis配置文件

> 修改`dockers-compose.yml`文件，以便后期修改`Redis配置`文件

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
    volumes:
      - ./conf/redis.conf:/usr/local/redis/redis.conf
    command: ["redis-server","/usr/local/redis/redis.conf"]
```

## 二、Redis的AUTH（设置连接密码）

### 方式一：通过修改redis.conf的配置文件，实现密码校验

> 修改**redis.conf**文件：`requirepass 密码`

#### 设置密码后连接redis

> 三种客户端的连接方式
>
> 1. redis-cli：在输入正常命令之前，先输入 `auth 密码`即可。
> 2. 图像化界面：修改面接信息，添加密码即可。
> 3. jedis连接：
>    - jedis.auth(password);
>    - new JedisPool(password);

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702139-GMF%7BLPJV2E-U6R5L-ZRQHNR.png)

### 方式二：

> 在不修改redis.conf文件的前提下，在第一次连接Reids时，输入命令`Config set requirepass 密码`

## 三、Redis的事务

> Redis事务特点：一次事务操作，该成功的成功，该失败的失败。
>
> Redis 事务可以一次执行多个命令， 并且带有以下两个重要的保证：
>
> - 事务是一个单独的隔离操作：事务中的所有命令都会序列化、按顺序地执行。事务在执行的过程中，不会被其他客户端发送来的命令请求所打断。
> - 事务是一个原子操作：事务中的命令要么全部被执行，要么全部都不执行。
>
> 一个事务从开始到执行会经历以下三个阶段：
>
> 1. 开始事务：`mulit`
> 2. 命令入队
> 3. 执行事务 | 取消事务：`exec` | `discard`

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702144-1.png)

> 在开启事务之前,先通过 watch命令去监听一个或多个key,在开启事务之后,如果有其他客户端修改了我监
> 听的key,事务会自动取消
>
> 如果执行了事务,或者取消了事务, watch监听自动消除,一般不需要手动执行 unwatch。

## 四、Reids的持久化机制

### 4.1 RDB持久化方式

> RDB时Rdis默认的持久化机制
>
> 1. RDB持久话文件速度比较快，而且存储的是一个二进制的文件,传输起来很方便。
>
> 2. RDB持久话的时机：
>
>    `save 多杀秒内 多少个key改变`：save 900 1
>
> 3. RDB无法保证数据的绝对安全

#### 修改redis.conf配置文件

```json
# RDB持久化机制的配置
# 900秒内，有一个key改变了，就执行RDB持久化存储
save 900 1
save 300 10
save 60 10000

# 开启RDB持久化的压缩
rdbcompression yes
# RDB持久化文件的名称
dbfilename redis.rdb
```

#### 修改docker-compose.yml配置文件，添加文件映射

```yml
volumes:
  - ./data:/data
```

### 4.2 AOF持久化方式

> AOF持久化机制默认是关闭的,Redi官方推荐同时开启RDB和AOF持久化,更安全,避免数据丢失
>
> - AOF持久化的速度,相对RDB较慢的,存储的是一个文本文件,到了后期文件会比较大,传输困难
>
> - AOF持久化时机
>
>   appendfsync always：每执行一个写操作,立即持久化到AQF文件中,性能比较低
>   appendfsync everysec：每秒执行一次持久化。（推荐）
>   appendfsync no：会根据你的操作系统不同,环境的不同,在一定时间内执行一次持久化。
>
> - AOF相对RDB更安全,推荐同时开启AOF和RDB。

#### 修改redis.conf 配置文件

```json
#开启AOF持久化
appendonly yes
#AOF文件的名称
appendfilename "redis.aof"

#AOF文件持久话的时机
#appendfsync always
appendfsync everysec
#appendfsync no
```

> 如果同时开启了AOE和RDB持久化,那么在 Redis宕机重启之后,需要加载一个持久化文件,优先选择AOF文
> 如果先开启了RDB,再次开启AOF。
>
> 如果RDB执行了持久化,那么RD文件中的内容会被AOF覆盖掉