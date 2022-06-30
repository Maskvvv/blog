---
title: Elasticsearch学习(四)-查询①
date: 2020-10-29
tags:
  - Elasticsearch
  - Elasticsearch学习(四)-查询①
categories:
  - Elasticsearch
  - Elasticsearch学习(四)-查询①
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700450-elasticsearch-logo.png)

<!-- more -->

## 一、准备数据

### 1.1 数据结构

- Index： sms-logs-index
- type：sms-logs-type

| 字段名称   | 备注                                |
| ---------- | ----------------------------------- |
| createDate | 创建时间String                      |
| sendDate   | 发送时间 date                       |
| longCode   | 发送长号码 如 16092389287811 string |
| Mobile     | 如 13000000000                      |
| corpName   | 发送公司名称，需要分词检索          |
| smsContent | 下发短信内容，需要分词检索          |
| State      | 短信下发状态 0 成功 1 失败 integer  |
| Operatorid | 运营商编号1移动2联通3电信 integer   |
| Province   | 省份                                |
| ipAddr     | 下发服务器IP地址                    |
| replyTotal | 短信状态报告返回时长 integer        |
| Fee        | 扣费 integer                        |

### 1.2 创建SmsLogs实体类

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SmsLogs {
    private Integer id;
    private Date createDate;
    private Date sendDate;
    private String longCode;
    private String mobile;
    private String corpName;
    private String smsContent;
    private Integer state;
    private Integer operatorId;
    private String province;
    private String ipAddr;
    private Integer replyTotal;
    private Integer fee;

}
```

### 1.3 创建索引和添加数据

```java
public class testData {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void createIndex() throws  Exception{
        // 1.准备关于索引的setting
        Settings.Builder settings = Settings.builder()
                .put("number_of_shards", 3)
                .put("number_of_replicas", 1);

        // 2.准备关于索引的mapping
        XContentBuilder mappings = JsonXContent.contentBuilder()
                .startObject()
                .startObject("properties")
                .startObject("corpName")
                .field("type", "keyword")
                .endObject()
                .startObject("createDate")
                .field("type", "date")
                .field("format", "yyyy-MM-dd")
                .endObject()
                .startObject("fee")
                .field("type", "long")
                .endObject()
                .startObject("ipAddr")
                .field("type", "ip")
                .endObject()
                .startObject("longCode")
                .field("type", "keyword")
                .endObject()
                .startObject("mobile")
                .field("type", "keyword")
                .endObject()
                .startObject("operatorId")
                .field("type", "integer")
                .endObject()
                .startObject("province")
                .field("type", "keyword")
                .endObject()
                .startObject("replyTotal")
                .field("type", "integer")
                .endObject()
                .startObject("sendDate")
                .field("type", "date")
                .field("format", "yyyy-MM-dd")
                .endObject()
                .startObject("smsContent")
                .field("type", "text")
                .field("analyzer", "ik_max_word")
                .endObject()
                .startObject("state")
                .field("type", "integer")
                .endObject()
                .endObject()
                .endObject();
        // 3.将settings和mappings 封装到到一个Request对象中
        CreateIndexRequest request = new CreateIndexRequest(index)
                .settings(settings)
                .mapping(type,mappings);
        // 4.使用client 去连接ES
        CreateIndexResponse response = client.indices().create(request, RequestOptions.DEFAULT);

        System.out.println("response:"+response.toString());

    }

    @Test
    public void  bulkCreateDoc() throws  Exception{
        // 1.准备多个json 对象
        String longcode = "1008687";
        String mobile ="138340658";
        List<String> companies = new ArrayList<>();
        companies.add("腾讯课堂");
        companies.add("阿里旺旺");
        companies.add("海尔电器");
        companies.add("海尔智家公司");
        companies.add("格力汽车");
        companies.add("苏宁易购");
        List<String> provinces = new ArrayList<>();
        provinces.add("北京");
        provinces.add("重庆");
        provinces.add("上海");
        provinces.add("晋城");
        List<String> smsContent = new ArrayList<>();
        smsContent.add("【腾讯课堂】亲爱的灯先生，您的腾讯课堂已经购买");
        smsContent.add("【阿里旺旺】亲爱的王先生，您的阿里旺旺已经购买");
        smsContent.add("【海尔电器】亲爱的李先生，您的海尔电器已经购买");
        smsContent.add("【海尔智家公司】亲爱的张先生，您的海尔智家公司已经购买");
        smsContent.add("【格力汽车】亲爱的周先生，您的格力汽车已经购买");
        smsContent.add("【苏宁易购】亲爱的赵先生，您的苏宁易购已经购买");


        BulkRequest bulkRequest = new BulkRequest();
        for (int i = 1; i <16 ; i++) {
            Thread.sleep(1000);
            SmsLogs s1 = new SmsLogs();
            s1.setId(i);
            s1.setCreateDate(new Date());
            s1.setSendDate(new Date());
            s1.setLongCode(longcode+i);
            s1.setMobile(mobile+2*i);
            s1.setCorpName(companies.get(i%5));
            s1.setSmsContent(smsContent.get(i%5));
            s1.setState(i%2);
            s1.setOperatorId(i%3);
            s1.setProvince(provinces.get(i%4));
            s1.setIpAddr("127.0.0."+i);
            s1.setReplyTotal(i*3);
            s1.setFee(i*6);
            String json1  = mapper.writeValueAsString(s1);
            bulkRequest.add(new IndexRequest(index,type,s1.getId().toString()).source(json1, XContentType.JSON));
            System.out.println("数据"+i+s1.toString());
        }

        // 3.client 执行
        BulkResponse responses = client.bulk(bulkRequest, RequestOptions.DEFAULT);

        // 4.输出结果
        System.out.println(responses.getItems().toString());
    }

}
```

## 二、ElasticSearch的各种查询

### 2.1 term&terms查询

#### 2.1.1 term查询

> term的查询是代表完全匹配,搜索之前不会对你搜索的关键字进行分词,对你的关键字去文档分词库中去匹
> 配内容

```java
POST /sms-logs-index/sms-logs-type/_search
{
  "from": 0, # limit
  "size": 5, # page
  "query": {
    "term": {
      "province": {
        "value": "北京"
      } 
    }
  }
}
```

> java实现方式

```java
public class Demo4term {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void termQuery() throws IOException {
        //1.创建request对象
        SearchRequest request = new SearchRequest(index);
        request.types(type);

        //2.指定查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();
        builder.from(0);
        builder.size(5);
        builder.query(QueryBuilders.termQuery("province","北京"));

        request.source(builder);

        //3.执行查询
        SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

        //4.获取到_source中的数据，并展示
        for (SearchHit hit : resp.getHits().getHits()) {
            Map<String, Object> result = hit.getSourceAsMap();
            System.out.println(result);
        }
    }
```

#### 2.1.2 terms查询

> terms和term的查询机制是一样,都不会将指定的查询关键字进行分词,直接去分词库中匹配,找到相应文档
> 内容。
>
> terms是在针对一个字段包含多个值的时候使用。
>
> term: where province=北京
>
> terms: where province=北京 or province= ? or province = ?

```java
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "terms": {
      "province": [
        "北京",
        "上海"
      ]
    }
  }
}
```

> java实现方式

```java
@Test
public void termsQuery() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    builder.query(QueryBuilders.termsQuery("province","北京","上海"));

    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

### 2.2 match查询

#### 2.2.1 match_all查询

> match 查询属于高级查询，会根据你查询字段的类型不一样，采用不同的查询方式
>
> - 查询的是日期或者数值，他会将你基于字符串的查询内容转换为日期或数值对待
> - 如果查询的内容是一个不能被分词的内容（keyword）,match 不会将你指定的关键字进行分词
> - 如果查询的内容是一个可以被分词的内容（text）,match 查询会将你指定的内容根据一定的方式进行分词，去分词库中匹配指定的内容
>
> match 查询，实际底层就是多个term 查询，将多个term查询的结果给你封装到一起

```json
# math_all查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "match_all": {}
  }
}
```

> java实现方式

```java
public class Demo5match {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void matchAllQuery() throws IOException {
        //1.创建request
        SearchRequest request = new SearchRequest(index);
        request.types(type);

        //2.封装查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();
        builder.query(QueryBuilders.matchAllQuery());
        builder.size(20);       //ES默认只查询10条数据,如果想查询更多,添加size

        request.source(builder);

        //3.执行查询
        SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

        //4.输出_source
        for (SearchHit hit : resp.getHits().getHits()) {
            Map<String, Object> result = hit.getSourceAsMap();
            System.out.println(result);
        }
    }
}
```

#### 2.2.2 match查询

> 指定一个Field作为筛选的条件

```json
# math查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "match": {
      "smsContent": "海尔电器"
    }
  }
}
```

> java实现方式

```java
@Test
public void matchQuery() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    //---------------------------------
    builder.query(QueryBuilders.matchQuery("smsContent","海尔电器"));
    builder.size(20);       //ES默认只查询10条数据,如果想查询更多,添加size

    //---------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

#### 2.2.3布尔match查询

> 基于一个Field匹配的内容，采用and或者or的方式连接

```json
# 布尔math查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "match": {
      "smsContent": {
        "query": "海尔 公司",
        "operator": "or"
      }
    }
  }
}

# 布尔math查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "match": {
      "smsContent": {
        "query": "海尔 公司",
        "operator": "and"
      }
    }
  }
}
```

> java操作

```java
@Test
public void bollMatchQuery() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();

    //---------------------------------
    builder.query(QueryBuilders.matchQuery("smsContent","海尔公司").operator(Operator.AND));

    //---------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

#### 2.2.4 multi_match查询

> match针对一个field做检索, multi_match针对多个fied进行检索,多个field对应一个text

```json
# multi_math查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "multi_match": {
      "query": "北京",
      "fields": ["province","smsContent"]
    }
  }
}
```

> java操作

```java
@Test
public void multiMatchQuery() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();

    //---------------------------------
    builder.query(QueryBuilders.multiMatchQuery("北京","province","smsContent"));

    //---------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

### 2.3 其他查询

#### 2.3.1 id查询

```json
# multi_math查询
GET /sms-logs-index/sms-logs-type/1
```

> java实现方式

```java
public class Demo6id {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void findById() throws IOException {
        //1.创建request
        GetRequest request = new GetRequest(index, type, "1");

        //2.执行查询
        GetResponse resp = client.get(request, RequestOptions.DEFAULT);

        //3.输出_source
        System.out.println(resp.getSourceAsMap());
    }
}
```

#### 2.3.2 ids查询

> 根据多个id查询,类似MsQL中的 where id in (id1，id2，id2…)

```json
# ids查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "ids": {
      "values": ["1","2","3"]
    }
  }
}
```

> java实现方式

```java
@Test
public void findByIds() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    //------------------------------
    builder.query(QueryBuilders.idsQuery().addIds("1","2","3"));

    //-------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

#### 2.3.3 prefix查询

> 前缀查询，可以通过一个关键字去指定一个field 的前缀，从而查询到指定文档

```json
# prefix查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "prefix": {
      "corpName": {
        "value": "海"
      }
    }
  }
}
```

> java实现方式

```java
 @Test
public void findByPrefix() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    //------------------------------
    builder.query(QueryBuilders.prefixQuery("corpName","海"));

    //-------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

#### 2.3.4 fuzzy查询

> 模糊查询，我们可以输入一个字符的大概，ES 可以根据输入的大概去匹配内容。查询结果不稳定

```json
# fuzzy查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "fuzzy": {
      "corpName": {
        "value": "海尔电气", 
        "prefix_length": 2
      }
    }
  }
}
```

> java操作

```java
@Test
public void findByFuzzy() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    //------------------------------
    builder.query(QueryBuilders.fuzzyQuery("corpName","海尔电气").prefixLength(2));

    //-------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

#### 2.3.5 wildcard查询

> 通配查询，同mysql中的like 是一样的，可以在查询时，在字符串中指定通配符*和占位符？

```json
# fuzzy查询*
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "wildcard": {
      "corpName": {
        "value": "腾讯*"
      }
    }
  }
}
# fuzzy查询？
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "wildcard": {
      "corpName": {
        "value": "腾讯??"
      }
    }
  }
}
```

> java操作

```java
@Test
public void findByWildcard() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    //------------------------------
    builder.query(QueryBuilders.wildcardQuery("corpName","腾讯*"));

    //-------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

#### 2.3.6 range查询

> 范围查询，只针对数值类型，对一个Field 进行大于或者小于的范围指定
>
> - lte：小于等于（less than）
> - lt：小于
> - gte：大于等于（greater than）
> - gt：大于

```json
# range查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "range": {
      "fee": {
        "gt": 10, # e代表=
        "lte": 20
      }
    }
  }
}
```

> java实现方式

```java
@Test
public void findByRange() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    //------------------------------
    builder.query(QueryBuilders.rangeQuery("fee").gt(10).lte(20));

    //-------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```

#### 2.3.7 regexp查询

> 正则查询，通过你编写的正则表达式去匹配内容
>
> *Ps:prefix wildcard  fuzzy 和regexp 查询效率比较低 ,在要求效率比较高时，避免使用*

```json
# regexp查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "regexp": {
      "mobile": "138[0-9]{8}"
    }
  }
}
```

> java实现方式

```java
@Test
public void findByRegexp() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index);
    request.types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    //------------------------------
    builder.query(QueryBuilders.regexpQuery("mobile","138[0-9]{8}"));

    //-------------------------------
    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出_source
    for (SearchHit hit : resp.getHits().getHits()) {
        Map<String, Object> result = hit.getSourceAsMap();
        System.out.println(result);
    }
}
```
