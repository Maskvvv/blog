# 学习在本机 Docker 环境中运行 ELK Stack

![](http://qiniu.zhouhongyin.top/2023/05/04/1683210056-image-20230504222056523.png)

```shell
#启动
docker-compose up

#停止容器
docker-compose down

#停止容器并且移除数据
docker-compose down -v

#一些docker 命令
docker ps
docker stop Name/ContainerId
docker start Name/ContainerId

#删除单个容器
$docker rm Name/ID
-f, –force=false; -l, –link=false Remove the specified link and not the underlying container; -v, –volumes=false Remove the volumes associated to the container

#删除所有容器
$docker rm `docker ps -a -q`  
停止、启动、杀死、重启一个容器
$docker stop Name/ID  
$docker start Name/ID  
$docker kill Name/ID  
$docker restart name/ID
```

```yml
version: '2.2'
services:
  kibana:
    image: docker.elastic.co/kibana/kibana:7.3.0
    container_name: kibana73
    environment:
      - I18N_LOCALE=zh-CN
      - XPACK_GRAPH_ENABLED=true
      - TIMELION_ENABLED=true
      - XPACK_MONITORING_COLLECTION_ENABLED="true"
    ports:
      - "5601:5601"
    networks:
      - es73net
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.3.0
    container_name: es73
    environment:
      - cluster.name=geektime
      - node.name=es73
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - discovery.seed_hosts=es73
      - cluster.initial_master_nodes=es73
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es73data1:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - es73net


volumes:
  es73data1:
    driver: local

networks:
  es73net:
    driver: bridge
```

