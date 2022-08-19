# join

使用的表结构

```sql
CREATE TABLE `t1` (
  `id` int(11) NOT NULL,
  `a` int(11) DEFAULT NULL,
  `b` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `a` (`a`)
) ENGINE=InnoDB;

CREATE TABLE `t2` (
  `id` int(11) NOT NULL,
  `a` int(11) DEFAULT NULL,
  `b` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `a` (`a`)
) ENGINE=InnoDB;
```

## Index Nested-Loop Join

```sql
select * from t1 straight_join t2 on (t1.a=t2.a);
-- straight_join 让 MySQL 使用固定的连接方式执行查询，这样优化器只会按照我们指定的方式去 join。在这个语句里，t1 是驱动表，t2 是被驱动表。
```

![](http://qiniu.zhouhongyin.top/2022/07/23/1658559509-4b9cb0e0b83618e01c9bfde44a0ea990.png)

1. 从表 t1 中读入一行数据 R；
2. 从数据行 R 中，取出 a 字段到表 t2 里去查找；
3. 取出表 t2 中满足条件的行，跟 R 组成一行，作为结果集的一部分；
4. 重复执行步骤 1 到 3，直到表 t1 的末尾循环结束。

这个过程是先遍历表 t1，然后根据从表 t1 中取出的每行数据中的 a 值，去表 t2 中查找满足条件的记录。在形式上，这个过程就跟我们写程序时的嵌套查询类似，并且可以用上被驱动表的索引，所以我们称之为“Index Nested-Loop Join”，简称 NLJ。

![](http://qiniu.zhouhongyin.top/2022/07/23/1658559578-d83ad1cbd6118603be795b26d38f8df6.jpeg)

> 结论：
>
> - 使用 join 语句，性能比强行拆成多个单表执行 SQL 语句的性能要好；
> - 如果使用 join 语句的话，需要让小表做驱动表。
>
> 上述条件都是在使用索引的条件下

## Simple Nested-Loop Join

```sql
select * from t1 straight_join t2 on (t1.a=t2.b);
```

由于表 t2 的字段 b 上没有索引，因此再用图 2 的执行流程时，每次到 t2 去匹配的时候，就要做一次全表扫描。

你可以先设想一下这个问题，继续使用图 2 的算法，是不是可以得到正确的结果呢？如果只看结果的话，这个算法是正确的，而且这个算法也有一个名字，叫做“Simple Nested-Loop Join”。

但是，这样算来，这个 SQL 请求就要扫描表 t2 多达 100 次，总共扫描 100*1000=10 万行。

这还只是两个小表，如果 t1 和 t2 都是 10 万行的表（当然了，这也还是属于小表的范围），就要扫描 100 亿行，这个算法看上去太“笨重”了。

当然，MySQL 也没有使用这个 Simple Nested-Loop Join 算法，而是使用了另一个叫作“Block Nested-Loop Join”的算法，简称 BNL。

## Block Nested-Loop Join

```sql
select * from t1 straight_join t2 on (t1.a=t2.b);
```

由于 t2.b 上没有索引，所以执行流程如下所示：

1. 把表 t1 的数据读入线程内存 join_buffer 中，**由于我们这个语句中写的是 select *，因此是把整个表 t1 放入了内存**；
2. 扫描表 t2，把表 t2 中的每一行取出来，跟 join_buffer 中的数据做对比，满足 join 条件的，作为结果集的一部分返回。

![](http://qiniu.zhouhongyin.top/2022/07/23/1658561639-15ae4f17c46bf71e8349a8f2ef70d573.jpeg)

![](http://qiniu.zhouhongyin.top/2022/07/23/1658561654-676921fa0883e9463dd34fb2bc5e87e1.png)

可以看到，在这个过程中，对表 t1 和 t2 都做了一次全表扫描，因此总的扫描行数是 1100。由于 join_buffer 是以无序数组的方式组织的，因此对表 t2 中的每一行，都要做 100 次判断，总共需要在内存中做的判断次数是：100*1000=10 万次。在时间复杂度上该算法和 Simple Nested-Loop Join 算法并没有差距，但是由于该算法 10万次比较实在内存中进行的，所以会更快。

### join_buffer

这个例子里表 t1 才 100 行，要是表 t1 是一个大表，join_buffer 放不下怎么办呢？

join_buffer 的大小是由参数 join_buffer_size 设定的，默认值是 256k。**如果放不下表 t1 的所有数据话，策略很简单，就是分段放**

```sql
select * from t1 straight_join t2 on (t1.a=t2.b);
```

1. 扫描表 t1，顺序读取数据行放入 join_buffer 中，放完第 88 行 join_buffer 满了，继续第 2 步；
2. 扫描表 t2，把 t2 中的每一行取出来，跟 join_buffer 中的数据做对比，满足 join 条件的，作为结果集的一部分返回；
3. 清空 join_buffer；
4. 继续扫描表 t1，顺序读取最后的 12 行数据放入 join_buffer 中，继续执行第 2 步。

![](http://qiniu.zhouhongyin.top/2022/07/23/1658562187-695adf810fcdb07e393467bcfd2f6ac4.jpeg)

在这个算法的执行过程中：

1. 扫描行数是 N+λ*N*M；
2. 内存判断 N*M 次。

显然，内存判断次数是不受选择哪个表作为驱动表影响的。而考虑到扫描行数，在 M 和 N 大小确定的情况下，N 小一些，整个算式的结果会更小。

所以结论是，应该让小表当驱动表。

当然，你会发现，在 N+λ*N*M 这个式子里，λ才是影响扫描行数的关键因素，这个值越小越好。

刚刚我们说了 N 越大，分段数 K 越大。那么，N 固定的时候，什么参数会影响 K 的大小呢？（也就是λ的大小）答案是 join_buffer_size。join_buffer_size 越大，一次可以放入的行越多，分成的段数也就越少，对被驱动表的全表扫描次数就越少。

这就是为什么，你可能会看到一些建议告诉你，如果你的 join 语句很慢，就把 join_buffer_size 改大。

### 第一个问题：能不能使用 join 语句？

- 如果可以使用 Index Nested-Loop Join 算法，也就是说可以用上被驱动表上的索引，其实是没问题的；
- 如果使用 Block Nested-Loop Join 算法，扫描行数就会过多。尤其是在大表上的 join 操作，这样可能要扫描被驱动表很多次，会占用大量的系统资源。所以这种 join 尽量不要用。

所以你在判断要不要使用 join 语句时，就是看 explain 结果里面，Extra 字段里面有没有出现“Block Nested Loop”字样。

### 第二个问题是：如果要使用 join，应该选择大表做驱动表还是选择小表做驱动表？

- 如果是 Index Nested-Loop Join 算法，应该选择小表做驱动表；
- 如果是 Block Nested-Loop Join 算法：
  - 在 join_buffer_size 足够大的时候，是一样的；
  - 在 join_buffer_size 不够大的时候（这种情况更常见），应该选择小表做驱动表。

所以，这个问题的结论就是，总是应该使用小表做驱动表。

## 什么叫作“小表”

### 情况一：

```sql
select * from t1 straight_join t2 on (t1.b=t2.b) where t2.id<=50;
select * from t2 straight_join t1 on (t1.b=t2.b) where t2.id<=50;
```

由于通过 where 筛选后 t2 只有 50 条数据成为了 “小表” 所以相比下来第二条语句更好。

### 情况二：

```sql
select t1.b,t2.* from  t1  straight_join t2 on (t1.b=t2.b) where t2.id<=100;
select t1.b,t2.* from  t2  straight_join t1 on (t1.b=t2.b) where t2.id<=100;
```

与上面不同的是，这里的 t1 没有取全部字段而是只取了字段 b 所以，join_buffer  中可以存放等多的数据，所以这里 t1 是“小表”。

> 所以，小表更准确地说，**在决定哪个表做驱动表的时候，应该是两个表按照各自的条件过滤，过滤完成之后，计算参与 join 的各个字段的总数据量，数据量小的那个表，就是“小表”，应该作为驱动表。**

## 结论

- 如果可以使用被驱动表的索引，join 语句还是有其优势的；
- 不能使用被驱动表的索引，只能使用 Block Nested-Loop Join 算法，这样的语句就尽量不要使用；
- 在使用 join 的时候，应该让小表做驱动表。

# join 时判断条件写在 on 后和写在 where 后面的区别

##  表结构

```sql
create table a(f1 int, f2 int, index(f1))engine=innodb;
create table b(f1 int, f2 int)engine=innodb;
insert into a values(1,1),(2,2),(3,3),(4,4),(5,5),(6,6);
insert into b values(3,3),(4,4),(5,5),(6,6),(7,7),(8,8);
```

## 两种 join 写法

```sql
select * from a left join b on(a.f1=b.f1) and (a.f2=b.f2); /*Q1*/

select * from a left join b on(a.f1=b.f1) where (a.f2=b.f2);/*Q2*/
```

## 执行结果

![](http://qiniu.zhouhongyin.top/2022/07/24/1658655350-871f890532349781fdc4a4287e9f91bd.png)

- 语句 Q1 返回的数据集是 6 行，表 a 中即使没有满足匹配条件的记录，查询结果中也会返回一行，并将表 b 的各个字段值填成 NULL。
- 语句 Q2 返回的是 4 行。从逻辑上可以这么理解，最后的两行，由于表 b 中没有匹配的字段，结果集里面 b.f2 的值是空，不满足 where 部分的条件判断，因此不能作为结果集的一部分。

## Q1 explain

![](http://qiniu.zhouhongyin.top/2022/07/24/1658656069-image-20220724174749432.png)

驱动表是表 a，被驱动表是表 b；由于表 b 的 f1 字段上没有索引，所以使用的是 Block Nested Loop Join（简称 BNL） 算法。

### 执行流程

1. 把表 a 的内容读入 join_buffer 中。因为是 select * ，所以字段 f1 和 f2 都被放入 join_buffer 了。
2. 顺序扫描表 b，对于每一行数据，判断 join 条件（也就是 (a.f1=b.f1) and (a.f2=b.f2)）是否满足，满足条件的记录, 作为结果集的一行返回。如果语句中有 where 子句，需要先判断 where 部分满足条件后，再返回。
3. 表 b 扫描完成后，对于没有被匹配的表 a 的行（在这个例子中就是 (1,1)、(2,2) 这两行），把剩余字段补上 NULL，再放入结果集中。

![](http://qiniu.zhouhongyin.top/2022/07/24/1658656090-8fd4b4b179fb84caaecece84b6406ad7.jpeg)

## Q2 explain

![](http://qiniu.zhouhongyin.top/2022/07/24/1658656151-f5712c56dc84d331990409a5c313ea9c.png)

这条语句是以表 b 为驱动表的。而如果一条 join 语句的 Extra 字段什么都没写的话，就表示使用的是 Index Nested-Loop Join（简称 NLJ）算法。

### 执行流程

顺序扫描表 b，每一行用 b.f1 到表 a 中去查，匹配到记录后判断 a.f2=b.f2 是否满足，满足条件的话就作为结果集的一部分返回。

## Q1 和 Q2 的区别

> 背景知识点：在 MySQL 里，NULL 跟任何值执行等值判断和不等值判断的结果，都是 NULL。这里包括， select NULL = NULL 的结果，也是返回 NULL。

因此，语句 Q2 里面 where a.f2=b.f2 就表示，查询结果里面不会包含 b.f2 是 NULL 的行，这样这个 left join 的语义就是“找到这两个表里面，f1、f2 对应相同的行。对于表 a 中存在，而表 b 中匹配不到的行，就放弃”。

这样，这条语句虽然用的是 left join，但是语义跟 join 是一致的。

因此，优化器就把这条语句的 left join 改写成了 join，然后因为表 a 的 f1 上有索引，就把表 b 作为驱动表，这样就可以用上 NLJ 算法。在执行 explain 之后，你再执行 show warnings，就能看到这个改写的结果，如图 5 所示。

![](http://qiniu.zhouhongyin.top/2022/07/24/1658656320-d74878e7469edb8b713a18c6158530ab.png)

这个例子说明，即使我们在 SQL 语句中写成 left join，执行过程还是有可能不是从左到右连接的。也就是说，**使用 left join 时，左边的表不一定是驱动表。**

这样看来，**如果需要 left join 的语义，就不能把被驱动表的字段放在 where 条件里面做等值判断或不等值判断，必须都写在 on 里面。**

## 另一个例子

```sql
select * from a join b on(a.f1=b.f1) and (a.f2=b.f2); /*Q3*/
select * from a join b on(a.f1=b.f1) where (a.f2=b.f2);/*Q4*/
```

我们再使用一次看 explain 和 show warnings 的方法，看看优化器是怎么做的。

![](http://qiniu.zhouhongyin.top/2022/07/24/1658656705-d9952e4c2150bc649c7f2977e6ea80f5.png)

图 6 join 语句改写

可以看到，这两条语句都被改写成：

```sql
select * from a join b where (a.f1=b.f1) and (a.f2=b.f2);
```

执行计划自然也是一模一样的。

也就是说，在这种情况下，join 将判断条件是否全部放在 on 部分就没有区别了。