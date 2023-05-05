# 什么是 Mapping

- Mapping 类似数据库中的 schema 的定义，作用如下
  - 定义索引中的字段的名称
  - 定义字段的数据类型，例如字符串，数字，布尔.....
  - 字段，倒排索引的相关配置，(Analyzed or Not Analyzed， Analyzer)
- Mapping 会把 JSON 文档映射成 Lucene 所需要的扁平格式
- 一个 Mapping 属于一个索引的 Type
  - 每个文档都属于一个 Type
  - 一个 Type 有一个Mapping 定义
  - 7.0 开始，不需要在 Mapping定义中指定 type 信息

# 字段的数据类型

- 简单类型
  - Text / Keyword
  - Date
  - Integer / Floating
  - Boolean
  - IPv4 &IPv6
- 复杂类型-对象和嵌套对象
  - 对象类型 / 嵌套类型
- 特殊类型
  - geo_point & geo_shape / percolator

# 什么是 Dynamic Mapping

- 在写入文档时候，如果索引不存在会自动创建索引
- Dynamic Mapping 的机制，使得我们无需手动定义Mappings。Elasticsearch 会自动根据文档信息，推算出字段的类型
- 但是有时候会推算的不对，例如地理位置信息
- 当类型如果设置不对时，会导致一些功能无法正常运行，例如 Range 查询

![](http://qiniu.zhouhongyin.top/2023/05/05/1683278014-image-20230505171334100.png)

# 类型的自动识别

![](http://qiniu.zhouhongyin.top/2023/05/05/1683278108-image-20230505171508154.png)

# 能否更改 Mapping 的字段类型

![](http://qiniu.zhouhongyin.top/2023/05/05/1683278285-image-20230505171805026.png)

# 控制 Dynamic Mappings

![](http://qiniu.zhouhongyin.top/2023/05/05/1683278421-image-20230505172021012.png)

# 总结

## keword 是一种字段类型

es 的每个字段可以做多字段，例如，你有一个content 的字段，类型是 text。你可以为他指定一个子字段叫 keyword（也可以取名字叫kw）类型设置成keword， 在做term查询时，就查询content.keyword（或者叫 content.kw。 es 默认为所有文本都设置成text，并且设置 keywoed 的子字段

## mapping信息是保存在cluster state 里面的。 

文件应该放在 nodes/{N}/_state/global-{NNN} 下面 https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-state.html 

## 使用动态 mapping 的隐患

设置成 strict，万一有一条数据里带着不存在的字段，写入就会失败。 设置成true，数据可以写入，还会在mapping中增加那个字段的设置。随着时间的流逝，这类数据会导致 mapping 设定的膨胀 

## 选择使用ES的场景，及同步数据的思路 

如果有全文搜索的需求。或者有统计分析的需求，都可以用 es 作为存储。数据可以在数据库里保存一份，定期同步到 es 中。然后对一些全文搜索的，对应 es 实现。 数据库和 es 同步可以考虑使用 logstash 的 jdbc connector。只需要配置就可以实现增量同步。对于你说的物理删除的记录如何同步 es，在 logstash 中不支持这个功能。但是你可以通过为数据增加 isDeleted 字段的方式。标记成删除状态。同步到es后 再用程序分别删除。