# Elastic Stack 生态圈

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192019-image-20230504172019875.png)

# Logstash - 数据处理管道

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192132-image-20230504172212188.png)

- 开源的服务器端数据处理管道，支持从不同来源采集数据转换数据，并将数据发送到不同的存储库中
- Logstash 诞生于 2009 年，最初用来做日志的采集与处理
- Logstash 创始人 Jordan Sisel
- 2013 年被 Elasticsearch 收购

## Logstash 特性

- 实时解析和转换数据
  - 从 IP 地址破译出地理坐标
  - 将 PII 数据匿名化，完全排除敏感字段
- 可扩展
  - 200 多个插件 (日志/数据库/Arcsigh/Netflow)
- 可靠性安全性
  - Logstash 会通过持久化队列来保证至少将运行中的事件送达一次
  - 数据传输加密
- 监控

# Kibana - 可视化分析利器

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192284-image-20230504172444843.png)

- Kibana 名字的含义= Kiwifruit + Banana
- 数据可视化工具，帮助用户解开对数据的任何疑问
- 基于 Logstash 的工具，2013 年加入 Elastic 公司

## Kibana 特性

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192382-image-20230504172621897.png)

# Elastic 的发展

- 2015 年 3月收购 Elastic Cloud，提供 Cloud 服务
- 2015 年3月收购 PacketBeat
- 2016 年 9 月收购 PreAlert - Machine Learning 异常检测
- 2017 年6月收购 Opbeat 进军 APM
- 2017 年11 月收购 SaaS 厂商 Swiftype，提供网站和 App 搜索
- 2018年 X-Pack 开源

# BEATS - 轻量的数据采集器

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192477-image-20230504172757290.png)

# X-Pack: 商业化套件

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192532-image-20230504172852079.png)

- 6.3之前的版本，X-Pack 以插件方式安装
- X-Pack开源之后，Elasticsearch & Kibana 支持 OSS 版和 Basic 两种版本
  - 部分X-Pack 功能支持免费使用，6.8 和 7.1 开始，Security 功能免费
- OSS，Basic，黄金级，白金级
- https://www.elastic.co/cn/subscriptions

# ELK 客户及应用场景

## 客户

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192612-image-20230504173012618.png)

## 应用场景

- 网站搜索/垂直搜索/代码搜索
- 日志管理与分析 / 安全指标监控应用性能监控 / WEB抓取舆情分

# 日志的重要性

## 为什么重要

- 运维:医生给病人看病。日志就是病人对自己的陈述
- 恶意攻击，恶意注册，刷单，恶意密码猜测

## 挑战

- 关注点很多，任何一个点都有可能引起问题
- 日志分散在很多机器，出了问题时，才发现日志被删了
- 很多运维人员是消防员，哪里有问题去哪里

# 日志管理

![](http://qiniu.zhouhongyin.top/2023/05/04/1683192766-image-20230504173246798.png)

- 方便的搜索日志
- 通过机器学习的方式对恶意请求进行嗅探和分析

# Elasticsearch 与数据库的集成

![](http://qiniu.zhouhongyin.top/2023/05/04/1683194708-image-20230504180508665.png)

- 单独使用 Elasticsearch 做为存储
- 以下情况可考虑与数据库集成
  - 与现有系统的集成
  - 需考虑事务性
  - 数据更新频繁

# 指标分析 /日志分析

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195021-image-20230504181021601.png)