# nacos 

```shell
docker run -d -p 8848:8848 -e MODE=standlone --restart always --name nacos nacos/nacos-server
```

# mysql

### 关闭本机的tomcat和mysql

```sh
# 关闭本机的tomcat和mysql
systemctl stop mysqld	# 停止mysql
systemctl disable mysqld	# 停止开机自启
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405965-image-20200926094820156.png)

### 部署 mysql

```sh
# 运行MySQL容器
docker run -d -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root daocloud.io/library/mysql:5.7.4
- # -e 指定环境变量
- # -e MYSQL_ROOT_PASSWORD=：指定密码

# 指定数据卷启动(防止数据丢失)
docker run -d -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root -v mysqldata:/var/lib/mysql mysql:5.5.62
# 容器数据默认保存在 /var/lib/mysql 

# 指定指定配置文件
docker run --name canal-mysql -p 33061:3306 -v /root/canal/mysql:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=root -d mysql:8.0
docker run -d -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root -v mysqldata:/var/lib/mysql  -v mysqlconf:/etc/mysql mysql:5.5.62
# 容器配置文件默认保存在 /etc/mysql
```

# 部署 tomcat

```sh
docker run -d -p 8080:8080 --name tomcat -v webapps:/usr/local/tomcat/webapps -v tomcatconf:/usr/local/tomcat/conf tomcat:8.0-jre8
# /usr/local/tomcat/webapps /usr/local/tomcat/conf 分别为容器内 webapps 和 配置文件目录。
```

# 部署 redis

```shell
docker run -d -p 6379:6379 --name redis redis:5.0.10
```

```shell
# 开启redis 持久化
docker run -d -p 6379:6379 -v redisdata:/data --name redis redis:5.0.10 redis-server --appendonly yes
# 通过 redis-server --appendonly yes 开启持久化，并映射容器内的 /data 路径
```

```shell
# 以配置文件的方式启动
docker run -d -v /root/redisconf:/usr/local/etc/redis -p 6379:6379 --name myredis redis:5.0.10 redis-server /usr/local/etc/redis/redis.conf
# 通过 redis-server /usr/local/etc/redis/redis.conf 命令在容器启动时加载 redis.conf 配置文件
```

# 部署 ElasticSearch

```shell
docker run -d --name elasticsearch --net elastic_search -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:6.8.0
# 由于 ES 默认以集群的方式启动，所以可以通过 -e "discovery.type=single-node" 命令设置为单节点启动
#建议通过　--net elastic_search　指定网桥
```

> 启动可能会遇到的问题：**max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]**
>
> ![](http://qiniu.zhouhongyin.top/2022/06/05/1654405969-image-20210520201355349.png)
>
> **解决方案:**
>
> 1. 在 centos 虚拟机中，修改 **sysctl.conf**：`vim /etc/sysctl.conf`
> 2. 加入如下配置：`vm.max_map_count=262144`
> 3. 启用配置：`sysctl -p`

```shell
# ES 持久化
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -p 9200:9200 -p 9300:9300 elasticsearch:6.8.0
```

```shell
# ES 挂载配置文件
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -v esconfig:/usr/share/elasticsearch/config -p 9200:9200 -p 9300:9300 elasticsearch:6.8.0
```

```shell
# ES 挂载插件目录
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -v esconfig:/usr/share/elasticsearch/config -v esplugins:/usr/share/elasticsearch/plugins -p 9200:9200 -p 9300:9300 elasticsearch:6.8.0
```

### 安装 kibana

```shell
docker run -d --name kibana --net elastic_search -p 5601:5601 kibana:6.8.0
```

```shell
# 指定 ES 端口启动
docker run -d --name kibana --net elastic_search -e "ELASTICSEARCH_HOSTS=http://elasticseach:9200" -p 5601:5601 kibana:6.8.0
```

```shell
# 加载配置文件启动
docker run -d --name kibana --net elastic_search -v kibanaconf:/usr/share/kibana/config -p 5601:5601 kibana:6.8.0
# 启动后修改 kibana.yml 即可
```

### rabbitmq

```shell
docker run -d -p 15672:15672 -p 5672:5672 --restart=always --name rabbitmq-delay maskvvv/rabbitmq-delay-queue
```

# mongodb

```shell
docker run -d -p 27017:27017 --name mongo mongo:5.0.5
```

