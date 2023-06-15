# 什么是 Mapping

![](http://qiniu.zhouhongyin.top/2023/06/15/1686810773-image-20230615143253701.png)

# 字段的数据类型

![](http://qiniu.zhouhongyin.top/2023/06/15/1686810797-image-20230615143316933.png)

# Dynamic Mapping

## 什么是 Dynamic Mapping

![](http://qiniu.zhouhongyin.top/2023/06/15/1686810846-image-20230615143406913.png)



## 类型自动识别

![](http://qiniu.zhouhongyin.top/2023/06/15/1686810917-image-20230615143517668.png)

## 控制 Dynamic Mapping

![](http://qiniu.zhouhongyin.top/2023/06/15/1686811078-image-20230615143757981.png)

## Mapping 字段类型的更改

![](http://qiniu.zhouhongyin.top/2023/06/15/1686810966-image-20230615143606383.png)

> - keword 是一种字段类型 es 的每个字段可以做多字段，例如，你有一个 content 的字段，类型是text。你可以为他指定一个子字段叫 keyword（也可以取名字叫kw）类型设置成 keword， 在做term 查询时，就查询 content.keyword（或者叫 content.kw。 es 默认为所有文本都设置成 text，并且设置 keywoed 的子字段 
> -  mapping 信息是保存在cluster state里面的。 文件应该放在 nodes/{N}/_state/global-{NNN} 下面 https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-state.html 
> - 使用动态 mapping 的隐患 设置成 strict，万一有一条数据里带着不存在的字段，写入就会失败。 设置成 true，数据可以写入，还会在 mapping 中增加那个字段的设置。随着时间的流逝，这类数据会导致 mapping 设定的膨胀

## 演示

Mapping中的字段一旦设定后，禁止直接修改。因为倒排索引生成后不允许直接修改。需要重新建立新的索引，做reindex操作。

类似数据库中的表结构定义，主要作用

- 定义索引下的字段名字
- 定义字段的类型
- 定义倒排索引相关的配置（是否被索引？采用的Analyzer）

对新增字段的处理
true
false
strict

在object下，支持做dynamic的属性的定义

```json
#写入文档，查看 Mapping
PUT mapping_test/_doc/1
{
  "firstName":"Chan",
  "lastName": "Jackie",
  "loginDate":"2018-07-24T10:29:48.103Z"
}

#查看 Mapping文件
GET mapping_test/_mapping


#Delete index
DELETE mapping_test

#dynamic mapping，推断字段的类型
PUT mapping_test/_doc/1
{
    "uid" : "123",
    "isVip" : false,
    "isAdmin": "true",
    "age":19,
    "heigh":180
}

#查看 Dynamic
GET mapping_test/_mapping


#默认Mapping支持dynamic，写入的文档中加入新的字段
PUT dynamic_mapping_test/_doc/1
{
  "newField":"someValue"
}

#该字段可以被搜索，数据也在_source中出现
POST dynamic_mapping_test/_search
{
  "query":{
    "match":{
      "newField":"someValue"
    }
  }
}


#修改为dynamic false
PUT dynamic_mapping_test/_mapping
{
  "dynamic": false
}

#新增 anotherField
PUT dynamic_mapping_test/_doc/10
{
  "anotherField":"someValue"
}


#该字段不可以被搜索，因为dynamic已经被设置为false
POST dynamic_mapping_test/_search
{
  "query":{
    "match":{
      "anotherField":"someValue"
    }
  }
}

get dynamic_mapping_test/_doc/10

#修改为strict
PUT dynamic_mapping_test/_mapping
{
  "dynamic": "strict"
}



#写入数据出错，HTTP Code 400
PUT dynamic_mapping_test/_doc/12
{
  "lastField":"value"
}

DELETE dynamic_mapping_test
```

# 显式 Mapping 设置与常见参数

## 如何显示定义一个 Mapping

![](http://qiniu.zhouhongyin.top/2023/06/15/1686819610-image-20230615170010193.png)

## 自定义 Mapping 的一些建议

![](http://qiniu.zhouhongyin.top/2023/06/15/1686819646-image-20230615170046803.png)

## 常见设置和参数

###  控制当前字段是否被索引

index 控制当前字段是否需要被索引：

- true：默认为 true，该字段会被 es 索引，所以可以被搜索
- false：该字段不会被 es 索引，所以不可以被搜索，可以节省磁盘空间

![](http://qiniu.zhouhongyin.top/2023/06/15/1686819837-image-20230615170357248.png)

### Index Option（倒排索引创建配置）

![](http://qiniu.zhouhongyin.top/2023/06/15/1686820136-image-20230615170856554.png)

### null_value（Null 值处理）

因为 es 不支持对 Null 搜索，所以如果想对 Null 值进行搜索的话需要进行特殊设置。

![](http://qiniu.zhouhongyin.top/2023/06/15/1686821070-image-20230615172430585.png)

### copy_to 设置

![](http://qiniu.zhouhongyin.top/2023/06/15/1686821281-image-20230615172801083.png)

### 数组类型

![](http://qiniu.zhouhongyin.top/2023/06/15/1686821311-image-20230615172831439.png)

## 演示

```json
#设置 index 为 false
DELETE users
PUT users
{
    "mappings" : {
      "properties" : {
        "firstName" : {
          "type" : "text"
        },
        "lastName" : {
          "type" : "text"
        },
        "mobile" : {
          "type" : "text",
          "index": false
        }
      }
    }
}

PUT users/_doc/1
{
  "firstName":"Ruan",
  "lastName": "Yiming",
  "mobile": "12345678"
}

POST /users/_search
{
  "query": {
    "match": {
      "mobile":"12345678"
    }
  }
}




#设定Null_value

DELETE users
PUT users
{
    "mappings" : {
      "properties" : {
        "firstName" : {
          "type" : "text"
        },
        "lastName" : {
          "type" : "text"
        },
        "mobile" : {
          "type" : "keyword",
          "null_value": "NULL"
        }

      }
    }
}

PUT users/_doc/1
{
  "firstName":"Ruan",
  "lastName": "Yiming",
  "mobile": null
}


PUT users/_doc/2
{
  "firstName":"Ruan2",
  "lastName": "Yiming2"

}

GET users/_search
{
  "query": {
    "match": {
      "mobile":"NULL"
    }
  }

}



#设置 Copy to
DELETE users
PUT users
{
  "mappings": {
    "properties": {
      "firstName":{
        "type": "text",
        "copy_to": "fullName"
      },
      "lastName":{
        "type": "text",
        "copy_to": "fullName"
      }
    }
  }
}
PUT users/_doc/1
{
  "firstName":"Ruan",
  "lastName": "Yiming"
}

GET users/_search?q=fullName:(Ruan Yiming)

POST users/_search
{
  "query": {
    "match": {
       "fullName":{
        "query": "Ruan Yiming",
        "operator": "and"
      }
    }
  }
}


#数组类型
PUT users/_doc/1
{
  "name":"onebird",
  "interests":"reading"
}

PUT users/_doc/1
{
  "name":"twobirds",
  "interests":["reading","music"]
}

POST users/_search
{
  "query": {
		"match_all": {}
	}
}

GET users/_mapping
```

# 多字段特性及配置自定义 Analyzer

## fields（多字段类型）

出于不同的目的，以不同的方式索引同一字段，这就是多字段（*multi-fields*）的意义。比如在下面这个例子中，text 类型 city 子u但有一个 fields “row” ，他的类型时 keyword，那么当创建一条文档时，city 字段的数据，会分别以 text 类型，和 keyword 进行索引。你可通过 `city.row` 的方式使用该字段。

```json
PUT my-index-000001
{
  "mappings": {
    "properties": {
      "city": {
        "type": "text",
        "fields": {
          "raw": { 
            "type":  "keyword"
          }
        }
      }
    }
  }
}

PUT my-index-000001/_doc/1
{
  "city": "New York"
}

PUT my-index-000001/_doc/2
{
  "city": "York"
}

GET my-index-000001/_search
{
  "query": {
    "match": {
      "city": "york" 
    }
  },
  "sort": {
    "city.raw": "asc" 
  },
  "aggs": {
    "Cities": {
      "terms": {
        "field": "city.raw" 
      }
    }
  }
}
```

因为 `city.raw` 是 keyword 类型，所以你可以通过他进行排序和聚合操作。

当然，你也可以对其指定分词器。

```json
PUT my-index-000001
{
  "mappings": {
    "properties": {
      "text": { 
        "type": "text",
        "fields": {
          "english": { 
            "type":     "text",
            "analyzer": "english"
          }
        }
      }
    }
  }
}

PUT my-index-000001/_doc/1
{ "text": "quick brown fox" } 

PUT my-index-000001/_doc/2
{ "text": "quick brown foxes" } 

GET my-index-000001/_search
{
  "query": {
    "multi_match": {
      "query": "quick brown foxes",
      "fields": [ 
        "text",
        "text.english"
      ],
      "type": "most_fields" 
    }
  }
}
```

## Exact Values 和 Full Text

![](http://qiniu.zhouhongyin.top/2023/06/15/1686838162-image-20230615220922879.png)

默认情况下， ES 会为每个字段创建一个倒排索引，Excat values 在索引时不会进行特殊的分词处理。

![](http://qiniu.zhouhongyin.top/2023/06/15/1686838284-image-20230615221124736.png)

## 自定义分词

你可以通过组合分词器的组件（Character Filter、Tokenizer、Token Filter）的方式，自定义分词器。

### Character Filter

![](http://qiniu.zhouhongyin.top/2023/06/15/1686838647-image-20230615221727718.png)

### Tokenizer

![](http://qiniu.zhouhongyin.top/2023/06/15/1686838718-image-20230615221838713.png)

### Token Filter

![](http://qiniu.zhouhongyin.top/2023/06/15/1686838732-image-20230615221852436.png)

### 自定义分词器

- `mappings.properties.FIELD.`
  - `analyzer`：指定索引字段时使用的分词器
  - `search_analyzer`：指定搜索时使用的分词器，不指定则使用 `analyzer` 中的指定的
  - `search_quote_analyzer`：query_string 查询中使用（不是很懂）
- `analysis.`
  - `analyzer.my_analyzer`：指定自定义分词器名称
    - `type`：分词器类型
    - `tokenizer`：指定 tokenizer
    - `filter`：指定 Token Filter
- `filter`： 自定义 Token Filter
  - `english_stop`：自定义 Token Filter 名称

```json
PUT my-index-000001
{
   "settings":{
      "analysis":{
         "analyzer":{
            "my_analyzer":{
               "type":"custom",
               "tokenizer":"standard",
               "filter":[
                  "lowercase"
               ]
            },
            "my_stop_analyzer":{ 
               "type":"custom",
               "tokenizer":"standard",
               "filter":[
                  "lowercase",
                  "english_stop"
               ]
            }
         },
         "filter":{
            "english_stop":{
               "type":"stop",
               "stopwords":"_english_"
            }
         }
      }
   },
   "mappings":{
       "properties":{
          "title": {
             "type":"text",
             "analyzer":"my_analyzer", 
             "search_analyzer":"my_stop_analyzer", 
             "search_quote_analyzer":"my_analyzer" 
         }
      }
   }
}

PUT my-index-000001/_doc/1
{
   "title":"The Quick Brown Fox"
}

PUT my-index-000001/_doc/2
{
   "title":"A Quick Brown Fox"
}

GET my-index-000001/_search
{
   "query":{
      "query_string":{
         "query":"\"the quick brown fox\"" 
      }
   }
}
```

## 演示

```java
PUT logs/_doc/1
{"level":"DEBUG"}

GET /logs/_mapping

POST _analyze
{
  "tokenizer":"keyword",
  "char_filter":["html_strip"],
  "text": "<b>hello world</b>"
}


POST _analyze
{
  "tokenizer":"path_hierarchy",
  "text":"/user/ymruan/a/b/c/d/e"
}



#使用char filter进行替换
POST _analyze
{
  "tokenizer": "standard",
  "char_filter": [
      {
        "type" : "mapping",
        "mappings" : [ "- => _"]
      }
    ],
  "text": "123-456, I-test! test-990 650-555-1234"
}

//char filter 替换表情符号
POST _analyze
{
  "tokenizer": "standard",
  "char_filter": [
      {
        "type" : "mapping",
        "mappings" : [ ":) => happy", ":( => sad"]
      }
    ],
    "text": ["I am felling :)", "Feeling :( today"]
}

// white space and snowball
GET _analyze
{
  "tokenizer": "whitespace",
  "filter": ["stop","snowball"],
  "text": ["The gilrs in China are playing this game!"]
}


// whitespace与stop
GET _analyze
{
  "tokenizer": "whitespace",
  "filter": ["stop","snowball"],
  "text": ["The rain in Spain falls mainly on the plain."]
}


//remove 加入lowercase后，The被当成 stopword删除
GET _analyze
{
  "tokenizer": "whitespace",
  "filter": ["lowercase","stop","snowball"],
  "text": ["The gilrs in China are playing this game!"]
}

//正则表达式
GET _analyze
{
  "tokenizer": "standard",
  "char_filter": [
      {
        "type" : "pattern_replace",
        "pattern" : "http://(.*)",
        "replacement" : "$1"
      }
    ],
    "text" : "http://www.elastic.co"
}

```

