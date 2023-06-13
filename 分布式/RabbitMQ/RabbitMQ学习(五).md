---
title: RabbitMQ学习(五)-RabbitMQ的应用
date: 2021-1-13
tags:
  - 微服务
  - RabbitMQ学习(五)-RabbitMQ的应用
  - RabbitMQ
  - spring
  - springboot
categories:
  - 微服务
  - RabbitMQ
  - RabbitMQ学习(五)-RabbitMQ的应用
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655044874-1_UnYL-2r54_7AnEwQv0cVxA.png)

<!--more-->

将之前的 spring boot 整合 ElasticSearch 的项目再整合上 RabbitMQ。

## 一、修改 customer 模块

### 1.1 导入相关依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

### 1.2 编写配置文件

```yml
spring:
# rabbitMQ
  rabbitmq:
    host: 192.168.31.138
    port: 5672
    password: test
    username: test
    virtual-host: /test
```

### 1.3 编写配置类

```java
@Configuration
public class RabbitMQConfig {
    @Bean
    public TopicExchange topicExchange(){
        return new TopicExchange("openapi-customer-exchange",true,false);
    }

    @Bean
    public Queue queueO(){
        return new Queue("openapi-customer-queue");
    }

    @Bean
    public Binding binding(TopicExchange topicExchange,Queue queue){
        return BindingBuilder.bind(queue).to(topicExchange).with("openapi.customer.*");
    }
}
```

### 1.4 修改 Service 层

从之前通过 RestTemplate 传递信息，变为 通过 RabbitMQ 传递消息。

```java
@Service
@Slf4j
public class CustomerServiceImpl implements CustomerService {

    @Autowired
    private RestTemplate restTemplate;

    @Autowired
    private CustomerMapper customerMapper;

    @Autowired
    private RabbitTemplate rabbitTemplate;

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

    @Override
    @Transactional
    public void addCustomer(Customer customer) {
        //1.调用mapper添加数据到mysql 中
        Integer count = customerMapper.save(customer);

        //2.判断添加是否成功
        if (count != 1){
            log.error("添加用户失败！：customer = {}",customer);
            throw new RuntimeException("添加用户失败！");
        }


        //3.调用搜索模块，添加数据到ES
        rabbitTemplate.convertAndSend("openapi-customer-exchange","openapi.customer.add",JSON.toJSON(customer));


       /*
       //3.调用搜索模块，添加数据到ES
       //3.1准备请求参数和请求头信息
        String json = JSON.toJSON(customer);//将参数转为json字符串
        HttpHeaders headers = new HttpHeaders();//设置请求头
        headers.setContentType(MediaType.parseMediaType("application/json;charset=utf-8"));
        //headers.setContentType(MediaType.APPLICATION_JSON_UTF8);
        HttpEntity<String> entity = new HttpEntity<>(json, headers);//将参数和请求头封装到HttpEntity中

        //3.2使用restTemplate调用搜索模块
        restTemplate.postForObject("http://localhost:8080/search/customer/add", entity, String.class);
*/
    }
}
```

## 二、修改 search 模块

### 2.1 导入相关依赖

同上。

### 2.2 编写配置文件

同上。

### 2.3 编写配置类

同上。

### 2.4 编写 json 工具类

添加一个将 json 转为对象的静态方法。

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

    public static <T> T parseJSON(String json,Class<T> clazz){
        ObjectMapper mapper = new ObjectMapper();
        try {
            return mapper.readValue(json,clazz);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return null;
        }
    }

}
```

### 2.5 编写消费者（ Listener ）

```java
@Component
public class CustomerListener {

    @Autowired
    private CustomerService customerService;

    @RabbitListener(queues = "openapi-customer-queue")
    private void consume(String json, Channel channel, Message message) throws IOException {
        //1.获取RoutingKey
        String routingKey = message.getMessageProperties().getReceivedRoutingKey();

        //2.使用switch 判断传来的业务是什么操作
        switch (routingKey){
            case "openapi.customer.add":
                //3.调用service完成添加
                customerService.saveCustomer(JSON.parseJSON(json,Customer.class));
                channel.basicAck(message.getMessageProperties().getDeliveryTag(),false);

        }

    }
}
```