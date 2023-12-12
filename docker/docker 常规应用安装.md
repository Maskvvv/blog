# nacos 

```shell
docker run -d -p 8848:8848 -e MODE=standlone --restart always --name nacos nacos/nacos-server

docker run -d -p 8848:8848 -p 9848:9848 -p 9849:9849 --privileged=true --restart=always -e MODE=standalone --name nacos nacos/nacos-server:v2.2.0
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
docker run -d -p 6379:6379 –requirepass 1234567788 --name redis redis:5.0.10
# 设置密码
docker run --name redis -p 6380:6379 -d redis --requirepass "1234567788"
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
docker run -d --name elasticsearch --net esnetwork -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.10.1
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
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -p 9200:9200 -p 9300:9300 elasticsearch:7.10.1
```

```shell
# ES 挂载配置文件
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -v esconfig:/usr/share/elasticsearch/config -p 9200:9200 -p 9300:9300 elasticsearch:7.10.1
```

```shell
# ES 挂载插件目录
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -v esconfig:/usr/share/elasticsearch/config -v esplugins:/usr/share/elasticsearch/plugins -p 9200:9200 -p 9300:9300 elasticsearch:7.10.1
```

```shell
# 全
docker run -d --name elasticsearch --net esnetwork -v esdata:/usr/share/elasticsearch/data -v esconfig:/usr/share/elasticsearch/config -v esplugins:/usr/share/elasticsearch/plugins -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.10.1
```

### 安装 kibana

```shell
docker run -d --name kibana --net esnetwork -p 5601:5601 kibana:7.10.1
```

```shell
# 指定 ES 端口启动
docker run -d --name kibana --net esnetwork -e "ELASTICSEARCH_HOSTS=http://elasticseach:9200" -p 5601:5601 kibana:7.10.1
```

```shell
# 加载配置文件启动
docker run -d --name kibana --net esnetwork -v kibanaconf:/usr/share/kibana/config -p 5601:5601 kibana:7.10.1
# 启动后修改 kibana.yml 即可
```

# rabbitmq

```shell
docker run -d -p 15672:15672 -p 5672:5672 --restart=always --name rabbitmq-delay maskvvv/rabbitmq-delay-queue
```

# mongodb

```shell
docker run -d -p 27017:27017 --name mongo mongo:5.0.5
```

# Dubbo

```shell
docker run -d -p 21810:2181 --name zookeeper zookeeper:3.4.14
```

# RocketMQ

## nameserver

```shell
docker run -d --name rmqnamesrv -p 9876:9876 -e "NAMESRV_ADDR=192.168.0.194:9876" apache/rocketmq:5.1.3 sh mqnamesrv
```

## broker

```shell
docker run -d --name rmqbroker -v rocketmq-broker:/home/rocketmq/rocketmq-5.1.3/ -p 10911:10911 -p 10909:10909 -e "NAMESRV_ADDR=192.168.0.194:9876" -e "BROKER_IP=192.168.0.194" -e "AUTO_CREATE_TOPIC_ENABLE=true" apache/rocketmq:5.1.3 sh mqbroker -n 192.168.0.194:9876 -c /home/rocketmq/rocketmq-5.1.3/conf/broker.conf

docker run -d --name rmqbroker2 -v rocketmq-broker:/home/rocketmq/rocketmq-5.1.3/ -p 10921:10921 -e "NAMESRV_ADDR=192.168.0.194:9876" -e "BROKER_IP=192.168.0.194" -e "AUTO_CREATE_TOPIC_ENABLE=true" apache/rocketmq:5.1.3 sh mqbroker -n 192.168.0.194:9876 -c /home/rocketmq/rocketmq-5.1.3/conf/2m-2s-async/broker-b.properties
```

### broker.conf

`/home/rocketmq/rocketmq-5.1.3/conf/broker.conf`

```properties
brokerClusterName = DefaultCluster
brokerName = broker-a
brokerId = 0
deleteWhen = 04
fileReservedTime = 48
brokerRole = ASYNC_MASTER
flushDiskType = ASYNC_FLUSH

brokerIP1 = 192.168.0.194
listenPort=10911
namesrvAddr=1192.168.0.194:9876
autoCreateTopicEnable = true
```

```properties
brokerClusterName=DefaultCluster
brokerName=broker-b
brokerId=0
deleteWhen=04
fileReservedTime=48
brokerRole=ASYNC_MASTER
flushDiskType=ASYNC_FLUSH

brokerIP1 = 192.168.0.194
listenPort=10921
namesrvAddr=192.168.0.194:9876
autoCreateTopicEnable = true
```

## rocketmq-console

```shell
docker run -e "JAVA_OPTS=-Drocketmq.namesrv.addr=192.168.0.194:9876 -Dcom.rocketmq.sendMessageWithVIPChannel=false" -p 8080:8080 -t styletang/rocketmq-console-ng:1.0.0
```

# nexus3

```shell
docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3
```

# Nginx

```shell
docker run -d -p 80:80 -p 443:443 -v /home/nginx/conf/nginx.conf:/etc/nginx/nginx.conf -v /home/nginx/html:/usr/share/nginx/html -v /home/nginx/log:/var/log/nginx -v /home/nginx/conf/conf.d:/etc/nginx/conf.d --name nginx nginx
```

