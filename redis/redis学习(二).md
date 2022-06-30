---
title: Redis学习(二)-数据类型和基本操作
date: 2020-10-07
tags:
  - Redis
  - Redis学习(二)-数据类型和基本操作
categories:
  - Redis
  - Redis学习(二)-数据类型和基本操作
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701948-download.png)

<!-- more -->

## 一、Redis数据类型

### 1.1 简介

> **常用的5种数据结构**
>
> - key-string：一个key对应一个值
> - key-hash：一个key对应一个Map。
> - key-list：一个key对应一个列表。
> - key-set：一个key对应一个集合。
> - key-zset：一个key对应一个有序的集合。
>
> **另外三种数据结构**
>
> HyperLogLog：计算近似值的。
>
> GEO：地理位置。
>
> BIT：一般存储的也是一个字符串,存储的是一个byte[ ]

### 1.2 五种常用的存储数据结构图

|                   五种常用的存储数据结构图                   |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701950-image-20201006183704028.png) |

> - **key-string：最常用的，一般用于存储一个值。**
> - **key-hash：存储一个对象数据的。**
> - **key-list：使用st结构实现栈和队列结构**
> - **key-set：交集，差集和并集的操作。**
> - **key-zset：排行榜，积分存储等操作。**

## 二、Redis数据类型常用命令

### 2.1 字符串(String)命令

> **Redis 字符串数据类型的相关命令用于管理 redis 字符串值**

| 序号 |          命令           |                             描述                             |
| :--: | :---------------------: | :----------------------------------------------------------: |
|  1   |      SET key value      |                      设置指定 key 的值                       |
|  2   |        GETt key         |                      获取指定 key 的值                       |
|  3   |   MSET key1 [key2...]   |              设置所有(一个或多个)给定 key 的值               |
|  4   |   MGET key1 [key2...]   |              获取所有(一个或多个)给定 key 的值               |
|  5   |        INCR key         |                   将 key 中储存的数字值增1                   |
|  6   |        DECR key         |                   将 key 中储存的数字值减1                   |
|  8   |  INCRBY key increment   |        将 key 所储存的值加上给定的增量值（increment）        |
|  9   |  DECRBY key decrement   |        将key 所储存的值减去给定的减量值（decrement）         |
|  10  | SETEX key seconds value | 设置值的同时，指定生存时间，并将 key 的过期时间设为 seconds (以秒为单位)（每次向 Redis中添加数据时，尽量都设置上生存时间） |
|  11  |     SETNX key value     | 设置值，如果当前key不存在的话（如果这个key存在，什么事都不做，如果这个key不存在，和set命令一样） |
|  12  |    APPEND key value     | 如果 key 已经存在并且是一个字符串， APPEND 命令将 value 追加到 key 原来的值的末尾。 |
|  13  |       STRLEN key        |               返回 key 所储存的字符串值的长度                |

### 2.2 哈希(Hash)命令

> **Redis hash 是一个string类型的field和value的映射表，hash特别适合用于`存储对象`。**

| 序号 |                    命令                     |                        描述                         |
| :--: | :-----------------------------------------: | :-------------------------------------------------: |
|  1   |            HSET key field value             |     将哈希表 key 中的字段 field 的值设为 value      |
|  2   |               HGET key field                |           获取存储在哈希表中指定字段的值            |
|  3   | HMSET key field1 value1 [field2 value2... ] | 同时将多个 field-value (域-值)对设置到哈希表 key 中 |
|  4   |        HMGET key field1 [field2...]         |                获取所有给定字段的值                 |
|  5   |         HINCRBY key field increment         | 为哈希表 key 中的指定字段的整数值加上增量 increment |
|  6   |           HSETNX key field value            |    只有在字段 field 不存在时，设置哈希表字段的值    |
|  7   |              HEXISTS key field              |        查看哈希表 key 中，指定的字段是否存在        |
|  8   |         HDEL key field1 [field2...]         |              删除一个或多个哈希表字段               |
|  9   |                 HGETALL key                 |        获取在哈希表中指定 key 的所有字段和值        |
|  10  |                  HVALS key                  |             获取哈希表中指定 key所有值              |
|  11  |                  HKEYS key                  |           获取哈希表中指定 key的所有字段            |
|  12  |                  HLEN key                   |          获取哈希表中指定 key的字段的数量           |

### 2.3 列表(List)命令

> Redis列表是简单的`字符串列表`，按照插入`顺序排序`。你可以添加一个元素导列表的头部（左边）或者尾部（右边）
>
> 一个列表最多可以包含 232 - 1 个元素 (4294967295, 每个列表超过40亿个元素)。

| 序号 |             命令             |                             描述                             |
| :--: | :--------------------------: | :----------------------------------------------------------: |
|  1   |  LPUSH key value1 [value2]   |                 将一个或多个值插入到列表头部                 |
|  2   |  RPUSH key value1 [value2]   |                 将一个或多个值插入到列表尾部                 |
|  3   |  LPUSHX key value1 [value2]  | 将一个或多个值插入到列表头（如果key不存在，什么事都不做，如果key存在，但是不是list结构，什么都不做） |
|  4   |  RPUSHX key value1 [value2]  | 将一个或多个值插入到列表尾（如果key不存在，什么事都不做，如果key存在，但是不是list结构，什么都不做） |
|  5   |     LSET key index value     |               通过索引设置列表中已存在元素的值               |
|  6   |           LPOP key           |                  移出并获取列表的第一个元素                  |
|  7   |           RPOP key           |                  移除并获取列表最后一个元素                  |
|  8   |    LRANGE key start stop     |                   获取列表指定范围内的元素                   |
|  9   |       LINDEX key index       |                   通过索引获取列表中的元素                   |
|  10  |           LLEN key           |                         获取列表长度                         |
|  11  |     LREM key count value     | 删除列表中指定的数据（他是删除当前列表中的 count个 value值, count>0从左侧向右侧删除, count<0从右侧向左侧删除count==0删除列表中全部的 value） |
|  12  |     LTRIM key start stop     | 对一个列表进行修剪(trim)，就是说，让列表只保留指定区间内的元素，不在指定区间之内的元素都将被删除。 |
|  13  | RPOPLPUSH source destination |   移除列表的最后一个元素，并将该元素添加到另一个列表并返回   |

### 2.4 集合(Set)命令

> Redis的Set是string类型的`无序集合`。集合成员是`唯一的`，这就意味着集合中不能出现重复的数据。
>
> Redis 中 集合是通过哈希表实现的，所以添加，删除，查找的复杂度都是O(1)。
>
> 集合中最大的成员数为 232 - 1 (4294967295, 每个集合可存储40多亿个成员)。

| 序号  |               命令                |                   介绍                    |
| :---: | :-------------------------------: | :---------------------------------------: |
| **1** | **SADD key member1 [member2...]** |       **向集合添加一个或多个成员**        |
| **2** |         **SMEMBERS key**          |         **返回集合中的所有成员**          |
| **3** |           **SPOP key**            |    **移除并返回集合中的一个随机元素**     |
| **4** |     **SINTER key1 [key2...]**     |        **返回给定所有集合的交集**         |
| **5** |     **SUNION key1 [key2...]**     |        **返回所有给定集合的并集**         |
| **6** |     **SDIFF key1 [key2...]**      |        **返回给定所有集合的差集**         |
| **7** | **SREM key member1 [member2...]** |       **移除集合中一个或多个成员**        |
| **8** |     **SISMEMBER key member**      | **判断 member 元素是否是集合 key 的成员** |

### 2.5 有序集合(sorted set)命令

> Redis 有序集合和集合一样也是string类型元素的集合,且`不允许重复的成员`。
>
> 不同的是`每个元素都会关联一个double类型的分数`。redis正是通过分数来为集合中的成员进行从小到大的排序。
>
> 有序集合的成员是`唯一的`,但分数(score)却`可以重复`。

| 序号 |                             命令                             |                             介绍                             |
| :--: | :----------------------------------------------------------: | :----------------------------------------------------------: |
|  1   |         ZADD key score1 member1 [score2 member2...]          |    向有序集合添加一个或多个成员，或者更新已存在成员的分数    |
|  2   |                 ZINCRBY key increment member                 | 有序集合中对指定成员的分数加上增量 increment（如果 member是存在于key中的，正常增加分数，如果 memeber不存在,这个命令就相当于zadd） |
|  3   |                          ZCARD key                           |                     获取有序集合的成员数                     |
|  4   |                      ZCOUNT key min max                      |             计算在有序集合中指定区间分数的成员数             |
|  5   |               ZREM key member 1 [member2 ...]                |                移除有序集合中的一个或多个成员                |
|  6   |                      ZSCORE key member                       |                  返回有序集中，成员的分数值                  |
|  7   |              ZRANGE key start stop [WITHSCORES]              | 根据分数从小到大排序，获取指定索引范围内的数据（ withscores如果添加这个参数，那么会返回 member对应的分数） |
|  8   |            ZREVRANGE key start stop [WITHSCORES]             | 根据分数从大到小排序，获取指定索引范围内的数据（ withscores如果添加这个参数，那么会返回 member对应的分数） |
|  9   |  ZRANGEBYSCORE key min max [WITHSCORES\] [LIMIT start stop]  | 通过指定分数范围返回有序集合内的成员（ limit 限制索引，min和max为+inf -inf输出全部） |
|  10  | ZREVRANGEBYSCORE key max min [WITHSCORES\] [LIMIT start stop] |      返回有序集中指定分数区间内的成员，分数从高到低排序      |

### 2.6 键(key)命令

> **Redis 键命令用于管理 redis 的键。**

| 序号 |                 命令                 |                             介绍                             |
| :--: | :----------------------------------: | :----------------------------------------------------------: |
|  1   |             KEYS pattern             | 查找所有符合给定模式( pattern (* \| 或以xxx为开头) )的 key 。 |
|  2   |              EXISTS key              |                    检查给定 key 是否存在                     |
|  3   |          DEL key1 [key2..]           |               该命令用于在 key 存在是删除 key                |
|  4   |       PEXPIRE key milliseconds       |                设置 key 的过期时间亿以毫秒计                 |
|  5   |          EXPIRE key seconds          |                   为给定 key 设置过期时间                    |
|  6   |        EXPIREAT key timestamp        | EXPIREAT 的作用和 EXPIRE 类似，都用于为 key 设置过期时间。 不同在于 EXPIREAT 命令接受的时间参数是 UNIX 时间戳(unix timestamp) |
|  7   | PEXPIREAT key milliseconds-timestamp |      设置 key 过期时间的时间戳(unix timestamp) 以毫秒计      |
|  8   |               TTL key                | 以秒为单位，返回给定 key 的剩余生存时间(TTL, time to live，-1标识未指定生存时间，-2标识不存在这个key) |
|  9   |               PTTL key               |            以毫秒为单位返回 key 的剩余的过期时间             |
|  10  |             PERSIST key              |             移除 key 的过期时间，key 将持久保持              |
|  11  |             MOVE key db              |        将当前数据库的 key 移动到给定的数据库 db 当中         |
|  12  |             SELECT 0~15              |                         选择操作的库                         |

### 2.7 库的命令

| 序号 |    命令     |                             介绍                             |
| :--: | :---------: | :----------------------------------------------------------: |
|  1   | SELECT 0~15 |                         选择操作的库                         |
|  2   |   FLUSHDB   |                   删除当前数据库的所有key                    |
|  3   |  FLUSHALL   |                   删除所有数据库的所有key                    |
|  4   |   DBSIZE    |                 返回当前数据库的 key 的数量                  |
|  5   |  LASTSAVE   | 返回最近一次 Redis 成功将数据保存到磁盘上的时间，以 UNIX 时间戳格式表示 |
|  6   |   MONITOR   |         实时打印出 Redis 服务器接收到的命令，调试用          |



