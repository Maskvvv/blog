# 文档 (Document)

可以理解为关系型数据库的一条记录

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213187-image-20230504231307239.png)

## JSON 文档

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213559-image-20230504231919449.png)

## 文档的元数据

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213650-image-20230504232049996.png)

# 索引

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213707-image-20230504232147611.png)

## 索引的不同语意

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213767-image-20230504232247179.png)

# Type

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213819-image-20230504232339749.png)

# 抽象与类比

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213843-image-20230504232403615.png)

# REST API 一很容易被各种语言调用

![](http://qiniu.zhouhongyin.top/2023/05/04/1683213927-image-20230504232527609.png)

# 索引管理

![](http://qiniu.zhouhongyin.top/2023/05/04/1683214073-image-20230504232753736.png)

![](http://qiniu.zhouhongyin.top/2023/05/04/1683214086-image-20230504232806673.png)

![](http://qiniu.zhouhongyin.top/2023/05/04/1683214098-image-20230504232818123.png)

# 一些基本的 API

需要通过Kibana导入Sample Data的电商数据

```shell
#查看索引相关信息
GET kibana_sample_data_ecommerce

#查看索引的文档总数
GET kibana_sample_data_ecommerce/_count

#查看前10条文档，了解文档格式
POST kibana_sample_data_ecommerce/_search
{
}

#_cat indices API
#查看indices
GET /_cat/indices/kibana*?v&s=index

#查看状态为绿的索引
GET /_cat/indices?v&health=green

#按照文档个数排序
GET /_cat/indices?v&s=docs.count:desc

#查看具体的字段
GET /_cat/indices/kibana*?pri&v&h=health,index,pri,rep,docs.count,mt

#How much memory is used per index?
GET /_cat/indices?v&h=i,tm&s=tm:desc

```

