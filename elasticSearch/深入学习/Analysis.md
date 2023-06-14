# Analysis 与 Analyzer

Analysis -文本分析是把全文本转换一系列单词 (term / token)的过程，也叫分词。

Analysis 是通过 Analyzer 来实现的，你可使用 Elasticsearch 内置的分析器 / 或者按需定制化分析器 进行分词。

除了在数据写入时转换词条，匹配 Query 语句时候也需要用相同的分析器对查询语句进行分析

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256062-image-20230505110742104.png)

# Analyzer 的组成

分词器是专门专门处理分词的组件，Analyzer 由 3 部分组成：

- Character Filters：针对原始文本进行处理，比如去除 html 标签
- Tokenizer：按照规则切分单词，比如 英语中根据空格切分单词
- Token Filters：将切分的单词进行加工，比如 小写，增加同义词 等

![](http://qiniu.zhouhongyin.top/2023/06/14/1686752924-image-20230614222844013.png)

# 使用 _analyzer API 的 3 种方式

## 直接指定 Analyzer 进行测试

```json
GET _analyze
{
  "analyzer": "standard",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## 指定索引的字段进行测试

```json
GET book/_analyze
{
  "field": "title",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## 自定义分词起进行测试

```json
GET /_analyze
{
  "tokenizer": "standard",
  "filter": ["lowercase"],
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

# Elasticsearch 的内置分词器

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256253-image-20230505111053699.png)

## Standard Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256366-image-20230505111246468.png)

```json
#standard
GET _analyze
{
  "analyzer": "standard",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## Simple Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256478-image-20230505111438816.png)

```json
#simpe
GET _analyze
{
  "analyzer": "simple",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## Whitespace Analyzer

![image-20230505111532031](http://qiniu.zhouhongyin.top/2023/05/05/1683256532-image-20230505111532031.png)

```json
GET _analyze
{
  "analyzer": "whitespace",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## Stop Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256581-image-20230505111621733.png)

```json
GET _analyze
{
  "analyzer": "stop",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## Keyword Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256633-image-20230505111713120.png)

```json
GET _analyze
{
  "analyzer": "keyword",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## Pattern Analyzer

![](http://qiniu.zhouhongyin.top/2023/05/05/1683256677-image-20230505111757713.png)

```json
GET _analyze
{
  "analyzer": "pattern",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

## English Analyzer

```json
#english
GET _analyze
{
  "analyzer": "english",
  "text": "2 running Quick brown-foxes leap over lazy dogs in the summer evening."
}
```

# 中文分词

## ICU Analyzer

![](http://qiniu.zhouhongyin.top/2023/06/14/1686753808-image-20230614224328315.png)

```json
POST _analyze
{
  "analyzer": "icu_analyzer",
  "text": "他说的确实在理”"
}
```

## ik 分词器

https://github.com/medcl/elasticsearch-analysis-ik/releases?after=v7.11.1

- ik_max_word：会将文本做最细粒度的拆分，比如会将“中华人民共和国国歌”拆分为“中华人民共和国,中华人民,中华,华人,人民共和国,人民,人,民,共和国,共和,和,国国,国歌”，会穷尽各种可能的组合，适合 Term Query； 
- ik_smart：会做最粗粒度的拆分，比如会将“中华人民共和国国歌”拆分为“中华人民共和国,国歌”，适合 Phrase 查询

```json
# ik_max_word 会将文本做最细粒度的拆分
GET _analyze
{
  "text": "中华人民共和国国歌",
  "analyzer": "ik_max_word"
}

# ik_smart 最粗粒度的拆分
GET _analyze
{
  "text": "中华人民共和国国歌",
  "analyzer": "ik_smart"
}
```

## Pinyin 分词器

https://github.com/medcl/elasticsearch-analysis-pinyin

```json
GET /_analyze
{
  "text": ["天安门"],
  "analyzer": "pinyin"
}
```

## hanlp 分词器

https://github.com/KennFalcon/elasticsearch-analysis-hanlp

```json
GET _analyze
{
  "text": "hanlp是一个自然语言处理包，能更好的根据上下文的语义，人名，地名，组织机构名等来切分词。其中hanlp在业界的名声最响。",
  "analyzer":"hanlp"
}
```

