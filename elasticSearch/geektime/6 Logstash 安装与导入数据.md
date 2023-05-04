[geektime-ELK/part-1/2.4-Logstash安装与导入数据 at master · geektime-geekbang/geektime-ELK · GitHub](https://github.com/geektime-geekbang/geektime-ELK/tree/master/part-1/2.4-Logstash安装与导入数据)

下载

https://www.elastic.co/cn/downloads/

![](http://qiniu.zhouhongyin.top/2023/05/04/1683211221-image-20230504224021514.png)

# 安装 Logstash

![](http://qiniu.zhouhongyin.top/2023/05/04/1683210593-image-20230504222952979.png)

# Movielens 测试数据集

![](http://qiniu.zhouhongyin.top/2023/05/04/1683210618-image-20230504223018249.png)

# 安装Logstash，并且导入Movielens的测试数据集

## 下载 movies.csv movie 文件

[geektime-ELK/movies.csv at master · geektime-geekbang/geektime-ELK · GitHub](https://github.com/geektime-geekbang/geektime-ELK/blob/master/part-1/2.4-Logstash安装与导入数据/movielens/ml-latest-small/movies.csv)

## 在 ./bin 目录下创建 logstash.conf 文件

```conf
input {
  file {
    path => "D:/workware/java/logstash-7.8.0/csv/movies.csv"
    start_position => "beginning"
    sincedb_path => "D:/workware/java/logstash-7.8.0/123"
  }
}
filter {
  csv {
    separator => ","
    columns => ["id","content","genre"]
  }

  mutate {
    split => { "genre" => "|" }
    remove_field => ["path", "host","@timestamp","message"]
  }

  mutate {

    split => ["content", "("]
    add_field => { "title" => "%{[content][0]}"}
    add_field => { "year" => "%{[content][1]}"}
  }

  mutate {
    convert => {
      "year" => "integer"
    }
    strip => ["title"]
    remove_field => ["path", "host","@timestamp","message","content"]
  }

}
output {
   elasticsearch {
     hosts => "http://localhost:9200"
     index => "movies"
     document_id => "%{id}"
   }
  stdout {}
}
```

> 两点注意：
>
> ```
> input {
>   file {
>     path => "D:/workware/java/logstash-7.8.0/csv/movies.csv"
>     start_position => "beginning"
>     sincedb_path => "D:/workware/java/logstash-7.8.0/123"
>   }
> }
> ```
>
> - path 为 movies.csv 文件的绝对路径， windows 环境下文件分隔符用 “/”
> - sincedb_path 为一个不存在的目录

## 执行

```shell
#启动Elasticsearch实例，然后启动 logstash，并制定配置文件导入数据
bin/logstash -f logstash.conf
```

