# 全局锁

顾名思义，全局锁就是对整个数据库实例加锁。MySQL 提供了一个加全局读锁的方法，命令是 `Flush tables with read lock` (FTWRL) ，通过命令 `unlock tables` 可以解除该锁，当然如果执行 `flush tables with read lock` 命令行窗口退出后，则数据库会恢复为执行该命令之前的状态。当你需要让整个库处于只读状态的时候，可以使用这个命令，之后其他线程的以下语句会被阻塞：**数据更新语句 DML**（数据的增删改）、数据定义语句 DDL（包括建表、修改表结构等）和更新类事务的提交语句。

**全局锁的典型使用场景是，做全库逻辑备份**。也就是把整库每个表都 select 出来存成文本。

让整库都只读，可能会有以下问题：

- 如果你在主库上备份，那么在备份期间都不能执行更新，业务基本上就得停摆；
- 如果你在从库上备份，那么备份期间从库不能执行主库同步过来的 binlog，会导致主从延迟。

官方自带的逻辑备份工具是 **mysqldump**。当 **mysqldump** 使用参数 `–single-transaction` 的时候，导数据之前就会启动一个事务，来确保拿到一致性视图。而由于 **MVCC** 的支持，这个过程中数据是可以正常更新的。

你一定在疑惑，有了这个功能，为什么还需要 **FTWRL** 呢？一致性读是好，但前提是引擎要支持这个隔离级别。比如，对于 **MyISAM** 这种不支持事务的引擎，如果备份过程中有更新，总是只能取到最新的数据，那么就破坏了备份的一致性。这时，我们就需要使用 **FTWRL** 命令了。

你也许会问，既然要全库只读，为什么不使用 `set global readonly=true` 的方式呢？确实 **readonly** 方式也可以让全库进入只读状态，但我还是会建议你用 **FTWRL** 方式，主要有两个原因：

- 一是，在有些系统中，**readonly** 的值会被用来做其他逻辑，比如用来判断一个库是主库还是备库。因此，修改 global 变量的方式影响面更大，我不建议你使用。
- 二是，在异常处理机制上有差异。如果执行 **FTWRL** 命令之后由于客户端发生异常断开，那么 MySQL 会自动释放这个全局锁，整个库回到可以正常更新的状态。而将整个库设置为 **readonly** 之后，如果客户端发生异常，则数据库就会一直保持 **readonly** 状态，这样会导致整个库长时间处于不可写状态，风险较高。

# 表级锁

MySQL 里面表级别的锁有两种：一种是表锁，一种是元数据锁（meta data lock，MDL)，这两中锁都是由 Server层实现的。

## 表锁

表锁的语法是 `lock tables table_name read/write`。与 FTWRL 类似，可以用 `unlock tables` 主动释放锁，也可以在客户端断开的时候自动释放。需要注意，lock tables 语法除了会限制别的线程的读写外，也限定了本线程接下来的操作对象。

举个例子, 如果在某个线程 A 中执行 `lock tables t1 read, t2 write`; 这个语句，则其他线程写 t1、读写 t2 的语句都会被阻塞。同时，线程 A 在执行 unlock tables 之前，也只能执行读 t1、读写 t2 的操作。连写 t1 都不允许，自然也不能访问其他表。

在还没有出现更细粒度的锁的时候，表锁是最常用的处理并发的方式。而对于 InnoDB 这种支持行锁的引擎，一般不使用 lock tables 命令来控制并发，毕竟锁住整个表的影响面还是太大。

## 元数据锁（meta data lock，MDL)

**MDL 不需要显式使用，在访问一个表的时候会被自动加上**。**MDL 作用是防止 DDL 和 DML 并发的冲突**。你可以想象一下，如果一个查询正在遍历一个表中的数据，而执行期间另一个线程对这个表结构做变更，删了一列，那么查询线程拿到的结果跟表结构对不上，肯定是不行的。

因此，在 MySQL 5.5 版本中引入了 MDL，**当对一个表做增删改查操作的时候，加 MDL 读锁**；**当要对表做结构变更操作的时候，加 MDL 写锁**。

- 读锁之间不互斥，因此你可以有多个线程同时对一张表增删改查。
- 读写锁之间、写锁之间是互斥的，用来保证变更表结构操作的安全性。因此，如果有两个线程要同时给一个表加字段，其中一个要等另一个执行完才能开始执行。

### 场景演示

![img](http://qiniu.zhouhongyin.top/2023/03/10/1678417911-7cf6a3bf90d72d1f0fc156ececdfb0ce.jpeg)

**现象的解释：**

- session A 获取 MDL 读锁，并且没有释放
- session B 获取的 MDL 的读锁，读锁之间不互斥，所以 session B 不会被阻塞
- session C 需要获取 MDL 的写锁，因为session A 还在持有读锁，读锁和写锁互斥，所以 session C 会被阻塞
- session D 需要获取读锁，为了防止 session 饿死的存在，每个表都有一个锁队列，由于 session C 的写锁先于 session D 的读锁，在 session C 获取写锁之前 session D 也会被阻塞

> MySQL 对申请 MDL 锁的操作会形成一个队列，队列中写锁获取优先级高于读锁。一旦出现写锁等待，不但当前操作会被阻塞，同时还会阻塞后续该表的所有操作

### 关于 Online DDL

由于 DDL 执行时如果锁表的话会严重影响性能，不锁表又难搞定操作期间 DML 语句的影响，于是 MySQL 推出了全新的 Online DDL概念。

Online DDL 的过程：

1. 拿 MDL 写锁
2. 降级成 MDL 读锁
3. 真正做 DDL
4. 升级成 MDL 写锁
5. 释放 MDL 锁

接着上面的例子解释 Online DDL，当把 session A commit 后，session C 和 session D 会先后结束阻塞。在 MySQL 8.0 版本中，`ALTER TABLE table_name ADD` 和 `ALTER TABLE table_name DROP COLUME ` 会有所区别，如果把 session C 中的语句换成 `ALTER TABLE table_name DROP COLUME ` 那么 session D 会先获得读锁，而 session  C 会被阻塞，原因解释：

1. session C 拿 MDL 写锁
2. session C 降级成 MDL 读锁
3. session D 拿 MDL 读锁
4. session C 真正做 DDL
5. **session C 升级成 MDL 写锁 （阻塞），如果 session D 事务不提交，session C 就会一直阻塞**

### 我关于 Alter table 的测试

版本说明：MySQL 8.0.12，隔离级别

![image-20230310160117568](http://qiniu.zhouhongyin.top/2023/03/10/1678435279-image-20230310160117568.png)

场景说明：将 session B 中的语句换成以下几种，当 session A commit 后，session B 和 session C 的阻塞情况：

#### ALTER TABLE table1 ADD column1

![image-20230310155829226](http://qiniu.zhouhongyin.top/2023/03/10/1678435111-image-20230310155829226.png)

session B 和 session C 都不会被阻塞

1. session B 获取 MDL 写锁，并且执行完 DDL，后释放锁
2. 在session B 执行完毕后，session C 获取 MDL 读锁，执行查询

#### ALTER TABLE table1 MODIFY column1

同 `ALTER TABLE table1 ADD column1`

#### ALTER TABLE table1 DROP COLUMN colum1

![image-20230310155956302](http://qiniu.zhouhongyin.top/2023/03/10/1678435202-image-20230310155956302.png)

session B 被阻塞，session C 执行

1. session B 拿 MDL 写锁
2. session B 降级成 MDL 读锁
3. session C 拿 MDL 读锁
4. session B 真正做 DDL
5. session B 升级成 MDL 写锁（阻塞）

#### ALTER table table1 ADD INDEX index1(column1)

![image-20230310160035645](http://qiniu.zhouhongyin.top/2023/03/10/1678435237-image-20230310160035645.png)

session B 和 session C 仍然被阻塞（不确定原因，不知道是不是 MySQL 的 bug）

解决方案：

1. 设置锁的超时时间：

```sql
-- 单位 秒,只在当前会话中生效
set lock_wait_timeout=10
ALTER table table1 ADD INDEX index1(column1)
```

2. 使用表锁

```sql
lock table table1 write;
ALTER table table1 ADD INDEX index1(column1)
unlock table
```

### 如何安全地给小表加字段

首先我们要解决长事务，事务不提交，就会一直占着 MDL 锁。在 MySQL 的 **information_schema** 库的 **innodb_trx** 表中，你可以查到当前执行中的事务，通过 `SELECT * FROM information_schema.innodb_trx`。如果你要做 DDL 变更的表刚好有长事务在执行，要考虑先暂停 DDL，或者 `kill` 掉这个长事务。

但考虑一下这个场景。如果你要变更的表是一个热点表，虽然数据量不大，但是上面的请求很频繁，而你不得不加个字段，你该怎么做呢？

这时候 kill 可能未必管用，因为新的请求马上就来了。比较理想的机制是，**在 alter table 语句里面设定等待时间**，如果在这个指定的等待时间里面能够拿到 MDL 写锁最好，拿不到也不要阻塞后面的业务语句，先放弃。之后开发人员或者 DBA 再通过重试命令重复这个过程。

```sql
ALTER TABLE tbl_name NOWAIT add column ...
ALTER TABLE tbl_name WAIT N add column ...
```

或者

```sql
-- 单位 秒,只在当前会话中生效
set lock_wait_timeout=10
ALTER TABLE auth_account ADD ...
```

> 事务或者锁的排查命令：
>
> ```sql
> SELECT * FROM information_schema.INNODB_TRX;
> 
> show processlist;
> 
> select * from performance_schema.metadata_locks;
> 
> SELECT * FROM sys.schema_table_lock_waits
> 
> KILL 120
> 
> SELECT version()
> ```
