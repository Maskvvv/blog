# 文档的 CRUD 

![](http://qiniu.zhouhongyin.top/2023/05/05/1683251659-image-20230505095419151.png)

- Type 名，约定都用 _doc
- Create - 如果 ID 已经存在，会失败
- Index - 如果ID不存在，创建新的文档。否则，先删除现有的文档再创建新的文档，版本会增加
- Update - 文档必须已经存在，更新只会对相应字段做增量修改

> 当创建文档时，指定的索引不存在，ES 会根据数据自动创建索引

# Create 一个文档

![](http://qiniu.zhouhongyin.top/2023/05/05/1683251758-image-20230505095558614.png)

# Get 一个文档

![](http://qiniu.zhouhongyin.top/2023/05/05/1683251919-image-20230505095839425.png)

# Index 文档

![](http://qiniu.zhouhongyin.top/2023/05/05/1683252039-image-20230505100039719.png)

# Update 文档

![](http://qiniu.zhouhongyin.top/2023/05/05/1683252200-image-20230505100320682.png)

# 实战演练

```sql
############Create Document############
#create document. 自动生成 _id
POST users/_doc
{
	"user" : "Mike",
    "post_date" : "2019-04-15T14:12:12",
    "message" : "trying out Kibana"
}

#create document. 指定Id。如果id已经存在，报错
PUT users/_doc/1?op_type=create
{
    "user" : "Jack",
    "post_date" : "2019-05-15T14:12:12",
    "message" : "trying out Elasticsearch"
}

#create document. 指定 ID 如果已经存在，就报错
PUT users/_create/1
{
     "user" : "Jack",
    "post_date" : "2019-05-15T14:12:12",
    "message" : "trying out Elasticsearch"
}

### Get Document by ID
#Get the document by ID
GET users/_doc/1


###  Index & Update
#Update 指定 ID  (先删除，在写入)
GET users/_doc/1

PUT users/_doc/1
{
	"user" : "Mike"

}


#GET users/_doc/1
#在原文档上增加字段
POST users/_update/1/
{
    "doc":{
        "post_date" : "2019-05-15T14:12:12",
        "message" : "trying out Elasticsearch"
    }
}



### Delete by Id
# 删除文档
DELETE users/_doc/1


### Bulk 操作
#执行两次，查看每次的结果

#执行第1次
POST _bulk
{ "index" : { "_index" : "test", "_id" : "1" } }
{ "field1" : "value1" }
{ "delete" : { "_index" : "test", "_id" : "2" } }
{ "create" : { "_index" : "test2", "_id" : "3" } }
{ "field1" : "value3" }
{ "update" : {"_id" : "1", "_index" : "test"} }
{ "doc" : {"field2" : "value2"} }


#执行第2次
POST _bulk
{ "index" : { "_index" : "test", "_id" : "1" } }
{ "field1" : "value1" }
{ "delete" : { "_index" : "test", "_id" : "2" } }
{ "create" : { "_index" : "test2", "_id" : "3" } }
{ "field1" : "value3" }
{ "update" : {"_id" : "1", "_index" : "test"} }
{ "doc" : {"field2" : "value2"} }

### mget 操作
GET /_mget
{
    "docs" : [
        {
            "_index" : "test",
            "_id" : "1"
        },
        {
            "_index" : "test",
            "_id" : "2"
        }
    ]
}


#URI中指定index
GET /test/_mget
{
    "docs" : [
        {

            "_id" : "1"
        },
        {

            "_id" : "2"
        }
    ]
}


GET /_mget
{
    "docs" : [
        {
            "_index" : "test",
            "_id" : "1",
            "_source" : false
        },
        {
            "_index" : "test",
            "_id" : "2",
            "_source" : ["field3", "field4"]
        },
        {
            "_index" : "test",
            "_id" : "3",
            "_source" : {
                "include": ["user"],
                "exclude": ["user.location"]
            }
        }
    ]
}

### msearch 操作
POST kibana_sample_data_ecommerce/_msearch
{}
{"query" : {"match_all" : {}},"size":1}
{"index" : "kibana_sample_data_flights"}
{"query" : {"match_all" : {}},"size":2}


### 清除测试数据
#清除数据
DELETE users
DELETE test
DELETE test2
```

# Bulk API

![](http://qiniu.zhouhongyin.top/2023/05/05/1683253260-image-20230505102100656.png)

- 支持在一次 API 调用中，对不同的索引进行操作
- 支持四种类型操作
  - Index
  - Create
  - Update
  - Delete
- 可以再 URI 中指定 Index，也可以在请求的 Payload 中进行
- 操作中单条操作失败，并不会影响其他操作
- 返回结果包括了每一条操作执行的结果

# 常见错误返回

![](http://qiniu.zhouhongyin.top/2023/05/05/1683253574-image-20230505102614172.png)

# 其他

## 关于 Index 文档

- Index = 删除再创建 
- Create = 创建新文档，如果已经存在，会报错 
- Update = 会对文档做增量的更新

## 关于 POST 和 PUT

对于ES的POST、PUT请求可以这么按照http请求的“幂等性”来理解。

PUT方法要求是幂等的，POST方式不是幂等的，POST方法修改资源状态时，URL指示的是该资源的父级资源，待修改资源的信息在请求体中携带。而PUT方法修改资源状态时，URL直接指示待修改资源。 所以，对于ES的PUT请求，URL上需要明确到document ID，即可以新增又可以更新整个文档（ES的更新都是get-有就delete-再创建），但无论如何都是这一个document。由于PUT请求既可以新增又可以更新的特性，为了提供put-if-absent特性，即没有时才新增，增加了op_type=create的选项（op_type只有create、index）。 而POST请求URL是不需要指定ID的，每次都会创建一个新的文档，就不是幂等的。 （其实PUT请求执行的操作，把PUT换成POST也是可以的，但这个官方没有说，是实验出来的） 上面是根据Http请求来区分，如果根据ES API来区分： index： 针对整个文档，既可以新增又可以更新； create：只是新增操作，已有报错，可以用PUT指定ID，或POST不指定ID； update：指的是部分更新，官方只是说用POST，请求body里用script或 doc里包含文档要更新的部分； delete和read：就是delete和get请求了，比较简单。