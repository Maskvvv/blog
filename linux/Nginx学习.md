---
title: Nginx学习
date: 2020-09-30
tags:
  - Linux
  - Nginx
categories:
  - Linux
  - Nginx
---

![](Nginx%E5%AD%A6%E4%B9%A0/download.png)

<!-- more -->

## 一、Nginx介绍

*Nginx* (engine['endʒɪn] x) 是一个高性能的HTTP和反向代理web服务器，同时也提供了IMAP/POP3/SMTP服务。Nginx是由伊戈尔·赛索耶夫为俄罗斯访问量第二的Rambler.ru站点（俄文：Рамблер）开发的，第一个公开版本0.1.0发布于2004年10月4日。

其将源代码以类BSD许可证的形式发布，因它的稳定性、丰富的功能集、示例配置文件和低系统资源的消耗而闻名。2011年6月1日，nginx 1.0.4发布。

Nginx是一款轻量级的Web服务器反向代理服务器及电子邮件（IMAP/POP3）代理服务器，在BSD-like 协议下发行。其特点是占有内存少，并发能力强，事实上nginx的并发能力在同类型的网页服务器中表现较好，中国大陆使用nginx网站用户有：百度、京东、新浪、网易、腾讯、淘宝等。

## 二、Nginx的安装

### 2.1 通过docker-compose安装Nginx

```yml
version: '3.1'
services:
  nginx:
    restart: always
    image: daocloud.io/library/nginx:latest
    container_name: nginx
    ports:
      - 80:80
```

![](Nginx%E5%AD%A6%E4%B9%A0/image-20200930103843673.png)

### 2.2 Nginx的配置文件

> **关于Nginx的核心配置文件`nginx.conf`**

```sh

user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

# 以上统称为全局块,
# worker_processes他的数值越大, Nginx的并发能力就越强
# error_log代表Nginx的错误日志存放的位置

events {
    worker_connections  1024;
}

# events 块
# worker_connections他的数值越大, Nginx并发能力越强

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}

# http块
# include 代表引入一个外部的文件 -> /mime.types中放置大量的媒体类型
# include /etc/nginx/conf.d/*.conf; -> 引入了conf.d目录下的以.conf为结尾的配置文件
```
-------

> **conf.d下面的`default.conf`文件**

```sh
server {
    listen       80;  # listen：代表Nginx监听的端口号
    server_name  localhost;  # localhost：代表代表Nginx接受请求的ip

    location / {
        root   /usr/share/nginx/html;  # root:将接收到的请求根据/usr/share/nginx/html去查找静态资源
        index  index.html index.htm;  # index:默认去root中的路径中找到index.html或者index.htm
    }
}
```

### 2.3 修改docker-compose文件

> **添加数据卷，使宿主机映射到 `/etc/nginx/conf.d`**

```yml
version: '3.1'
services:
  nginx:
    restart: always
    image: daocloud.io/library/nginx:latest
    container_name: nginx
    ports:
      - 80:80
    volumes:
      - /opt/docker_nginx/config.d:/etc/nginx/conf.d
```

-----------

> **在`/opt/docker_nginx/config.d`下新建`default.conf`**

```json
server{
  listen 80;
  server_name localhost;

  location / {
    root /usr/share/nginx/html;
    index index.html index.htm;
  }
}
```

## 三、Nignx反向代理

### 3.1 正向代理和反向代理介绍

> 正向代理：
>
> 1. 正向代理服务时由客户端设立的。
> 2. 客户端了解代理服务器和目标服务器都是谁。
> 3. 帮助咱们实现突破访问权限,提高访问的速度,对目标服务器隐藏客户端的ip地址

![](Nginx%E5%AD%A6%E4%B9%A0/image-20201001095419635.png)

> 反向代理：
>
> 1. 反向代理服务器是配置在服务端的。
> 2. 客户端是不知道访问的到底是哪一台服务器。
> 3. 达到负载均衡,并且可以隐藏服务器真正的ip地址。

![](Nginx%E5%AD%A6%E4%B9%A0/image-20201001100243652.png)

### 3.2 基于Nginx实现反向代理

> **修改Nginx配置文件，通过Nginx访问tomcat服务器。**

```json
server{
  listen 80;
  server_name localhost;
     
	#基于反向代理访问到 Tomcat服务器
  location / {
    proxy_pass http://192.168.199.138:8080/;

  }
}
```

### 3.3 关于Nginx的location映射

> **优先级关系：**
>
> **`(location =) > (location /xxx/yyy/zzz) > (location ^~) > (location ~,~*) > (location /起始路径) > (location /)`**



```json
# 1. = 匹配
location = /xxx{
  # 精准匹配，主机名后面不能带任何的字符串
}
```

----

```json
# 2. 通用匹配
location /xxx {
  # 匹配所有以/xx开头的路径，后可以跟字符串
}

# 3. 正则匹配
location ~ /xxx {
  # 匹配所有以/xx开头的路径
}

# 4. 匹配开头路径
location ^~ /xxx/ {
  # 匹配所有以/xxx开头的路径
}
```

----

```json
# 5. ~* \.(gif|jpg|png)$ {
  # 匹配以gif或者jpg或者png为结尾的路径
}
```

## 四、Nginx负载均衡

> Nginx为我们默认提供了三种负载均衡的策略:
>
> 1. 轮询：
>
>    将客户端发起的请求,平均的分配给每一台服务器。
>
> 2. 权重：
>
>    会将客户端的请求,根据服务器的权重值不同,分配不同的数量。
>
> 3. ip_hash
>
>    基于发起请求的客户端的ip地址不同,他始终会将请求发送到指定的服务器上

### 4.1 轮询

```json
upstream my-server{
  server ip:port;
  server ip:port;
  ...
}

server{
  listen 80;
  server_name localhost;

  location / {
    proxy_pass http://my-server/;
  }
}
```

### 4.2 权重

```json
upstream my-server{
  server ip:port weight=10;
  server ip:port weight=5;
  ...
}

server{
  listen 80;
  server_name localhost;

  location / {
    proxy_pass http://my-server/;
  }
}
```

### 4.3 ip_hash

```
upstream my-server{
  ip_hash;
  server ip:port weight=10;
  server ip:port weight=5;
  ...
}

server{
  listen 80;
  server_name localhost;

  location / {
    proxy_pass http://my-server/;
  }
}
```

## 五、Nginx动静分离

> Nginx 的并发能力公式：
>
> `work_processes * work_connection / 4|2 = Nginx`做种的并发能力
>
> 动态资源需要/4，静态资源需要/2
>
> Nginx 通过动静分离,来提升 Nginx 的并发能力,更快的给用户响应

### 5.1 动态资源代理

```json
# 配置如下
location / {
  proxy_pass 路径;
}
```

### 5.2 静态资源代理

```json
# 配置如下
location / {
  root 静态资源路径;
  index 默认访问路径下的什么资源;
  autoindex on;  # 代表展示静态资源全的全部内容,以列表的形式展开。
}
```

---

```yml
#先修改 docker,添加一个数据卷,映射到Nginx服务器的/data/img和/data/html目录
version: '3.1'
services:
  nginx:
    restart: always
    image: daocloud.io/library/nginx:latest
    container_name: nginx
    ports:
      - 80:80
    volumes:
      - /opt/docker_nginx/config.d:/etc/nginx/conf.d
      - /opt/docker_nginx/img/:/data/img
      - /opt/docker_nginx/html/:/data/html
```

```json
#添加了index.html和1.jpg静态资源
#修改default.conf配置文件
server{
  listen 80;
  server_name localhost;

  # 代理html静态资源
  location /html {
    root /data;  # 不写成/data/html的原因，root会自动拼接在/html后
    index index.html;
  }
  # 代理img静态资源
  location /img {
  root /data;
  autoindex on;  # 资源会以列表的形式展示
}
```

