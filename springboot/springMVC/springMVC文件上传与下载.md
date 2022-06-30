---
title: springMVC 文件的上传与下载
date: 2021-4-27
tags:
  - spring
  - springboot
  - Mybatis
  - 文件上传与下载
  - springcloud
categories:
  - spring
  - springboot
  - springMVC
---



![](http://qiniu.zhouhongyin.top/2022/06/05/1654404587-1654404567174-download.png)



<!-- more -->

## 一、搭建初始环境

### 1.1 创建一个普通的 springboot 项目。

### 1.2 导入相关依赖

```xml
<dependencies>

    <!--操作文件的一些工具类-->
    <dependency>
        <groupId>commons-fileupload</groupId>
        <artifactId>commons-fileupload</artifactId>
        <version>1.4</version>
    </dependency>
	<!--lombok-->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
    </dependency>
	<!--springweb-->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
        <exclusions>
            <exclusion>
                <groupId>org.junit.vintage</groupId>
                <artifactId>junit-vintage-engine</artifactId>
            </exclusion>
        </exclusions>
    </dependency>

</dependencies>
```

## 二、文件的上传

### 2.1 编写前端页面

在 resource/static 路径下创建 file.html

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
    <form action="/file/upload" method="post" enctype="multipart/form-data">
        <input name="image" type="file"/><br>
        <input type="submit" value="submit">
    </form>
</body>
</html>
```

> 提交文件时，form 表单的 enctype 属性值必须为 `multipart/form-data`，例如 `enctype="multipart/form-data"`

### 2.2 编写后端接口

#### 2.2.1 编写配置文件

```yml
file:
  # 存放文件的地址
  path: "G:/springboot/springcloud/ems_parent/ems-empl/src/main/resources/static/"
```

#### 2.2.2 编写 Controller 接口类

```java
@RestController
public class FIleController {

    @Value(value = "${file.path}")
    private String realPath;

    @PostMapping(value = "/file/upload")
    public void upload(@RequestPart MultipartFile image,HttpServletRequest request) throws IOException {
        System.out.println("文件的原始名：" + image.getOriginalFilename());
        System.out.println("文件的大小：" + image.getSize());
        System.out.println("文件的类型：" + image.getContentType());

        // 1.通过 commons-fileupload 提供的工具类获取原始文件的文件类型后缀。
        String extension = FilenameUtils.getExtension(image.getOriginalFilename());
        // 2.拼接新的文件名
        String fileNewName = UUID.randomUUID().toString().replace("-","") + "." + extension;

        //3.将文件分日期存放
        LocalDate now = LocalDate.now(); // 获取当前日期
        File file = new File(realPath, now.toString());
        //如果文件不存在创建当前目录
        if (!file.exists()) file.mkdir();

        // 4.MultipartFile 提供的方法可以直接将 MultipartFile 类型的文件存储指定的路径
        image.transferTo(new File(file,fileNewName));

    }

}
```

> **commons-fileupload 提供的工具类：**
>
> - **FilenameUtils.getExtension()：**可以根据传入的文件名参数获取文件的后缀。（a.txt --> txt）
> - **IOUtils.copy(inputStream,outputStream)：**自动将输入流读入输出流
>
> **JDK8 提供的新的日期类：**
>
> - **LocalTime.now()：**获取当前时间。（例如：16:52:07.686）
> - **LocalDate.now()：**获取日期。（例如：2021-04-27）
> - **LocalDateTime.now()：**获取当前时间和日期。（例如：2021-04-27T16:52:07.686）

## 三、文件的下载

### 3.1 编写前端页面

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
    <a href="/file/download?fileName=504dd76bce544057963e335bc8dff449.jpg">文件下载</a>
</body>
</html>
```

### 3.2 编写后端接口

```java
@RestController
public class FIleController {

    @RequestMapping(value = "/file/download")
    public void upload1(String fileName, HttpServletResponse response) throws IOException {

        // 获取文件输入流
        FileInputStream inputStream = new FileInputStream(new File(realPath,fileName));
        ServletOutputStream outputStream = response.getOutputStream();
        System.out.println(realPath+fileName);

        //设置响应头和文件类型 attachment为附件形式下载 inline为在线打开
        response.setHeader("content-disposition","attachment;fileName="+ URLEncoder.encode(fileName,"UTF-8"));
        response.setContentType("text/plain;charset=UTF-8");

        // 将输入流读入输出流
        IOUtils.copy(inputStream,outputStream);
        IOUtils.closeQuietly(inputStream);
        IOUtils.closeQuietly(outputStream);

//        int len;
//        byte[] bytes = new byte[1024];
//        while (true){
//            len = inputStream.read(bytes);
//            if (len == -1) break;
//            outputStream.write(bytes);
//        }
//
//        inputStream.close();
//        outputStream.close();

    }

}
```

> - **文件在线打开不下载问题：**需要设置响应头 `content-disposition: attachment;fileName=文件名`（**attachment**为附件形式下载 **inline**为在线打开）
> - **下载的文件名和文件乱码问题：**
>   - **文件乱码：**需要设置 响应头 `Content-Type: text/plain;charset=UTF-8`
>   - **文件名乱码：**需要对文件名进行`URLEncoder.encode(fileName,"UTF-8")`编码

## 四、springCloud 中的文件上传

通过 openFeign 调用文件上传接口。

### 4.1 导入 openFeign 的依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

### 4.2 在启动类上添加注解

在启动类上添加 `@EnableFeignClients` 注解，开启 openFeign 服务。

```java
@SpringBootApplication
@EnableFeignClients
public class EmsUsersApplication {
    public static void main(String[] args) {
        SpringApplication.run(EmsUsersApplication.class, args);
    }

}
```

### 4.2 编写 openFeignClient

```java
@FeignClient("files")
public interface FileClient {
    @PostMapping(value = "/file/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    void upload(@RequestPart MultipartFile image);
}
```

> 上传文件时：
>
> - 必须指定 `consumes = MediaType.MULTIPART_FORM_DATA_VALUE`
> - 必须在 `MultipartFile `类型的参数前添加 `@RequestPart `注解

