# 如何显示定义一个 Mapping

![](http://qiniu.zhouhongyin.top/2023/05/05/1683292887-image-20230505212127488.png)

# 自定义 Mapping的一些建议

![](http://qiniu.zhouhongyin.top/2023/05/05/1683292908-image-20230505212148054.png)

# 控制当前字段是否被索引

![](http://qiniu.zhouhongyin.top/2023/05/05/1683292959-image-20230505212239150.png)

# Index Options

![](http://qiniu.zhouhongyin.top/2023/05/05/1683293003-image-20230505212323652.png)

# null_value

![](http://qiniu.zhouhongyin.top/2023/05/05/1683293093-image-20230505212453110.png)

# copy_to 设置

![](http://qiniu.zhouhongyin.top/2023/05/05/1683293141-image-20230505212541433.png)

# 数组类型

![](http://qiniu.zhouhongyin.top/2023/05/05/1683293260-image-20230505212739999.png)

# 演示

```sql

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

# 其他

- text类型和keyword类型 
- 多字段定义 

一切文本类型的字符串可以定义成 “text”或“keyword”两种类型。区别在于，text类型会使用默认分词器分词，当然你也可以为他指定特定的分词器。如果定义成keyword类型，那么默认就不会对其进行分词。 

es 对字符串类型的 mapping 设定，会将其定义成 text，同时为他定义一个叫做 keyword 的子字段。keyword 只是他的名字，你也可以定义成kw。这个字段的类型是keyword（这是一个类型的关键字） 多字段类型情况下，你可以查询 title，也可以查询title.keyword查询类型为keyword的子字段