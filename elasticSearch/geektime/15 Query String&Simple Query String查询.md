# 数据准备

```sql
PUT /users/_doc/1
{
  "name":"Ruan Yiming",
  "about":"java, golang, node, swift, elasticsearch"
}

PUT /users/_doc/2
{
  "name":"Li Yiming",
  "about":"Hadoop"
}
```

# Query String Query

类似URI Query

```sql
POST users/_search
{
  "query": {
    "query_string": {
      "default_field": "name",
      "query": "Ruan AND Yiming"
    }
  }
}


POST users/_search
{
  "query": {
    "query_string": {
      "fields":["name","about"],
      "query": "(Ruan AND Yiming) OR (Java AND Elasticsearch)"
    }
  }
}
```

# Simple Query String Query

![](http://qiniu.zhouhongyin.top/2023/05/05/1683277064-image-20230505165744034.png)

```sql
#Simple Query 默认的operator是 Or, query 中的 “AND” 会失效
POST users/_search
{
  "query": {
    "simple_query_string": {
      "query": "Ruan AND Yiming",
      "fields": ["name"]
    }
  }
}

# 通过 default_operator 实现与操作
POST users/_search
{
  "query": {
    "simple_query_string": {
      "query": "Ruan Yiming",
      "fields": ["name"],
      "default_operator": "AND"
    }
  }
}


```

# query String 和 query match 的区别

在 kibana 的 dev tool 和自己编写程序时，query match的更为常见。query string 只需要大概了解。方便在浏览器地址栏里调用，或者是在kibana的ui里就行查询