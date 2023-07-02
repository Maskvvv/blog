---
title: Elasticsearch学习(五)-查询②
date: 2020-10-30
tags:
  - Elasticsearch
  - Elasticsearch学习(五)-查询②
categories:
  - Elasticsearch
  - Elasticsearch学习(五)-查询②
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700492-elasticsearch-logo.png)

<!-- more -->

## 一、深分页Scroll

> ES 对from +size时又限制的，from +size 之和 不能大于1W,超过后 效率会十分低下
>
> from+size  ES查询数据的方式：
>
> 1. 第一步将用户指定的关键词进行分词，
> 2. 第二部将词汇去分词库中进行检索，得到多个文档id,第三步去各个分片中拉去数据， 耗时相对较长
>
> 3. 第四步根据score 将数据进行排序， 耗时相对较长
>
> 4. 第五步根据from 和size 的值 将部分数据舍弃，
>
> 5. 第六步，返回结果。
>
>   scroll +size ES 查询数据的方式：
>
> 1. 第一步将用户指定的关键词进行分词，
>
> 2. 第二部将词汇去分词库中进行检索，得到多个文档id,
>
> 3. 第三步，将文档的id放在一个上下文中
>
> 4. 第四步，根据指定的size去ES中检索指定个数数据，拿完数据的文档id,会从上下文中移除
>
> 5. 第五步，如果需要下一页的数据，直接去ES的上下文中找后续内容。
>
> 6. 第六步，循环第四步和第五步
>
>
> scroll 不适合做实时查询。

```json
# 执行scroll查询，并将文档id信息存放在ES上下文中，并指定生存时间
POST /sms-logs-index/sms-logs-type/_search?scroll=1m
{
  "query": {
    "match_all": {}
  },
  "size": 2,
  "sort": [		#排序
    {
      "fee": {
        "order": "desc"
      }
    }
  ]
}

# 根据scroll查询下一页数据
POST /_search/scroll
{
  "scroll_id": "根据的一步得到的scroll_id填写",
  "scroll": "1m" #生存时间
}

# 删除scroll在es中上下文的数据
DELETE /_search/scroll/根据的一步得到的scroll_id填写
```

> java实现方式

```java
public class Demo7Scroll {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void scrollQuery() throws IOException {
        //1.创建searchRequest
        SearchRequest request = new SearchRequest(index).types(type);

        //2.指定scroll信息
        request.scroll(TimeValue.timeValueMinutes(1L));

        //3.指定查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();

        builder.size(4);
        builder.sort("fee", SortOrder.DESC);
        builder.query(QueryBuilders.matchAllQuery());

        request.source(builder);

        //4.获取返回结果scrollId，source
        SearchResponse resp = client.search(request, RequestOptions.DEFAULT);
        String scrollId = resp.getScrollId();
        System.out.println("-----------首页------------");
        for (SearchHit hit : resp.getHits().getHits()) {
            System.out.println(hit.getSourceAsMap());
        }

        while (true){
            //5.循环创建searchScrollRequest
            SearchScrollRequest scrollRequest = new SearchScrollRequest(scrollId);

            //6.指定scrollId的生存时间
            scrollRequest.scroll(TimeValue.timeValueMinutes(1L));

            //7.执行查询获取返回结果
            SearchResponse scrollResp = client.scroll(scrollRequest, RequestOptions.DEFAULT);

            //8.判断是否查询到了数据输出
            SearchHit[] hits = scrollResp.getHits().getHits();
            if (hits != null && hits.length > 0){
                System.out.println("------------下一页------------");
                for (SearchHit hit : hits) {
                    System.out.println(hit.getSourceAsMap());
                }
            }else {
                System.out.println("------------结束------------");

                //9.判断没有查询到的数据-退出循环
                break;
            }

        }

        //10.创建clearScrollRequest
        ClearScrollRequest clearScrollRequest = new ClearScrollRequest();

        //11.指定scrollId
        clearScrollRequest.addScrollId(scrollId);

        //12.删除scrollId
        ClearScrollResponse clearScrollResponse = client.clearScroll(clearScrollRequest, RequestOptions.DEFAULT);

        //13.输出结果
        System.out.println("删除scroll："+clearScrollResponse.isSucceeded());
    }
}
```

## 二、delete-by-query

> 根据 term,match 等查询方式去删除大量索引
>
> PS:如果你要删除的内容，时index下的大部分数据，推荐创建一个新的index,然后把保留的文档内容，添加到全新的索引

```json
# deltet-by-quert
POST /sms-logs-index/sms-logs-type/_delete_by_query
{
  "query": {
    "range": {
      "fee": {
        "gt": 10,
        "lte": 20
      }
    }
  }
}
```

> java实现方式

```java
public class Demo8deleteQuery {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void detletByQuery() throws IOException {
        //1.创建一个deleteByQueryRequest
        DeleteByQueryRequest request = new DeleteByQueryRequest(index).types(type);

        //2.指定索引条件 与s earchRequest实现的方式不一样
        request.setQuery(QueryBuilders.rangeQuery("fee").lt(4));

        //3.执行删除
        BulkByScrollResponse resp = client.deleteByQuery(request, RequestOptions.DEFAULT);

        //4.输出返回结果
        System.out.println(resp.toString());
    }
}
```

## 三、复合查询

### 3.1 bool查询

> 复合过滤器，将你的多个查询条件 以一定的逻辑组合在一起。
>
> - must：所有条件组合在一起，表示 and 的意思
> - must_not： 将must_not中的条件，全部都不匹配，表示not的意思
> - should：所有条件用should 组合在一起，表示 or 的意思

```json
# 查询省份为上海或者北京
# 运营商不是联通
# smsContent包含格力和购买
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "bool": {
      "should": [
        {
          "term": {
            "province": {
              "value": "上海"
            }
          }
        },
        {
          "term": {
            "province": {
              "value": "北京"
            }
          }
        }
      ],
      
      "must_not": [
        {
          "term": {
            "operatorId": {
              "value": "2"
            }
          }
        }
      ],
      "must": [
        {
          "match": {
            "smsContent": "格力"
          }
        },
        {
          "match": {
            "smsContent": "购买"
          }
        }
      ]
    }
  }
}
```

> java实现方式

```java
public class Demo9BoolQuery {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void boolQuery() throws IOException {
        //1.创建request
        SearchRequest request = new SearchRequest(index).types(type);

        //2.封装查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();
        BoolQueryBuilder boolQueryBuilder = new BoolQueryBuilder();

        // 查询省份为上海或者北京
        boolQueryBuilder.should(QueryBuilders.termQuery("province","上海"));
        boolQueryBuilder.should(QueryBuilders.termQuery("province","北京"));
        // 运营商不是联通
        boolQueryBuilder.mustNot(QueryBuilders.termQuery("operatorId","2"));
        // smsContent包含格力和购买
        boolQueryBuilder.must(QueryBuilders.matchQuery("smsContent","格力"));
        boolQueryBuilder.must(QueryBuilders.matchQuery("smsContent","购买"));

        builder.query(boolQueryBuilder);
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

### 3.2 boosting查询

> boosting 查询可以帮助我们去影响查询后的score
>
> - positive:只有匹配上positive 查询的内容，才会被放到返回的结果集中
>
> - negative: 如果匹配上positive 的结果集中 降低也匹配上了negative文档score.
>
> - negative_boost:指定系数,必须小于1   0.5 
>
> 关于查询时，分数时如何计算的：
>
> - 搜索的关键字再文档中出现的频次越高，分数越高
> - 指定的文档内容越短，分数越高。
> - 我们再搜索时，指定的关键字也会被分词，这个被分词的内容，被分词库匹配的个数越多，分数就越高。

```json
# boosting 查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "boosting": {
      "positive": {
        "match": {
          "smsContent": "海尔电器"
        }
      },
      "negative": {
        "term": {
          "province": {
            "value": "重庆"
          }
        }
      },
      "negative_boost": 0.2
    } 
  }
}
```

> java实现方式

```java
@Test
public void boostingQuery() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index).types(type);

    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    BoostingQueryBuilder boosting = QueryBuilders.boostingQuery(
            QueryBuilders.matchQuery("smsContent","海尔电器"),
            QueryBuilders.termQuery("province","重庆")
    ).negativeBoost(0.2f);

    builder.query(boosting);
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

## 四、filter查询

> query 查询：根据你的查询条件，去计算文档的匹配度得到一个分数，并根据分数排序，不会做缓存的。
>
> filter 查询：根据查询条件去查询文档，不去计算分数，而且filter会对经常被过滤的数据进行缓存。

```json
# filter 查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "bool": {
      "filter": [
       {
          "term": {
            "corpName": "海尔智家公司"
          }
       },
       {
         "range": {
           "fee": {
             "lte": 50
           }  
         }
       }
        
      ]
    }
  }
}
```

> java实现方式

```java
public class Demo10Filter {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void filterQuery() throws IOException {
        //1.创建request
        SearchRequest request = new SearchRequest(index).types(type);

        //2.封装查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();
        BoolQueryBuilder boolQueryBuilder = QueryBuilders.boolQuery();
        boolQueryBuilder.filter(QueryBuilders.termQuery("corpName","海尔智家公司"));
        boolQueryBuilder.filter(QueryBuilders.rangeQuery("fee").lte(50));


        builder.query(boolQueryBuilder);
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

## 五、高亮查询

> 高亮查询就是用户输入的关键字，以一定特殊样式展示给用户，让用户知道为什么这个结果被检索出来
>
> 高亮展示的数据，本身就是文档中的一个field,单独将field以highlight的形式返回给用户
>
> ES提供了一个`highlight` 属性，他和 `query 同级别`。
>
> - frament_size：指定高亮数据前展示多少个字符回来
> - fields：指定哪些field以高亮显示
> - pre_tags：指定前缀标签`<front color="red">`
> - post_tags：指定后缀标签` </font>`

```json
# highlight查询
POST /sms-logs-index/sms-logs-type/_search
{
  "query": {
    "match": {
      "smsContent": "张先生"
    }
  },
  "highlight": {
    "fields": {
      "smsContent":{}
    },
    "pre_tags": "<font color='red'>",
    "post_tags": "</font>",
    "fragment_size": 1
  }
}
```

> java操作

```java
public class Demo11HighLight {

    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void highLightQuery() throws IOException {
        //1.创建request
        SearchRequest request = new SearchRequest(index).types(type);

        //2.封装查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();
        builder.query(QueryBuilders.matchQuery("smsContent","张先生"));

        HighlightBuilder highlightBuilder = new HighlightBuilder();
        highlightBuilder.field("smsContent")
                .preTags("<font color='red'>")
                .postTags("</font>");

        builder.highlighter(highlightBuilder);
        request.source(builder);

        //3.执行查询
        SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

        //4.输出_source
        for (SearchHit hit : resp.getHits().getHits()) {
            System.out.println(hit.getHighlightFields().get("smsContent"));
        }

    }
}
```

## 六、聚合查询（aggregation）

> ES的聚合查询和 MySQL（ count() 、avg() ）的聚合查询类似，ES的聚合查询相比 MySQL 要强大得多。ES提供的统计数据的方式多种多样。

```json
# ES聚合查询的RESTful语法
POST /sms-logs-index/sms-logs-type/_search
{
  "aggs": {
    "自己指定，推荐agg": {
      "AGG_TYPE": {
          "属性": "值"
      }
    }
  }
}
```

### 6.1 去重计数查询（cardinality）

> 去重计数，即`cardinality` 先将返回的文档中的一个指定的field进行去重，统计一共有多少条

```json
# 去重计数查询
POST /sms-logs-index/sms-logs-type/_search
{
  "aggs": {
    "agg": {
      "cardinality": {
        "field": "province"
      }
    }
  }
}
```

> Java实现方式

```java
public class Demo12Agg {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "sms-logs-index";
    String type="sms-logs-type";

    @Test
    public void findByRegexp() throws IOException {
        //1.创建request
        SearchRequest request = new SearchRequest(index).types(type);


        //2.封装查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();
        builder.aggregation(AggregationBuilders.cardinality("agg").field("province"));

        request.source(builder);

        //3.执行查询
        SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

        //4.输出
        Cardinality agg = resp.getAggregations().get("agg");
        System.out.println(agg.getValue());
    }
}
```

### 6.2 范围统计（range）

> 统计一定范围内出现的文档个数，比如，针对某一个field 的值再0~100,100~200,200~300 之间文档出现的个数分别是多少范围统计 可以针对 普通的数值，针对时间类型，针对ip类型都可以响应。
>
> 可查询的类型：
>
> - 数值：rang    
> - 时间 ：date_rang     
> - ip：ip_rang

```json
# 数值方式范围统计 from 带等于效果 ，to 不带等于效果
POST /sms-logs-index/sms-logs-type/_search
{
  "aggs": {
    "agg": {
      "range": {
        "field": "fee",
        "ranges": [
          {
            "to": 50
          },
          {
            "from": 50,
            "to": 100
          },
          {
            "from": 80
          }
        ]
      }
    }
  }
}

# 时间方式范围统计
POST /sms-logs-index/sms-logs-type/_search
{
  "aggs": {
    "agg": {
      "date_range": {
        "field": "createDate",
        "format": "yyyy", 
        "ranges": [
          {
            "from": 2001,
            "to": "now"
          }
        ]
      }
    }
  }
}

# ip方式范围统计
POST /sms-logs-index/sms-logs-type/_search
{
  "aggs": {
    "agg": {
      "ip_range": {
        "field": "ipAddr",
        "ranges": [
          {
            "from": "127.0.0.1",
            "to": "127.0.0.10"
          }
        ]
      }
    }
  }
}
```

> java实现方式

```java
@Test
public void range() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index).types(type);


    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    /*
    "ranges": [
      {
        "to": 50
      },
      {
        "from": 50,
        "to": 100
      },
      {
        "from": 80
      }
    ]
     */
    builder.aggregation(AggregationBuilders.range("agg").field("fee")
                                .addUnboundedTo(50)
                                .addRange(50,100)
                                .addUnboundedFrom(80));


    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出
    Range agg = resp.getAggregations().get("agg");

    for (Range.Bucket bucket : agg.getBuckets()) {
        String key = bucket.getKeyAsString();
        long docCount = bucket.getDocCount();
        System.out.println(String.format("key: %s,count: %s",key,docCount));
    }
}
```

### 6.3 统计聚合查询（extended_stats）

> 他可以帮你查询指定field 的最大值，最小值，平均值，平方和...
>
> 使用 extended_stats

```json
# 统计聚合查询
POST /sms-logs-index/sms-logs-type/_search
{
  "aggs": {
    "agg": {
      "extended_stats": {
        "field": "fee"
      }
    }
  }
}
```

> java实现方式

```java
@Test
public void extendedStats() throws IOException {
    //1.创建request
    SearchRequest request = new SearchRequest(index).types(type);


    //2.封装查询条件
    SearchSourceBuilder builder = new SearchSourceBuilder();
    builder.aggregation(AggregationBuilders.extendedStats("agg").field("fee"));

    request.source(builder);

    //3.执行查询
    SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

    //4.输出
    ExtendedStats extendedStats = resp.getAggregations().get("agg");

    System.out.println("max:"+extendedStats.getMaxAsString());
    System.out.println("min:"+extendedStats.getMinAsString());
}
```

### 其他聚合查询 查看官方文档

**[官网地址](https://www.elastic.co/guide/en/elasticsearch/reference/6.5/search-aggregations.html)**

## 七、地图经纬度搜索

> ES中提供了一个数据类型geo_point，这个类型就是来寻出经纬度（longitude and latitude）的
>
> ES的地图检索方式：
>
> - geo_distance :直线距离检索方式
> - geo_bounding_box: 以2个点确定一个矩形，获取再矩形内的数据
> - geo_polygon:以多个点，确定一个多边形，获取多边形的全部数据

### 7.1 数据结构和数据的准备

```json
# 创建一个索引，指定一个name，location
PUT /map
{
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 1
  },
  "mappings": {
    "map": {
      "properties": {
        "name": {
          "type": "text"
        },
        "location": {
          "type": "geo_point"
        }
      }
    }
  }
}

#添加测试数据
PUT /map/map/1
{
  "name": "天安门",
  "location": {
    "lon": 116.403694,
    "lat":39.914492
  }
}

PUT /map/map/2
{
  "name":"中央戏剧学院",
  "location":{
    "lon": 116.411599,
    "lat":39.941715
  }
}

PUT /map/map/3
{
  "name":"北京邮电大学",
  "location":{
    "lon": 116.3646,
    "lat":39.966935
  }
}
```

### 7.2 geo_distance查询

> 指定一个点的经纬度 （geo_distance ），并指定半径（distance）和圆形（distance_type），搜索在以点为中心半径内存在的点。

```json
# geo_distance
POST /map/map/_search
{
  "query": {
    "geo_distance": {
      "location": {				# 确定一个点
        "lon": 116.3646,
        "lat":39.966935
      },
      "distance": 5000,			# 确定半径
      "distance_type": "arc"	# 以定义的点和直线画圆
    }
  }
}
```

### 7.3 geo_bounding_box查询

> 指定左上角（top_left）和右下角（bottom_right）的点，查询矩形框内的点

```json
# geo_bounding_box
POST /map/map/_search
{
  "query": {
    "geo_bounding_box": {
      "location": {
        "top_left": {
          "lon": 116.375092,
          "lat":39.951671
        },
        "bottom_right": {
          "lon": 116.432871,
          "lat":39.902759
        }
      }
    }
  }
}
```

### 7.4 geo_polygon查询

> 指定多个点组成多边形，搜索出多边形内的点

```json
# geo_polygon
POST /map/map/_search
{
  "query": {
    "geo_polygon": {
      "location": {
        "points": [
          {
          "lon": 116.375092,
          "lat":39.951671
          },
          {
          "lon": 116.432871,
          "lat":39.902759
          },
          {
          "lon": 116.430859,
          "lat":39.948906
          }
        ]
      }
    }
  }
}
```

> java实现方式

```java
public class Deom13Location {
    ObjectMapper mapper = new ObjectMapper();
    RestHighLevelClient client =  ESClient.getClient();
    String index = "map";
    String type="map";

    @Test
    public void GeoPolygon() throws IOException {
        //1.创建request
        SearchRequest request = new SearchRequest(index).types(type);

        //2.封装查询条件
        SearchSourceBuilder builder = new SearchSourceBuilder();
        List<GeoPoint> points = new ArrayList<>();
        points.add(new GeoPoint(39.951671,116.375092));
        points.add(new GeoPoint(39.902759,116.432871));
        points.add(new GeoPoint(39.948906,116.430859));

        builder.query(QueryBuilders.geoPolygonQuery("location",points));

        request.source(builder);

        //3.执行查询
        SearchResponse resp = client.search(request, RequestOptions.DEFAULT);

        //4.输出
        for (SearchHit hit : resp.getHits().getHits()) {
            System.out.println(hit.getSourceAsMap());
        }
    }
}
```



