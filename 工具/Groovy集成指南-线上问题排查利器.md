# Groovy集成指南：线上问题排查利器

## 概述

在生产环境中，经常会遇到需要临时执行一些代码来排查问题、修复数据或者获取系统信息的场景。传统的做法是修改代码、重新打包、发布，这个过程耗时且风险较高。通过集成Groovy脚本引擎，我们可以在不重启应用的情况下动态执行代码，大大提高问题排查和处理的效率。

## 技术架构

本方案基于Spring Boot + Groovy实现，主要包含以下组件：

- **GroovyLoader**: Groovy脚本加载器，负责编译和管理Groovy脚本
- **BackDoorGroovyController**: HTTP接口控制器，提供脚本执行入口
- **ILoader**: 脚本执行接口，所有Groovy脚本需要实现此接口
- **AutowiredBean**: 示例Bean，演示依赖注入功能

## 集成步骤

### 1. 添加Maven依赖

在`pom.xml`中添加Groovy相关依赖：

```xml
<dependencies>
    <!-- Groovy 3.x 依赖 -->
    <dependency>
        <groupId>org.codehaus.groovy</groupId>
        <artifactId>groovy-all</artifactId>
        <version>3.0.15</version>
        <type>pom</type>
    </dependency>
    
    <!-- Spring Boot Web -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    
    <!-- Hutool工具类 -->
    <dependency>
        <groupId>cn.hutool</groupId>
        <artifactId>hutool-all</artifactId>
        <version>5.8.16</version>
    </dependency>
    
    <!-- FastJSON -->
    <dependency>
        <groupId>com.alibaba</groupId>
        <artifactId>fastjson</artifactId>
        <version>1.2.83</version>
    </dependency>
    
    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
</dependencies>
```

### 2. 创建核心接口

定义所有Groovy脚本需要实现的接口：

```java
package com.zhy.other.groovy.loader;

/**
 * Groovy脚本执行接口
 * 所有动态加载的Groovy脚本都需要实现此接口
 *
 * @author zhouhongyin
 * @since 2023/5/20 11:54
 */
public interface ILoader {
    /**
     * 脚本执行入口方法
     * @return 执行结果
     * @throws Exception 执行异常
     */
    String process() throws Exception;
}
```

### 3. 实现Groovy加载器

创建Groovy脚本的加载和管理组件：

```java
package com.zhy.other.groovy.loader;

import groovy.lang.GroovyClassLoader;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.codec.binary.Base64;
import org.codehaus.groovy.control.CompilerConfiguration;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.support.AbstractBeanDefinition;
import org.springframework.beans.factory.support.BeanDefinitionBuilder;
import org.springframework.beans.factory.support.BeanDefinitionRegistry;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;
import org.springframework.context.support.AbstractApplicationContext;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;

/**
 * Groovy脚本加载器
 * 负责编译Groovy脚本并将其注册到Spring容器中
 *
 * @author zhouhongyin
 * @since 2023/5/20 11:54
 */
@Slf4j
@Component
public class GroovyLoader implements ApplicationContextAware {

    private static final GroovyClassLoader groovyClassLoader;
    public static final String UTF_8 = "UTF-8";
    private ApplicationContext ctx;

    static {
        // 配置Groovy编译器，设置UTF-8编码
        CompilerConfiguration compilerConfiguration = new CompilerConfiguration();
        compilerConfiguration.setSourceEncoding(UTF_8);
        groovyClassLoader = new GroovyClassLoader(
            Thread.currentThread().getContextClassLoader(), 
            compilerConfiguration
        );
    }

    /**
     * 获取或创建Bean实例
     * @param beanName Bean名称
     * @param scriptBase64 Base64编码的Groovy脚本
     * @return Bean实例
     */
    public Object getBean(String beanName, String scriptBase64) {
        // 1. 尝试从Spring容器中获取已存在的Bean
        Object bean = getBeanInner(beanName);
        if (bean != null) return bean;

        // 2. 编译Groovy脚本，获取Class对象
        Class clz = compile(scriptBase64);

        // 3. 将Class注册到Spring容器
        applyClz2Spring(beanName, clz);

        // 4. 再次从Spring容器获取Bean实例
        bean = getBeanInner(beanName);
        return bean;
    }

    /**
     * 编译Base64编码的Groovy脚本
     */
    private Class compile(String scriptBase64) {
        String script = new String(Base64.decodeBase64(scriptBase64), StandardCharsets.UTF_8);
        return groovyClassLoader.parseClass(script);
    }

    /**
     * 将Class注册到Spring容器
     */
    private void applyClz2Spring(String beanName, Class clz) {
        AbstractBeanDefinition beanDefinition = BeanDefinitionBuilder
            .genericBeanDefinition(clz)
            .getRawBeanDefinition();
        // 设置自动装配模式为按类型装配
        beanDefinition.setAutowireMode(AbstractBeanDefinition.AUTOWIRE_BY_TYPE);
        
        ((BeanDefinitionRegistry) ((AbstractApplicationContext) ctx).getBeanFactory())
            .registerBeanDefinition(beanName, beanDefinition);
    }

    /**
     * 从Spring容器获取Bean
     */
    private Object getBeanInner(String beanName) {
        try {
            return ctx.getBean(beanName);
        } catch (BeansException e) {
            log.info("Bean不存在: {}", beanName);
        }
        return null;
    }

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.ctx = applicationContext;
    }
}
```

### 4. 创建请求DTO

定义HTTP请求的数据传输对象：

```java
package com.zhy.other.groovy.dto;

import lombok.Data;

/**
 * Groovy脚本执行请求参数
 */
@Data
public class BackDoorGroovyDto {
    /**
     * 安全密钥，防止恶意调用
     */
    private String key;
    
    /**
     * Base64编码的Groovy脚本内容
     */
    private String javaScriptBase64;
    
    /**
     * Bean名称，用于Spring容器管理
     */
    private String beanName;
}
```

### 5. 实现HTTP控制器

创建提供脚本执行服务的REST接口：

```java
package com.zhy.other.groovy.controller;

import com.zhy.other.groovy.dto.BackDoorGroovyDto;
import com.zhy.other.groovy.loader.GroovyLoader;
import com.zhy.other.groovy.loader.ILoader;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.web.bind.annotation.*;

import javax.annotation.Resource;

/**
 * Groovy脚本执行控制器
 * 提供动态执行Groovy脚本的HTTP接口
 *
 * @author zhouhongyin
 * @since 2023/5/20 12:37
 */
@RequestMapping("/backdoor/groovy")
@RestController
public class BackDoorGroovyController {
    
    @Resource
    private GroovyLoader groovyLoader;

    @Resource
    private ApplicationContext applicationContext;

    /**
     * 执行Groovy脚本
     * @param param 请求参数
     * @return 执行结果
     * @throws Exception 执行异常
     */
    @PostMapping
    public String process(@RequestBody BackDoorGroovyDto param) throws Exception {
        // 安全验证
        if (!"666".equals(param.getKey())) {
            return "访问被拒绝";
        }

        String beanName = param.getBeanName();
        
        // 加载并执行Groovy脚本
        Object myClassLoader = groovyLoader.getBean(beanName, param.getJavaScriptBase64());
        ILoader loader = (ILoader) myClassLoader;
        String resp = loader.process();

        // 清理资源：移除Bean实例和定义
        ConfigurableApplicationContext configurableContext = 
            (ConfigurableApplicationContext) applicationContext;
        DefaultListableBeanFactory beanFactory = 
            (DefaultListableBeanFactory) configurableContext.getBeanFactory();

        // 移除Bean实例缓存
        beanFactory.destroySingleton(beanName);
        // 移除BeanDefinition
        beanFactory.removeBeanDefinition(beanName);

        return resp;
    }
}
```

### 6. 创建示例Bean

创建一个示例Bean用于演示依赖注入：

```java
package com.zhy.other.groovy.loader;

import org.springframework.stereotype.Component;

/**
 * 示例Bean，用于演示Groovy脚本中的依赖注入
 *
 * @author zhouhongyin
 * @since 2023/10/25 23:05
 */
@Component
public class AutowiredBean {
    
    public void print() {
        System.out.println("I am AutowiredBean - 依赖注入成功！");
    }
    
    public String getSystemInfo() {
        return "系统时间: " + new java.util.Date() + 
               ", JVM内存: " + Runtime.getRuntime().totalMemory() / 1024 / 1024 + "MB";
    }
}
```

## 使用示例

### 示例1：基础信息查询脚本

```groovy
package com.zhy.other.groovy.loader

import org.springframework.beans.factory.annotation.Autowired

class SystemInfoLoader implements ILoader {
    
    @Autowired
    private AutowiredBean autowiredBean
    
    @Override
    String process() throws Exception {
        autowiredBean.print()
        
        def systemInfo = [:]
        systemInfo.javaVersion = System.getProperty("java.version")
        systemInfo.osName = System.getProperty("os.name")
        systemInfo.userDir = System.getProperty("user.dir")
        systemInfo.totalMemory = Runtime.getRuntime().totalMemory() / 1024 / 1024 + "MB"
        systemInfo.freeMemory = Runtime.getRuntime().freeMemory() / 1024 / 1024 + "MB"
        systemInfo.maxMemory = Runtime.getRuntime().maxMemory() / 1024 / 1024 + "MB"
        systemInfo.availableProcessors = Runtime.getRuntime().availableProcessors()
        
        return com.alibaba.fastjson.JSON.toJSONString(systemInfo, 
            com.alibaba.fastjson.serializer.SerializerFeature.PrettyFormat)
    }
}
```

### 示例2：数据库连接信息查询脚本

```groovy
package com.zhy.other.groovy.loader

import cn.hutool.extra.spring.SpringUtil
import com.alibaba.fastjson.JSON
import com.alibaba.fastjson.serializer.SerializerFeature
import org.springframework.beans.factory.annotation.Autowired

import javax.sql.DataSource
import java.sql.Connection
import java.sql.DatabaseMetaData

class DatabaseInfoLoader implements ILoader {
    
    @Autowired
    private AutowiredBean autowiredBean
    
    @Override
    String process() throws Exception {
        autowiredBean.print()
        
        DataSource dataSource = SpringUtil.getBean(DataSource.class)
        Connection connection = null
        
        try {
            connection = dataSource.getConnection()
            DatabaseMetaData metaData = connection.getMetaData()
            
            def connectionInfo = [:]
            connectionInfo.url = metaData.getURL()
            connectionInfo.username = metaData.getUserName()
            connectionInfo.databaseProductName = metaData.getDatabaseProductName()
            connectionInfo.databaseProductVersion = metaData.getDatabaseProductVersion()
            connectionInfo.driverName = metaData.getDriverName()
            connectionInfo.driverVersion = metaData.getDriverVersion()
            connectionInfo.catalog = connection.getCatalog()
            connectionInfo.schema = connection.getSchema()
            connectionInfo.autoCommit = connection.getAutoCommit()
            connectionInfo.readOnly = connection.isReadOnly()
            connectionInfo.transactionIsolation = connection.getTransactionIsolation()
            
            return JSON.toJSONString(connectionInfo, SerializerFeature.PrettyFormat)
        } finally {
            if (connection != null) {
                connection.close()
            }
        }
    }
}
```

### 示例3：文件下载脚本

```groovy
package com.zhy.other.groovy.loader

import cn.hutool.core.io.IoUtil
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpHeaders
import org.springframework.web.context.request.RequestContextHolder
import org.springframework.web.context.request.ServletRequestAttributes

import javax.servlet.ServletOutputStream
import javax.servlet.http.HttpServletResponse
import java.io.FileInputStream

class FileDownloadLoader implements ILoader {
    
    @Autowired
    private AutowiredBean autowiredBean
    
    @Override
    String process() throws Exception {
        autowiredBean.print()
        
        // 获取HTTP响应对象
        ServletRequestAttributes attributes = 
            (ServletRequestAttributes) RequestContextHolder.getRequestAttributes()
        HttpServletResponse response = attributes.getResponse()
        
        // 设置响应头
        response.setHeader(HttpHeaders.CONTENT_DISPOSITION, "attachment;filename=system-log.txt")
        response.setHeader(HttpHeaders.CONTENT_TYPE, "text/plain")
        
        ServletOutputStream outputStream = response.getOutputStream()
        
        // 这里可以根据实际需求修改文件路径
        String filePath = "/var/log/application.log"
        FileInputStream fileInputStream = new FileInputStream(filePath)
        
        try {
            IoUtil.copy(fileInputStream, outputStream)
            return "文件下载成功"
        } finally {
            IoUtil.close(outputStream)
            IoUtil.close(fileInputStream)
        }
    }
}
```

## 调用方式

### 1. 准备Groovy脚本

将上述Groovy脚本进行Base64编码：

```bash
# 使用命令行工具进行Base64编码
echo "你的Groovy脚本内容" | base64
```

### 2. 发送HTTP请求

```bash
curl -X POST http://localhost:8080/backdoor/groovy \
  -H "Content-Type: application/json" \
  -d '{
    "key": "666",
    "beanName": "systemInfoLoader",
    "javaScriptBase64": "你的Base64编码脚本"
  }'
```

### 3. 使用Postman测试

- **URL**: `POST http://localhost:8080/backdoor/groovy`
- **Headers**: `Content-Type: application/json`
- **Body**:
```json
{
  "key": "666",
  "beanName": "systemInfoLoader",
  "javaScriptBase64": "cGFja2FnZSBjb20uemh5Lm90aGVyLmdyb292eS5sb2FkZXIKCmltcG9ydCBvcmcuc3ByaW5nZnJhbWV3b3JrLmJlYW5zLmZhY3RvcnkuYW5ub3RhdGlvbi5BdXRvd2lyZWQKCmNsYXNzIFN5c3RlbUluZm9Mb2FkZXIgaW1wbGVtZW50cyBJTG9hZGVyIHsKICAgIAogICAgQEF1dG93aXJlZAogICAgcHJpdmF0ZSBBdXRvd2lyZWRCZWFuIGF1dG93aXJlZEJlYW4KICAgIAogICAgQE92ZXJyaWRlCiAgICBTdHJpbmcgcHJvY2VzcygpIHRocm93cyBFeGNlcHRpb24gewogICAgICAgIGF1dG93aXJlZEJlYW4ucHJpbnQoKQogICAgICAgIHJldHVybiAi57O757uf5L+h5oGv5p+l6K+i5oiQ5YqfIgogICAgfQp9"
}
```

## 安全注意事项

### 1. 访问控制

- **密钥验证**: 使用强密钥，定期更换
- **IP白名单**: 限制只有特定IP可以访问
- **权限控制**: 结合Spring Security进行更细粒度的权限控制

```java
// 增强的安全验证
@PostMapping
public String process(@RequestBody BackDoorGroovyDto param, HttpServletRequest request) {
    // 1. 密钥验证
    if (!isValidKey(param.getKey())) {
        log.warn("非法访问尝试，IP: {}", getClientIP(request));
        return "访问被拒绝";
    }
    
    // 2. IP白名单验证
    if (!isAllowedIP(getClientIP(request))) {
        log.warn("IP不在白名单中: {}", getClientIP(request));
        return "访问被拒绝";
    }
    
    // 3. 频率限制
    if (!rateLimiter.tryAcquire()) {
        log.warn("访问频率过高，IP: {}", getClientIP(request));
        return "访问频率过高";
    }
    
    // ... 执行脚本逻辑
}
```

### 2. 脚本安全

- **代码审查**: 执行前人工审查脚本内容
- **沙箱环境**: 在隔离环境中测试脚本
- **权限限制**: 限制脚本可访问的资源和操作

### 3. 生产环境建议

- **日志记录**: 详细记录所有脚本执行日志
- **监控告警**: 对异常执行进行监控和告警
- **备份恢复**: 执行前备份关键数据
- **回滚机制**: 提供快速回滚能力

## 常见应用场景

### 1. 线上问题排查

- 查看系统状态和配置信息
- 检查数据库连接和数据状态
- 分析日志文件内容
- 监控系统资源使用情况

### 2. 数据修复

- 批量更新错误数据
- 清理无效数据
- 数据格式转换
- 缓存刷新操作

### 3. 系统维护

- 清理临时文件
- 重置系统状态
- 更新配置参数
- 执行定时任务

### 4. 性能优化

- 分析慢查询
- 优化缓存策略
- 调整系统参数
- 监控性能指标

## 总结

通过集成Groovy脚本引擎，我们可以在生产环境中快速、安全地执行临时代码，大大提高了问题排查和处理的效率。这种方案具有以下优势：

1. **灵活性**: 可以动态执行任意Java/Groovy代码
2. **便捷性**: 无需重启应用即可执行新逻辑
3. **安全性**: 通过多层安全机制保护系统安全
4. **可控性**: 完整的日志记录和监控机制
5. **扩展性**: 易于扩展和定制功能

在使用过程中，务必注意安全性，建议在非生产环境充分测试后再在生产环境使用。同时，建立完善的操作规范和应急预案，确保系统的稳定性和安全性。