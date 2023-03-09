# 一、安装 RabbitMQ

通过 docker 安装 rabbitmq

```shell
docker run -d -p 15672:15672 -p 5672:5672 --restart=always --name rabbitmq daocloud.io/library/rabbitmq:management 
```

# 二、安装 ElasticSearch

通过 docker 安装 ElasticSearch

```shell
docker run -d --name elasticsearch --net elastic_search -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.10.0
```

![image-20230301092327613](http://qiniu.zhouhongyin.top/2023/03/01/1677633810-image-20230301092327613.png)

# 三、安装 Kibana

通过 docker 安装 Kibana

```shell
docker run -d --name kibana --net elastic_search -p 5601:5601 kibana:7.10.0
```

# 四、配置 MySQL

## 4.1 修改 my.cnf

对于自建 MySQL , 需要先开启 Binlog 写入功能，配置 binlog-format 为 ROW 模式，my.cnf 中配置如下

```properties
[mysqld]
log-bin=mysql-bin # 开启 binlog
binlog-format=ROW # 选择 ROW 模式
server_id=1 # 配置 MySQL replaction 需要定义，不要和 canal 的 slaveId 重复
```

## 4.2 查看配置是否生效

```sql
show variables like '%log_bin%';
```

### 4.3 创建 canal 的 MySQL 账号

```sql
CREATE USER canal IDENTIFIED BY 'canal';  
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'canal'@'%';
-- GRANT ALL PRIVILEGES ON *.* TO 'canal'@'%' ;
FLUSH PRIVILEGES;
```

# 五、canal 的安装与配置

## 5.1 安装

```shell
docker run --name canal -p 11111:11111 -d \
-v /docker/canal/conf/:/home/admin/canal-server/conf/ \
-v /docker/canal/logs/:/home/admin/canal-server/logs/ \
canal/canal-server:v1.1.5
```

## 5.2 配置

### 5.2.1 配置 `instance.properties`

容器内路径 `/home/admin/canal-server/conf/example/instance.properties`

```properties
#################################################
## mysql serverId , v1.0.26+ will autoGen
# canal.instance.mysql.slaveId=0

# enable gtid use true/false
canal.instance.gtidon=false

# position info
# 需要订阅 binlog 的 mysql 的地址
canal.instance.master.address=127.0.0.1:3308
canal.instance.master.journal.name=binlog.000002
canal.instance.master.position=5
canal.instance.master.timestamp=
canal.instance.master.gtid=

# rds oss binlog
canal.instance.rds.accesskey=
canal.instance.rds.secretkey=
canal.instance.rds.instanceId=

# table meta tsdb info
canal.instance.tsdb.enable=true
#canal.instance.tsdb.url=jdbc:mysql://127.0.0.1:3306/canal_tsdb
# canal.instance.tsdb.dbUsername=canal
# canal.instance.tsdb.dbPassword=canal

#canal.instance.standby.address =
#canal.instance.standby.journal.name =
#canal.instance.standby.position =
#canal.instance.standby.timestamp =
#canal.instance.standby.gtid=

# username/password
# 需要订阅 binlog 的 mysql 的 账号
canal.instance.dbUsername=canal
canal.instance.dbPassword=canal
canal.instance.connectionCharset = UTF-8
# enable druid Decrypt database password
canal.instance.enableDruid=false
#canal.instance.pwdPublicKey=MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALK4BUxdDltRRE5/zXpVEVPUgunvscYFtEip3pmLlhrWpacX7y7GCMo2/JM6LeHmiiNdH1FWgGCpUfircSwlWKUCAwEAAQ==

# table regex
# 配置需要订阅的数据库和表
canal.instance.filter.regex=.*\\..*
# table black regex
canal.instance.filter.black.regex=mysql\\.slave_.*
# table field filter(format: schema1.tableName1:field1/field2,schema2.tableName2:field1/field2)
#canal.instance.filter.field=test1.t_product:id/subject/keywords,test2.t_company:id/name/contact/ch
# table field black filter(format: schema1.tableName1:field1/field2,schema2.tableName2:field1/field2)
#canal.instance.filter.black.field=test1.t_product:subject/product_image,test2.t_company:id/name/contact/ch

# mq config
# 配置 rabbitmq 的 routerkey
canal.mq.topic=canal.athena.*
# dynamic topic route by schema or table regex
#canal.mq.dynamicTopic=mytest1.user,topic2:mytest2\\..*,.*\\..*
canal.mq.partition=0
# hash partition config
#canal.mq.enableDynamicQueuePartition=false
#canal.mq.partitionsNum=3
#canal.mq.dynamicTopicPartitionNum=test.*:4,mycanal:6
#canal.mq.partitionHash=test.table:id^name,.*\\..*
#################################################

```

> **关于 `canal.instance.master.*` 相关配置：**
>
> `.journal.name` 和 `position` 这两个配置可以在， address 的数据库中执行 `SHOW MASTER STATUS` 获取的 `File` 和 `Position` 两个字段。
>
> 如果是设置为空的话，那么从第一次启动 cannal 的时候开始算起
>
> **关于 `canal.instance.filter.regex`** 
>
> - `.*\\..*` ：表示匹配所有的库里所有的表
> - `canal\\..*`：表示匹配 `canal` 库下所有的表
> - `canal\\.prefix.*`：表示匹配 `canal` 库下以 `prefix` 开头的表
> - `canal.table1`：表示陪陪 `canal` 库下的 `table1` 表
> - `canal\\.prefix.*,canal.table1`：多个规则用 `,` 分开
>
> **关于 `canal.instance.tsdb.enable`：**
>
> 建议默认即可
>
> - 这几项 `canal.instance.tsdb.enable` 的配置表示是否打开 tsdb 开关，tsdb 是为预防表结构发生变化从而在 canal 订阅 binlog 时产生问题。
> - canal 使用数据库存储上一次的表结构信息，然后对比两次的表结构，可解决此错误。
> - `canal.instance.tsdb.**` 的几项配置为存储表结构的数据库。



### 5.2.2 配置 `canal.properties`

容器内路径 `/home/admin/canal-server/conf/canal.properties`

```properties
#################################################
######### 		common argument		#############
#################################################
# tcp bind ip
canal.ip =
# register ip to zookeeper
canal.register.ip =
canal.port = 11111
canal.metrics.pull.port = 11112
# canal instance user/passwd
# canal.user = canal
# canal.passwd = E3619321C1A937C46A0D8BD1DAC39F93B27D4458

# canal admin config
#canal.admin.manager = 127.0.0.1:8089
canal.admin.port = 11110
canal.admin.user = admin
canal.admin.passwd = 4ACFE3202A5FF5CF467898FC58AAB1D615029441
# admin auto register
#canal.admin.register.auto = true
#canal.admin.register.cluster =
#canal.admin.register.name =

canal.zkServers =
# flush data to zk
canal.zookeeper.flush.period = 1000
canal.withoutNetty = false
# tcp, kafka, rocketMQ, rabbitMQ, pulsarMQ
# 配置发送方式为 rabbitmq
canal.serverMode = rabbitMQ
# flush meta cursor/parse position to file
canal.file.data.dir = ${canal.conf.dir}
canal.file.flush.period = 1000
## memory store RingBuffer size, should be Math.pow(2,n)
canal.instance.memory.buffer.size = 16384
## memory store RingBuffer used memory unit size , default 1kb
canal.instance.memory.buffer.memunit = 1024 
## meory store gets mode used MEMSIZE or ITEMSIZE
canal.instance.memory.batch.mode = MEMSIZE
canal.instance.memory.rawEntry = true

## detecing config
canal.instance.detecting.enable = false
#canal.instance.detecting.sql = insert into retl.xdual values(1,now()) on duplicate key update x=now()
canal.instance.detecting.sql = select 1
canal.instance.detecting.interval.time = 3
canal.instance.detecting.retry.threshold = 3
canal.instance.detecting.heartbeatHaEnable = false

# support maximum transaction size, more than the size of the transaction will be cut into multiple transactions delivery
canal.instance.transaction.size =  1024
# mysql fallback connected to new master should fallback times
canal.instance.fallbackIntervalInSeconds = 60

# network config
canal.instance.network.receiveBufferSize = 16384
canal.instance.network.sendBufferSize = 16384
canal.instance.network.soTimeout = 30

# binlog filter config
canal.instance.filter.druid.ddl = true
canal.instance.filter.query.dcl = false
canal.instance.filter.query.dml = false
canal.instance.filter.query.ddl = false
canal.instance.filter.table.error = false
canal.instance.filter.rows = false
canal.instance.filter.transaction.entry = false
canal.instance.filter.dml.insert = false
canal.instance.filter.dml.update = false
canal.instance.filter.dml.delete = false

# binlog format/image check
canal.instance.binlog.format = ROW,STATEMENT,MIXED 
canal.instance.binlog.image = FULL,MINIMAL,NOBLOB

# binlog ddl isolation
canal.instance.get.ddl.isolation = false

# parallel parser config
canal.instance.parser.parallel = true
## concurrent thread number, default 60% available processors, suggest not to exceed Runtime.getRuntime().availableProcessors()
#canal.instance.parser.parallelThreadSize = 16
## disruptor ringbuffer size, must be power of 2
canal.instance.parser.parallelBufferSize = 256

# table meta tsdb info
canal.instance.tsdb.enable = true
canal.instance.tsdb.dir = ${canal.file.data.dir:../conf}/${canal.instance.destination:}
canal.instance.tsdb.url = jdbc:h2:${canal.instance.tsdb.dir}/h2;CACHE_SIZE=1000;MODE=MYSQL;
canal.instance.tsdb.dbUsername = canal
canal.instance.tsdb.dbPassword = canal
# dump snapshot interval, default 24 hour
canal.instance.tsdb.snapshot.interval = 24
# purge snapshot expire , default 360 hour(15 days)
canal.instance.tsdb.snapshot.expire = 360

#################################################
######### 		destinations		#############
#################################################
canal.destinations = example
# conf root dir
canal.conf.dir = ../conf
# auto scan instance dir add/remove and start/stop instance
canal.auto.scan = true
canal.auto.scan.interval = 5
# set this value to 'true' means that when binlog pos not found, skip to latest.
# WARN: pls keep 'false' in production env, or if you know what you want.
canal.auto.reset.latest.pos.mode = false

canal.instance.tsdb.spring.xml = classpath:spring/tsdb/h2-tsdb.xml
#canal.instance.tsdb.spring.xml = classpath:spring/tsdb/mysql-tsdb.xml

canal.instance.global.mode = spring
canal.instance.global.lazy = false
canal.instance.global.manager.address = ${canal.admin.manager}
#canal.instance.global.spring.xml = classpath:spring/memory-instance.xml
canal.instance.global.spring.xml = classpath:spring/file-instance.xml
#canal.instance.global.spring.xml = classpath:spring/default-instance.xml

##################################################
######### 	      MQ Properties      #############
##################################################
# aliyun ak/sk , support rds/mq
canal.aliyun.accessKey =
canal.aliyun.secretKey =
canal.aliyun.uid=

# 是否为flat json格式对象
canal.mq.flatMessage = true
canal.mq.canalBatchSize = 50
canal.mq.canalGetTimeout = 100
# Set this value to "cloud", if you want open message trace feature in aliyun.
canal.mq.accessChannel = local

canal.mq.database.hash = true
canal.mq.send.thread.size = 30
canal.mq.build.thread.size = 8

##################################################
######### 		     Kafka 		     #############
##################################################
kafka.bootstrap.servers = 127.0.0.1:9092
kafka.acks = all
kafka.compression.type = none
kafka.batch.size = 16384
kafka.linger.ms = 1
kafka.max.request.size = 1048576
kafka.buffer.memory = 33554432
kafka.max.in.flight.requests.per.connection = 1
kafka.retries = 0

kafka.kerberos.enable = false
kafka.kerberos.krb5.file = "../conf/kerberos/krb5.conf"
kafka.kerberos.jaas.file = "../conf/kerberos/jaas.conf"

##################################################
######### 		    RocketMQ	     #############
##################################################
rocketmq.producer.group = test
rocketmq.enable.message.trace = false
rocketmq.customized.trace.topic =
rocketmq.namespace =
rocketmq.namesrv.addr = 127.0.0.1:9876
rocketmq.retry.times.when.send.failed = 0
rocketmq.vip.channel.enabled = false
rocketmq.tag = 

##################################################
######### 		    RabbitMQ	     #############
##################################################
rabbitmq.host = 127.0.0.1
rabbitmq.virtual.host = /
rabbitmq.exchange = athena.canal.exchange
rabbitmq.username = guest
rabbitmq.password = guest
rabbitmq.deliveryMode = 


##################################################
######### 		      Pulsar         #############
##################################################
pulsarmq.serverUrl =
pulsarmq.roleToken =
pulsarmq.topicTenantPrefix =
```

> **关于 `rabbitmq.exchange`：**
>
> `exchange` 需要提前在 rabbitmq 上创建，否则 canal启动时会报错
>
> **关于 `canal.mq.flatMessage`**：
>
> 是否为 json 格式，如果设置为 false ，对应 MQ 收到的消息为 protobuf 格式，需要通过CanalMessageDeserializer 进行解码
>
> **关于 `canal.instance.filter.*`：**
>
> - **`canal.instance.filter.druid.ddl`：**v1.0.25版本新增，是否启用druid的DDL parse的过滤，基于sql的完整parser可以解决之前基于正则匹配补全的问题，默认为true
> - **`canal.instance.filter.query.dcl`：**是否忽略 DCL 的 query 语句，比如grant/create user等
> - **`canal.instance.filter.query.dml`：**是否忽略DML的query语句，比如insert/update/delete table.(mysql5.6的ROW模式可以包含statement模式的query记录)
> - **`canal.instance.filter.query.ddl`：**是否忽略DDL的query语句，比如create table/alater table/drop table/rename table/create index/drop index. (目前支持的ddl类型主要为table级别的操作，create databases/trigger/procedure暂时划分为dcl类型)

## 5.3 关于让 canal 从头同步 binlog

因为 canal 会将当前 server 同步 binlog 的进度存储在 `/home/admin/canal-server/conf/example/meta.dat` ，并不会优先读取 `instance.properties` 下 `canal.instance.master.*` 的配置，所以要想让 canal 重新同步 binlog 需要停止 canal 后删除 `meta.dat` 文件，然后重新启动即可。

同步信息到

# 六、同步信息到 ES

## 6.1 添加 Maven 依赖

```xml
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch</artifactId>
    <version>7.8.0</version>
</dependency>
<dependency>
    <groupId>org.elasticsearch.client</groupId>
    <artifactId>elasticsearch-rest-high-level-client</artifactId>
    <version>7.8.0</version>
</dependency>
```

## 6.2 创建 ES 客户端

```java
@Configuration
public class RestClientConfig extends AbstractElasticsearchConfiguration {

    @Override
    @Bean
    public RestHighLevelClient elasticsearchClient() {
        final ClientConfiguration clientConfiguration = ClientConfiguration.builder()
                .connectedTo("localhost:9200")
                .build();
        return RestClients.create(clientConfiguration).rest();
    }
}
```

## 6.3 创建消费者

```java
@Component
public class CanalConsumer {

    @Resource
    private RestHighLevelClient client;

    @PostConstruct
    private void createIndex() {
        CreateIndexRequest request = new CreateIndexRequest("canal");

        try {
            CreateIndexResponse response = client.indices().create(request, RequestOptions.DEFAULT);
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    /**
     * 消息消费者
     * queues: 指定要消费的队列
     * ackMode：MANUAL AUTO
     * concurrency: 开几个线程消费消息
     */
    @RabbitListener(queues = "canal.athena.canal",
            ackMode = "MANUAL",
            concurrency = "1")
    public void onMessage(String msg, Channel channel, Message message) throws IOException {
        try {
            String body = new String(message.getBody());

            IndexRequest request = new IndexRequest("canal");

            request.source(body, XContentType.JSON);
            
            client.index(request, RequestOptions.DEFAULT);

            log.info( "{}-message:{}", Thread.currentThread(), msg);

            channel.basicAck(message.getMessageProperties().getDeliveryTag(), true);
        } catch (Exception e) {
            e.printStackTrace();
            channel.basicNack(message.getMessageProperties().getDeliveryTag(), true, true);
        }

    }

}
```