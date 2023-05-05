# Request Body Search

![](http://qiniu.zhouhongyin.top/2023/05/05/1683275606-image-20230505163326117.png)

# 分页

![](http://qiniu.zhouhongyin.top/2023/05/05/1683275885-image-20230505163805693.png)

# _source filtering

![](http://qiniu.zhouhongyin.top/2023/05/05/1683275957-image-20230505163917896.png)

# 脚本字段

用例: 订单中有不同的汇率需要结合汇率对，订单价格进行排序

```sql
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
```

# 使用查询表达式-Match

```sql
# term (last or christmas)
POST movies/_search
{
  "query": {
    "match": {
      "title": "last christmas"
    }
  }
}

# phrase （last and christmas）
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
```

# 短语搜索 - Match Phrase

```sql
# （last and christmas）
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

# （last something christmas）
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

