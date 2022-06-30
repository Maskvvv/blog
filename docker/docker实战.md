---
title: Docker 部署 spring + Vue 项目实战
date: 2021-5-23
updated: 2021-5-23
tags:
  - Linux
  - Docker
  - docker-compose
  - Vue
categories:
  - Docker
  - Docker 部署 spring + Vue 项目实战
---

<img src="http://qiniu.zhouhongyin.top/2022/06/05/1654405810-Microsoft.VisualStudio.Services.Icons.png" style="zoom:33%;" />

<!--more-->

## 一、整体架构

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405806-image-20210523162135399.png)

## 二、 打包项目

### 2.1 打包 Vue 项目

在 Vue 项目路径运行 `npm run build` 命令即可打包，打包完成后在项目路径会出现一个名为 `dist` 的文件夹，该文件夹就是打包好的 Vue 项目。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405829-image-20210523162847763.png)

### 2.2 打包 spring boot 项目

在 Vue 项目路径运行 `mvn package` 命令即可打包，打包完成后在`项目路径/target`会出现一个名为 `***.jar` 的文件，该文件夹就是打包好的 spring boot项目。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405840-image-20210523163509490.png)

## 三、编写 Dockerfile

目的是创建一个含有这运行着 spring boot 项目的自定义镜像。

在 `/root/admin-vue/spring_dockerfile` 路径下创建 `Dockerfile` ，并将刚才达成 `jar` 包的 spring boot 项目上传到当前该目录。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405843-image-20210523164022586.png)

编写 `Dockerfile` ：

```dockerfile
FROM openjdk:8-jdk # 使用 jdk8 的镜像
EXPOSE 8080 # 暴露 8080 端口方便后面映射到宿主机上面的端口
WORKDIR /java/app # 设置工作路径 
COPY ./vueadmin-java-0.0.1-SNAPSHOT.jar vueadmin.jar # 将当前路径下（相对于 Dockerfile 而言）的vueadmin-java-0.0.1-SNAPSHOT.jar 拷贝到工作路径并重新命名为 vueadmin.jar
CMD ["java","-jar","vueadmin.jar"] # 运行该项目

FROM openjdk:8-jdk
EXPOSE 8080
WORKDIR /java/app
COPY ./vueadmin-java-0.0.1-SNAPSHOT.jar vueadmin.jar
CMD ["java","-jar","vueadmin.jar"]
```

## 四、编写 docker-compose.yml

通过 Compose 来编排 nginx、redis、mysql、spring boot 这些服务。

在 `/root/admin-vue` 路径下创建 `docker-compose.yml` 文件。

```yml
version: "3.7"
services:
  admin-vue-springboot:
    build: # 通过Docker 构建镜像和容器
      context: ./spring_dockerfile
      dockerfile: Dockerfile
    container_name: admin-vue-springboot
    ports:
      - "8081:8080"
    depends_on:
      - mysql
      - redis
      - nginx
    networks:
      - adimn_vue
  mysql:
    image: mysql:5.5.62
    container_name: mysql
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=root # 设置 MySQL 密码
    volumes:
      - mysql_datadir:/var/lib/mysql # 映射 mysql 存储数据的目录
    networks:
      - adimn_vue

  redis:
    image: redis:5.0.10
    container_name: redis
    ports:
      - "6380:6379"
    command: "redis-server /usr/local/etc/redis/redis.conf --appendonly yes" # 开启持久化和加载自定义配置文件
    volumes:
      - redis_data:/data # redis 持久化目录
      - redis_conf:/usr/local/etc/redis # redis 配置文件目录
    networks:
      - adimn_vue
  # nginx 服务
  nginx:
    image: nginx
    container_name: nginx
    ports:
      - "8080:80"
    volumes:
      - nginx_content:/usr/share/nginx/html # 映射静态资源目录
      - nginx_conf:/etc/nginx # 映射配置文件目录
    networks:
      - adimn_vue

#声明 数据卷
volumes:
  mysql_datadir:
  nginx_content:
  nginx_conf:
  redis_data:
  redis_conf:

# 声明网桥
networks:
  adimn_vue:
```

编写完成后再 `docker-compose.yml` 同级目录下运行 `docker-compose up -d --build`命令（如果自定义的镜像不存在需要加上 `--build` 来构建自定义镜像），即可创建各服务。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405851-image-20210523165640675.png)

运行成功后 docker 会在宿主机的 `/var/lib/docker/volumes` 目录下自动创建 `docker-compose` 中映射的数据卷。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405857-image-20210523165941201.png)

## 五、部署 Vue

### 5.1 添加 Vue 项目到 nginx

将我们打包好的 Vue 项目上传到 `/var/lib/docker/volumes/admin-vue_nginx_content/_data/`目录下。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405861-image-20210523170315221.png)

### 5.2 编辑 nginx 配置文件

编辑 `/var/lib/docker/volumes/admin-vue_nginx_conf/_data/conf.d/` 路径下名为 `default.conf` 的配置文件。

![](http://qiniu.zhouhongyin.top/image-20210523170524265.png)

```conf
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    location / {
        try_files $uri $uri/ @router; #需要指向下面的@router否则会出现vue的路由在nginx中刷新出现404
        root   /usr/share/nginx/html/dist; # 静态资源路径
        index  index.html index.htm;
    }
    #对应上面的@router，主要原因是路由的路径资源并不是一个真实的路径，所以无法找到具体的文件
    #因此需要rewrite到index.html中，然后交给路由在处理请求资源
    location @router {
        rewrite ^.*$ /index.html last;
    }
    
    # 或者都可以
    location / {
      root   /usr/share/nginx/html/mkhb/dist;
	  try_files $uri $uri/ /index.html;
      index  index.html index.htm;
    }
    
    location /prod-api/{
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header REMOTE-HOST $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://ip:8080/;
    }

}
```

> 解决 nginx 部署 Vue 项目出现 404 问题。参考博客：https://www.cnblogs.com/qingmuchuanqi48/p/11831389.html?ivk_sa=1024320u

## 六、配置 Redis 

由于 Redis 不自带配置文件需要我们自己去下载对应版本的 `redis.conf` 配置文件。

下载完毕后需要设置配置文件中 `bind 0.0.0.0` ，开放所有 ip 连接。

设置完毕后将 `redis.conf` 配置文件上传至 `/var/lib/docker/volumes/admin-vue_nginx_conf/_data/conf.d/` 后重启 redis 服务即可。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405865-image-20210523171532512.png)

## 七、测试

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405867-image-20210523171657063.png)

## 八、解决 VUE 项目打包上线因 chunk.js 文件过大导致页面加载缓慢解决方案

### 8.1 安装 compression-webpack-plugin 插件

```shell
npm install --save-dev compression-webpack-plugin@5.0.0
```

> 此处需要添加版本号，不然默认会安装最新版而报错：`Cannot read property ‘tapPromise‘ of undefined`。[参考博客](https://www.cnblogs.com/wuzhiquan/p/14179388.html)

### 8.2 修改 vue.config.js 文件

添加 configureWebpack 配置使其可以对 js 文件进行压缩。

```js
const path = require('path');

const webpack = require('webpack')
const CompressionWebpackPlugin = require('compression-webpack-plugin')
const productionGzipExtensions = ['js', 'css']
const isProduction = process.env.NODE_ENV === 'production'

module.exports = {
    devServer: {
        disableHostCheck: true
    },
    configureWebpack: {
        resolve: {
            alias: {
                '@': path.resolve(__dirname, './src'),
                '@i': path.resolve(__dirname, './src/assets'),
            }
        },
        plugins: [
            new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/),

            // 下面是下载的插件的配置
            new CompressionWebpackPlugin({
                algorithm: 'gzip',
                test: new RegExp('\\.(' + productionGzipExtensions.join('|') + ')$'),
                threshold: 10240,
                minRatio: 0.8
            }),
            new webpack.optimize.LimitChunkCountPlugin({
                maxChunks: 5,
                minChunkSize: 100
            })
        ]
    }
}

```

**打包后的文件大小对比**

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405873-image-20210615161031543.png)

### 8.3 修改 nginx 配置文件

修改配置文件，开启 nginx 对 js 文件的压缩。

~~~conf
server{
	```
	gzip on;
    gzip_min_length 1k;
    gzip_comp_level 9;
    gzip_types text/plain application/x-javascript application/javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;
    gzip_vary on;
    gzip_disable "MSIE [1-6]\.";
    
    ```
}
~~~

> 注意这里 `application/x-javascript application/javascript` 顺序不能颠倒，否则 nginx 的 gzip 压缩 js 无效。[参考博客](https://blog.csdn.net/qq_32814555/article/details/80748545?utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-4.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-4.control) 