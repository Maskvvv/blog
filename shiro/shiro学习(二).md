---
title: shiro学习(二)
date: 2020-11-14
tags:
  - spring
  - springboot
  - shiro
categories:
  - spring
  - springboot
  - shiro学习(二)
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702319-SHIRO_APACHE_SECURITY-01.png)

<!-- more -->

## 一、使用MD5和Salt（Shiro编码加密）

### 1.1 MD5算法

- **特点：**MD5算法不可逆如何内容相同无论执行多少次md5生成结果始终是一致。
- **作用：**一般用来加密或者签名(校验和：一般用来验证文件是否完整和正确)。
- **生成结果：**始终是一个16进制32位长度字符串。

### 1.2 加密流程

> 实际应用是将盐和散列后的值存在数据库中，自动 realm从数据库取出盐和加密后的值由 shiro完成密码校验。

![](http://qiniu.zhouhongyin.top/2022/06/08/1654702322-image-20201114215830345.png)

### 1.3 加密测试

```java
public class TestShiroMD5 {
    public static void main(String[] args) {
        //使用MD5
        Md5Hash md5Hash = new Md5Hash("123");
        System.out.println(md5Hash.toHex());

        //使用MD5 + Salt
        Md5Hash md5Hash1 = new Md5Hash("123","O#2$1q");
        System.out.println(md5Hash1.toHex());

        //使用MD5 + Salt + hash散列
        Md5Hash md5Hash2 = new Md5Hash("123","O#2$1q",024);
        System.out.println(md5Hash2.toHex());
    }
}
```

![加密后的结果](http://qiniu.zhouhongyin.top/2022/06/08/1654702329-image-20201114213800060.png)

### 1.4 自定义realm中测试加密

#### 1.4.1 编写自定义realm

```java
public class CustomerMD5Realm extends AuthorizingRealm {
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
            //参数：1.用户名 2.密码 3.注册时的Salt 4.Realm名字。通过返回这些参数Shiro会自动进行密码校验
            SimpleAuthenticationInfo simpleAuthenticationInfo = new SimpleAuthenticationInfo(
                    principal,
                    "fc753b6f31731d70c1e9cf8befa23197",
                    ByteSource.Util.bytes("O#2$1q"),
                    this.getName());
            return simpleAuthenticationInfo;
        }

        return null;
    }
}
```

#### 1.4.2 测试自定义Realm

```java
public class TestCustomerMd5RealmAuthenticator{
    public static void main(String[] args) {
        //1.创建安全管理器对象、
        DefaultSecurityManager securityManager = new DefaultSecurityManager();

        //2.给自定义realm添加算法类型（MD5），和hash散列次数
        CustomerMD5Realm realm = new CustomerMD5Realm();
        HashedCredentialsMatcher credentialsMatcher = new HashedCredentialsMatcher();
        //2.1 设置md5算法
        credentialsMatcher.setHashAlgorithmName("md5");
        //2.2 设置散列次数
        credentialsMatcher.setHashIterations(1024);
        //2.3 给自定义realm设置散列凭证匹配器
        realm.setCredentialsMatcher(credentialsMatcher);

        //3给安全管理器设置自定义Realm
        securityManager.setRealm(realm);

        //4.给SecurityUtils是指安全管理器
        SecurityUtils.setSecurityManager(securityManager);

        //5.通过SecurityUtils获取Subject
        Subject subject = SecurityUtils.getSubject();

        //6.创建token令牌
        UsernamePasswordToken token = new UsernamePasswordToken("zhy","123");

        try {
            //7.用户验证
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

> 校验通过 **MD5+Salt+hash** 散列加密的密码时需要告诉Shiro这是加密过后的密码。

## 二、Shiro 授权

### 2.1 定义

授权，也叫访问控制，即在应用中控制谁能访问哪些资源（如访问页面/编辑数据/页面操作等）。在授权中需了解的几个关键对象：主体（Subject）、资源（Resource）、权限（Permission）、角色（Role）。

> - **主体**：主体，即访问应用的用户，在 Shiro 中使用 Subject 代表该用户。用户只有授权后才允许访问相应的资源。
> - **资源**：在应用中用户可以访问的URL，比如访问 JSP 页面、查看/编辑某些数据、访问某个业务方法、打印文本等等都是资源。用户只要授权后才能访问。
> - **权限**：安全策略中的原子授权单位，通过权限我们可以表示在应用中用户有没有操作某个资源的权力。即权限表示在应用中用户能不能访问某个资源，如： 访问用户列表页面
>   查看/新增/修改/删除用户数据（即很多时候都是 CRUD（增查改删）式权限控制）打印文档等。如上可以看出，权限代表了用户有没有操作某个资源的权利，即反映在某个资源上的操作允不允许，不反映谁去执行这个操作。所以后续还需要把权限赋予给用户，即定义哪个用户允许在某个资源上做什么操作（权限），Shiro 不会去做这件事情，而是由实现人员提供。Shiro 支持粗粒度权限（如用户模块的所有权限）和细粒度权限（操作某个用户的权限，即实例级别的）。
> - **角色**：角色代表了操作集合，可以理解为`权限的集合`，`一般情况下我们会赋予用户角色而不是权限，即这样用户可以拥有一组权限，赋予权限时比较方便`。典型的如：项目经理、技术总监、CTO、开发工程师等都是角色，不同的角色拥有一组不同的权限。

### 2.2 三种授权方式

#### 编程式：通过写 if/else 授权代码块完成：

```java
Subject subject = SecurityUtils.getSubject();
if(subject.hasRole(“admin”)) {
    //有权限
} else {
    //无权限
}
```

#### 注解式：通过在执行的 Java 方法上放置相应的注解完成：

```java
@RequiresRoles("admin")
public void hello() {
    //有权限
}
//没有权限将抛出相应的异常
```

#### JSP/GSP 标签：在 JSP/GSP 页面通过相应的标签完成：

```jsp
<shiro:hasRole name="admin">
<!— 有权限 —>
</shiro:hasRole>
```

### 2.3 字符串通配符权限

**规则：**“`资源标识符：操作：对象实例 ID`” 即对哪个资源的哪个实例可以进行什么操作。其默认支持通配符权限字符串，“:”表示资源/操作/实例的分割；“,”表示操作的分割；“*”表示任意资源/操作/实例。

> - **单个资源单个权限：**
>
>   用户拥有资源“user”的“update”权限：`subject().checkPermissions("system:user:update");`
>
> - **单个资源多个权限：**
>
>   用户拥有资源“user”的“update”和“delete”权限：`subject().checkPermissions("user:update", "user:delete");subject().checkPermissions("system:user:update,delete");`
>
> - **单个资源全部权限：**
>
>   `subject().checkPermissions("user:*");`(推荐)
>
>   ` subject().checkPermissions("user");`
>
> - **单个实例单个权限：**
>
>   对资源 user 的 1 实例拥有update 权限：`subject().checkPermissions("user:update:1");`
>
> - **Shiro 对权限字符串缺失部分的处理**
>
>   如“user:view”等价于“`user:view:*`”；而“organization”等价于“`organization:*`”或者“`organization:*:*`”。可以这么理解，这种方式实现了前缀匹配。
>
>   另外如“`user:*`”可以匹配如“`user:delete`”、“`user:delete`”可以匹配如“`user:delete:1`”、“`user:*:1`”可以匹配如“user:view:1”、“user”可以匹配“`user:view`”或“`user:view:1`”等。即`*`可以匹配所有，不加`*`可以进行前缀匹配；但是如“`*:view`”不能匹配“`system:user:view`”，需要使用“`*:*:view`”，即后缀匹配必须指定前缀（多个冒号就需要多个`*`来匹配）。

### 2.4 测试

#### Realm编写

```java
public class CustomerMD5Realm extends AuthorizingRealm {
    //授权
    protected AuthorizationInfo doGetAuthorizationInfo(PrincipalCollection principalCollection) {
        String primaryPrincipal = (String) principalCollection.getPrimaryPrincipal();
        System.out.println("身份信息(用户名)："+primaryPrincipal);

        SimpleAuthorizationInfo simpleAuthorizationInfo = new SimpleAuthorizationInfo();
        //将根据用户名从数据库中查询的角色信息赋值给权限对象
        simpleAuthorizationInfo.addRole("admin");
        simpleAuthorizationInfo.addRole("user");
        //将根据用户名从数据库中查询的权限信息赋值给权限对象
        simpleAuthorizationInfo.addStringPermission("user:*:1");
        simpleAuthorizationInfo.addStringPermission("product:create");

        return simpleAuthorizationInfo;
    }

    //认证
    protected AuthenticationInfo doGetAuthenticationInfo(AuthenticationToken authenticationToken) throws AuthenticationException {

        //在token中获取用户名
        String principal = (String) authenticationToken.getPrincipal();

        //匹配用户名，后面用户名和密码应该在数据库中查询
        if ("zhy".equals(principal)){
            //参数：1.用户名 2.密码 3.注册时的Salt 4.Realm名字。通过返回这些参数Shiro会自动进行密码校验
            SimpleAuthenticationInfo simpleAuthenticationInfo = new SimpleAuthenticationInfo(
                    principal,
                    "aef9adbba635d84b7d7760e40293202e",
                    ByteSource.Util.bytes("O#2$1q"),
                    this.getName());
            return simpleAuthenticationInfo;
        }

        return null;
    }
}
```

#### 授权测试

```java
public class TestCustomerMd5RealmAuthenticator{
    public static void main(String[] args) {
        //1.创建安全管理器对象、
        DefaultSecurityManager securityManager = new DefaultSecurityManager();

        //2.给自定义realm添加算法类型（MD5），和hash散列次数
        CustomerMD5Realm realm = new CustomerMD5Realm();
        HashedCredentialsMatcher credentialsMatcher = new HashedCredentialsMatcher();
        //2.1 设置md5算法
        credentialsMatcher.setHashAlgorithmName("md5");
        //2.2 设置散列次数
        credentialsMatcher.setHashIterations(1024);
        //2.3 给自定义realm设置散列凭证匹配器
        realm.setCredentialsMatcher(credentialsMatcher);

        //3给安全管理器设置自定义Realm
        securityManager.setRealm(realm);

        //4.给SecurityUtils是指安全管理器
        SecurityUtils.setSecurityManager(securityManager);

        //5.通过SecurityUtils获取Subject
        Subject subject = SecurityUtils.getSubject();

        //6.创建token令牌
        UsernamePasswordToken token = new UsernamePasswordToken("zhy","123");

        try {
            //7.用户验证
            subject.login(token);
            System.out.println(subject.isAuthenticated());
        } catch (UnknownAccountException e) {
            e.printStackTrace();
            System.out.println("username error!");
        } catch (IncorrectCredentialsException e) {
            e.printStackTrace();
            System.out.println("password error!");
        }

        //授权
        if (subject.isAuthenticated()){
            //基于角色权限控制
            System.out.println(subject.hasRole("super"));
            //基于多角色权限控制(与关系)
            System.out.println(subject.hasAllRoles(Arrays.asList("admin","super")));
            //是否具有其中一个角色(或关系)
            boolean[] booleans = subject.hasRoles(Arrays.asList("admin", "super", "user"));
            for (boolean aBoolean : booleans) {
                System.out.println(aBoolean);
            }
            System.out.println("======================");
            //字符串通配符权限：资源标识符：操作：对象实例 ID
            System.out.println("权限："+subject.isPermitted("user:create:1"));
            System.out.println("权限："+subject.isPermitted("product:create:1"));
            //同时具有哪些权限
            System.out.println(subject.isPermittedAll("product:create:1", "user:delete:1"));
            //分别具有哪些权限
            boolean[] permitted = subject.isPermitted("user:create:1", "order:create");
            for (boolean b : permitted) {
                System.out.println(b);
            }
        }
    }
}
```

