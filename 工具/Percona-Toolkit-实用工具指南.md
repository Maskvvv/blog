# Percona Toolkit 实用工具指南

## 概述

Percona Toolkit 是一套强大的 MySQL 数据库管理工具集，本文档重点介绍两个在生产环境中最常用的工具：
- **pt-online-schema-change**: 在线表结构变更工具
- **pt-archiver**: 数据归档和清理工具

---

## 1. pt-online-schema-change - 在线表结构变更工具

### 🎯 工具简介

`pt-online-schema-change` 是一个用于在线修改 MySQL 表结构的工具，它可以在不锁表的情况下执行 DDL 操作，避免了传统 `ALTER TABLE` 语句对业务的影响。

### 🔧 工作原理

1. **创建影子表**: 复制原表结构并应用变更
2. **创建触发器**: 在原表上创建触发器，同步数据变更
3. **数据复制**: 将原表数据复制到新表
4. **原子交换**: 快速交换表名完成变更
5. **清理资源**: 删除触发器和临时表

### 📝 基本语法

```bash
pt-online-schema-change [OPTIONS] --alter="ALTER_STATEMENT" D=database,t=table
```

### 🚀 使用示例

#### 1. Dry Run 模式（推荐先执行）

```bash
# 预览执行计划，不实际修改表
pt-online-schema-change \
  --alter="ADD COLUMN new_col VARCHAR(50) DEFAULT 'default_value'" \
  --host=127.0.0.1 --port=33060 --user=root --password=1234567788 \
  --progress=time,30 \
  --dry-run \
  D=test,t=user
```

**输出解析：**
- `Creating new table...`: 创建临时表 `test._user_new`
- `Altering new table...`: 在临时表上执行DDL变更
- `Not creating triggers because this is a dry run`: 跳过触发器创建
- `Not copying rows because this is a dry run`: 跳过数据复制
- `Dry run complete. test.user was not altered`: 预览完成，原表未修改

#### 2. 实际执行

```bash
# 实际执行表结构变更
pt-online-schema-change \
  --alter="ADD COLUMN new_col VARCHAR(50) DEFAULT 'default_value'" \
  --host=127.0.0.1 --port=33060 --user=root --password=1234567788 \
  --progress=time,30 \
  --execute \
  D=test,t=user
```

**执行流程解析：**
1. `Created new table test._user_new OK` - 创建新表
2. `Altered test._user_new OK` - 修改新表结构
3. `Created triggers OK` - 创建数据同步触发器
4. `Copying approximately 4 rows...` - 复制现有数据
5. `Copied rows OK` - 数据复制完成
6. `Swapped original and new tables OK` - 原子交换表名
7. `Dropped old table test._user_old OK` - 删除旧表
8. `Successfully altered test.user` - 变更成功完成

**验证结果：**
```sql
-- 查看新表结构
DESC test.user;
-- 新列已成功添加：new_col | varchar(50) | YES | | default_value |

-- 查看数据
SELECT id, username, new_col FROM test.user;
-- 所有现有记录的new_col字段都自动填充了默认值 'default_value'
```

### 📋 常用参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `--alter` | DDL 变更语句 | `"ADD COLUMN col1 INT"` |
| `--dry-run` | 预览模式，不实际执行 | - |
| `--execute` | 实际执行变更 | - |
| `--host` | MySQL服务器地址 | `--host=127.0.0.1` |
| `--port` | MySQL服务器端口 | `--port=33060` |
| `--user` | MySQL用户名 | `--user=root` |
| `--password` | MySQL密码 | `--password=your_password` |
| `--progress` | 显示进度信息 | `--progress=time,30` (每30秒显示时间进度) |
| `--chunk-size` | 每次复制的行数 | `--chunk-size=1000` |
| `--max-lag` | 主从延迟阈值（秒） | `--max-lag=5` |
| `--critical-load` | 系统负载阈值 | `--critical-load="Threads_running=50"` |

**重要提示：**
- 数据库和表名格式：`D=database_name,t=table_name`
- `--progress=time,30` 表示每30秒显示一次时间进度
- 必须指定 `--dry-run` 或 `--execute` 其中之一

### 🎯 适用场景

#### ✅ 推荐使用场景：

1. **添加列**
   ```bash
   --alter="ADD COLUMN status TINYINT DEFAULT 1"
   ```

2. **修改列属性**
   ```bash
   --alter="MODIFY COLUMN name VARCHAR(100) NOT NULL"
   ```

3. **添加索引**
   ```bash
   --alter="ADD INDEX idx_create_time (create_time)"
   ```

4. **删除索引**
   ```bash
   --alter="DROP INDEX idx_old_column"
   ```

#### ❌ 不适用场景：

- 表没有主键或唯一键
- 表有外键约束
- 表有触发器
- 需要重命名表

### 🛡️ 安全建议

1. **必须先执行 dry-run**
2. **在业务低峰期执行**
3. **监控系统负载和主从延迟**
4. **备份重要数据**
5. **测试环境先验证**

---

## 2. pt-archiver - 数据归档和清理工具

### 🎯 工具简介

`pt-archiver` 是一个用于归档和删除 MySQL 表中旧数据的工具，它可以安全地处理大量数据，避免长时间锁表。

### 🔧 工作原理

1. **分批查询**: 根据条件分批查询数据
2. **数据处理**: 将数据写入文件、另一个表或直接删除
3. **逐行提交**: 每处理一行数据提交一次事务
4. **性能控制**: 通过限制批次大小和添加延迟控制性能影响

### 📝 基本语法

```bash
pt-archiver --source DSN --where WHERE_CONDITION [--dest DSN | --file FILE | --purge]
```

### 🚀 使用示例

#### 1. 归档到文件

```bash
# 将数据归档到文件
pt-archiver \
  --source h=127.0.0.1,P=3306,u=root,p=password,D=database,t=table \
  --where "create_time < DATE_SUB(NOW(), INTERVAL 3 MONTH)" \
  --file /backup/archived_data_$(date +%Y%m%d).sql \
  --limit 1000 \
  --commit-each \
  --dry-run
```

#### 2. 归档到另一个表

```bash
# 将数据迁移到归档表
pt-archiver \
  --source h=127.0.0.1,P=3306,u=root,p=password,D=prod,t=orders \
  --dest h=127.0.0.1,P=3306,u=root,p=password,D=archive,t=old_orders \
  --where "order_date < '2023-01-01'" \
  --limit 500 \
  --sleep 1 \
  --dry-run
```

#### 3. 直接删除数据

```bash
# 直接删除旧数据
pt-archiver \
  --source h=127.0.0.1,P=3306,u=root,p=password,D=logs,t=access_log \
  --where "log_time < DATE_SUB(NOW(), INTERVAL 7 DAY)" \
  --purge \
  --limit 1000 \
  --commit-each \
  --sleep 0.1 \
  --dry-run
```

### 📋 常用参数说明

| 参数 | 说明 | 示例 |
|------|------|------|
| `--source` | 源数据库连接信息 | `h=host,P=port,u=user,p=pass,D=db,t=table` |
| `--dest` | 目标数据库连接信息 | 同 source 格式 |
| `--file` | 归档到文件 | `--file /backup/data.sql` |
| `--purge` | 直接删除，不保存 | - |
| `--where` | 过滤条件 | `"id > 1000 AND status = 'inactive'"` |
| `--limit` | 每批处理行数 | `--limit 1000` |
| `--commit-each` | 每行提交一次事务 | - |
| `--sleep` | 每批处理后休眠时间（秒） | `--sleep 0.5` |
| `--dry-run` | 预览模式 | - |

### 🎯 使用场景

#### 1. 历史数据清理

**场景**: 清理3个月前的访问日志

```bash
pt-archiver \
  --source h=localhost,u=root,p=password,D=website,t=access_logs \
  --where "access_time < DATE_SUB(NOW(), INTERVAL 3 MONTH)" \
  --purge \
  --limit 2000 \
  --sleep 0.5 \
  --commit-each
```

#### 2. 数据迁移

**场景**: 将已完成的订单迁移到历史表

```bash
pt-archiver \
  --source h=localhost,u=root,p=password,D=ecommerce,t=orders \
  --dest h=localhost,u=root,p=password,D=archive,t=historical_orders \
  --where "status = 'completed' AND order_date < '2023-01-01'" \
  --limit 1000 \
  --sleep 1
```

#### 3. 数据备份

**场景**: 备份重要客户数据

```bash
pt-archiver \
  --source h=localhost,u=root,p=password,D=crm,t=customers \
  --file /backup/vip_customers_$(date +%Y%m%d).sql \
  --where "customer_level = 'VIP'" \
  --limit 500
  # 注意：使用 --file 参数时，pt-archiver 默认不删除原数据
```

#### 4. 测试数据清理

**场景**: 清理测试环境的临时数据

```bash
pt-archiver \
  --source h=test-server,u=root,p=password,D=test_db,t=temp_data \
  --where "created_at < DATE_SUB(NOW(), INTERVAL 1 DAY)" \
  --purge \
  --limit 5000 \
  --commit-each
```

### 🛡️ 安全建议

1. **必须先执行 dry-run 预览**
2. **合理设置 limit 和 sleep 参数**
3. **在业务低峰期执行**
4. **重要数据先备份**
5. **监控数据库性能指标**

### ⚠️ 常见问题与注意事项

#### 1. pt-online-schema-change 参数格式问题

**❌ 错误的参数格式：**
```bash
# 错误：--progress 参数缺少具体值
pt-online-schema-change --alter="ADD COLUMN col1 INT" \
  --progress \
  --dry-run D=test,t=user
```

**✅ 正确的参数格式：**
```bash
# 正确：--progress 必须指定具体的显示方式
pt-online-schema-change --alter="ADD COLUMN col1 INT" \
  --host=127.0.0.1 --port=33060 --user=root --password=password \
  --progress=time,30 \
  --dry-run D=test,t=user
```

**重要说明：**
- `--progress=time,30` 表示每30秒显示一次时间进度
- 连接参数必须明确指定：`--host`, `--port`, `--user`, `--password`
- 数据库表格式：`D=database_name,t=table_name`
- 必须指定 `--dry-run`（预览）或 `--execute`（执行）

#### 2. pt-online-schema-change 热点表锁定问题

**🔥 问题描述：热点表一直有数据变更，Creating triggers步骤卡住**

**❓ 会一直等待下去吗？**

- **不会无限等待**：pt-online-schema-change有内置超时和负载检查机制
- **默认行为**：会根据 `--max-load` 和 `--critical-load` 参数自动暂停或中断
- **用户控制**：可以随时使用 Ctrl+C 安全中断

**🛠️ 解决方案：**

**方案1：优化执行时机和参数**
```bash
# 在业务低峰期执行，使用保守参数
pt-online-schema-change \
  --alter="ADD COLUMN new_col VARCHAR(50)" \
  --host=127.0.0.1 --port=33060 --user=root --password=password \
  --max-lag=1 \
  --critical-load="Threads_running=10" \
  --chunk-size=100 \
  --sleep=2 \
  --progress=time,10 \
  --execute D=test,t=hot_table
```

**方案2：实时监控和诊断**
```bash
# 检查阻塞情况
mysql -e "SHOW PROCESSLIST;" | grep -E "(Waiting|Locked)"

# 检查MDL锁（MySQL 5.7+）
mysql -e "SELECT object_schema, object_name, lock_type, lock_status 
         FROM performance_schema.metadata_locks 
         WHERE object_name = 'your_table';"
```

**方案3：紧急处理流程**
```bash
# 1. 安全中断（推荐）
# 在pt-osc终端按 Ctrl+C

# 2. 清理残留的临时表和触发器
mysql -e "DROP TABLE IF EXISTS test._table_new;
DROP TRIGGER IF EXISTS test.pt_osc_table_del;
DROP TRIGGER IF EXISTS test.pt_osc_table_upd;
DROP TRIGGER IF EXISTS test.pt_osc_table_ins;"

# 3. 优化参数重新执行
```

**🎯 生产环境最佳实践：**
- **渐进式参数调优**：从保守参数开始，逐步调整
- **业务配合**：在业务低峰期执行，必要时协调业务暂停写入
- **实时监控**：监控系统负载、主从延迟、锁等待情况
- **应急预案**：准备回滚方案和紧急处理流程

**⚠️ 关键参数说明：**
- `--max-lag=1`：主从延迟超过1秒立即暂停
- `--critical-load="Threads_running=10"`：系统负载过高时中断
- `--chunk-size=100`：减小批次大小，降低锁竞争
- `--sleep=2`：每批次间暂停2秒，给业务让路

#### 3. pt-archiver 参数问题

**❌ 错误用法：使用 --execute 参数**
```bash
# 错误：pt-archiver 没有 --execute 参数
pt-archiver --source ... --dest ... --execute
```

**✅ 正确用法：默认就是执行模式**
```bash
# 正确：不需要 --execute 参数
pt-archiver --source ... --dest ... --where "condition"

# 预览模式使用 --dry-run
pt-archiver --source ... --dest ... --where "condition" --dry-run
```

**说明**: pt-archiver 默认就是执行模式，只有 `--dry-run` 是预览模式，没有 `--execute` 参数。

#### 2. 目标表创建问题

**❌ 常见误解：pt-archiver 会自动创建目标表**
```bash
# 这会报错：Table 'db.target_table' doesn't exist
pt-archiver --source h=host,D=db,t=source_table \
           --dest h=host,D=db,t=non_existing_table \
           --where "condition"
```

**✅ 正确做法：必须手动创建目标表**
```bash
# 步骤1：创建目标表（与源表相同结构）
mysql -e "CREATE TABLE archive_db.orders_archive LIKE prod_db.orders;"

# 步骤2：可选 - 添加归档管理字段
mysql -e "ALTER TABLE archive_db.orders_archive 
         ADD COLUMN archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
         ADD COLUMN archived_by VARCHAR(50) DEFAULT USER();"

# 步骤3：执行归档
pt-archiver --source h=host,D=prod_db,t=orders \
           --dest h=host,D=archive_db,t=orders_archive \
           --where "order_date < '2024-01-01'"
```

**设计原因**:
- **安全考虑**: 避免因表名错误而意外创建表
- **结构控制**: 让用户明确控制目标表结构
- **权限验证**: 确保用户有创建表的权限和意图
- **数据安全**: 防止自动创建导致的数据丢失风险

#### 3. 推荐的目标表创建模式

**模式1：完全相同结构**
```sql
CREATE TABLE target_table LIKE source_table;
```

**模式2：添加归档管理字段**
```sql
CREATE TABLE orders_archive LIKE orders;
ALTER TABLE orders_archive 
ADD COLUMN archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN archived_by VARCHAR(50) DEFAULT USER(),
ADD COLUMN archive_reason VARCHAR(200);
```

**模式3：自定义结构（只保留需要的字段）**
```sql
CREATE TABLE orders_summary (
    id INT PRIMARY KEY,
    order_no VARCHAR(50),
    customer_id INT,
    total_amount DECIMAL(10,2),
    order_date DATE,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 3. 最佳实践

### 📋 重要注意事项

1. **pt-archiver 默认行为说明**
   - 使用 `--file` 参数时：只导出数据，不删除原表数据
   - 使用 `--dest` 参数时：先插入目标表，再删除源表数据
   - 使用 `--purge` 参数时：直接删除数据，不保存

2. **使用 --commit-each 避免长事务**

3. **合理设置批次大小和延迟时间**

### 🔄 标准操作流程

#### pt-online-schema-change 流程：

1. **环境准备**
   - 确认表有主键或唯一键
   - 检查磁盘空间（需要额外空间存储临时表）
   - 确认没有外键约束

2. **预览执行**
   ```bash
   # 先执行 dry-run
   pt-online-schema-change --alter="..." --dry-run ...
   ```

3. **实际执行**
   ```bash
   # 确认无误后执行
   pt-online-schema-change --alter="..." --execute ...
   ```

4. **监控验证**
   - 监控系统负载
   - 检查主从延迟
   - 验证表结构变更结果

#### pt-archiver 流程：

1. **数据分析**
   - 统计需要归档的数据量
   - 确认过滤条件的准确性
   - 评估执行时间

2. **预览执行**
   ```bash
   # 先执行 dry-run
   pt-archiver --source ... --where "..." --dry-run
   ```

3. **小批量测试**
   ```bash
   # 先处理少量数据测试
   pt-archiver --source ... --limit 100 --execute
   ```

4. **批量执行**
   ```bash
   # 确认无误后批量处理
   pt-archiver --source ... --limit 1000 --sleep 1 --execute
   ```

### 📊 性能调优建议

#### pt-online-schema-change 调优：

```bash
pt-online-schema-change \
  --alter="ADD COLUMN new_col INT" \
  --chunk-size=1000 \
  --max-lag=5 \
  --critical-load="Threads_running=50" \
  --progress=time,30 \
  --execute \
  D=database,t=table
```

#### pt-archiver 调优：

```bash
pt-archiver \
  --source h=host,u=user,p=pass,D=db,t=table \
  --where "condition" \
  --limit 1000 \
  --sleep 0.1 \
  --commit-each \
  --statistics \
  --purge
```

### 🚨 故障处理

#### 常见问题及解决方案：

1. **pt-online-schema-change 中断**
   - 检查临时表是否存在：`SHOW TABLES LIKE '%_new'`
   - 清理触发器：`SHOW TRIGGERS`
   - 手动清理临时资源

2. **pt-archiver 执行缓慢**
   - 调整 `--limit` 参数
   - 增加 `--sleep` 时间
   - 检查索引是否合适

3. **主从延迟过大**
   - 降低 `--chunk-size`
   - 增加 `--max-lag` 阈值
   - 暂停执行等待同步

---

## 4. 监控和日志

### 📈 关键监控指标

- **系统负载**: CPU、内存、磁盘 I/O
- **数据库指标**: 连接数、锁等待、主从延迟
- **执行进度**: 已处理行数、剩余时间
- **错误日志**: 异常和警告信息

### 📝 日志记录建议

```bash
# 记录执行日志
pt-online-schema-change \
  --alter="..." \
  --execute \
  --progress=time,30 \
  D=db,t=table \
  2>&1 | tee schema_change_$(date +%Y%m%d_%H%M%S).log

pt-archiver \
  --source ... \
  --purge \
  --statistics \
  2>&1 | tee archiver_$(date +%Y%m%d_%H%M%S).log
```

---

## 5. 总结

### 🎯 工具选择指南

| 需求 | 推荐工具 | 说明 |
|------|----------|------|
| 在线修改表结构 | pt-online-schema-change | 零停机时间变更 |
| 清理历史数据 | pt-archiver | 安全高效的数据清理 |
| 数据迁移 | pt-archiver | 支持表间数据迁移 |
| 数据备份 | pt-archiver | 导出数据到文件 |

### ✅ 核心优势

- **零停机时间**: 不影响业务正常运行
- **安全可靠**: 支持 dry-run 预览和事务控制
- **性能友好**: 分批处理，可控制系统负载
- **功能丰富**: 支持多种数据处理场景

### 🔧 使用要点

1. **必须先测试**: 生产环境执行前务必在测试环境验证
2. **监控为先**: 执行过程中持续监控系统状态
3. **备份重要**: 重要数据变更前必须备份
4. **分批执行**: 大量数据处理时采用分批策略
5. **错误处理**: 准备好异常情况的处理预案

---

**注意**: 本文档基于 Percona Toolkit 3.6.0 版本编写，不同版本可能存在参数差异，请参考官方文档获取最新信息。