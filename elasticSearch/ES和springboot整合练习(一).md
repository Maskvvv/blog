---
title: Elasticsearch和springboot整合练习(一)-环境搭建
date: 2021-01-07
tags:
  - springboot
  - Elasticsearch
  - Elasticsearch和springboot整合练习(一)-环境搭建
categories:
  - Elasticsearch
  - Elasticsearch和springboot整合练习(一)-环境搭建
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700578-elasticsearch-logo.png)

<!-- more -->

## 一、架构图

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700583-image-20210108111803758.png)

## 二、搜索模块

创建一个名为search的springboot项目，用来操作ES。

### 2.1 导入相关依赖

```xml
<dependencies>
    <dependency>
        <groupId>commons-beanutils</groupId>
        <artifactId>commons-beanutils</artifactId>
        <version>1.9.3</version>
    </dependency>
    <!--elasticsearch-->
    <dependency>
        <groupId>org.elasticsearch</groupId>
        <artifactId>elasticsearch</artifactId>
        <version>6.5.4</version>
    </dependency>

    <!--elasticsearch的高级API-->
    <dependency>
        <groupId>org.elasticsearch.client</groupId>
        <artifactId>elasticsearch-rest-high-level-client</artifactId>
        <version>6.5.4</version>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-devtools</artifactId>
        <scope>runtime</scope>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### 2.2 编写springboot配置文件

编写配置文件，配置ES所需参数。

```yml
elasticsearch:
  host: 192.168.31.138
  port: 9200
```

### 2.3 将RestHighLevelClient注入springboot中

编写ElasticSearchConfig配置类将elasticsearch的高级API注入到spring容器中。

```java
@Configuration
public class ElasticSearchConfig {
    //服务器ip地址
    @Value("${elasticsearch.host}")
    private String host;
    //ES的端口
    @Value("${elasticsearch.port}")
    private int port;

    @Bean
    public RestHighLevelClient client(){
        //创建httphost对象
        HttpHost httpHost = new HttpHost(host, port);

        //创建RestClientBuilder
        RestClientBuilder clientBuilder = RestClient.builder(httpHost);

        //创建RestHighLevelClient
        RestHighLevelClient client = new RestHighLevelClient(clientBuilder);

        //返回RestHighLevelClient
        return client;
    }
}
```

### 2.4 创建Customer实体类

```java
@Data
public class Customer implements Serializable {
    /**
     * 主键
     *
     * isNullAble:0
     */
    private Integer id;

    /**
     * 公司名
     * isNullAble:1
     */
    private String username;

    /**
     *
     * isNullAble:1
     */
    private String password;

    /**
     *
     * isNullAble:1
     */
    private String nickname;

    /**
     * 金钱
     * isNullAble:1
     */
    private Long money;

    /**
     * 地址
     * isNullAble:1
     */
    private String address;

    /**
     * 状态
     * isNullAble:1
     */
    private Integer state;
}
```

### 2.5 创建ES索引和类型，并添加数据

在test包中创建名为ElasticInitTests的测试类，用来创建ES索引和添加数据。

```java
@SpringBootTest
class ElasticInitTests {

    @Autowired
    private RestHighLevelClient client;

    String index = "openapi_customer";
    String type = "customer";

    //创建索引
    @Test
    public void createIndex() throws IOException {
        //1. 准备关于索引的settings
        Settings.Builder settings = Settings.builder()
                .put("number_of_shards", 5)
                .put("number_of_replicas", 1);

        //2. 准备关于索引的结构mappings
        XContentBuilder mappings = JsonXContent.contentBuilder()
                .startObject()
                .startObject("properties")
                .startObject("id")
                .field("type","integer")
                .endObject()
                .startObject("username")
                .field("type","keyword")
                .endObject()
                .startObject("password")
                .field("type","keyword")
                .endObject()
                .startObject("nickname")
                .field("type","text")
                .endObject()
                .startObject("money")
                .field("type","long")
                .endObject()
                .startObject("address")
                .field("type","text")
                .endObject()
                .startObject("state")
                .field("type","integer")
                .endObject()
                .endObject()
                .endObject();


        //3. 将settings和mappings封装到一个Request对象
        CreateIndexRequest request = new CreateIndexRequest(index)
                .settings(settings)
                .mapping(type,mappings);

        //4. 通过client对象去连接ES并执行创建索引
        CreateIndexResponse resp = client.indices().create(request, RequestOptions.DEFAULT);

        //5. 输出
        System.out.println("resp:" + resp.toString());

    }

    //添加测试数据
    @Test
    public void bulkCreateDoc() throws IOException {
        //1. 准备多个json数据
        Customer c1 = new Customer();
        c1.setId(1);
        c1.setUsername("haier");
        c1.setPassword("111111");
        c1.setNickname("海尔集团");
        c1.setMoney(2000000L);
        c1.setAddress("青岛");
        c1.setState(1);

        Customer c2 = new Customer();
        c2.setId(2);
        c2.setUsername("lianxiang");
        c2.setPassword("111111");
        c2.setNickname("联想");
        c2.setMoney(1000000L);
        c2.setAddress("联想");
        c2.setState(1);

        Customer c3 = new Customer();
        c3.setId(3);
        c3.setUsername("google");
        c3.setPassword("111111");
        c3.setNickname("谷歌");
        c3.setMoney(1092L);
        c3.setAddress("没过");
        c3.setState(1);

        ObjectMapper mapper = new ObjectMapper();

        String json1 = mapper.writeValueAsString(c1);
        String json2 = mapper.writeValueAsString(c2);
        String json3 = mapper.writeValueAsString(c3);

        //2. 创建Request，将准备好的数据封装进去
        BulkRequest request = new BulkRequest();
        //需要参数: 索引、类型、id 然后调用source方法传入json类型参数
        request.add(new IndexRequest(index,type,c1.getId().toString()).source(json1, XContentType.JSON));
        request.add(new IndexRequest(index,type,c2.getId().toString()).source(json2,XContentType.JSON));
        request.add(new IndexRequest(index,type,c3.getId().toString()).source(json3,XContentType.JSON));

        //3. 用client执行
        BulkResponse resp = client.bulk(request, RequestOptions.DEFAULT);

        //4. 输出结果
        System.out.println(resp.toString());
    }

}
```

### 通过kibana查看创建的索引和添加的数据

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700595-image-20210109094931337.png)

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700598-image-20210109094956162.png)

## 三、客户模块

创建一个名为customer的spring boot的项目。

### 3.1 导入相关依赖

```xml
<dependencies>

    <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>druid-spring-boot-starter</artifactId>
        <version>1.1.23</version>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.mybatis.spring.boot</groupId>
        <artifactId>mybatis-spring-boot-starter</artifactId>
        <version>2.1.4</version>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-devtools</artifactId>
        <scope>runtime</scope>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### 3.2 创建dao层

创建CustomerMapper.java和CustomerMapper.xml。

### 3.3 编写springboot配置文件

```yml
#端口号
server:
  port: 80
  
#数据库相关配置
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/openapi?serverTimezone=UTC
    driver-class-name: com.mysql.cj.jdbc.Driver
    type: com.alibaba.druid.pool.DruidDataSource
    username: root
    password: root
    
#mybatis相关配置
mybatis:
  type-aliases-package: com.zhy.openapi.entity
  mapper-locations: classpath:mapper/*.xml
  configuration:
    map-underscore-to-camel-case: true
```

### 3.4 导入静态资源到static路径下

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700604-image-20210109095911734.png)

### 3.5 创建Customer实体类

```java
@Data
public class Customer implements Serializable {
    /**
     * 主键
     *
     * isNullAble:0
     */
    private Integer id;

    /**
     * 公司名
     * isNullAble:1
     */
    private String username;

    /**
     *
     * isNullAble:1
     */
    private String password;

    /**
     *
     * isNullAble:1
     */
    private String nickname;

    /**
     * 金钱
     * isNullAble:1
     */
    private Long money;

    /**
     * 地址
     * isNullAble:1
     */
    private String address;

    /**
     * 状态
     * isNullAble:1
     */
    private Integer state;
}
```
