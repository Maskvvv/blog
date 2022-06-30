```sql
-- 查看表结构
desc table_name;

-- 查看生成表的SQL
show create table table_name;

-- 查看索引信息（包括索引结构等）
show index from  table_name;

-- 查看SQL执行时间（精确到小数点后8位）
set profiling = 1;
SQL...
show profiles;

-- 查看sql 执行计划
EXPLAIN SQL...;
```

