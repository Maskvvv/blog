---
title: Swagger 整合 Spring Boot
date: 2021-10-1
tags:
  - spring
  - springboot
  - swagger
categories:
  - spring
  - springboot
  - Swagger 整合 Spring Boot
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041577-image-20211001204600248.png)

<!-- more -->

# 一、Swagger 引言

Swagger 是一个规范和完整的框架，用于生成、描述、调用和可视化 RESTful 风格的 Web 服务。总体目标是使客户端和文件系统作为服务器以同样的速度来更新。文件的方法，参数和模型紧密集成到服务器端的代码，允许API来始终保持同步。

# 二、Swagger 注解说明

- `@Api`：用在类上，说明该类的作用。

- `@ApiOperation`：注解来给API增加方法说明。
- `@ApiImplicitParams` : 用在方法上包含一组参数说明。
- `@ApiImplicitParam`：用来注解来给方法入参增加说明。参数：
  - paramType：指定参数放在哪个地方
    - header：请求参数放置于Request Header，使用 @RequestHeader 获取
    - query：请求参数放置于请求地址，使用 @RequestParam 获取
    - path：（用于restful接口）-->请求参数的获取：@PathVariable
    - body：请求体中提交
    - form：form表单提交
  - name：参数名
  - dataType：参数类型
  - required：参数是否必须传(true | false)
  - value：说明参数的意思
  - defaultValue：参数的默认值

- `@ApiResponses`：用于表示一组响应
- `@ApiResponse`：用在  @ApiResponses 中，一般用于表达一个错误的响应信息
  - code：数字，例如 400  
  - message：信息，例如"请求参数异常!" 
  - response：抛出异常的类   
- `@ApiModel`：描述一个 Model 的信息（一般用在请求参数无法使用 @ApiImplicitParam 注解进行描述的时候）
- `@ApiModelProperty`：描述一个 model 的属性

# 三、Spring Boot 整合 Swagger

## 3.1 添加 Maven 依赖

```xml
<!--swagger-->
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>2.9.2</version>
</dependency>
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>2.9.2</version>
</dependency>
```

> 注：如果导入出错，换个版本在试试

## 3.2 编写 Swagger 配置类

```java
**
 * swagger 配置文件
 * @Author: zhouhongyin
 * @date: 2021/10/1
 */
@Configuration
@EnableSwagger2
public class SwaggerConfig {

    /**
     * 创建API应用
     * apiInfo() 增加API相关信息
     * 通过select()函数返回一个ApiSelectorBuilder实例,用来控制哪些接口暴露给Swagger来展现，
     * 本例采用指定扫描的包路径来定义指定要建立API的目录。
     *
     * @return
     */
    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo())
                .select()
                .apis(RequestHandlerSelectors.basePackage("com.markerhub.controller"))
                .paths(PathSelectors.any())
                .build();
    }

    /**
     * 创建该API的基本信息（这些基本信息会展现在文档页面中）
     * 访问地址：http://项目实际地址/swagger-ui.html
     * @return
     */
    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
                .title("spring boot 后台管理系统 APIs")
                .description("更多请关注http://www.baidu.com")
                .termsOfServiceUrl("http://www.baidu.com")
                .version("1.0")
                .build();
    }
}
```

> 注意：需要通过 `@EnableSwagger2` 注解开启 Swagger 

## 3.3 编写 Swagger 提供的注解

```java
/**
 * @description:
 * @author: zhouhongyin
 * @time: 2021/9/29 14:34
 */
@RestController
@RequestMapping("sys/dept")
@Api(value = "部门api", tags = "部门api")
public class DeptController {

    @Resource
    private DeptService deptService;

    /**
     *
     * @param current
     * @param size
     * @return
     */
    @ApiOperation(value = "分页查看部门信息", notes = "分页查看部门信息")
    @ApiImplicitParams({
            @ApiImplicitParam(name = "current", paramType = "query", value = "当前页", defaultValue = "1"),
            @ApiImplicitParam(name = "size", paramType = "query", value = "每页大小", defaultValue = "10")}
    )
    @GetMapping("list")
    @PreAuthorize("hasAuthority('sys:dept:list')")
    public Result queryDeptByPage(@RequestParam(value = "current", defaultValue = "1") int current,
                                  @RequestParam(value = "size", defaultValue = "10") int size) {
        PageInfo<Dept> deptPageInfo = deptService.selectAllDeptByPage(current, size);

        return Result.succ(deptPageInfo);
    }

    /**
     * 添加部门
     * @param dept
     * @return
     */
    @ApiOperation(value = "添加部门信息")
    @ApiImplicitParam(name = "dept", paramType = "body", value = "部门信息")
    @PostMapping("save")
    @PreAuthorize("hasAuthority('sys:dept:save')")
    public Result addDept(@RequestBody @Validated @NotNull(message = "部门信息不能为空") Dept dept) {
        deptService.insertDept(dept.getDeptName());

        return Result.succ("添加成功！");
    }

    /**
     * 修改部门
     * @param dept
     * @return
     */
    @ApiOperation(value = "修改部门信息")
    @ApiImplicitParam(name = "dept", paramType = "body", value = "部门信息")
    @PostMapping("update")
    @PreAuthorize("hasAuthority('sys:dept:update')")
    public Result editDept(@RequestBody @Validated @NotNull(message = "部门信息不能为空") Dept dept) {
        deptService.updateDept(dept);

        return Result.succ("修改成功！");
    }

}
```

## 3.4 访问 Sagger 提供的网页

访问 `http://ip/swagger-ui.html` ，即可查看 Swagger 页面。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041568-image-20211002085835684.png)

# 四、Swagger 和 Spring Security 整合问题

由于 Spring Security 会过滤 Swagger 的许多访问路径，所以需要添加一下拦截白名单。

```java
"/swagger-ui.html",
"/webjars/**",
"/v2/api-docs",
"/swagger-resources/configuration/ui",
"/swagger-resources",
"/swagger-resources/configuration/security"
```

# 五、Swagger 和 YApi 整合

## 5.1 方式一：（通过 Json 文件整合）

### 5.1.1 进入 Swagger 的 api-docs 页面

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041564-image-20211002090653153.png)

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041562-image-20211002090712306.png)

### 5.1.2 将该页面的 Json 信息 保存为 .json 文件

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041560-image-20211002090958061.png)

### 5.1.3 导入将文件导入 Yapi

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041556-image-20211002091107205.png)

### 5.1.4 效果

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041554-image-20211002091203843.png)

## 5.2 方法二：通过 url 导入

填入 api-docs 页面的路径即可。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655041551-aHR0cHM6Ly9tYWxsLWZpbGVzLm9zcy1jbi1zaGVuemhlbi5hbGl5dW5jcy5jb20vMjAxOS0wNC0xNV8xNS00Ni0zOC5qcGc.jpg)

