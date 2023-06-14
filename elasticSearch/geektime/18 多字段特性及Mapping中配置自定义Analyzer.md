# 多字段类型

![](http://qiniu.zhouhongyin.top/2023/05/05/1683294123-image-20230505214203539.png)

# Exact Values V.S Full Text

![](http://qiniu.zhouhongyin.top/2023/05/05/1683294171-image-20230505214251222.png)

![](http://qiniu.zhouhongyin.top/2023/05/05/1683294259-image-20230505214419113.png)

# 自定义分词

- 当Elasticsearch 自带的分词器无法满足时，可以自定义分词器。通过自组合不同的组件实现
  - Character Filter
  - Tokenizer
  - Token Filter

## Character Filters

![](http://qiniu.zhouhongyin.top/2023/05/05/1683294312-image-20230505214511933.png)

## Tokenizer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683294391-image-20230505214630912.png)

## Token Filters

![](http://qiniu.zhouhongyin.top/2023/05/05/1683294419-image-20230505214659766.png)

## 设置一个 Custom Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683294467-image-20230505214747749.png)