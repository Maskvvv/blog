---
title: Elasticsearch和springboot整合练习(三)-添加用户
date: 2021-01-09
tags:
  - springboot
  - Elasticsearch
  - Elasticsearch和springboot整合练习(三)-添加用户
categories:
  - Elasticsearch
  - Elasticsearch和springboot整合练习(三)-添加用户

---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700914-elasticsearch-logo.png)

<!-- more -->

## 一、search模块的实现

### 1.1 service层

向CustomerService接口中添加存储客户的抽象方法saveCustomer()。

```java
public interface CustomerService {

    String searchCustomerByQuery(Map<String,Object> param) throws IOException, InvocationTargetException, IllegalAccessException;

    void saveCustomer(Customer customer) throws IOException;

}
```

在CustomerServiceImpl实现此抽象方法。

```java
@Override
public void saveCustomer(Customer customer) throws IOException {
    //1.创建IndexRequest
    IndexRequest request = new IndexRequest(index, type, customer.getId() + "");

    //2.封装数据
    request.source(JSON.toJSON(customer), XContentType.JSON);

    //3.执行添加
    IndexResponse response = client.index(request, RequestOptions.DEFAULT);

    //4.判断添加是否成功（失败抛出异常）
    if (!"created".equalsIgnoreCase(response.getResult().toString())){
        log.error("向ES添加客户异常：index = {},type = {},customer = {}",index,type,customer);
        throw new RuntimeException("向ES添加客户异常");
    }
}
```

#### 测试

```java
@Test
void saveCustomer() throws IOException {
    Customer customer = new Customer();
    customer.setAddress("北京");
    customer.setId(4);
    customer.setUsername("kuaishou");
    customer.setPassword("123456");
    customer.setNickname("快手");
    customer.setState(1);
    service.saveCustomer(customer);

}
```

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700910-image-20210109141301747.png)

### 1.2 controller层

```java
@PostMapping(value = "/add")
public void add(@RequestBody Customer customer) throws IOException {
    service.saveCustomer(customer);
}
```

#### 测试

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700905-image-20210109144845279.png)

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700901-image-20210109144904926.png)

## 二、customer模块的实现

### 2.1 mapper层

#### CustomerMapper.java

```java
@Repository
public interface CustomerMapper {
    Integer save(Customer customer);
}
```

#### CustomerMapper.xml

> `useGeneratedKeys=“true” keyProperty=“id”`：
>
> - useGeneratedKeys设置为 true 时，表示如果插入的表id以自增列为主键，则允许 JDBC 支持自动生成主键，并可将自动生成的主键id返回。
> - useGeneratedKeys参数只针对 insert 语句生效，默认为 false；

```xml
<mapper namespace="com.zhy.openapi.mapper.CustomerMapper">
    <insert id="save" parameterType="customer" useGeneratedKeys="true" keyProperty="id">
        insert into
        customer
        (id, username, password, nickname, money, address, state)
        values (#{id},#{username},#{password},#{nickname},#{money},#{address},#{state})
    </insert>
</mapper>
```

#### 测试

```java
@SpringBootTest
class CustomerMapperTest {
    @Autowired
    private CustomerMapper customerMapper;
    @Test
    void save() {
        Customer customer = new Customer();
        customer.setAddress("北京");
        customer.setId(4);
        customer.setUsername("kuaishou");
        customer.setPassword("123456");
        customer.setNickname("快手");
        customer.setState(1);
        Integer save = customerMapper.save(customer);
        System.out.println(save);
    }
}
```

### 2.2 service层

#### CustomerService.java

```java
public interface CustomerService {
    String findCustomerByQuery(Map<String,Object> parameter);
    void addCustomer(Customer customer);
}
```

#### CustomerServiceImpl.java

```java
@Override
@Transactional//事务注解
public void addCustomer(Customer customer) {
    //1.调用mapper添加数据到mysql 中
    Integer count = customerMapper.save(customer);

    //2.判断添加是否成功
    if (count != 1){
        log.error("添加用户失败！：customer = {}",customer);
        throw new RuntimeException("添加用户失败！");
    }

    //3.调用搜索模块，添加数据到ES

    //3.1准备请求参数和请求头信息
    String json = JSON.toJSON(customer);//将参数转为json字符串
    HttpHeaders headers = new HttpHeaders();//设置请求头
    headers.setContentType(MediaType.parseMediaType("application/json;charset=utf-8"));
    //headers.setContentType(MediaType.APPLICATION_JSON_UTF8);
    HttpEntity<String> entity = new HttpEntity<>(json, headers);//将参数和请求头封装到HttpEntity中

    //3.2使用restTemplate调用搜索模块
    restTemplate.postForObject("http://localhost:8080/search/customer/add", entity, String.class);
}
```

#### 测试

```java
@Test
void save() {
    Customer customer = new Customer();
    customer.setAddress("test");
    customer.setUsername("test");
    customer.setPassword("test");
    customer.setNickname("test");
    customer.setState(1);
    customerService.addCustomer(customer);
}
```

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700895-image-20210109152151165.png)

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700892-image-20210109152209908.png)

### 2.3 controller层

#### ResultVO.java

创建一个ResultVO类型对象，封装返回结果。

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResultVO {
    private boolean status;
    private String message;
    private Object result;

    public ResultVO(boolean status, String message) {
        this.status = status;
        this.message = message;
    }
}
```

#### CustomerController.java

```java
@PostMapping("/add")
public ResultVO add(Customer customer){
    try {
        //1.调用service执行添加
        customerService.addCustomer(customer);
        //2.返回json（成功）
        return new ResultVO(true,"add success");
    } catch (RuntimeException e) {
        e.printStackTrace();
        //3.返回json（成功）
        return new ResultVO(false,e.getMessage());
    }
}
```

