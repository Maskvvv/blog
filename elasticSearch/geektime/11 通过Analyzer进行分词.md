# Analysis 与 Analyzer

- Analysis -文本分析是把全文本转换一系列单词 (term / token)的过程，也叫分词
- Analysis 是通过 Analyzer 来实现的
  - 可使用 Elasticsearch 内置的分析器/或者按需定制化分析器
- 除了在数据写入时转换词条，匹配 Query 语句时候也需要用相同的分析器对查询语句进行分析

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256062-image-20230505110742104.png)

# Analyzer 的组成

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256161-image-20230505110921560.png)

# Elasticsearch 的内置分词器

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256253-image-20230505111053699.png)

## 使用 _analyzer API

- 直接指定 Analyzer 进行测试
- 指定索引的字段进行测试
- 自定义分词起进行测试

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256285-image-20230505111124985.png)

## Standard Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256366-image-20230505111246468.png)

## Simple Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256478-image-20230505111438816.png)

## Whitespace Analyzer

![image-20230505111532031](http://qiniu.zhouhongyin.top/2023/05/05/1683256532-image-20230505111532031.png)

## Stop Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256581-image-20230505111621733.png)

## Keyword Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256633-image-20230505111713120.png)

## Pattern Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256677-image-20230505111757713.png)



## Language Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256731-image-20230505111851318.png)

## 中文分词的难点

- 中文句子，切分成一个一个词 (不是一个个字)
- 英文中，单词有自然的空格作为分隔
- 一句中文，在不同的上下文，有不通的理解
  - 这个苹果，不大好吃 /这个苹果，不大，好吃!
- 一些例子
  - 他说的确实在理/这事的确定不下来

## ICU Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256908-image-20230505112147957.png)

- 需要安装 plugin
  - `Elasticsearch-plugin install analysis-icu`
- 提供了 Unicode 的支持，更好的支持亚洲语言

## 更多的中文分词器

![](http://qiniu.zhouhongyin.top/2023/05/05/1683257262-image-20230505112742457.png)

## IK 分词器

### 安装

`bin/elasticsearch-plugin  install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.8.0/elasticsearch-analysis-ik-7.8.0.zip`

### 使用

```sql
POST _analyze
{
  "analyzer": "ik_smart",
  "text":     "中华人民共和国国歌"
}

POST _analyze
{
  "analyzer": "ik_max_word",
  "text":     "中华人民共和国国歌"
}
```

- `ik_max_word`: 会将文本做最细粒度的拆分，比如会将“中华人民共和国国歌”拆分为“中华人民共和国,中华人民,中华,华人,人民共和国,人民,人,民,共和国,共和,和,国国,国歌”，会穷尽各种可能的组合，适合 Term Query； 
- `ik_smart`: 会做最粗粒度的拆分，比如会将“中华人民共和国国歌”拆分为“中华人民共和国,国歌”，适合 Phrase 查询

> 建议：生成索引时候可以使用ik_max_word，查询的时候使用ik_smart

# 演示

```sql
#Simple Analyzer – 按照非字母切分（符号被过滤），小写处理
#Stop Analyzer – 小写处理，停用词过滤（the，a，is）
#Whitespace Analyzer – 按照空格切分，不转小写
#Keyword Analyzer – 不分词，直接将输入当作输出
#Patter Analyzer – 正则表达式，默认 \W+ (非字符分隔)
#Language – 提供了30多种常见语言的分词器
#2 running Quick brown-foxes leap over lazy dogs in the summer evening

#查看不同的analyzer的效果
#standard
GET _analyze
{
  "analyzer": "standard",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

#simpe
GET _analyze
{
  "analyzer": "simple",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}


GET _analyze
{
  "analyzer": "stop",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}


#stop
GET _analyze
{
  "analyzer": "whitespace",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

#keyword
GET _analyze
{
  "analyzer": "keyword",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}

GET _analyze
{
  "analyzer": "pattern",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}


#english
GET _analyze
{
  "analyzer": "english",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}


POST _analyze
{
  "analyzer": "icu_analyzer",
  "text": "他说的确实在理”"
}


POST _analyze
{
  "analyzer": "standard",
  "text": "他说的确实在理”"
}


POST _analyze
{
  "analyzer": "icu_analyzer",
  "text": "这个苹果不大好吃"
}

```

