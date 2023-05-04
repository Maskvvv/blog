# 本地部署 & 水平扩展

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195328-image-20230504181528167.png)

- 开发环境部署
- 单节点，一个节点承担多种角色
- 单机部署多个节点，便于学习了解分布式集群的工作机制

# 安装 Java

- 运行 Elasticsearch，需安装并配置 JDK
  - 设置 $JAVA HOME
- 各个版本对 Java 的依赖
  - Elasticsearch 5 需要 Java 8 以上的版本
  - Elasticsearch 从6.5 开始支持 Java 11
  - https://www.elastic.co/support/matrix#matrix_jvm
  - 7.0 开始，内置了 Java 环境

# 获取 Elasticsearch 安装包

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195433-image-20230504181713748.png)

- 下载二进制文件
- https://www.elastic.co/downloads/elasticsearch
- 支持 Docker 本地运行
- Helm chart for kubernetes
- Puppet Module

# Elasticsearch 的文件目录结构

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195475-image-20230504181755415.png)

# JVM 配置

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195607-image-20230504182007118.png)

- 修改 JVM -config / jvm.options
  - 7.1下载的默认设置是1GB
- 配置的建议
  - Xmx 和 Xms 设置成一样
  - Xmx 不要超过机器内存的 50%
  - 不要超过 30GB - https://www.elastic.co/blog/a-heap-of-trouble

# 运行 Elasticsearch

运行 bin 目录下的 elasticsearch

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195765-image-20230504182245764.png)

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195801-image-20230504182321425.png)

使用浏览器打开 localhost:9200 查看是否运行成功

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195866-image-20230504182426710.png)

# 安装与查看插件

```shell
bin/elasticsearch-plugin install analysis-icu
bin/elasticsearch-plugin list
```

![](http://qiniu.zhouhongyin.top/2023/05/04/1683196091-image-20230504182811882.png)

![](http://qiniu.zhouhongyin.top/2023/05/04/1683195974-image-20230504182614319.png)

