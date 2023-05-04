# 从开源到上市

- 当前市值超过50亿美金，开盘当天涨幅达94%
- 软件下载量，超3.5亿次
- 10万+的社区成员
- 7200+订阅用户，分布在100+国家
- 云服务-Elastic，Amazon，阿里巴巴，腾讯

# Elasticsearch 的客户

![](http://qiniu.zhouhongyin.top/2023/05/04/1683190978-image-20230504170258522.png)

# Elasticsearch 简介

## 数据库产品排名

![](http://qiniu.zhouhongyin.top/2023/05/04/1683191113-image-20230504170513713.png)

## 于 ES 相近的产品

- Elasticsearch -开源分布式搜索分析引警
  - 近实时 (Near Real Time)
  - 分布式存储/搜索/分析引擎
- Solr (Apache 开源项目)
- Splunk (商业上市公司)

## ES 的趋势

![](http://qiniu.zhouhongyin.top/2023/05/04/1683191154-image-20230504170553893.png)

## 起源 - Lucene

- 基于 Java 语言开发的搜索引擎库类
- 创建于1999 年，2005 年成为 Apache 顶级开源项目
- Lucene 具有高性能、易扩展的优点
- Lucene 的局限性
  - 只能基于 Java 语言开发
  - 类库的接口学习曲线陡峭
  - 原生并不支持水平扩展

# Elasticsearch 的诞生

![](http://qiniu.zhouhongyin.top/2023/05/04/1683191306-image-20230504170826067.png)

- 2004 年 Shay Banon 基于 Lucene 开发了 Compass
- 2010 年Shay Banon 重写了 Compass，取名 Elasticsearch
  - 支持分布式，可水平扩展
  - 提供 RestFull 的接口，降低全文检索的学习曲线，可以被任何编程语言调用

# Elasticsearch 的分布式架构

![](http://qiniu.zhouhongyin.top/2023/05/04/1683191357-image-20230504170917168.png)

- 集群规模可以从单个扩展至数百个节点
- 高可用&水平扩展
  - 服务和数据两个纬度
- 支持不同的节点类型
  - 支持 Hot &Warm 架构

# 支持多种方式集成接入

- 多种编程语言的类库 (https://www.elastic.co/guide/en/elasticsearch/client/index.html)
  - Java / .NET / Python / Ruby / PHP / Groovy / Perl
- RESTful API v.s Transport API
  - 9200 vs 9300 (建议使用RESTful API)
- JDBC & ODBC

# Elasticsearch 的主要功能

![](http://qiniu.zhouhongyin.top/2023/05/04/1683191499-image-20230504171139729.png)

- 海量数据的分户式存储以及集群管理
  - 服务与数据的高可用，水平扩展
- 近实时搜索，性能卓越
  - 结构化/全文/地理位置/自动完成
- 海量数据的近实时分析
  - 聚合功能

# 市场反应

![](http://qiniu.zhouhongyin.top/2023/05/04/1683191613-image-20230504171333883.png)

- 2010年第一次发布;2012年成立公司
- 成立6个月，160万下载，首轮募到 1000万美金风险投资
  - Rod Johnson
  - Benchmark Capital / Data Collective
- 不要求你必须是一位数据科学家才能把它用好

# Elasticsearch 版本与升级

- 0.4: 2010年2月第一次发布
- 1.0: 2014年1月
- 2.0: 2015年10月
- 5.0: 2016年10月
- 6.0: 2017年10月
- 7.0: 2019年4月

## 新特性 5.x

- Lucene 6.x，性能提升，默认打分机制从 TF-IDF 改为 BM 25
- 支持 Ingest 节点 / Painless Scripting / Completion suggested 支持 /原生的 Java REST 客户端
- Type 标记成 deprecated，支持了 Keyword 的类型
- 性能优化
  - 内部引擎移除了避免同一文档并发更新的竞争锁，带来 15%一20% 的性能提升
  - Instant aggregation，支持分片上聚合的缓存
  - 新增了Profile API

## 新特性 7.x

- Lucene 8.0
- 重大改进-正式废除单个索引下多 Type 的支持
- 7.1开始，Security 功能免费使用
- ECK - Elasticseach Operator on Kubernetes 
- 新功能
  - New Cluster coordinationo
  - Feature-Complete High Level REST Client
  - Script Score Query
- 性能优化
  - 默认的 Primary Shard 数从5 改为 1，避免 Over Sharding
  - 性能优化，更快的 Top k