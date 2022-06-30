---
title: shiro学习(一)
date: 2020-11-13
tags:
  - spring
  - springboot
  - shiro
categories:
  - spring
  - springboot
  - shiro学习(一)
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702238-SHIRO_APACHE_SECURITY-01.png)

<!-- more -->

## 一、权限控制

### 1.1 什么是权限控制

基本上涉及到用户参与的系统都要进行权限管理，权限管理属于系统安全的范畴，权限管理实现对用户访问系统的控制，**按照安全规则或者安全策略控制用户可以访问而且只能访问自己被授权的资源。**

权限管理包括用户**身份认证**和**授权**两部分，简称**认证授权**。对于需要访问控制的资源用户首先经过身份认证，认证通过后用户具有该资源的访问权限方可访问。

### 1.2 什么是身份验证

**身份认证**，就是判断一个用户是否为合法用户的处理过程。最常用的简单身份认证方式是系统通过核对用户**输入的用户名和口令**，看其是否与系统中存储的该用户的用户名和口令一致，来判断用户身份是否正确。对于采用指纹等系统，则出示指纹；对于硬件Key等刷卡系统，则需要刷卡。

### 1.3 什么是授权

**授权，即访问控制**，控制谁能访问啷些资源。主体进行身份认证后需要分配权限方可访问系统的资源，对于某些资源没有权限是无法访问的。

## 二、Shiro简介

Apache Shiro 是 Java 的一个安全框架。目前，使用 Apache Shiro 的人越来越多，因为它相当简单，对比 Spring Security，可能没有 Spring Security 做的功能强大，但是在实际工作时可能并不需要那么复杂的东西，所以使用小而简单的 Shiro 就足够了。

Shiro 可以非常容易的开发出足够好的应用，其不仅可以用在 JavaSE 环境，也可以用在 JavaEE 环境。Shiro 可以帮助我们完成：认证、授权、加密、会话管理、与 Web 集成、缓存等。

## 三、Shiro的核心架构

![Shiro的核心架构](http://qiniu.zhouhongyin.top/2022/06/08/1654702252-ShiroArchitecture.png)

- **Subject**：主体，可以看到主体可以是任何可以与应用交互的 “用户”；
- **SecurityManager**：相当于 SpringMVC 中的 DispatcherServlet 或者 Struts2 中的 FilterDispatcher；是 Shiro 的心脏；所有具体的交互都通过 SecurityManager 进行控制；它管理着所有 Subject、且负责进行认证和授权、及会话、缓存的管理。
- **Authenticator**：认证器，负责主体认证的，这是一个扩展点，如果用户觉得 Shiro 默认的不好，可以自定义实现；其需要认证策略（Authentication Strategy），即什么情况下算用户认证通过了；
- **Authrizer**：授权器，或者访问控制器，用来决定主体是否有权限进行相应的操作；即控制着用户能访问应用中的哪些功能；
- **Realm**：可以有 1 个或多个 Realm，可以认为是安全实体数据源，即用于获取安全实体的；可以是 JDBC 实现，也可以是 LDAP 实现，或者内存实现等等；由用户提供；注意：Shiro 不知道你的用户 / 权限存储在哪及以何种格式存储；所以我们一般在应用中都需要实现自己的 Realm；
- **SessionManager**：如果写过 Servlet 就应该知道 Session 的概念，Session 呢需要有人去管理它的生命周期，这个组件就是 SessionManager；而 Shiro 并不仅仅可以用在 Web 环境，也可以用在如普通的 JavaSE 环境、EJB 等环境；所以呢，Shiro 就抽象了一个自己的 Session 来管理主体与应用之间交互的数据；这样的话，比如我们在 Web 环境用，刚开始是一台 Web 服务器；接着又上了台 EJB 服务器；这时想把两台服务器的会话数据放到一个地方，这个时候就可以实现自己的分布式会话（如把数据放到 Memcached 服务器）；
- **SessionDAO**：DAO 大家都用过，数据访问对象，用于会话的 CRUD，比如我们想把 Session 保存到数据库，那么可以实现自己的 SessionDAO，通过如 JDBC 写到数据库；比如想把 Session 放到 Memcached 中，可以实现自己的 Memcached SessionDAO；另外 SessionDAO 中可以使用 Cache 进行缓存，以提高性能；
- **CacheManager**：缓存控制器，来管理如用户、角色、权限等的缓存的；因为这些数据基本上很少去改变，放到缓存中后可以提高访问的性能
- **Cryptography**：密码模块，Shiro 提高了一些常见的加密组件用于如密码加密 / 解密的。

## 四、Shiro的认证（验证）

### 4.1 身份验证

**身份验证**，即在应用中谁能证明他就是他本人。一般提供如他们的身份 ID 一些标识信息来表明他就是他本人，如提供身份证，用户名 / 密码来证明。在 shiro 中，用户需要提供 `principals` （身份）和 `credentials`（证明）给 shiro，从而应用能验证用户身份。

### 4.2 Shiro中认证的关键对象

- **Subject**：主体访问系统的用户，主体可以是用户、程序等,进行认证的都称为主体；
- **principals**：身份，即主体的标识属性，可以是任何东西，如用户名、邮箱等，唯一即可。一个主体可以有多个 principals，但只有一个 Primary principals，一般是用户名 / 密码 / 手机号。
- **credentials**：证明 / 凭证，即只有主体知道的安全值，如密码 / 数字证书等。最常见的 principals 和 credentials 组合就是用户名 / 密码了。接下来先进行一个基本的身份认证。

### 4.3 测试

![包结构](http://qiniu.zhouhongyin.top/2022/06/08/1654702256-image-20201114194047959.png)

#### 4.3.1 创建一个普通的Maven工程

#### 4.3.2 导入pox.xml依赖

```xml
<dependencies>
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.13</version>
    </dependency>
    <dependency>
        <groupId>org.apache.shiro</groupId>
        <artifactId>shiro-core</artifactId>
        <version>1.5.3</version>
    </dependency>
</dependencies>
```

#### 4.3.3 创建shrio的配置文件shiro.ini

> .ini 是shiro的配置文件，可以在前期提供学习使用，户名 / 密码硬编码在 ini 配置文件，以后需要改成如数据库存储，且密码需要加密存储。

```ini
[users]
zhy=123
mike=456
jone=789
```

#### 4.3.4 编写测试类TestAuthenticator

> - 首先通过 `new IniSecurityManagerFactory` 并指定一个 `ini` 配置文件来创建一个 `SecurityManager` 工厂；
> - 接着获取 `SecurityManager` 并绑定到 `SecurityUtils`，这是一个全局设置，设置一次即可；
> - 通过 `SecurityUtils` 得到 `Subject`，其会自动绑定到当前线程；如果在 web 环境在请求结束时需要解除绑定；然后获取身份验证的 `Token`，如用户名 / 密码；
> - 调用 `subject.login` 方法进行登录，其会自动委托给 `SecurityManager.login` 方法进行登录；
> - 如果身份验证失败请捕获 `AuthenticationException` 或其子类，常见的如： `DisabledAccountException`（禁用的帐号）、`LockedAccountException`（锁定的帐号）、`UnknownAccountException`（错误的帐号）、`ExcessiveAttemptsException`（登录失败次数过多）、`IncorrectCredentialsException` （错误的凭证）、`ExpiredCredentialsException`（过期的凭证）等，具体请查看其继承关系；对于页面的错误消息展示，最好使用如 “用户名 / 密码错误” 而不是 “用户名错误”/“密码错误”，防止一些恶意用户非法扫描帐号库；
> - 最后可以调用 `subject.logout` 退出，其会自动委托给 `SecurityManager.logout` 方法退出。

```java
public class TestAuthenticator {

    public static void main(String[] args) {
        //1.创建安全管理器对象、
        DefaultSecurityManager securityManager = new DefaultSecurityManager();

        //2.给安全管理器设置realm
        securityManager.setRealm(new IniRealm("classpath:shiro.ini"));

        //3.给SecurityUtils是指安全管理器
        SecurityUtils.setSecurityManager(securityManager);

        //4.通过SecurityUtils获取Subject
        Subject subject = SecurityUtils.getSubject();

        //5.创建token令牌
        UsernamePasswordToken token = new UsernamePasswordToken("zhy","123");

        try {
            //6.用户验证
            subject.login(token);
            System.out.println(subject.isAuthenticated());
        } catch (UnknownAccountException e) {
            e.printStackTrace();
            System.out.println("username error!");
        } catch (IncorrectCredentialsException e) {
            e.printStackTrace();
            System.out.println("password error!");
        }
    }
}
```

### 4.4 Shiro中认证流程分析

> 1. 首先调用 `Subject.login(token)` 进行登录，其会自动委托给 `Security Manager`，调用之前必须通过 `SecurityUtils.setSecurityManager()` 设置；
> 2. `SecurityManager` 负责真正的身份验证逻辑；它会委托给 `Authenticator` 进行身份验证；
> 3. `Authenticator` 才是真正的身份验证者，`Shiro API` 中核心的身份认证入口点，此处可以自定义插入自己的实现；
> 4. `Authenticator` 可能会委托给相应的 `AuthenticationStrategy` 进行多 `Realm` 身份验证，默认 `ModularRealmAuthenticator` 会调用 `AuthenticationStrategy` 进行多 `Realm` 身份验证；
> 5. `Authenticator `会把相应的 `token` 传入 `Realm`，从 `Realm` 获取身份验证信息，如果没有返回 / 抛出异常表示身份验证失败了。此处可以配置多个 `Realm`，将按照相应的顺序及策略进行访问。

![身份认证流程图](http://qiniu.zhouhongyin.top/2022/06/08/1654702262-4.png)

#### 4.4.1 Realm

**Realm：**域，`Shiro` 从 `Realm `获取安全数据（如用户、角色、权限），就是说 `SecurityManager` 要验证用户身份，那么它需要从 `Realm` 获取相应的用户进行比较以确定用户身份是否合法；也需要从 `Realm` 得到用户相应的角色 / 权限进行验证用户是否能进行操作；可以把 `Realm` 看成 `DataSource`，即安全数据源。如我们之前的 `ini` 配置方式将使用 `org.apache.shiro.realm.text.IniRealm`。

#### 4.4.2 Shiro提供的Realm

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702265-image-20201114200602554.png)

### 4.5 自定义Realm

一般继承 `AuthorizingRealm`（授权）即可；其继承了 `AuthenticatingRealm`（即身份验证），而且也间接继承了 `CachingRealm`（带有缓存实现）。

通过继承`AuthorizingRealm` 实现其中的 `doGetAuthorizationInfo()` 抽象方法和间接继承`AuthenticatingRealm` 中的`doGetAuthenticationInfo()` 抽象方法，来完成自定义的身份认证和授权。

> 上面测试使用的是 Shiro 提供的 `SimpleAccountRealm`，用户名校验是在Shiro实现的`doGetAuthenticationInfo()`方法中完成的，密码校验是在 `AuthenticatingRealm` 中`assertCredentialsMatch()` 进行（通过 equals( ) 进行比较的）。

#### 4.5.1 测试

> 编写自定义Realm `CustomerRealm.java` 并继承`AuthorizingRealm`，实现其两个抽象方法。

```java
public class CustomerRealm extends AuthorizingRealm {
    //授权
    protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principalCollection) {
        return null;
    }

    //认证
    protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken authenticationToken) throws AuthenticationException {

        //在token中获取用户名
        String principal = (String) authenticationToken.getPrincipal();

        //匹配用户名，后面用户名和密码应该在数据库中查询
        if ("zhy".equals(principal)){
            //参数：1.用户名 2.密码 3.Realm名字,通过返回这些参数Shiro会自动进行密码校验
            SimpleAuthenticationInfo simpleAuthenticationInfo = new SimpleAuthenticationInfo(principal, "123", this.getName());
            return simpleAuthenticationInfo;
        }

        return null;
    }
}
```

> 使用自定义Realm

```java
public class TestCustomerRealmAuthen {
    public static void main(String[] args) {
        //1.创建安全管理器对象、
        DefaultSecurityManager securityManager = new DefaultSecurityManager();

        //2.给安全管理器设置自定义Realm
        securityManager.setRealm(new CustomerRealm());

        //3.给SecurityUtils是指安全管理器
        SecurityUtils.setSecurityManager(securityManager);

        //4.通过SecurityUtils获取Subject
        Subject subject = SecurityUtils.getSubject();

        //5.创建token令牌
        UsernamePasswordToken token = new UsernamePasswordToken("zhy","123");

        try {
            //6.用户验证
            subject.login(token);
            System.out.println(subject.isAuthenticated());
        } catch (UnknownAccountException e) {
            e.printStackTrace();
            System.out.println("username error!");
        } catch (IncorrectCredentialsException e) {
            e.printStackTrace();
            System.out.println("password error!");
        }
    }
}
```

