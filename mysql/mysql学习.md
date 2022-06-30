---
title: mysql 学习
date: 2021-07-12
tags:
  - 数据库
  - mysql 学习
  - mysql
categories:
  - 数据库
  - mysql
  - mysql 学习
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701608-download.png)

<!-- more -->

# 基础语法

## SElECT

SELECT 语句用于从数据库中选取数据。结果被存储在一个结果表中，称为结果集。

**示例：**

```sql
SELECT column_name, column_name
FROM table_name;
```

```sql
SELECT * FROM table_name;
```

## SELECT DISTINCT

在表中，一个列可能会包含多个重复值，有时您也许希望仅仅列出不同（distinct）的值。DISTINCT 关键词用于返回唯一不同的值。

**示例：**

```sql
SELECT DISTINCT column_name,column_name
FROM table_name;
```

## WHERE

​	WHERE 子句用于提取那些满足指定条件的记录。

**示例：**

```sql
SELECT column_name,column_name
FROM table_name
WHERE column_name operator value;
```

## AND & OR 运算符

如果第一个条件和第二个条件都成立，则 AND 运算符显示一条记录。如果第一个条件和第二个条件中只要有一个成立，则 OR 运算符显示一条记录。

**示例：**

```sql
-- AND
SELECT * FROM Websites
WHERE country='CN'
AND alexa > 50;

-- OR
SELECT * FROM Websites
WHERE country='USA'
OR country='CN';

-- AND & OR
SELECT * FROM Websites
WHERE alexa > 15
AND (country='CN' OR country='USA');
```

## ORDER BY

ORDER BY 关键字用于对结果集按照一个列或者多个列进行排序。

ORDER BY 关键字默认按照升序对记录进行排序。如果需要按照**降序**对记录进行排序，您可以使用 **DESC** 关键字。

**示例：**

```sql
SELECT column_name,column_name
FROM table_name
ORDER BY column_name,column_name ASC|DESC; -- 升序(默认)|降序
```

## INSERT INTO

INSERT INTO 语句用于向表中插入新记录。

**示例：**

```sql
-- 方式一(不指定要插入数据的列名，只提供被插入的值):
INSERT INTO table_name
VALUE value1,value2,value3,...);

-- 方式二(指定类名及被插入的值):
INSERT INTO table_name (column1,column2,column3,...)
VALUES (value1,value2,value3,...);
```

## UPDATE

UPDATE 语句用于更新表中已存在的记录。

**示例：**

```SQL
UPDATE table_name
SET columnl = value1, column2 = value2, ...
WHERE some_column = some_value;
```

> 请注意 SQL UPDATE 语句中的 WHERE 子句！ WHERE 子句规定哪条记录或者哪些记录需要更新。**如果您省略了 WHERE 子句，所有的记录都将被更新！**

## DELETE

DELETE 语句用于删除表中的记录。

```sql
DELETE FROM table_name
WHERE some_column=some_value;
```

> WHERE 子句规定哪条记录或者哪些记录需要删除。**如果您省略了 WHERE 子句，所有的记录都将被删除！**

# SQL 高级

## LIMIT

SELECT LIMIT 子句用于规定要返回的记 录的数目。

SELECT LIMIT 子句对于拥有数千条记录的大型表来说，是非常有用的。

> **注意：**并非所有的数据库系统都支持 SELECT LIMIT语句。 **SQL Server / MS Access** 支持 TOP *number*|*percent* 语句来选取指定的条数数据， **Oracle** 可以使用 ROWNUM 来选取。*

**示例：**

```sql
SELECT column_name(s)
FROM table_name
LIMIT number; -- number 表示显示前几条数据
```

## LIKE 

LIKE 操作符用于在 WHERE 子句中搜索列中的指定模式。

**示例：**

```sql
SELECT column_name(s)
FROM table_name
WHERE column_name LIKE “%pattern_”;
```

## 通配符

通配符可用于替代字符串中的任何其他字符。在 SQL 中，通配符与 SQL LIKE 操作符一起使用。

| 通配符                         | 描述                       |
| :----------------------------- | :------------------------- |
| %                              | 替代 0 个或多个字符        |
| _                              | 替代一个字符               |
| [*charlist*]                   | 字符列中的任何单一字符     |
| [^*charlist*] 或 [!*charlist*] | 不在字符列中的任何单一字符 |

### 使用 SQL [charlist] 通配符

MySQL 中使用 **REGEXP** 或 **NOT REGEXP** 运算符 (或 RLIKE 和 NOT RLIKE) 来操作正则表达式。

下面的 SQL 语句选取 name 以 "G"、"F" 或 "s" 开始的所有网站：

```sql
SELECT * FROM Websites
WHERE name REGEXP '^[GFs]';
```

下面的 SQL 语句选取 name 以 A 到 H 字母开头的网站：

```sql
SELECT * FROM Websites
WHERE name REGEXP '^[A-H]';
```

下面的 SQL 语句选取 name 不以 A 到 H 字母开头的网站：

```sql
SELECT * FROM Websites
WHERE name REGEXP '^[^A-H]';
```

## IN

IN 操作符允许您在 WHERE 子句中规定多个值。

**示例：**

```sql
SELECT column_name(s)
frome table_name
WHERE column_name [NOT] IN (valune1, valune2, valune3, ....);
```

## BETWEEN 

BETWEEN 操作符选取介于两个值之间的数据范围内的值（**左闭右闭区间**）。这些值可以是**数值、文本或者日期**。

**示例：**

```sql
SELECT column_name(s)
FROM table_name
WHERE column_name [NOT] BETWEEN value1 AND value2;
```

**实例：**

```sql
-- NOT
SELECT column_name
FROM table_name
WHERE NOT column_name BETWEEN 1 AND 5;

-- 数值
SELECT column_name
FROM table_name
WHERE number_column BETWEEN 1 AND 5;

-- 字符
SELECT column_name
FROM table_name
WHERE char_column BETWEEN ‘A’ AND ‘H’;

-- 日期
SELECT column_name
FROM table_name
WHERE date_column BETWEEN '2021-05-10' AND '2021-05-14';
```

## SQL 别名

通过使用 SQL，可以为表名称或列名称指定别名。

**示例：**

```sql
-- 列别名
SELECT column_name AS alias_name
FROM table_name;

-- 列别名简写
SELECT column_name alias_name
FROM table_name;

-- 合并列别名
SELECT CONCAT(column_name1, column_name2, column_name3, ...) AS alias_name
FROM table_name;
```

```sql
-- 表别名
SELECT column_name(s)
FROM table_name AS alias_name;
```

## 连接(JOIN)

SQL join 用于把来自两个或多个表的行结合起来。

下图展示了 **LEFT JOIN、RIGHT JOIN、INNER JOIN、OUTER JOIN** 相关的 7 种用法。

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701618-image-20210713110131810.png)

 **SQL JOIN 类型：**

- **left join** : 左连接，返回左表中所有的记录以及右表中连接字段相等的记录。
- **right join** : 右连接，返回右表中所有的记录以及左表中连接字段相等的记录。
- **inner join** : 内连接，又叫等值连接，只返回两个表中连接字段相等的行。
- **full join** : 外连接，返回两个表中的行：left join + right join。（MySQL中不支持 FULL OUTER JOIN）
- **cross join** : 结果是笛卡尔积，就是第一个表的行数乘以第二个表的行数。（From 两个表就是）

> **关键字 on**
>
> 数据库在通过**连接两张或多张表来返回记录时**，都会**生成一张中间的临时表**，然后再将这张临时表返回给用户。
>
> 在使用 **left jion** 时，**on** 和 **where** 条件的区别如下：
>
> - **on** 条件是在**生成临时表时**使用的条件，它不管 **on** 中的条件是否为真，都会返回左边表中的记录。
> - **where** 条件是在**临时表生成好后**，再对临时表进行过滤的条件。这时已经没有 **left join** 的含义（必须返回左边表的记录）了，**条件不为真的就全部过滤掉。**

### INNER JOIN

INNER JOIN 内连接，又叫等值连接，只返回两个表中连接字段相等的行。

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701622-img_innerjoin.gif)

**示例：**

```sql
-- 方式一
SELECT column_name(s)
FROM table1
INNER JOIN table2
ON table1.column_name = table2.column_name;

-- 方式二(省略 INNER)
SELECT column_name(s)
FROM table1
JOIN table2
ON table1.column_name = table2.column_name;
```

> **注释：**INNER JOIN 与 JOIN 是相同的。

### LEFT JOIN

LEFT JOIN 关键字从左表返回**所有的行**以及右表中连接**字段相等的记录**。如果右表中**没有匹配**，则**结果为 NULL**。

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701624-img_leftjoin.gif)

**示例：**

```SQL
SELECT column_name(s)
FROM table1
LEFT JOIN table2
ON table1.column_name = table2.column_name;
```

### RIGHT JOIN

LEFT JOIN 关键字从右表返回**所有的行**以及左表中连接**字段相等的记录**。如果右表中**没有匹配**，则**结果为 NULL**。

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701627-img_rightjoin.gif)

**示例：**

```sql
SELECT column_name(s)
FROM table1
RIGHT JOIN table2
ON table1.column_name = table2.column_name;
```

## UNION

UNION 操作符用于合并两个或多个 SELECT 语句的结果集。

请注意，UNION 内部的每个 SELECT 语句必须拥**有相同数量的列**。列也必须拥有**相似的数据类型**。同时，每个 SELECT 语句中的列的**顺序必须相同**。

**示例：**

```sql
-- UNION (只输出每行结果不同的值)
SELECT column_name(s) FROM table1
UNION
SELECT column_name(s) FROM table2;

-- UNION (将两个结果集整个输出即使有重复的值)
SELECT column_name(s) FROM table1
UNION ALL
SELECT column_name(s) FROM table2;
```

## INSERT INTO SELECT

通过 SQL，您可以从一个表复制信息到另一个表。

SELECT INTO 语句从一个表复制数据，然后把数据插入到另一个新表中。

> 两个表需要存在至少一个完全相同的列。

**示例：**

```sql
-- 方式一(从一个表中复制所有的列插入到另一个已存在的表):
INSERT INTO table2
SELECT * FROM table1;

-- 方式二(只复制希望的列插入到另一个已存在的表中):
INSERT INTO table2 (column_name(s))
SELECT column_name(s)
FROM table1;
```

> **select into from 和 insert into select 都是用来复制表**（MySql 不支持 select into from）
>
> 两者的主要区别为： **select into from** 要求**目标表不存在**，因为在插入时会**自动创建**；**insert into select from** 要求目标**表存在**。
>
> 1. 复制表结构及其数据：
>
> ```
> create table table_name_new as select * from table_name_old
> ```
>
> 2. 只复制表结构：
>
> ```
> create table table_name_new as select * from table_name_old where 1=2;
> ```
>
> 或者：
>
> ```
> create table table_name_new like table_name_old
> ```
>
> 3. 只复制表数据：
>
> 如果两个表结构一样：
>
> ```
> insert into table_name_new select * from table_name_old
> ```
>
> 如果两个表结构不一样：
>
> ```
> insert into table_name_new(column1,column2...) select column1,column2... from table_name_old
> ```

# DATABASE （数据库）

## CREATE DATABASE

CREATE DATABASE 语句用于创建数据库。

**示例：**

```sql
CREATE DATABASE dbname;
```

# TABLE（表）

## 数据类型

在 MySQL 中，有三种主要的类型：**Text（文本）**、**Number（数字）**和 **Date/Time（日期/时间）**类型。

### Text 类型

| 数据类型         | 描述                                                         |
| :--------------- | :----------------------------------------------------------- |
| CHAR(size)       | 保存**固定长度**的字符串（可包含字母、数字以及特殊字符）。在括号中指定字符串的长度。最多 255 个字符。 |
| VARCHAR(size)    | 保存**可变长度**的字符串（可包含字母、数字以及特殊字符）。在括号中指定字符串的最大长度。最多 255 个字符。<br />**注释：**如果值的长度大于 255，则被转换为 TEXT 类型。 |
| TINYTEXT         | 存放最大长度为 255 个字符的字符串。                          |
| TEXT             | 存放最大长度为 65,535 个字符的字符串。                       |
| BLOB             | 用于 BLOBs（Binary Large OBjects 大型二进制对象）。存放最多 65,535 字节的数据。 |
| MEDIUMTEXT       | 存放最大长度为 16,777,215 个字符的字符串。                   |
| MEDIUMBLOB       | 用于 BLOBs（Binary Large OBjects）。存放最多 16,777,215 字节的数据。 |
| LONGTEXT         | 存放最大长度为 4,294,967,295 个字符的字符串。                |
| LONGBLOB         | 用于 BLOBs (Binary Large OBjects)。存放最多 4,294,967,295 字节的数据。 |
| ENUM(x,y,z,etc.) | 允许您输入可能值的列表。可以在 ENUM 列表中列出最大 65535 个值。如果列表中不存在插入的值，则插入空值。**注释：**这些值是按照您输入的顺序排序的。可以按照此格式输入可能的值： ENUM('X','Y','Z') |
| SET              | 与 ENUM 类似，不同的是，SET 最多只能包含 64 个列表项且 SET 可存储一个以上的选择。 |

### Number 类型

| 数据类型        | 描述                                                         |
| :-------------- | :----------------------------------------------------------- |
| TINYINT(size)   | 带符号-128到127 ，无符号0到255。                             |
| SMALLINT(size)  | 带符号范围-32768到32767，无符号0到65535, size 默认为 6。     |
| MEDIUMINT(size) | 带符号范围-8388608到8388607，无符号的范围是0到16777215。 size 默认为9 |
| INT(size)       | 带符号范围-2147483648到2147483647，无符号的范围是0到4294967295。 size 默认为 11 |
| BIGINT(size)    | 带符号的范围是-9223372036854775808到9223372036854775807，无符号的范围是0到18446744073709551615。size 默认为 20 |
| FLOAT(size,d)   | 带有浮动小数点的小数字。在 size 参数中规定显示最大位数。在 d 参数中规定小数点右侧的最大位数。 |
| DOUBLE(size,d)  | 带有浮动小数点的大数字。在 size 参数中规显示定最大位数。在 d 参数中规定小数点右侧的最大位数。 |
| DECIMAL(size,d) | 作为字符串存储的 DOUBLE 类型，允许固定的小数点。在 size 参数中规定显示最大位数。在 d 参数中规定小数点右侧的最大位数。 |

> **注意：**以上的 size 代表的并不是存储在数据库中的具体的长度，如 int(4) 并不是只能存储4个长度的数字。
>
> 实际上 int(size) 所占多少存储空间并无任何关系。int(3)、int(4)、int(8) 在磁盘上都是占用 4 btyes 的存储空间。就是在显示给用户的方式有点不同外，int(M) 跟 int 数据类型是相同的。
>
> 例如：
>
> 1、int 的值为10 （指定 zerofill ）
>
> ```
> int（9）显示结果为000000010
> int（3）显示结果为010
> ```
>
> 就是显示的长度不一样而已都是占用四个字节的空间

### Date 类型

| 数据类型    | 描述                                                         |
| :---------- | :----------------------------------------------------------- |
| DATE()      | 日期。格式：**YYYY-MM-DD**<br />**注释：**支持的范围是从 '1000-01-01' 到 '9999-12-31' |
| DATETIME()  | 日期和时间的组合。格式：**YYYY-MM-DD HH:MM:SS**<br />**注释：**支持的范围是从 '1000-01-01 00:00:00' 到 '9999-12-31 23:59:59' |
| TIMESTAMP() | 时间戳。TIMESTAMP 值使用 Unix 纪元('1970-01-01 00:00:00' UTC) 至今的秒数来存储。格式：**YYYY-MM-DD HH:MM:SS**<br />**注释：**支持的范围是从 '1970-01-01 00:00:01' UTC 到 '2038-01-09 03:14:07' UTC |
| TIME()      | 时间。格式：**HH:MM:SS**<br />**注释：**支持的范围是从 '-838:59:59' 到 '838:59:59' |
| YEAR()      | 2 位或 4 位格式的年。<br />**注释：**4 位格式所允许的值：1901 到 2155。2 位格式所允许的值：70 到 69，表示从 1970 到 2069。 |

> 即便 DATETIME 和 TIMESTAMP 返回相同的格式，它们的工作方式很不同。在 INSERT 或 UPDATE 查询中，**TIMESTAMP 自动把自身设置为当前的日期和时间**。TIMESTAMP 也**接受不同的格式**，比如 **YYYYMMDDHHMMSS**、**YYMMDDHHMMSS**、**YYYYMMDD** 或 **YYMMDD**。

## SQL 约束（Constraints）

SQL 约束用于规定表中的数据规则。

如果存在违反约束的数据行为，行为会被约束终止。

约束可以在创建表时规定（通过 CREATE TABLE 语句），或者在表创建之后规定（通过 ALTER TABLE 语句）。

**示例：**

```sql
CREATE TABLE table_name
(
column_name1 data_type(size) constraint_name,
column_name2 data_type(size) constraint_name,
column_name3 data_type(size) constraint_name,
....
);
```

在 SQL 中，我们有如下约束：

- **NOT NULL** - 指示某列不能存储 NULL 值。
- **UNIQUE** - 保证某列的每行必须有唯一的值。
- **PRIMARY KEY** - NOT NULL 和 UNIQUE 的结合。确保某列（或两个列多个列的结合）有唯一标识，有助于更容易更快速地找到表中的一个特定的记录。
- **FOREIGN KEY** - 保证一个表中的数据匹配另一个表中的值的参照完整性。
- **CHECK** - 保证列中的值符合指定的条件。
- **DEFAULT** - 规定没有给列赋值时的默认值。

### NOT NULL 约束

NOT NULL 约束强制列不接受 NULL 值。

NOT NULL 约束强制字段始终包含值。这意味着，如果不向字段添加值，就无法插入新记录或者更新记录。

**实例：**

```sql
CREATE TABLE Persons (
    ID int NOT NULL,
    LastName varchar(255) NOT NULL,
    FirstName varchar(255) NOT NULL,
    Age int
);
```

#### 添加 NOT NULL 约束

```sql
ALTER TABLE Persons
MODIFY Age int NOT NULL;
```

#### 删除 NOT NULL 约束

```sql
ALTER TABLE Persons
MODIFY Age int NULL;
```

### UNIQUE 约束

UNIQUE 约束唯一标识数据库表中的每条记录。

UNIQUE 和 PRIMARY KEY 约束均为列或列集合提供了唯一性的保证。

PRIMARY KEY 约束拥有自动定义的 UNIQUE 约束。

请注意，每个表可以有多个 UNIQUE 约束，但是每个表只能有一个 PRIMARY KEY 约束。

**实例：**

```sql
-- 方式一（定义单个列）：
CREATE TABLE test
(
	id INT(10) NOT NULL UNIQUE
);

-- 方式二（定义单个列）：
CREATE TABLE test
(
	id INT(10) NOT NULL,
	UNIQUE (id)
);

-- 方式三（定义多个列）：
CREATE TABLE test
(
	id INT(10) NOT NULL,
    name varchar(10),
	UNIQUE (id, ...)
);
```

#### 添加 UNIQUE 约束

```sql
-- 添加单列
ALTER TABLE test
ADD UNIQUE (id);

-- 添加多列
ALTER TABLE test
ADD UNIQUE (id, name);
```

#### 撤销 UNIQUE 约束

```SQL
ALTER TABLE test
DROP UNIQUE id;
```

### PRIMARY KEY 约束

PRIMARY KEY 约束唯一标识数据库表中的每条记录。

主键必须包含唯一的值。

主键列不能包含 NULL 值。

每个表都应该有一个主键，并且每个表只能有一个主键。

```sql
-- 方式一（设置单个主键）：
CREATE TABLE test2
(
	id INT(10) PRIMARY KEY,
	name VARCHAR(10),
	UNIQUE(id)
)

-- 方式二（设置单个主键）： 
CREATE TABLE test2
(
	id INT(10),
	name VARCHAR(10),
	PRIMARY KEY (id),
	UNIQUE(name)
)

-- 方式二（设置多个个主键）： 
CREATE TABLE test2
(
	id INT(10),
	name VARCHAR(10),
	PRIMARY KEY (id, name)
)
```

#### 添加 PRIMARY KEY 约束

```sql
-- 添加单列
ALTER TABLE test
ADD PRIMARY KEY (id);

-- 添加多列
ALTER TABLE test
ADD PRIMARY KEY (id, name);
```

#### 撤销 PRIMARY KEY 约束

```SQL
ALTER TABLE test
DROP PRIMARY KEY;
```

### CHECK 约束

CHECK 约束用于限制列中的值的范围。

如果对单个列定义 CHECK 约束，那么该列只允许特定的值。

如果对一个表定义 CHECK 约束，那么此约束会基于行中其他列的值在特定的列中对值进行限制。

```sql
-- 定义单列的 CHECK 约束
CREATE TABLE Persons
(
    P_Id int NOT NULL,
    CHECK (P_Id>0)
)

-- 定义多列的 CHECK 约束
CREATE TABLE Persons
(
P_Id int NOT NULL,
City varchar(255),
CHECK (P_Id>0 AND City='Sandnes')
)
```

#### 添加 CHECK 约束

```sql
-- 添加单列
ALTER TABLE test
ADD CHECK (P_Id>0);

-- 添加多列
ALTER TABLE test
ADD CHECK (P_Id>0 AND City='Sandnes');
```

#### 撤销 CHECK 约束

```SQL
ALTER TABLE test
DROP CHECK (P_Id>0);
```

### DEFAULT 约束

DEFAULT 约束用于向列中插入默认值。

如果没有规定其他的值，那么会将默认值添加到所有的新记录。

```SQL
CREATE TABLE Persons
(
    P_Id int NOT NULL,
    City varchar(255) DEFAULT 'Sandnes'
)
```

#### 添加 DEFAULT 约束

```sql
-- 添加单列
ALTER TABLE test
ALTER `name` set DEFAULT 'zhy'
```

#### 撤销 DEFAULT 约束

```SQL
ALTER TABLE test
ALTER `name` DROP DEFAULT
```

### AUTO INCREMENT

Auto-increment 会在新记录插入表中时生成一个唯一的数字。（只有主键才能自增）

```sql
CREATE TABLE test2
(
	id INT(10) PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(10)
)AUTO_INCREMENT = 100 --(设置自增ID从100开始)
```

MySQL 使用 AUTO_INCREMENT 关键字来执行 auto-increment 任务。

默认地，AUTO_INCREMENT 的开始值是 1，每条新记录递增 1。

**要让 AUTO_INCREMENT 序列以其他的值起始**，请使用下面的 SQL 语法：

```sql
ALTER TABLE Persons AUTO_INCREMENT=100
```

#### 添加 AUTO INCREMENT

```sql
ALTER TABLE test2 
MODIFY COLUMN id INT(10) AUTO_INCREMENT;
```

#### 撤销 AUTO INCREMENT

```SQL
ALTER TABLE test2 
MODIFY COLUMN id INT(10);
```

## CREATE TABLE

CREATE TABLE 语句用于创建数据库中的表。

表由行和列组成，每个表都必须有个表名。

**示例：**

```sql
CREATE TABLE table_name
(
    column_name1 data_type(size),
    column_name2 data_type(size),
    column_name3 data_type(size),
    ....
);
-- column_name 参数规定表中列的名称。
-- data_type 参数规定列的数据类型（例如 varchar、integer、decimal、date 等等）。
-- size 参数规定表中列的最大长度。
```

## DROP

### DROP INDEX

```sql
ALTER TABLE table_name DROP INDEX index_name
```

### DROP TABLE 语句

DROP TABLE 语句用于删除表。

```sql
DROP TABLE table_name
```

### DROP DATABASE 语句

DROP DATABASE 语句用于删除数据库。

```sql
DROP DATABASE database_name
```

### TRUNCATE TABLE 语句

如果我们仅仅需要删除表内的数据，但并不删除表本身，那么我们该如何做呢？

请使用 TRUNCATE TABLE 语句：

```SQL
TRUNCATE TABLE table_name
```

## ALTER

ALTER TABLE 语句用于在已有的表中添加、删除或修改列。

```sql
-- 添加列
ALTER TABLE table_name
ADD column_name datatype

-- 删除列
ALTER TABLE table_name
DROP COLUMN column_name

-- 修改列
ALTER TABLE table_name
MODIFY COLUMN column_name datatype
```

# 函数

## Date 函数

### NOW() 函数

返回当前的日期和时间

```sql
SELECT NOW()

CREATE TABLE Orders
(
    OrderId int NOT NULL,
    OrderDate datetime DEFAULT NOW(),
    PRIMARY KEY (OrderId)
)
```

### CURDATE() 函数

CURDATE() 返回当前的日期。

```sql
SELECT CURDATE()

CREATE TABLE Orders
(
    OrderId int NOT NULL,
    OrderDate datetime DEFAULT CURDATE(),
    PRIMARY KEY (OrderId)
)
```

### CURTIME() 函数

CURTIME() 返回当前的时间。

```sql
SELECT CURTIME()

CREATE TABLE Orders
(
    OrderId int NOT NULL,
    OrderDate datetime DEFAULT CURTIME(),
    PRIMARY KEY (OrderId)
)
```

### DATE() 函数

DATE() 函数提取日期或日期时间表达式的日期部分。

**语法：**

```sql
DATE(date)
-- date 参数是合法的日期表达式。
```

**实例：**

```sql
SELECT ProductName, DATE(OrderDate) AS OrderDate
FROM Orders
WHERE OrderId=1
-- OrderDate = 2021-11-11 13:23:44.657
```

### EXTRACT() 函数

EXTRACT() 函数用于返回日期/时间的单独部分，比如年、月、日、小时、分钟等等。

**语法：**

```sql
EXTRACT(unit FROM date)
```

date 参数是合法的日期表达式。unit 参数可以是下列的值：

| Unit 值            |
| :----------------- |
| MICROSECOND        |
| SECOND             |
| MINUTE             |
| HOUR               |
| DAY                |
| WEEK               |
| MONTH              |
| QUARTER            |
| YEAR               |
| SECOND_MICROSECOND |
| MINUTE_MICROSECOND |
| MINUTE_SECOND      |
| HOUR_MICROSECOND   |
| HOUR_SECOND        |
| HOUR_MINUTE        |
| DAY_MICROSECOND    |
| DAY_SECOND         |
| DAY_MINUTE         |
| DAY_HOUR           |
| YEAR_MONTH         |

**示例：**

```sql
SELECT EXTRACT(YEAR FROM OrderDate) AS OrderYear,
EXTRACT(MONTH FROM OrderDate) AS OrderMonth,
EXTRACT(DAY FROM OrderDate) AS OrderDay
FROM Orders
WHERE OrderId=1
```

### DATE_ADD() 函数

DATE_ADD() 函数向日期添加指定的时间间隔。

**语法：**

```sql
DATE_ADD(date,INTERVAL expr type)
```

date 参数是合法的日期表达式。expr 参数是您希望添加的时间间隔。

type 参数可以是下列值：

| Type 值            |
| :----------------- |
| MICROSECOND        |
| SECOND             |
| MINUTE             |
| HOUR               |
| DAY                |
| WEEK               |
| MONTH              |
| QUARTER            |
| YEAR               |
| SECOND_MICROSECOND |
| MINUTE_MICROSECOND |
| MINUTE_SECOND      |
| HOUR_MICROSECOND   |
| HOUR_SECOND        |
| HOUR_MINUTE        |
| DAY_MICROSECOND    |
| DAY_SECOND         |
| DAY_MINUTE         |
| DAY_HOUR           |
| YEAR_MONTH         |

### DATE_SUB() 函数

DATE_SUB() 函数从日期减去指定的时间间隔。

**语法：**

```sql
DATE_SUB(date,INTERVAL expr type)
```

date 参数是合法的日期表达式。expr 参数是您希望添加的时间间隔。

type 参数可以是下列值：

| Type 值            |
| :----------------- |
| MICROSECOND        |
| SECOND             |
| MINUTE             |
| HOUR               |
| DAY                |
| WEEK               |
| MONTH              |
| QUARTER            |
| YEAR               |
| SECOND_MICROSECOND |
| MINUTE_MICROSECOND |
| MINUTE_SECOND      |
| HOUR_MICROSECOND   |
| HOUR_SECOND        |
| HOUR_MINUTE        |
| DAY_MICROSECOND    |
| DAY_SECOND         |
| DAY_MINUTE         |
| DAY_HOUR           |
| YEAR_MONTH         |

### DATEDIFF() 函数

DATEDIFF() 函数返回两个日期之间的天数。

**语法：**

```sql
DATEDIFF(date1,date2)
```

date1 和 date2 参数是合法的日期或日期/时间表达式。

> **注释：**只有值的日期部分参与计算。

### TimeStampDiff()  函数

算两日期时间之间相差的天数，秒数，分钟数，周数，小时数。

**语法：**

```sql
TIMESTAMPDIFF(unit,datetime_expr1,datetime_expr2)
```

返回日期或日期时间表达式datetime_expr1 和datetime_expr2the 之间的整数差。

其中unit单位有如下几种：

| unit                       | 释义 |
| -------------------------- | ---- |
| FRAC_SECOND (microseconds) | 毫秒 |
| SECOND                     | 秒   |
| MINUTE                     | 分钟 |
| HOUR                       | 小时 |
| DAY                        | 天   |
| WEEK                       | 星期 |
| MONTH                      | 月   |
| QUARTER                    | 季度 |
| YEAR                       | 年   |

### DATE_FORMAT() 函数

DATE_FORMAT() 函数用于以不同的格式显示日期/时间数据。

**语法：**

```sql
DATE_FORMAT(date,format)
```

date 参数是合法的日期。format 规定日期/时间的输出格式。

可以使用的格式有：

| 格式 | 描述                                           |
| :--- | :--------------------------------------------- |
| %a   | 缩写星期名                                     |
| %b   | 缩写月名                                       |
| %c   | 月，数值                                       |
| %D   | 带有英文前缀的月中的天                         |
| %d   | 月的天，数值（00-31）                          |
| %e   | 月的天，数值（0-31）                           |
| %f   | 微秒                                           |
| %H   | 小时（00-23）                                  |
| %h   | 小时（01-12）                                  |
| %I   | 小时（01-12）                                  |
| %i   | 分钟，数值（00-59）                            |
| %j   | 年的天（001-366）                              |
| %k   | 小时（0-23）                                   |
| %l   | 小时（1-12）                                   |
| %M   | 月名                                           |
| %m   | 月，数值（00-12）                              |
| %p   | AM 或 PM                                       |
| %r   | 时间，12-小时（hh:mm:ss AM 或 PM）             |
| %S   | 秒（00-59）                                    |
| %s   | 秒（00-59）                                    |
| %T   | 时间, 24-小时（hh:mm:ss）                      |
| %U   | 周（00-53）星期日是一周的第一天                |
| %u   | 周（00-53）星期一是一周的第一天                |
| %V   | 周（01-53）星期日是一周的第一天，与 %X 使用    |
| %v   | 周（01-53）星期一是一周的第一天，与 %x 使用    |
| %W   | 星期名                                         |
| %w   | 周的天（0=星期日, 6=星期六）                   |
| %X   | 年，其中的星期日是周的第一天，4 位，与 %V 使用 |
| %x   | 年，其中的星期一是周的第一天，4 位，与 %v 使用 |
| %Y   | 年，4 位                                       |
| %y   | 年，2 位                                       |

**实例：**

下面的脚本使用 DATE_FORMAT() 函数来显示不同的格式。我们使用 NOW() 来获得当前的日期/时间：

```sql
DATE_FORMAT(NOW(),'%b %d %Y %h:%i %p')
DATE_FORMAT(NOW(),'%m-%d-%Y')
DATE_FORMAT(NOW(),'%d %b %y')
DATE_FORMAT(NOW(),'%d %b %Y %T:%f')
```

结果如下所示：

```sql
Nov 04 2008 11:45 PM
11-04-2008
04 Nov 08
04 Nov 2008 11:45:34:243
```

## NULL 函数

### NULL 值

如果表中的某个列是可选的，那么我们可以在不向该列添加值的情况下插入新记录或更新已有的记录。这意味着该字段将以 NULL 值保存。

NULL 值的处理方式与其他值不同。

NULL 用作未知的或不适用的值的占位符。

> **注释：**
>
> - 无法比较 NULL 和 0；它们是不等价的。
> - 无法使用比较运算符来测试 NULL 值，比如 =、< 或 <>。

#### IS NULL 

判断某列的值是否为空。

**语法：**

```sql
SELECT column_name(s)
FROM table1
WHERE column_name1 IS NULL;
```

#### IS NOT NULL 

判断某列的值是否不为空。

**语法：**

```sql
SELECT column_name(s)
FROM table1
WHERE column_name1 IS NOT NULL;
```

# MySQL 函数汇总

## MySQL 字符串函数

| 函数                                  | 描述                                                         | 实例                                                         |
| :------------------------------------ | :----------------------------------------------------------- | :----------------------------------------------------------- |
| ASCII(s)                              | 返回字符串 s 的第一个字符的 ASCII 码。                       | 返回 CustomerName 字段第一个字母的 ASCII 码：`SELECT ASCII(CustomerName) AS NumCodeOfFirstChar FROM Customers;` |
| CHAR_LENGTH(s)                        | 返回字符串 s 的字符数                                        | 返回字符串 RUNOOB 的字符数`SELECT CHAR_LENGTH("RUNOOB") AS LengthOfString;` |
| CHARACTER_LENGTH(s)                   | 返回字符串 s 的字符数                                        | 返回字符串 RUNOOB 的字符数`SELECT CHARACTER_LENGTH("RUNOOB") AS LengthOfString;` |
| CONCAT(s1,s2...sn)                    | 字符串 s1,s2 等多个字符串合并为一个字符串                    | 合并多个字符串`SELECT CONCAT("SQL ", "Runoob ", "Gooogle ", "Facebook") AS ConcatenatedString;` |
| CONCAT_WS(x, s1,s2...sn)              | 同 CONCAT(s1,s2,...) 函数，但是每个字符串之间要加上 x，x 可以是分隔符 | 合并多个字符串，并添加分隔符：`SELECT CONCAT_WS("-", "SQL", "Tutorial", "is", "fun!")AS ConcatenatedString;` |
| FIELD(s,s1,s2...)                     | 返回第一个字符串 s 在字符串列表(s1,s2...)中的位置            | 返回字符串 c 在列表值中的位置：`SELECT FIELD("c", "a", "b", "c", "d", "e");` |
| FIND_IN_SET(s1,s2)                    | 返回在字符串 s2 中与 s1 匹配的字符串的位置                   | 返回字符串 c 在指定字符串中的位置：`SELECT FIND_IN_SET("c", "a,b,c,d,e");` |
| FORMAT(x,n)                           | 函数可以将数字 x 进行格式化 "#,###.##", 将 x 保留到小数点后 n 位，最后一位四舍五入。 | 格式化数字 "#,###.##" 形式：`SELECT FORMAT(250500.5634, 2);     -- 输出 250,500.56` |
| INSERT(s1,x,len,s2)                   | 字符串 s2 替换 s1 的 x 位置开始长度为 len 的字符串           | 从字符串第一个位置开始的 6 个字符替换为 runoob：`SELECT INSERT("google.com", 1, 6, "runoob");  -- 输出：runoob.com` |
| LOCATE(s1,s)                          | 从字符串 s 中获取 s1 的开始位置                              | 获取 b 在字符串 abc 中的位置：`SELECT LOCATE('st','myteststring');  -- 5`返回字符串 abc 中 b 的位置：`SELECT LOCATE('b', 'abc') -- 2` |
| LCASE(s)                              | 将字符串 s 的所有字母变成小写字母                            | 字符串 RUNOOB 转换为小写：`SELECT LCASE('RUNOOB') -- runoob` |
| LEFT(s,n)                             | 返回字符串 s 的前 n 个字符                                   | 返回字符串 runoob 中的前两个字符：`SELECT LEFT('runoob',2) -- ru` |
| LOWER(s)                              | 将字符串 s 的所有字母变成小写字母                            | 字符串 RUNOOB 转换为小写：`SELECT LOWER('RUNOOB') -- runoob` |
| LPAD(s1,len,s2)                       | 在字符串 s1 的开始处填充字符串 s2，使字符串长度达到 len      | 将字符串 xx 填充到 abc 字符串的开始处：`SELECT LPAD('abc',5,'xx') -- xxabc` |
| LTRIM(s)                              | 去掉字符串 s 开始处的空格                                    | 去掉字符串 RUNOOB开始处的空格：`SELECT LTRIM("    RUNOOB") AS LeftTrimmedString;-- RUNOOB` |
| MID(s,n,len)                          | 从字符串 s 的 n 位置截取长度为 len 的子字符串，同 SUBSTRING(s,n,len) | 从字符串 RUNOOB 中的第 2 个位置截取 3个 字符：`SELECT MID("RUNOOB", 2, 3) AS ExtractString; -- UNO` |
| POSITION(s1 IN s)                     | 从字符串 s 中获取 s1 的开始位置                              | 返回字符串 abc 中 b 的位置：`SELECT POSITION('b' in 'abc') -- 2` |
| REPEAT(s,n)                           | 将字符串 s 重复 n 次                                         | 将字符串 runoob 重复三次：`SELECT REPEAT('runoob',3) -- runoobrunoobrunoob` |
| REPLACE(s,s1,s2)                      | 将字符串 s2 替代字符串 s 中的字符串 s1                       | 将字符串 abc 中的字符 a 替换为字符 x：`SELECT REPLACE('abc','a','x') --xbc` |
| REVERSE(s)                            | 将字符串s的顺序反过来                                        | 将字符串 abc 的顺序反过来：`SELECT REVERSE('abc') -- cba`    |
| RIGHT(s,n)                            | 返回字符串 s 的后 n 个字符                                   | 返回字符串 runoob 的后两个字符：`SELECT RIGHT('runoob',2) -- ob` |
| RPAD(s1,len,s2)                       | 在字符串 s1 的结尾处添加字符串 s2，使字符串的长度达到 len    | 将字符串 xx 填充到 abc 字符串的结尾处：`SELECT RPAD('abc',5,'xx') -- abcxx` |
| RTRIM(s)                              | 去掉字符串 s 结尾处的空格                                    | 去掉字符串 RUNOOB 的末尾空格：`SELECT RTRIM("RUNOOB     ") AS RightTrimmedString;   -- RUNOOB` |
| SPACE(n)                              | 返回 n 个空格                                                | 返回 10 个空格：`SELECT SPACE(10);`                          |
| STRCMP(s1,s2)                         | 比较字符串 s1 和 s2，如果 s1 与 s2 相等返回 0 ，如果 s1>s2 返回 1，如果 s1<s2 返回 -1 | 比较字符串：`SELECT STRCMP("runoob", "runoob");  -- 0`       |
| SUBSTR(s, start, length)              | 从字符串 s 的 start 位置截取长度为 length 的子字符串         | 从字符串 RUNOOB 中的第 2 个位置截取 3个 字符：`SELECT SUBSTR("RUNOOB", 2, 3) AS ExtractString; -- UNO` |
| SUBSTRING(s, start, length)           | 从字符串 s 的 start 位置截取长度为 length 的子字符串         | 从字符串 RUNOOB 中的第 2 个位置截取 3个 字符：`SELECT SUBSTRING("RUNOOB", 2, 3) AS ExtractString; -- UNO` |
| SUBSTRING_INDEX(s, delimiter, number) | 返回从字符串 s 的第 number 个出现的分隔符 delimiter 之后的子串。 如果 number 是正数，返回第 number 个字符左边的字符串。 如果 number 是负数，返回第(number 的绝对值(从右边数))个字符右边的字符串。 | `SELECT SUBSTRING_INDEX('a*b','*',1) -- a SELECT SUBSTRING_INDEX('a*b','*',-1)  -- b SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('a*b*c*d*e','*',3),'*',-1)  -- c` |
| TRIM(s)                               | 去掉字符串 s 开始和结尾处的空格                              | 去掉字符串 RUNOOB 的首尾空格：`SELECT TRIM('    RUNOOB    ') AS TrimmedString;` |
| UCASE(s)                              | 将字符串转换为大写                                           | 将字符串 runoob 转换为大写：`SELECT UCASE("runoob"); -- RUNOOB` |
| UPPER(s)                              | 将字符串转换为大写                                           | 将字符串 runoob 转换为大写：`SELECT UPPER("runoob"); -- RUNOOB` |

------

## MySQL 数字函数

| 函数名                             | 描述                                                         | 实例                                                         |
| :--------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| ABS(x)                             | 返回 x 的绝对值                                              | 返回 -1 的绝对值：`SELECT ABS(-1) -- 返回1`                  |
| ACOS(x)                            | 求 x 的反余弦值(参数是弧度)                                  | `SELECT ACOS(0.25);`                                         |
| ASIN(x)                            | 求反正弦值(参数是弧度)                                       | `SELECT ASIN(0.25);`                                         |
| ATAN(x)                            | 求反正切值(参数是弧度)                                       | `SELECT ATAN(2.5);`                                          |
| ATAN2(n, m)                        | 求反正切值(参数是弧度)                                       | `SELECT ATAN2(-0.8, 2);`                                     |
| AVG(expression)                    | 返回一个表达式的平均值，expression 是一个字段                | 返回 Products 表中Price 字段的平均值：`SELECT AVG(Price) AS AveragePrice FROM Products;` |
| CEIL(x)                            | 返回大于或等于 x 的最小整数                                  | `SELECT CEIL(1.5) -- 返回2`                                  |
| CEILING(x)                         | 返回大于或等于 x 的最小整数                                  | `SELECT CEILING(1.5); -- 返回2`                              |
| COS(x)                             | 求余弦值(参数是弧度)                                         | `SELECT COS(2);`                                             |
| COT(x)                             | 求余切值(参数是弧度)                                         | `SELECT COT(6);`                                             |
| COUNT(expression)                  | 返回查询的记录总数，expression 参数是一个字段或者 * 号       | 返回 Products 表中 products 字段总共有多少条记录：`SELECT COUNT(ProductID) AS NumberOfProducts FROM Products;` |
| DEGREES(x)                         | 将弧度转换为角度                                             | `SELECT DEGREES(3.1415926535898) -- 180`                     |
| n DIV m                            | 整除，n 为被除数，m 为除数                                   | 计算 10 除于 5：`SELECT 10 DIV 5;  -- 2`                     |
| EXP(x)                             | 返回 e 的 x 次方                                             | 计算 e 的三次方：`SELECT EXP(3) -- 20.085536923188`          |
| FLOOR(x)                           | 返回小于或等于 x 的最大整数                                  | 小于或等于 1.5 的整数：`SELECT FLOOR(1.5) -- 返回1`          |
| GREATEST(expr1, expr2, expr3, ...) | 返回列表中的最大值                                           | 返回以下数字列表中的最大值：`SELECT GREATEST(3, 12, 34, 8, 25); -- 34`返回以下字符串列表中的最大值：`SELECT GREATEST("Google", "Runoob", "Apple");   -- Runoob` |
| LEAST(expr1, expr2, expr3, ...)    | 返回列表中的最小值                                           | 返回以下数字列表中的最小值：`SELECT LEAST(3, 12, 34, 8, 25); -- 3`返回以下字符串列表中的最小值：`SELECT LEAST("Google", "Runoob", "Apple");   -- Apple` |
| LN                                 | 返回数字的自然对数，以 e 为底。                              | 返回 2 的自然对数：`SELECT LN(2);  -- 0.6931471805599453`    |
| LOG(x) 或 LOG(base, x)             | 返回自然对数(以 e 为底的对数)，如果带有 base 参数，则 base 为指定带底数。 | `SELECT LOG(20.085536923188) -- 3 SELECT LOG(2, 4); -- 2`    |
| LOG10(x)                           | 返回以 10 为底的对数                                         | `SELECT LOG10(100) -- 2`                                     |
| LOG2(x)                            | 返回以 2 为底的对数                                          | 返回以 2 为底 6 的对数：`SELECT LOG2(6);  -- 2.584962500721156` |
| MAX(expression)                    | 返回字段 expression 中的最大值                               | 返回数据表 Products 中字段 Price 的最大值：`SELECT MAX(Price) AS LargestPrice FROM Products;` |
| MIN(expression)                    | 返回字段 expression 中的最小值                               | 返回数据表 Products 中字段 Price 的最小值：`SELECT MIN(Price) AS MinPrice FROM Products;` |
| MOD(x,y)                           | 返回 x 除以 y 以后的余数                                     | 5 除于 2 的余数：`SELECT MOD(5,2) -- 1`                      |
| PI()                               | 返回圆周率(3.141593）                                        | `SELECT PI() --3.141593`                                     |
| POW(x,y)                           | 返回 x 的 y 次方                                             | 2 的 3 次方：`SELECT POW(2,3) -- 8`                          |
| POWER(x,y)                         | 返回 x 的 y 次方                                             | 2 的 3 次方：`SELECT POWER(2,3) -- 8`                        |
| RADIANS(x)                         | 将角度转换为弧度                                             | 180 度转换为弧度：`SELECT RADIANS(180) -- 3.1415926535898`   |
| RAND()                             | 返回 0 到 1 的随机数                                         | `SELECT RAND() --0.93099315644334`                           |
| ROUND(x)                           | 返回离 x 最近的整数                                          | `SELECT ROUND(1.23456) --1`                                  |
| SIGN(x)                            | 返回 x 的符号，x 是负数、0、正数分别返回 -1、0 和 1          | `SELECT SIGN(-10) -- (-1)`                                   |
| SIN(x)                             | 求正弦值(参数是弧度)                                         | `SELECT SIN(RADIANS(30)) -- 0.5`                             |
| SQRT(x)                            | 返回x的平方根                                                | 25 的平方根：`SELECT SQRT(25) -- 5`                          |
| SUM(expression)                    | 返回指定字段的总和                                           | 计算 OrderDetails 表中字段 Quantity 的总和：`SELECT SUM(Quantity) AS TotalItemsOrdered FROM OrderDetails;` |
| TAN(x)                             | 求正切值(参数是弧度)                                         | `SELECT TAN(1.75);  -- -5.52037992250933`                    |
| TRUNCATE(x,y)                      | 返回数值 x 保留到小数点后 y 位的值（与 ROUND 最大的区别是不会进行四舍五入） | `SELECT TRUNCATE(1.23456,3) -- 1.234`                        |

------

## MySQL 日期函数

| 函数名                            | 描述                                                         | 实例                                                         |
| :-------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| ADDDATE(d,n)                      | 计算起始日期 d 加上 n 天的日期                               | `SELECT ADDDATE("2017-06-15", INTERVAL 10 DAY); ->2017-06-25` |
| ADDTIME(t,n)                      | n 是一个时间表达式，时间 t 加上时间表达式 n                  | 加 5 秒：`SELECT ADDTIME('2011-11-11 11:11:11', 5); ->2011-11-11 11:11:16 (秒)`添加 2 小时, 10 分钟, 5 秒:`SELECT ADDTIME("2020-06-15 09:34:21", "2:10:5");  -> 2020-06-15 11:44:26` |
| CURDATE()                         | 返回当前日期                                                 | `SELECT CURDATE(); -> 2018-09-19`                            |
| CURRENT_DATE()                    | 返回当前日期                                                 | `SELECT CURRENT_DATE(); -> 2018-09-19`                       |
| CURRENT_TIME                      | 返回当前时间                                                 | `SELECT CURRENT_TIME(); -> 19:59:02`                         |
| CURRENT_TIMESTAMP()               | 返回当前日期和时间                                           | `SELECT CURRENT_TIMESTAMP() -> 2018-09-19 20:57:43`          |
| CURTIME()                         | 返回当前时间                                                 | `SELECT CURTIME(); -> 19:59:02`                              |
| DATE()                            | 从日期或日期时间表达式中提取日期值                           | `SELECT DATE("2017-06-15");     -> 2017-06-15`               |
| DATEDIFF(d1,d2)                   | 计算日期 d1->d2 之间相隔的天数                               | `SELECT DATEDIFF('2001-01-01','2001-02-02') -> -32`          |
| DATE_ADD(d，INTERVAL expr type)   | 计算起始日期 d 加上一个时间段后的日期，type 值可以是：MICROSECONDSECONDMINUTEHOURDAYWEEKMONTHQUARTERYEARSECOND_MICROSECONDMINUTE_MICROSECONDMINUTE_SECONDHOUR_MICROSECONDHOUR_SECONDHOUR_MINUTEDAY_MICROSECONDDAY_SECONDDAY_MINUTEDAY_HOURYEAR_MONTH | `SELECT DATE_ADD("2017-06-15", INTERVAL 10 DAY);     -> 2017-06-25 SELECT DATE_ADD("2017-06-15 09:34:21", INTERVAL 15 MINUTE); -> 2017-06-15 09:49:21 SELECT DATE_ADD("2017-06-15 09:34:21", INTERVAL -3 HOUR); ->2017-06-15 06:34:21 SELECT DATE_ADD("2017-06-15 09:34:21", INTERVAL -3 HOUR); ->2017-04-15` |
| DATE_FORMAT(d,f)                  | 按表达式 f 的要求显示日期 d                                  | `SELECT DATE_FORMAT('2011-11-11 11:11:11','%Y-%m-%d %r') -> 2011-11-11 11:11:11 AM` |
| DATE_SUB(date,INTERVAL expr type) | 函数从日期减去指定的时间间隔。                               | Orders 表中 OrderDate 字段减去 2 天：`SELECT OrderId,DATE_SUB(OrderDate,INTERVAL 2 DAY) AS OrderPayDate FROM Orders` |
| DAY(d)                            | 返回日期值 d 的日期部分                                      | `SELECT DAY("2017-06-15");   -> 15`                          |
| DAYNAME(d)                        | 返回日期 d 是星期几，如 Monday,Tuesday                       | `SELECT DAYNAME('2011-11-11 11:11:11') ->Friday`             |
| DAYOFMONTH(d)                     | 计算日期 d 是本月的第几天                                    | `SELECT DAYOFMONTH('2011-11-11 11:11:11') ->11`              |
| DAYOFWEEK(d)                      | 日期 d 今天是星期几，1 星期日，2 星期一，以此类推            | `SELECT DAYOFWEEK('2011-11-11 11:11:11') ->6`                |
| DAYOFYEAR(d)                      | 计算日期 d 是本年的第几天                                    | `SELECT DAYOFYEAR('2011-11-11 11:11:11') ->315`              |
| EXTRACT(type FROM d)              | 从日期 d 中获取指定的值，type 指定返回的值。 type可取值为： MICROSECONDSECONDMINUTEHOURDAYWEEKMONTHQUARTERYEARSECOND_MICROSECONDMINUTE_MICROSECONDMINUTE_SECONDHOUR_MICROSECONDHOUR_SECONDHOUR_MINUTEDAY_MICROSECONDDAY_SECONDDAY_MINUTEDAY_HOURYEAR_MONTH | `SELECT EXTRACT(MINUTE FROM '2011-11-11 11:11:11')  -> 11`   |
| FROM_DAYS(n)                      | 计算从 0000 年 1 月 1 日开始 n 天后的日期                    | `SELECT FROM_DAYS(1111) -> 0003-01-16`                       |
| HOUR(t)                           | 返回 t 中的小时值                                            | `SELECT HOUR('1:2:3') -> 1`                                  |
| LAST_DAY(d)                       | 返回给给定日期的那一月份的最后一天                           | `SELECT LAST_DAY("2017-06-20"); -> 2017-06-30`               |
| LOCALTIME()                       | 返回当前日期和时间                                           | `SELECT LOCALTIME() -> 2018-09-19 20:57:43`                  |
| LOCALTIMESTAMP()                  | 返回当前日期和时间                                           | `SELECT LOCALTIMESTAMP() -> 2018-09-19 20:57:43`             |
| MAKEDATE(year, day-of-year)       | 基于给定参数年份 year 和所在年中的天数序号 day-of-year 返回一个日期 | `SELECT MAKEDATE(2017, 3); -> 2017-01-03`                    |
| MAKETIME(hour, minute, second)    | 组合时间，参数分别为小时、分钟、秒                           | `SELECT MAKETIME(11, 35, 4); -> 11:35:04`                    |
| MICROSECOND(date)                 | 返回日期参数所对应的微秒数                                   | `SELECT MICROSECOND("2017-06-20 09:34:00.000023"); -> 23`    |
| MINUTE(t)                         | 返回 t 中的分钟值                                            | `SELECT MINUTE('1:2:3') -> 2`                                |
| MONTHNAME(d)                      | 返回日期当中的月份名称，如 November                          | `SELECT MONTHNAME('2011-11-11 11:11:11') -> November`        |
| MONTH(d)                          | 返回日期d中的月份值，1 到 12                                 | `SELECT MONTH('2011-11-11 11:11:11') ->11`                   |
| NOW()                             | 返回当前日期和时间                                           | `SELECT NOW() -> 2018-09-19 20:57:43`                        |
| PERIOD_ADD(period, number)        | 为 年-月 组合日期添加一个时段                                | `SELECT PERIOD_ADD(201703, 5);    -> 201708`                 |
| PERIOD_DIFF(period1, period2)     | 返回两个时段之间的月份差值                                   | `SELECT PERIOD_DIFF(201710, 201703); -> 7`                   |
| QUARTER(d)                        | 返回日期d是第几季节，返回 1 到 4                             | `SELECT QUARTER('2011-11-11 11:11:11') -> 4`                 |
| SECOND(t)                         | 返回 t 中的秒钟值                                            | `SELECT SECOND('1:2:3') -> 3`                                |
| SEC_TO_TIME(s)                    | 将以秒为单位的时间 s 转换为时分秒的格式                      | `SELECT SEC_TO_TIME(4320) -> 01:12:00`                       |
| STR_TO_DATE(string, format_mask)  | 将字符串转变为日期                                           | `SELECT STR_TO_DATE("August 10 2017", "%M %d %Y"); -> 2017-08-10` |
| SUBDATE(d,n)                      | 日期 d 减去 n 天后的日期                                     | `SELECT SUBDATE('2011-11-11 11:11:11', 1) ->2011-11-10 11:11:11 (默认是天)` |
| SUBTIME(t,n)                      | 时间 t 减去 n 秒的时间                                       | `SELECT SUBTIME('2011-11-11 11:11:11', 5) ->2011-11-11 11:11:06 (秒)` |
| SYSDATE()                         | 返回当前日期和时间                                           | `SELECT SYSDATE() -> 2018-09-19 20:57:43`                    |
| TIME(expression)                  | 提取传入表达式的时间部分                                     | `SELECT TIME("19:30:10"); -> 19:30:10`                       |
| TIME_FORMAT(t,f)                  | 按表达式 f 的要求显示时间 t                                  | `SELECT TIME_FORMAT('11:11:11','%r') 11:11:11 AM`            |
| TIME_TO_SEC(t)                    | 将时间 t 转换为秒                                            | `SELECT TIME_TO_SEC('1:12:00') -> 4320`                      |
| TIMEDIFF(time1, time2)            | 计算时间差值                                                 | `SELECT TIMEDIFF("13:10:11", "13:10:10"); -> 00:00:01`       |
| TIMESTAMP(expression, interval)   | 单个参数时，函数返回日期或日期时间表达式；有2个参数时，将参数加和 | `SELECT TIMESTAMP("2017-07-23",  "13:10:11"); -> 2017-07-23 13:10:11` |
| TO_DAYS(d)                        | 计算日期 d 距离 0000 年 1 月 1 日的天数                      | `SELECT TO_DAYS('0001-01-01 01:01:01') -> 366`               |
| WEEK(d)                           | 计算日期 d 是本年的第几个星期，范围是 0 到 53                | `SELECT WEEK('2011-11-11 11:11:11') -> 45`                   |
| WEEKDAY(d)                        | 日期 d 是星期几，0 表示星期一，1 表示星期二                  | `SELECT WEEKDAY("2017-06-15"); -> 3`                         |
| WEEKOFYEAR(d)                     | 计算日期 d 是本年的第几个星期，范围是 0 到 53                | `SELECT WEEKOFYEAR('2011-11-11 11:11:11') -> 45`             |
| YEAR(d)                           | 返回年份                                                     | `SELECT YEAR("2017-06-15"); -> 2017`                         |
| YEARWEEK(date, mode)              | 返回年份及第几周（0到53），mode 中 0 表示周天，1表示周一，以此类推 | `SELECT YEARWEEK("2017-06-15"); -> 201724`                   |

------

## MySQL 高级函数

| 函数名                                                       | 描述                                                         | 实例                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| BIN(x)                                                       | 返回 x 的二进制编码                                          | 15 的 2 进制编码:`SELECT BIN(15); -- 1111`                   |
| BINARY(s)                                                    | 将字符串 s 转换为二进制字符串                                | `SELECT BINARY "RUNOOB"; -> RUNOOB`                          |
| `CASE expression    WHEN condition1 THEN result1    WHEN condition2 THEN result2   ...    WHEN conditionN THEN resultN    ELSE result END` | CASE 表示函数开始，END 表示函数结束。如果 condition1 成立，则返回 result1, 如果 condition2 成立，则返回 result2，当全部不成立则返回 result，而当有一个成立之后，后面的就不执行了。 | `SELECT CASE  　WHEN 1 > 0 　THEN '1 > 0' 　WHEN 2 > 0 　THEN '2 > 0' 　ELSE '3 > 0' 　END ->1 > 0` |
| CAST(x AS type)                                              | 转换数据类型                                                 | 字符串日期转换为日期：`SELECT CAST("2017-08-29" AS DATE); -> 2017-08-29` |
| COALESCE(expr1, expr2, ...., expr_n)                         | 返回参数中的第一个非空表达式（从左向右）                     | `SELECT COALESCE(NULL, NULL, NULL, 'runoob.com', NULL, 'google.com'); -> runoob.com` |
| CONNECTION_ID()                                              | 返回唯一的连接 ID                                            | `SELECT CONNECTION_ID(); -> 4292835`                         |
| CONV(x,f1,f2)                                                | 返回 f1 进制数变成 f2 进制数                                 | `SELECT CONV(15, 10, 2); -> 1111`                            |
| CONVERT(s USING cs)                                          | 函数将字符串 s 的字符集变成 cs                               | `SELECT CHARSET('ABC') ->utf-8     SELECT CHARSET(CONVERT('ABC' USING gbk)) ->gbk` |
| CURRENT_USER()                                               | 返回当前用户                                                 | `SELECT CURRENT_USER(); -> guest@%`                          |
| DATABASE()                                                   | 返回当前数据库名                                             | `SELECT DATABASE();    -> runoob`                            |
| IF(expr,v1,v2)                                               | 如果表达式 expr 成立，返回结果 v1；否则，返回结果 v2。       | `SELECT IF(1 > 0,'正确','错误')     ->正确`                  |
| [IFNULL(v1,v2)](https://www.runoob.com/mysql/mysql-func-ifnull.html) | 如果 v1 的值不为 NULL，则返回 v1，否则返回 v2。              | `SELECT IFNULL(null,'Hello Word') ->Hello Word`              |
| ISNULL(expression)                                           | 判断表达式是否为 NULL                                        | `SELECT ISNULL(NULL); ->1`                                   |
| LAST_INSERT_ID()                                             | 返回最近生成的 AUTO_INCREMENT 值                             | `SELECT LAST_INSERT_ID(); ->6`                               |
| NULLIF(expr1, expr2)                                         | 比较两个字符串，如果字符串 expr1 与 expr2 相等 返回 NULL，否则返回 expr1 | `SELECT NULLIF(25, 25); ->`                                  |
| SESSION_USER()                                               | 返回当前用户                                                 | `SELECT SESSION_USER(); -> guest@%`                          |
| SYSTEM_USER()                                                | 返回当前用户                                                 | `SELECT SYSTEM_USER(); -> guest@%`                           |
| USER()                                                       | 返回当前用户                                                 | `SELECT USER(); -> guest@%`                                  |
| VERSION()                                                    | 返回数据库的版本号                                           | `SELECT VERSION() -> 5.6.34`                                 |