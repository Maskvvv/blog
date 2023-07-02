---
title: Elasticsearch和springboot整合练习(二)-查询用户
date: 2021-01-08
tags:
  - springboot
  - Elasticsearch
  - Elasticsearch和springboot整合练习(二)-查询用户
categories:
  - Elasticsearch
  - Elasticsearch和springboot整合练习(二)-查询用户
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700699-elasticsearch-logo.png)

<!-- more -->

## 一、search模块的实现

### 1.1 search模块最后包结构

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700702-image-20210109100247154.png)

### 1.2 JSON工具类

创建可以将对象转为json字符串的工具类JSON.java。

```java
public class JSON {
    public static String toJSON(Object src){
        ObjectMapper mapper = new ObjectMapper();
        try {
            return mapper.writeValueAsString(src);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return "";
        }
    }
}
```

### 1.3 vo层

编写LayUITableVO.java实体类，以便提供给layui表格指定的数据格式。

```java
@Data
public class LayUITableVO<T> {
    private Integer code = 0;
    private String msg = "";
    private Long count;
    private List<T> data;
}
```

### 1.4 service

编写CustomerService接口和他的实现类CustomerServiceImpl，来根据给定的参数：page、limit、name、state返回查询结果。

#### CustomerService

```java
public interface CustomerService {
    String searchCustomerByQuery(Map<String,Object> param) throws IOException, InvocationTargetException, IllegalAccessException;
}
```

#### CustomerServiceImpl

```java
@Service
public class CustomerServiceImpl implements CustomerService {

    private String index = "openapi_customer";
    private String type = "customer";

    @Autowired
    private RestHighLevelClient client;

    @Override
    public String searchCustomerByQuery(Map<String, Object> param) throws IOException, InvocationTargetException {

        //1.searchRequest
        SearchRequest request = new SearchRequest(index);
        request.types(type);

        //2.封装查询条件
        SearchSourceBuilder source = new SearchSourceBuilder();
        Object name = param.get("name");
        if (!StringUtils.isEmpty(name)){
            source.query(QueryBuilders.termQuery("username",name));
        }

        Object state = param.get("state");
        if (state != null){
            source.query(QueryBuilders.termQuery("state",state));
        }

        Integer page = (Integer) param.get("page");
        Integer limit = (Integer) param.get("limit");

        //起始那条数据
        source.from((page - 1) * limit);
        source.size(limit);

        request.source(source);

        //3.执行查询
        SearchResponse response = client.search(request, RequestOptions.DEFAULT);

        //4.封装数据
        LayUITableVO<Customer> vo = new LayUITableVO<>();
        vo.setCount(response.getHits().getTotalHits());

        List<Customer> data = new ArrayList<>();
        for (SearchHit hit : response.getHits().getHits()) {
            Customer customer = new Customer();
            try {
                BeanUtils.populate(customer,hit.getSourceAsMap());
            } catch (Exception e) {
                e.printStackTrace();
            }
            data.add(customer);
        }
        vo.setData(data);

        //5.返回数据
        return JSON.toJSON(vo);
    }
}
```

### 1.5 controller层

```java
@RestController
@RequestMapping("/search/customer")
public class CustomerController {

    @Autowired
    private CustomerService service;

    @PostMapping(value = "/table",produces = "application/json;charset=utf-8")
    public String table(@RequestBody Map<String,Object> param) throws IllegalAccessException, IOException, InvocationTargetException {
        String result = service.searchCustomerByQuery(param);
        return result;
    }

}
```

> 通过**@PostMapping**的**produces**属性可以指定返回值的数据类型和解码方式。

### 1.6 通过postman测试编写的接口

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700710-image-20210109101742690.png)

## 二、customer模块实现

### 2.1 customer模块最后包结构

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700725-image-20210109101957976.png)

### 2.1 编写RestTemplateConfig配置类将RestTemplate注入到spring中

通过RestTemplate我们可以调用search中的接口来获取数据。

```java
@Configuration
public class RestTemplateConfig {
    @Bean
    public RestTemplate restTemplate(){
        return new RestTemplate();
    }
}
```

### 2.2 json工具类

```java
public class JSON {
    public static String toJSON(Object src){
        ObjectMapper mapper = new ObjectMapper();
        try {
            return mapper.writeValueAsString(src);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return "";
        }
    }
}
```

### 2.3 service层

编写CustomerService接口和他的实现类CustomerServiceImpl，通过RestTemplate向search模块中的接口发送请求来获取数据。

#### CustomerService

```java
public interface CustomerService {
    String findCustomerByQuery(Map<String,Object> parameter);
}
```

#### CustomerServiceImpl

> RestTemplate使用步骤：
>
> 1. 创建HttpHeaders类型对象调用setContentType()方法设置请求头
> 2. 创建HttpEntity卡类型的对象将请求参数和请求头封装到其中
> 3. 通过restTemplate的postForObject方法并传入参数：请求地址、HttpEntity类型对象、请求后的返回值类型，来获取请求后的数据。

```java
@Service
public class CustomerServiceImpl implements CustomerService {

    @Autowired
    private RestTemplate restTemplate;

    @Override
    public String findCustomerByQuery(Map<String, Object> parameter) {
        //1.准备请求参数和请求头信息
        String json = JSON.toJSON(parameter);//将参数转为json字符串
        HttpHeaders headers = new HttpHeaders();//设置请求头
        //headers.setContentType(MediaType.parseMediaType("application/json;charset=utf-8"));
        headers.setContentType(MediaType.APPLICATION_JSON_UTF8);
        HttpEntity<String> entity = new HttpEntity<>(json, headers);//将参数和请求头封装到HttpEntity中
        //2.使用restTemplate调用搜索模块
        String result = restTemplate.postForObject("http://localhost:8080/search/customer/table", entity, String.class);
        return result;
    }
}
```

### 2.4 controller层

```java
@RestController
@RequestMapping("/sys/customer")
public class CustomerController {
    @Autowired
    private CustomerService customerService;

    @GetMapping(value = "/table",produces = "application/json;charset=utf-8")
    public String table(@RequestParam(defaultValue = "1") Integer page, @RequestParam(defaultValue = "10") Integer limit,String name, Integer state){
        //封装数据
        Map<String,Object> map = new HashMap<>();
        map.put("page",page);
        map.put("limit",limit);
        map.put("name",name);
        map.put("state",state);

        //调用service
        String customerByQuery = customerService.findCustomerByQuery(map);
        return customerByQuery;
    }
}
```

### 2.5 最后页面呈现效果

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700731-image-20210109104309814.png)