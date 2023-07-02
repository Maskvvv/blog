---
title: Elasticsearch学习(一)-引言和安装
date: 2020-10-26
tags:
  - Elasticsearch
  - Elasticsearch学习(一)-引言和安装
categories:
  - Elasticsearch
  - Elasticsearch学习(一)-引言和安装
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654699854-elasticsearch-logo.png)

<!-- more -->

## 一、ES引言

### 1.1 ES简介

Elaticsearch，简称为es， es是一个开源的**高扩展的分布式全文检索引擎**，它可以近乎实时的**存储**、**检索**数据；本身扩展性很好，可以扩展到上百台服务器，处理PB级别（大数据时代）的数据。es也使用Java开发并使用Lucene作为其核心来实现所有索引和搜索的功能，但是它的目的是通过简单的RESTful API来隐藏Lucene的复杂性，从而让全文搜索变得简单。

 据国际权威的数据库产品评测机构DB Engines的统计，在2016年1月，ElasticSearch已超过Solr等，成为排名第一的搜索引擎类应用。

### 1.2 ES的特点

> - ES是使用java 语言并且基于**lucence编写**的搜索引擎框架，他提供了分布式的全文搜索功能，提供了一个统一的基于**restful风格的web 接口**。
> - lucence：一个搜索引擎底层
> - 分布式：突出ES的**横向扩展能力**
> - 全文检索：将一段词语进行**分词**，并将分出的词语统一的放在一个分词库中，再搜索时，根据关键字取分词库中检索，找到匹配的内容（倒排索引）。
> - restful风格的web 接口：只要发送一个http请求，并且根据请求方式的不同，携带参数的不同，执行相应的功能。
> - 应用广泛：WIKI, github,Gold man

### 1.3 ES和solr

> - solr 查询**死数据**，速度比es快。但是数据如果是改变的，solr查询速度会降低很多，ES的查询速度没有明显的改变
> - solr搭建集群 依赖ZK，ES本**身就支持集群搭建**
> - 最开始solr 的社区很火爆，针对国内文档 少，ES出现后，国内社区火爆程度 上升，，ES的文档非常健全
> - ES对云计算和大数据支持很好

### 1.4 使用场景

> - 维基百科，类似百度百科，全文检索，高亮，搜索推荐/2 （权重，百度！）
> - The Guardian（**国外新闻网站**），类似搜狐新闻，用户行为日志（点击，浏览，收藏，评论）+社交网络数据（对某某新闻的相关看法），数据分析，给到每篇新闻文章的作者，让他知道他的文章的公众 反馈（好，坏，热门，垃圾，鄙视，崇拜）
> - Stack Overﬂow（国外的程序异常讨论论坛），IT问题，程序的报错，提交上去，有人会跟你讨论和回答，全文检索，搜索相关问题和答案，程序报错了，就会将报错信息粘贴到里面去，搜索有没有对应的答案
> - GitHub（开源代码管理），搜索上千亿行代码
> - 电商网站，检索商品
> - 日志数据分析，logstash采集日志，ES进行复杂的数据分析，ELK技术， elasticsearch+logstash+kibana
> - 商品价格监控网站，用户设定某商品的价格阈值，当低于该阈值的时候，发送通知消息给用户，比如 说订阅牙膏的监控，如果高露洁牙膏的家庭套装低于50块钱，就通知我，我就去买。
> - BI系统，商业智能，Business Intelligence。比如说有个大型商场集团，BI，分析一下某某区域最近3年的用户消费金额的趋势以及用户群体的组成构成，产出相关的数张报表，**区，最近3年，每年消费 金额呈现100%的增长，而且用户群体85%是高级白领，开一个新商场。ES执行数据分析和挖掘， Kibana进行数据可视化
> - 国内：站内搜索（电商，招聘，门户，等等），IT系统搜索（OA，CRM，ERP，等等），数据分析（ES热门的一个使用场景）
>

### 1.5 倒排索引

> 该索引表中的每一项都包括一个属性值和具有该属性值的各记录的地址。由于不是由记录来确定属性值，而是由属性值来确定记录的位置，因而称为倒排索引(inverted index)。Elasticsearch能够实现快速、高效的搜索功能，正是基于倒排索引原理。
>
> 1. 将存放的数据以一定的方式进行分词，并将分词的内容存放到一个单独的分词库中。
> 2. 当用户取查询数据时，会将用户的查询关键字进行分词，然后去分词库中匹配内容，最终得到数据的id标识
>
> 3. 根据id标识去存放数据的位置拉去指定数据

![](http://qiniu.zhouhongyin.top/2022/06/08/1654699886-image-20201031084724933.png)

## 二、ES的数据结构

### 2.1 ES与关系型数据库对比

| **Relational DB** | **Elasticsearch** |
| :---------------- | :---------------- |
| 数据库(database)  | 索引 Index        |
| 表(tables)        | 类型 Types        |
| 行(rows)          | 文档 Documents    |
| 字段(columns)     | Fields            |

### 2.2 索引(Index)，节点和集群，分片和备份

Elasticsearch 数据管理的顶层单位就叫做 Index（索引），相当于关系型数据库里的数据库的概念。另外，每个Index的名字必须是小写。

ESElasticsearch 本质上是一个分布式数据库，允许多台服务器协同工作，每台服务器可以运行多个Elasticsearch实例。单个Elasticsearch实例称为一个节点（Node），一组节点构成一个集群（Cluster）。

服务中会创建多个索引，每个索引默认被分成5个分片，每个分片存在至少一个备份分片，备份分片 不会帮助检索数据（当ES检索压力特别大的时候才，备份分片才会帮助检索数据），备份的分片必须放在不同的服务器中

![](http://qiniu.zhouhongyin.top/2022/06/08/1654699938-image-20201031090915373.png)

### 2.3 类型(Type)

Document 可以分组，比如employee这个 Index 里面，可以按部门分组，也可以按职级分组。这种分组就叫做 Type，它是虚拟的逻辑分组，用来过滤 Document，类似关系型数据库中的数据表。
  不同的 Type 应该有相似的结构（Schema），性质完全不同的数据（比如 products 和 logs）应该存成两个 Index，而不是一个 Index 里面的两个 Type（虽然可以做到）。

> ps：ES6.X中一个index下只可以创建一个Type，ES7.X中一个index下没有Type

### 2.4 文档(Document)

之前说elasticsearch是面向文档的，那么就意味着索引和搜索数据的最小单位是文档，elasticsearch中，文档有几个重要属性 :

- 自我包含，一篇文档同时包含字段和对应的值，也就是同时包含 key:value！
- 可以是层次型的，一个文档中包含自文档，复杂的逻辑实体就是这么来的！ {就是一个json对象！ fastjson进行自动转换！}
- 灵活的结构，文档不依赖预先定义的模式，我们知道关系型数据库中，要提前定义字段才能使用，在elasticsearch中，对于字段是非常灵活的，有时候，我们可以忽略该字段，或者动态的添加一个 新的字段。

尽管我们可以随意的新增或者忽略某个字段，但是，每个字段的类型非常重要，比如一个年龄字段类型，可以是字符 串也可以是整形。因为elasticsearch会保存字段和类型之间的映射及其他的设置。这种映射具体到每个映射的每种类型，这也是为什么在elasticsearch中，类型有时候也称为映射类型。

### 2.5 字段（Fields）

每个Document都类似一个JSON结构，它包含了许多字段，每个字段都有其对应的值，多个字段组成了一个 Document，可以类比关系型数据库数据表中的字段。
  在 Elasticsearch 中，文档（Document）归属于一种类型（Type），而这些类型存在于索引（Index）中。

## 三、ES的安装

### 3.1 通过docker-compose安装elasticsearch和kibana

#### 编写docker-compose.yml文件

```yml
version: "3.1"
services:
  elasticsearch:
    image: daocloud.io/library/elasticsearch:6.5.4 
    restart: always
    container_name: elasticsearch
    ports:
      - 9200:9200
    environment:
      - "ES_JAVA_OPTS=-Xms64m -Xmx128m"
      - "discovery.type=single-node"
      - "COMPOSE_PROJECT_NAME=elasticsearch-server"
  kibana:
    image: daocloud.io/library/kibana:6.5.4 
    restart: always
    container_name: kibana
    ports:
      - 5601:5601
    environment:
      - ELASTICSEARCH_HOSTS=http://192.168.199.138:9200
    depends_on:
      - elasticsearch
```

> 注：ES创建时需要分配内存，否则会创建失败

### 3.2 kibana ES可视化界面的基本使用

![](http://qiniu.zhouhongyin.top/2022/06/08/1654699960-image-20201031101026461.png)

### 3.3 IK分词器的安装

> 进入ES容器，并在ES容器的bin路径下执行`./elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.5.4/elasticsearch-analysis-ik-6.5.4.zip`

![](http://qiniu.zhouhongyin.top/2022/06/08/1654699990-image-20201026092614811.png)

#### 测试

```json
POST _analyze
{
  "analyzer":"ik_max_word",
  "text":"百度搜索"
}
```