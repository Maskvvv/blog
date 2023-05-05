# Search API 分类

- URI Search
  - 使用 HTTP 的形式，在URL中使用查询参数
- Request Body Search
  - 使用 Elasticsearch 提供的，基于JSON 格式的更加完备的Query Domain Specific Language (DSL)

## 指定查询的索引

![](http://qiniu.zhouhongyin.top/2023/05/05/1683257524-image-20230505113204735.png)

## URI 查询

![](http://qiniu.zhouhongyin.top/2023/05/05/1683258180-image-20230505114300675.png)

## Request Body

![](http://qiniu.zhouhongyin.top/2023/05/05/1683258239-image-20230505114359589.png)

## 搜索 Response

![](http://qiniu.zhouhongyin.top/2023/05/05/1683258635-image-20230505115035023.png)

# 搜索的相关性 Relevance

![](http://qiniu.zhouhongyin.top/2023/05/05/1683258708-image-20230505115148431.png)

## Web  搜索

![](http://qiniu.zhouhongyin.top/2023/05/05/1683258780-image-20230505115300805.png)

## 电商搜索

![](http://qiniu.zhouhongyin.top/2023/05/05/1683258849-image-20230505115409091.png)

## 衡量相关性

- Information Retrieval

  - Precision (准) - 尽可能返回较少的无关文档
  - Recall (查全率) - 尽量返回较多的相关文档
  - Ranking - 是否能够按照相关度进行排序?

  ## Precision & Recall

![](http://qiniu.zhouhongyin.top/2023/05/05/1683259043-image-20230505115723814.png)