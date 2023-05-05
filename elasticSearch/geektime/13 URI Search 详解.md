# URI Search - 通过 URI query 实现搜索

![](http://qiniu.zhouhongyin.top/2023/05/05/1683265319-image-20230505134159724.png)

```sql
#基本查询
GET /movies/_search?q=2012&df=title&sort=year:desc&from=0&size=10&timeout=1s

#带profile
GET /movies/_search?q=2012&df=title
{
	"profile":"true"
}
```

# Query String Syntax (1)

![](http://qiniu.zhouhongyin.top/2023/05/05/1683265851-image-20230505135051254.png)

```sql
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
```

# Query String Syntax (2)

![](http://qiniu.zhouhongyin.top/2023/05/05/1683266100-image-20230505135500633.png)

```sql
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

# 查找美丽心灵（必须包含 Mind，不一定包含 Beautiful）
GET /movies/_search?q=title:(Beautiful %2BMind)
{
	"profile":"true"
}
```

# Query String Syntax (3)

![](http://qiniu.zhouhongyin.top/2023/05/05/1683275098-image-20230505162458622.png)

```sql
#范围查询 ,区间写法
GET /movies/_search?q=title:beautiful AND year:[2002 TO 2018%7D
{
	"profile":"true"
}
```

# Query String Syntax (4)

![](http://qiniu.zhouhongyin.top/2023/05/05/1683275479-image-20230505163118893.png)

```sql
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

