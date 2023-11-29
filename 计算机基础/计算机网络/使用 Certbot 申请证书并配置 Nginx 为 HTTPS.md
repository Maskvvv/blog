# 安装 Certbot

```shell
yum install epel-release -y
yum install certbot -y
```

# 申请证书

```shell
certbot certonly -d *.test.com -d test.com --manual --preferred-challenges dns
```

期间会让你添加一个 TXT 类型的 Dns 解析记录，你需要登录云服务提供商的管理后台添加，按要求填就可以了，我用的阿里云如下所示：

![](http://qiniu.zhouhongyin.top/2023/11/29/1701240007-image-20231129144007068.png)

申请成功后会在该路径下生成证书和对应的私钥  `/etc/letsencrypt/live/test.com/`

![](http://qiniu.zhouhongyin.top/2023/11/29/1701240176-image-20231129144256872.png)

# 修改 Nginx 配置

```nginx
server {
    listen       80;
    server_name  test.com;
    root         /usr/share/nginx/html;
    return 301 https://$host$request_uri;
}
server {
    listen       80;
    server_name  *.test.com;
    root         /usr/share/nginx/html;
    return 301 https://$host$request_uri;
}

server {
    listen  443 ssl;
    server_name  zhouhongyin.top;

    #access_log  /var/log/nginx/host.access.log  main;

    # include /etc/nginx/conf.d/ssl.conf
    ssl_certificate  /etc/letsencrypt/archive/zhouhongyin.top/fullchain1.pem;
    ssl_certificate_key  /etc/letsencrypt/archive/zhouhongyin.top/privkey1.pem;

    location / {
        root   /usr/share/nginx/html/Maskvvv-master;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
```

> 这里需要注意的是如果你的 nginx 是安装在 docker 里的，需要证书路径需要填写容器内的路径，否则会找不到证书。

