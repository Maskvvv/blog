---
title: Elasticsearch学习(三)-java操作ES
date: 2020-10-28
tags:
  - Elasticsearch
  - Elasticsearch学习(三)-java操作ES
categories:
  - Elasticsearch
  - Elasticsearch学习(三)-java操作ES
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700253-elasticsearch-logo.png)

<!-- more -->

## 一、java连接ES

### 1.1 导入pom.xml依赖

```xml
<!--1.elasticsearch-->
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch</artifactId>
    <version>6.5.4</version>
</dependency>

<!--1.elasticsearch的高级API-->
<dependency>
    <groupId>org.elasticsearch.client</groupId>
    <artifactId>elasticsearch-rest-high-level-client</artifactId>
    <version>6.5.4</version>
</dependency>

<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.12</version>
</dependency>

<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>1.18.12</version>
</dependency>
```

### 1.2 创建ES的连接工具类

```java
public class ESClient {
    public static RestHighLevelClient getClient(){

        //创建httphost对象
        HttpHost httpHost = new HttpHost("192.168.199.138", 9200);

        //创建RestClientBuilder
        RestClientBuilder clientBuilder = RestClient.builder(httpHost);

        //创建RestHighLevelClient
        RestHighLevelClient client = new RestHighLevelClient(clientBuilder);

        //返回RestHighLevelClient
        return client;

    }
}
```

### 1.3 测试

```java
@Test
public void test(){
    RestHighLevelClient client = ESClient.getClient();
    System.out.println("ok");

}
```

## 二、索引操作

### 2.1 创建一个索引并指定数据结构

```java
public class Demo2Index {

    RestHighLevelClient client = ESClient.getClient();

    String index = "person";
    String type = "man";

    @Test
    public void createIndex() throws IOException {

        //1.准备关于索引的settings
        Settings.Builder settings = Settings.builder()
                .put("number_of_shards",3)
                .put("number_of_replicas",1);

        //2.准备棍鱼索引的结构mappings
        /*
            {
              "mapping": {
                "man": {
                  "properties": {
                    "age": {
                      "type": "integer"
                    },
                    "birthday": {
                      "type": "date",
                      "format": "yyyy-MM-dd"
                    },
                    "name": {
                      "type": "text"
                    }
                  }
                }
              }
            }
         */
        XContentBuilder mappings = JsonXContent.contentBuilder()
                .startObject()
                    .startObject("properties")
                        .startObject("name")
                            .field("type", "text")
                        .endObject()
                        .startObject("age")
                            .field("type", "integer")
                        .endObject()
                        .startObject("birthday")
                            .field("type", "date")
                            .field("format","yyyy-MM-dd")
                        .endObject()
                    .endObject()
                .endObject();

        //3.将settings和mappings封装到一个request对象中
        CreateIndexRequest request = new CreateIndexRequest(index)
                .settings(settings)
                .mapping(type, mappings);

        //4.通过client对象去连接ES并执行创建索引
        CreateIndexResponse resp = client.indices().create(request, RequestOptions.DEFAULT);

        //5.输出
        System.out.println(resp);
    }
}
```

### 2.2 检查索引是否存在

```java
@Test
public void exists() throws IOException {
    //1.准备request对象
    GetIndexRequest request = new GetIndexRequest();
    request.indices(index);

    //2.通过client去操作
    boolean exists = client.indices().exists(request, RequestOptions.DEFAULT);

    //3.输出
    System.out.println(exists);


}
```

### 2.3 删除索引

```java
@Test
public void delete() throws IOException {
    //1.准备request对象
    DeleteIndexRequest request = new DeleteIndexRequest();
    request.indices(index);

    //2.通过client去操作
    AcknowledgedResponse delete = client.indices().delete(request, RequestOptions.DEFAULT);

    //3.输出
    System.out.println(delete.isAcknowledged());

}
```

## 三、文档的操作

### 3.1 创建文档

#### 3.1.1 添加依赖

```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.10.4</version>
</dependency>
```

#### 3.1.2 编写实体类

```java
public class Person {

    @JsonIgnore
    private Integer id;
    private String name;
    private Integer age;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date birthday;

}
```

#### 3.1.3 测试

```java
public class Demo3Document {
    //创建es执行对象
    RestHighLevelClient client = ESClient.getClient();

    //创建Jackson对象
    ObjectMapper mapper = new ObjectMapper();

    String index = "person";
    String type = "man";

    @Test
    public void creatDoc() throws IOException {
        //1.准备一个json数据
        Person person = new Person(1, "mike", 18, new Date());
        String json = mapper.writeValueAsString(person);

        //2.准备一个request对象
        IndexRequest request = new IndexRequest(index,type,person.getId().toString());
        request.source(json, XContentType.JSON);

        //3.通过client对象执行添加
        IndexResponse resp= client.index(request, RequestOptions.DEFAULT);

        //4.输出返回结果
        System.out.println(resp.getResult().toString());
    }
}

```

### 3.2修改文档

```java
@Test
public void updateDoc() throws IOException {

    //1.创建一个Map，指定需要修改的内容
    Map<String,Object> doc = new HashMap<String,Object>();
    doc.put("name","jone");
    String docID = "1";

    //2.创建request对象，封装数据
    UpdateRequest request = new UpdateRequest(index, type, docID);
    request.doc(doc);

    //3.通过client对象执行
    UpdateResponse update = client.update(request, RequestOptions.DEFAULT);

    //4.输出返回结果
    System.out.println(update);

}
```

### 3.3 删除文档

```java
@Test
public void deleteDoc() throws IOException {

    //1.创建request对象，封装数据
    DeleteRequest request = new DeleteRequest(index, type, "1");

    //2.通过client对象执行
    DeleteResponse response = client.delete(request, RequestOptions.DEFAULT);

    //3.输出返回结果
    System.out.println(response);

}
```

### 3.4 文档的批量添加

```java
@Test
public void bulkDoc() throws IOException {

    //1.准备多个json数据
    Person p1 = new Person(1, "张三", 23, new Date());
    Person p2 = new Person(2, "李四", 13, new Date());
    Person p3 = new Person(3, "王五", 28, new Date());

    String json1 = mapper.writeValueAsString(p1);
    String json2 = mapper.writeValueAsString(p2);
    String json3 = mapper.writeValueAsString(p3);

    //2.创建BulkRequest对象，封装数据
    BulkRequest request = new BulkRequest();
    request.add(new IndexRequest(index,type,p1.getId().toString()).source(json1,XContentType.JSON));
    request.add(new IndexRequest(index,type,p2.getId().toString()).source(json2,XContentType.JSON));
    request.add(new IndexRequest(index,type,p3.getId().toString()).source(json3,XContentType.JSON));

    //3.通过client对象执行
    BulkResponse resp = client.bulk(request, RequestOptions.DEFAULT);

    //4.输出返回结果
    System.out.println(resp);

}
```

### 3.5 文档的批量删除

```java
@Test
public void bulkDeleteDoc() throws IOException {

    //1.创建BulkRequest对象，封装数据
    BulkRequest request = new BulkRequest();
    request.add(new DeleteRequest(index,type,"1"));
    request.add(new DeleteRequest(index,type,"2"));
    request.add(new DeleteRequest(index,type,"3"));

    //2.通过client对象执行
    BulkResponse resp = client.bulk(request, RequestOptions.DEFAULT);

    //3.输出返回结果
    System.out.println(resp);

}
```
