# Search API

Search API 有两大类：

- URI Search：使用 HTTP 的形式，在URL中使用查询参数
- Request Body Search：使用 Elasticsearch 提供的，基于JSON 格式的更加完备的Query Domain Specific Language (DSL)

```json
#URI Query
GET index_name/_search?q=customer_first_name:Eddie
GET kibana*/_search?q=customer_first_name:Eddie
GET /_all/_search?q=customer_first_name:Eddie

#REQUEST Body
POST index_name/_search
{
	"profile": true,
	"query": {
		"match_all": {}
	}
}
```

# 指定查询的索引

![](http://qiniu.zhouhongyin.top/2023/05/05/1683257524-image-20230505113204735.png)

# 搜索 Response

![](http://qiniu.zhouhongyin.top/2023/05/05/1683258635-image-20230505115035023.png)

# URL Search（了解）

![](http://qiniu.zhouhongyin.top/2023/06/15/1686799815-image-20230615113015213.png)

## Query String Syntax

![](http://qiniu.zhouhongyin.top/2023/06/15/1686800049-image-20230615113409398.png)

![](http://qiniu.zhouhongyin.top/2023/06/15/1686800072-image-20230615113432261.png)

![](http://qiniu.zhouhongyin.top/2023/06/15/1686800095-image-20230615113455644.png)



![](http://qiniu.zhouhongyin.top/2023/06/15/1686800112-image-20230615113512754.png)

## 演示

```java
#基本查询
GET /movies/_search?q=2012&df=title&sort=year:desc&from=0&size=10&timeout=1s

#带profile
GET /movies/_search?q=2012&df=title
{
	"profile":"true"
}


#泛查询，正对_all,所有字段
GET /movies/_search?q=2012
{
	"profile":"true"
}

#指定字段
GET /movies/_search?q=title:2012&sort=year:desc&from=0&size=10&timeout=1s
{
	"profile":"true"
}


# 查找美丽心灵, Mind为泛查询
GET /movies/_search?q=title:Beautiful Mind
{
	"profile":"true"
}

# 泛查询
GET /movies/_search?q=title:2012
{
	"profile":"true"
}

#使用引号，Phrase查询
GET /movies/_search?q=title:"Beautiful Mind"
{
	"profile":"true"
}

#分组，Bool查询
GET /movies/_search?q=title:(Beautiful Mind)
{
	"profile":"true"
}


#布尔操作符
# 查找美丽心灵
GET /movies/_search?q=title:(Beautiful AND Mind)
{
	"profile":"true"
}

# 查找美丽心灵
GET /movies/_search?q=title:(Beautiful NOT Mind)
{
	"profile":"true"
}

# 查找美丽心灵
GET /movies/_search?q=title:(Beautiful %2BMind)
{
	"profile":"true"
}


#范围查询 ,区间写法
GET /movies/_search?q=title:beautiful AND year:[2002 TO 2018%7D
{
	"profile":"true"
}


#通配符查询
GET /movies/_search?q=title:b*
{
	"profile":"true"
}

//模糊匹配&近似度匹配
GET /movies/_search?q=title:beautifl~1
{
	"profile":"true"
}

GET /movies/_search?q=title:"Lord Rings"~2
{
	"profile":"true"
}
```

# Request Body Search

## Request Body & Query DSL

```java
#ignore_unavailable=true，可以忽略尝试访问不存在的索引“404_idx”导致的报错
#查询movies分页
POST /movies,404_idx/_search?ignore_unavailable=true
{
  "profile": true,
	"query": {
		"match_all": {}
	}
}

POST /kibana_sample_data_ecommerce/_search
{
  "from":10,
  "size":20,
  "query":{
    "match_all": {}
  }
}


#对日期排序
POST kibana_sample_data_ecommerce/_search
{
  "sort":[{"order_date":"desc"}],
  "query":{
    "match_all": {}
  }

}

#source filtering
POST kibana_sample_data_ecommerce/_search
{
  "_source":["order_date"],
  "query":{
    "match_all": {}
  }
}


#脚本字段
GET kibana_sample_data_ecommerce/_search
{
  "script_fields": {
    "new_field": {
      "script": {
        "lang": "painless",
        "source": "doc['order_date'].value+'hello'"
      }
    }
  },
  "query": {
    "match_all": {}
  }
}


POST movies/_search
{
  "query": {
    "match": {
      "title": "last christmas"
    }
  }
}

POST movies/_search
{
  "query": {
    "match": {
      "title": {
        "query": "last christmas",
        "operator": "and"
      }
    }
  }
}

POST movies/_search
{
  "query": {
    "match_phrase": {
      "title":{
        "query": "one love"

      }
    }
  }
}

POST movies/_search
{
  "query": {
    "match_phrase": {
      "title":{
        "query": "one love",
        "slop": 1

      }
    }
  }
}
```

> match 和 match_phrase 的区别：
>
> 二者都对根据字段类型对查询字符串进行分词，被分的词之间 match 是 “或” 的关系，而 match_phrase 是 “与” 的关系。

## Query String & Simp Query String（了解）

### Query String

![](http://qiniu.zhouhongyin.top/2023/06/15/1686809254-image-20230615140734639.png)

### Simp Query String

![](http://qiniu.zhouhongyin.top/2023/06/15/1686809297-image-20230615140817397.png)

### 演示

```json
PUT /users/_doc/1
{
    "name": "Ruan Yiming",
    "about": "java, golang, node, swift, elasticsearch"
}

PUT /users/_doc/2
{
    "name": "Li Yiming",
    "about": "Hadoop"
}


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
            "fields": [
                "name",
                "about"
            ],
            "query": "(Ruan AND Yiming) OR (Java AND Elasticsearch)"
        }
    }
}


#Simple Query 默认的operator是 Or
POST users/_search
{
    "query": {
        "simple_query_string": {
            "query": "Ruan AND Yiming",
            "fields": [
                "name"
            ]
        }
    }
}


POST users/_search
{
    "query": {
        "simple_query_string": {
            "query": "Ruan Yiming",
            "fields": [
                "name"
            ],
            "default_operator": "AND"
        }
    }
}


GET /movies/_search
{
    "profile": true,
    "query": {
        "query_string": {
            "default_field": "title",
            "query": "Beafiful AND Mind"
        }
    }
}


# 多fields
GET /movies/_search
{
    "profile": true,
    "query": {
        "query_string": {
            "fields": [
                "title",
                "year"
            ],
            "query": "2012"
        }
    }
}



GET /movies/_search
{
    "profile": true,
    "query": {
        "simple_query_string": {
            "query": "Beautiful +mind",
            "fields": [
                "title"
            ]
        }
    }
}
```

# 总结

- 查询分 URI 查询和DSL查询两大类。用 DSL 查询比较多，DSL 查询有分 term query，match query 和一些复合查询。
- 三种查询的区别 query 功能强大易出错 query_string 功能简单灵活性低 simple_query_string 功能简单灵活性低