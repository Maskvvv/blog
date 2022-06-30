---
title: Elasticsearch学习(二)-基本操作
date: 2020-10-27
tags:
  - Elasticsearch
  - Elasticsearch学习(二)-基本操作
categories:
  - Elasticsearch
  - Elasticsearch学习(二)-基本操作
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700128-elasticsearch-logo.png)

<!-- more -->

## 一、操作ES的restful语法

> GET请求：
>
> - http://ip:port/index：查询索引信息
> - http://ip:port/index/type/doc_id：查询指定的文档信息
>
> POST请求：
>
> - http://ip:port/index/type/_search：查询文档，可以在请求体中添加json字符串来代表查询条件
>
> - http://ip:port/index/type/doc_id/_update： 修改文档，在请求体中添加json字符串来代表修改的信息
>
> PUT请求：
>
> - http://ip:port/index：创建一个索引，需要在请求体中指定索引的信息
> - http://ip:port/index/type/_mappings：代表创建索引时，指定索引文档存储属性的信息
>
> DELETE 请求：
>
> - http://ip:port/index：删除跑路
> - http://ip:port/index/type/doc_id：删除指定的文档

## 二、索引（Index）操作

### 2.1 ES中Field的数据类型

[官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/6.5/mapping-types.html)

> - 字符串类型:
>
>   text: 一般用于全文检索，将当前field 进行分词
>
>   keyword:当前field  不会进行分词
>
> - 数值类型：
>     long:
>     Intger:
>     short:
>     byte:
>     double:
>     float:
>     half_float: 精度比float 小一半
>     scaled_float:根据一个long 和scaled 来表达一个浮点型 long-345, -scaled 100 ->3.45
>
> - 时间类型：
>     date类型,根据时间类型指定具体的格式
>
> - 布尔类型：
>     boolean 类型，表达true 和false
>
> - 二进制类型：
>     binary类型暂时支持Base64编码的字符串
>
> - 范围类型：
>     integer_range：
>     float_range：
>     long_range：赋值时，无需指定具体的内容，只需存储一个范围即可，gte,lte,gt,lt,
>     double_range：
>     date_range：
>     ip_range：
>
> - 经纬度类型：
>     geo_point:用来存储经纬度
>
> - IP类型：
>     ip:可以存储IPV4 和IPV6
>
> 其他的数据类型，参考官网

### 2.2 创建一个索引

```json
#创建一个索引
#number_of_shards  分片数
#number_of_replicas 备份数
PUT /person
{
  "settings": {
    "number_of_shards": 5, 
    "number_of_replicas": 1
  }
}
```

### 2.3 查看索引

```json
#查看索引信息
GET /person
```

### 2.4 删除索引

```json
#删除索引
DELETE /person
```

### 2.5 创建索引并指定数据结构

```json
#创建索引，指定数据类型
PUT /book
{
  "settings": {
    #分片数
    "number_of_shards": 5,
    #备份数
    "number_of_replicas": 1
  },
    #指定数据类型
 "mappings": {
    #类型 Type
   "novel":{
    #文档存储的field
     "properties":{
       #field属性名
       "name":{
         #类型
         "type":"text",
         #指定分词器
         "analyzer":"ik_max_word",
         #指定当前的field可以被作为查询的条件
         "index":true,
         #是否需要额外存储
         "store":false
       },
       "author":{
         "type":"keyword"
       },
       "count":{
         "type":"long"
       },
       "on-sale":{
         "type":"date",
           #指定时间类型的格式化方式
         "format": "yyyy-MM-dd HH:mm:ss||yyyy-MM-dd||epoch_millis"
       },
        "descr":{
          "type":"text",
          "analyzer":"ik_max_word"
       }
     }
   }
 }
}
```

## 三、文档（Document）操作

> 文档在ES服务中的唯一标识， _indx ,_type,_id  三个内容为组合，锁定一个文档，操作时添加还时修改操作。

### 3.1 新建文档

```json
# 添加文档，自动指定id
POST /book/novel
{
  "name": "三国演义",
  "author": "罗贯中",
  "count": "1000000",
  "on-sale": "1888-01-01",
  "descr": "《三国演义》描写了从东汉末年到西晋初年之间近百年的历史风云，以描写战争为主，诉说了东汉末年的群雄割据混战和魏、蜀、吴三国之间的政治和军事斗争，最终司马炎一统三国，建立晋朝的故事。反映了三国时代各类社会斗争与矛盾的转化，并概括了这一时代的历史巨变，塑造了一群叱咤风云的三国英雄人物。"
  
}

# 添加文档,手动指定id
PUT /book/novel/1
{
  "name": "西游记",
  "author": "吴承恩",
  "count": "1650000",
  "on-sale": "1888-01-01",
  "descr": "《西游记》描写了从东汉末年到西晋初年之间近百年的历史风云，以描写战争为主，诉说了东汉末年的群雄割据混战和魏、蜀、吴三国之间的政治和军事斗争，最终司马炎一统三国，建立晋朝的故事。反映了三国时代各类社会斗争与矛盾的转化，并概括了这一时代的历史巨变，塑造了一群叱咤风云的三国英雄人物。"
}
```

### 3.2 修改文档

#### 方式一：覆盖式修改

> 会覆盖指定id的文档，如果有的字段未赋值则会为空值。

```json
PUT /book/novel/1
{
  "name": "西游记",
  "author": "吴承恩",
  "count": "1000000",
  "on-sale": "1888-01-01",
  "descr": "《西游记》描写了从东汉末年到西晋初年之间近百年的历史风云，以描写战争为主，诉说了东汉末年的群雄割据混战和魏、蜀、吴三国之间的政治和军事斗争，最终司马炎一统三国，建立晋朝的故事。反映了三国时代各类社会斗争与矛盾的转化，并概括了这一时代的历史巨变，塑造了一群叱咤风云的三国英雄人物。"
}
```

#### 方式二：使用doc修改方式

> 可只修改指定Field对应的值，而不影响其他字段的值

```json
POST /book/novel/1/_update
{
  "doc": {
    "count": "123456"
  }
}
```

### 3.3 删除文档

```json
#需指定id
DELETE /book/novel/h3d2YnUBkqGJFDBxX1Cg
```