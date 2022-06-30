---
title: shiro学习(三)-springboot整合shiro
date: 2020-11-16
tags:
  - spring
  - springboot
  - shiro
categories:
  - spring
  - springboot
  - shiro学习(三)-springboot整合shiro
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702369-SHIRO_APACHE_SECURITY-01.png)

<!--more-->

## 一、认证授权流程

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702372-20201023204342907.png)

## 二、基本环境搭建

### 2.1 数据库表的数据结构

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702375-image-20201123214400779.png)

### 2.2 创建一个普通的springboot项目

### 2.3 导入pom.xml相关依赖

```xml
<dependencies>
    <!--druid数据源-->
    <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>druid-spring-boot-starter</artifactId>
        <version>1.1.23</version>
    </dependency>
    <!--shiro依赖-->
    <dependency>
        <groupId>org.apache.shiro</groupId>
        <artifactId>shiro-spring</artifactId>
        <version>1.5.3</version>
    </dependency>
    <!--ehcache-->
    <dependency>
        <groupId>org.apache.shiro</groupId>
        <artifactId>shiro-ehcache</artifactId>
        <version>1.4.0</version>
    </dependency>
    <!--thymeleaf模板依赖-->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>
    <!--web依赖-->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <!--mybatis-->
    <dependency>
        <groupId>org.mybatis.spring.boot</groupId>
        <artifactId>mybatis-spring-boot-starter</artifactId>
        <version>2.1.4</version>
    </dependency>
    <!--mysql驱动-->
    <dependency>
        <groupId>mysql</groupId>
        <artifactId>mysql-connector-java</artifactId>
        <scope>runtime</scope>
    </dependency>
    <!--lombok插件-->
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

### 2.4 编写springboot配置文件

```yml
spring:
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    type: com.alibaba.druid.pool.DruidDataSource
    username: root
    password: root
    url: jdbc:mysql://localhost:3306/shiro?serverTimezone=UTC
mybatis:
  type-aliases-package: com.zhy.entity
  mapper-locations: classpath:mappers/*.xml
  configuration:
    map-underscore-to-camel-case: true
server:
  port: 8081
```

### 2.5 创建相关包结构

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702378-image-20201122220905148.png)

## 三、编写dao层操作数据库

### 3.1 创建实体类

```java
//用户实体类
public class User {
    //用户id
    private Integer id;
    //用户名
    private String username;
    //密码
    private String password;
    //盐
    private String salt;
    //角色集合
    private List<Roles> role;
}
//角色实体类
public class Roles {

    //角色id
    private Integer id;
    //角色
    private String role;

}
```

### 3.2 编写mapper接口

```java
@Repository
public interface CustomerMapper {
    //根据用户姓名查询用户信息
    public User queryUserByName(String name);
    //根据用户姓名查询用户所具有的角色
    public User queryRolesByName(String name);
    //插入用户
    public int registryUser(User user);
}
```

### 3.3 编写mapper.xml

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.zhy.dao.CustomerMapper">

    <select id="queryUserByName" resultType="user">
        select * from t_user where username = #{name};
    </select>

    <resultMap id="userMap" type="user">
        <id column="uid" property="id"/>
        <result column="username" property="username"/>

        <collection property="role" javaType="list" ofType="Roles">
            <result column="rrole" property="role"/>
        </collection>
    </resultMap>

    <select id="queryRolesByName" resultMap="userMap">
        select u.id uid,u.username username,r.role rrole
        from t_user u
        left join t_user_roles ur on u.id = ur.user_id
        left join t_roles r on r.id = ur.roles_id
        where u.username = #{name};
    </select>
    
    <insert id="registryUser" parameterType="user">
        insert into t_user (username, password, salt)
        values (#{username},#{password},#{salt});
    </insert>
</mapper>
```

> 由于一个用户可能有多个角色所以可以通过resultMap将一个用户的多个角色映射到user类中的list集合中。

## 四、Service层编写

### 4.1 编写Service接口

```java
public interface CustomerService {
    //根据用户姓名查询用户信息
    public User queryUserByName(String name);
    //根据用户姓名查询用户所具有的角色
    public User queryRolesByName(String name);
    //插入用户
    public int registryUser(User user);
}
```

### 4.2 编写Service的实现类

```java
@Service
public class CustomerServiceImpl implements CustomerService{
    @Resource
    private CustomerMapper customerMapper;

    @Override
    public User queryUserByName(String name) {
        return customerMapper.queryUserByName(name);
    }

    @Override
    public User queryRolesByName(String name) {
        return customerMapper.queryRolesByName(name);
    }

    @Override
    public int registryUser(User user) {
        //随机生成salt
        String salt = UUID.randomUUID().toString().substring(0,7);
        //给user设置salt
        user.setSalt(salt);
        //使用MD5算法对密码进行加密
        String password = new Md5Hash(user.getPassword(), salt, 1024).toHex();
        //给user设置加密后的密码
        user.setPassword(password);
        return customerMapper.registryUser(user);
    }
}
```

> 注册时需要对用户的密码进行加密：
>
> 1. 通过UUID生成随机盐
> 2. 通过Md5Hash对用户密码进行加密
>    - 参数：1. 密码 2. 盐 3. 散列次数

### 4.3 测试

```java
@SpringBootTest
class CustomerMapperTest {
    @Resource
    private CustomerService customerService;

    @Test
    void queryUserByName() {
        User user1 = customerService.queryUserByName("jone");
        System.out.println(user1);

    }
    @Test
    void queryRolesByName() {
        User user = customerMapper.queryRolesByName("zhy");
        System.out.println(user);

    }
    @Test
    void uuid(){
        UUID uuid = UUID.randomUUID();
        String s = uuid.toString().substring(0,6);
        System.out.println(s);
    }

    @Test
    void registryUser(){
        User user = new User();
        user.setUsername("jone");
        user.setPassword("159456");

        int i = customerService.registryUser(user);
        System.out.println(i);
    }
}
```

## 五、编写Shiro相关配置类

### 5.1 编写自定义Realm

> 自定义Realm需要继承`AuthorizingRealm`并实现其中的两个方法：`doGetAuthorizationInfo`和`doGetAuthenticationInfo`分别进行**权限的校验**和**身份的认证**。
>
> - `doGetAuthenticationInfo`（身份的认证）：
>
>   此方法需要返回一个`AuthenticationInfo`接口的实现类，也就是`SimpleAuthenticationInfo`，此实现类可通过有参的构造方法创建，需要提供的参数有：
>
>   1. 用户名
>   2. 从数据库中查询出来的密码（shiro会自动将此密码与用户输入的密码进行比较）
>   3. 原加密用户密码所用的盐（从数据库中查出）
>   4. realm的名字
>
> - `doGetAuthorizationInfo`（权限的校验）：
>
>   此方法需要返回一个`AuthorizationInfo`接口的实现类，也就是`SimpleAuthorizationInfo`，
>
>   通过调用此实现类的`addRole()`方法可以向当前用户添加角色；通过调用此实现类的`addStringPermissions()`方法可以向当前用户添加权限。
>
> 

```java
public class CustomerRealm extends AuthorizingRealm {
    @Resource
    private CustomerService customerService;

    @Override
    protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principalCollection) {
        //获取用户名
        String primaryPrincipal = (String) principalCollection.getPrimaryPrincipal();
        //根据用户名查询用户权限
        User user = customerService.queryRolesByName(primaryPrincipal);
        List<Roles> roles = user.getRole();
        //System.out.println("正在进行权限认证");
        if (roles != null){
            SimpleAuthorizationInfo simpleAuthorizationInfo = new SimpleAuthorizationInfo();
            roles.forEach(role -> {
                //对用户的权限进行添加
                simpleAuthorizationInfo.addRole(role.getRole());
                //System.out.println(role.getRole());
            });

            return simpleAuthorizationInfo;
        }
        return null;

    }

    @Override
    protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken authenticationToken) throws AuthenticationException {
        //获取用户名
        String principal = (String) authenticationToken.getPrincipal();
        //根据用户名查询用户
        User user = customerService.queryUserByName(principal);
        if (user.getUsername().equals(principal)){
            //参数：1.用户名 2.密码 3.salt 4.realm名
            SimpleAuthenticationInfo simpleAuthenticationInfo = new SimpleAuthenticationInfo(principal,user.getPassword(), ByteSource.Util.bytes(user.getSalt()),this.getName());
            return simpleAuthenticationInfo;
        }
        return null;

    }
}
```

### 5.2 编写ShiroConfig将shiro注入到spring中

> 1. 创建`ShiroFilterFactoryBean`拦截所有请求，并将`DefaultWebSecurityManager`注入到此类中
>
>    通过`ShiroFilterFactoryBean`可以设置登录页面的url、为授权时的url、需要拦截的页面
>
> 2. 创建`DefaultWebSecurityManager`，并将Realm注入到此类中
>
> 3. 创建`Realm`，return自定义realm的实现类
>
>    可以将realm默认凭证校验匹配器修改为`HashedCredentialsMatcher`，并设置其使用的算法和散列次数。
>    
>    可通过Realm的`setCacheManager()`开启缓存，以缓解数据库压力。

```java
@Configuration
public class ShiroConfig {

    //1.创建ShiroFilter 拦截所有请求
    @Bean
    public ShiroFilterFactoryBean shiroFilterFactoryBean(DefaultWebSecurityManager defaultWebSecurityManager){

        ShiroFilterFactoryBean shiroFilterFactoryBean = new ShiroFilterFactoryBean();
        //给ShiroFilter设置安全管理器
        shiroFilterFactoryBean.setSecurityManager(defaultWebSecurityManager);
        LinkedHashMap<String,String> map = new LinkedHashMap<>();//这里最好用有序的map
        
        //map.put("/admin","roles[admin,user]"); 这里的角色是and关系，想用or需要重写方法
        //将map集合中的权限信息放入ShiroFilter中
        
        //设置user角色权限
        map.put("/","roles[user]");
        map.put("/user_page/form-step","roles[user]");
        map.put("/user_page/table","roles[user]");
        map.put("/admin/**","roles[admin]");



        //静态资源过滤
        map.put("/api/**","anon");
        map.put("/css/**","anon");
        map.put("/images/**","anon");
        map.put("/js/**","anon");
        map.put("/lib/**","anon");
//        map.put("/admin/**","anon");

        //设置登录页面
        map.put("/login","anon");
        map.put("/verifyCode","anon");
        map.put("/403","anon");
//        map.put("/admin/403","anon");
        map.put("/user_page/login-3","anon");
        map.put("/register","anon");
        map.put("/**","authc");//最后再进行全部资源的认证
        shiroFilterFactoryBean.setFilterChainDefinitionMap(map);
        
        
        //设置登录界面的url
        shiroFilterFactoryBean.setLoginUrl("/login");
        //设置无权限时的url
        shiroFilterFactoryBean.setUnauthorizedUrl("/unauthorized");

        return shiroFilterFactoryBean;
    }

    //2.创建安全管理器
    @Bean
    public DefaultWebSecurityManager defaultWebSecurityManager(Realm realm){

        DefaultWebSecurityManager defaultWebSecurityManager = new DefaultWebSecurityManager();
        //给安全管理器设置自定义realm
        defaultWebSecurityManager.setRealm(realm);
        return defaultWebSecurityManager;
    }

    //3.创建自定义realm
    @Bean
    public Realm realm(){
        CustomerRealm customerRealm = new CustomerRealm();
        //创建hash凭证匹配器
        HashedCredentialsMatcher credentialsMatcher = new HashedCredentialsMatcher();
        //设置加密算法为MD5
        credentialsMatcher.setHashAlgorithmName("MD5");
        //设置散列次数
        credentialsMatcher.setHashIterations(1024);
        //修改凭证校验匹配器（原始是通过equals方法进行比较的）
        customerRealm.setCredentialsMatcher(credentialsMatcher);
        
        //开启缓存
        userRealm.setCacheManager(new EhCacheManager());
        userRealm.setCachingEnabled(true);//开启全局缓存
        userRealm.setAuthenticationCachingEnabled(true);//开启认证缓存
        userRealm.setAuthenticationCacheName("authenticationCache");
        userRealm.setAuthorizationCachingEnabled(true);//开启授权缓存
        userRealm.setAuthorizationCacheName("authorizationCache");
        
        return customerRealm;
    }
}
```

> 两种授权方式的配置：
>
> 如果通过注解的方式对接口进行授权（如：@RequiresRoles(value = {"admin","common_user"},logical = Logical.OR)），则需要在ShiroConfig中添加两个配置使注解生效：
>
> ```java
> @Bean
> public DefaultAdvisorAutoProxyCreator advisorAutoProxyCreator() {
>     DefaultAdvisorAutoProxyCreator advisorAutoProxyCreator = new DefaultAdvisorAutoProxyCreator();
>     advisorAutoProxyCreator.setProxyTargetClass(true);
>     return advisorAutoProxyCreator;
> }
> @Bean
> public AuthorizationAttributeSourceAdvisor authorizationAttributeSourceAdvisor(DefaultWebSecurityManager defaultWebSecurityManager) {
>     AuthorizationAttributeSourceAdvisor authorizationAttributeSourceAdvisor = new AuthorizationAttributeSourceAdvisor();
>     authorizationAttributeSourceAdvisor.setSecurityManager(defaultWebSecurityManager);
>     return authorizationAttributeSourceAdvisor;
> }
> ```
>
> 如果是通过`ShiroFilterFactoryBean`进行授权则不需要添加如上配置。

## 六、编写Controller层

```java
@Controller
@CrossOrigin
public class CustomerController {
    //页面跳转
    @GetMapping("/index")
    public String toIndex(){

        return "index";
    }

    @GetMapping("/login")
//    @ResponseBody
    public String toLogin(){

        return "login";
    }

    @GetMapping("/admin")
    @RequiresRoles(value = {"admin"})
    public String toAdmin(){

        return "admin";
    }

    @GetMapping("/common_user")
    @RequiresRoles(value = {"admin","common_user"},logical = Logical.OR)
    public String toUser(){

        return "common_user";
    }
//    @GetMapping("/unauthorized")
    @ResponseBody
    @ExceptionHandler(AuthorizationException.class)
    public String toUnauthorized(){
        return "您没有权限访问";
    }
    
    //功能实现
    @GetMapping("/logout")
    @RequiresRoles(value = {"admin","common_user"},logical = Logical.OR)
    public String LoginOut(){

        Subject subject = SecurityUtils.getSubject();
        subject.logout();

        return "login";
    }
    
    @PostMapping("/login")
//    @ResponseBody
    public String Login(@RequestBody Map map){
        String username = (String) map.get("username");
        String password = (String) map.get("password");
        System.out.println("login");
        Subject subject = SecurityUtils.getSubject();
        System.out.println(username+":"+password);

        try {
            subject.login(new UsernamePasswordToken(username,password));
            System.out.println("success");
            return "index";
        } catch (AuthenticationException e) {
            e.printStackTrace();
        }
        return "login";
    }

    @GetMapping("/onLogin")
    @ResponseBody
//    @RequiresRoles(value = {"admin","common_user"},logical = Logical.OR)
    public String Login(){
        return "onLogin";

    }
}
```

> 注：如果通过注解的形式对接口进行授权，若用户没有权限只会抛出异常，而不会走`shiroFilterFactoryBean.setUnauthorizedUrl("/unauthorized")`中设置的未授权路径，所以可以通过`@ExceptionHandler(AuthorizationException.class)`注解来捕获此异常进行处理。