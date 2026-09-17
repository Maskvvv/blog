---
title: 报表 SQL 从超时被杀到 6 秒：一次延迟关联优化的完整推演
date: 2026-09-17
tags: [MySQL, SQL优化, 执行计划, 延迟关联, 覆盖索引, 隐式类型转换]
---

# 报表 SQL 从超时被杀到 6 秒：一次延迟关联优化的完整推演

> 本文所有耗时均为生产环境实测数据，业务标识已脱敏。环境：MySQL 5.7（InnoDB）。

## 一、起因：一个只返回 746 行的查询，跑了 5 分钟被数据库杀掉

生产日志里跳出来这么一条：

```
org.springframework.jdbc.UncategorizedSQLException:
### Error querying database.  Cause: java.sql.SQLException:
    Query execution was interrupted, maximum statement execution time exceeded
### SQL: SELECT ho.order_id, hod.order_detail_id, hosbd.order_send_bill_id, ...
; SQL state [HY000]; error code [3024]
```

错误码 **3024** 是 MySQL 服务端的 `max_execution_time` 把查询强制中断了（这套库配的是 300 秒）。

一个供应商后台的「售后单导出」接口，按 30 天时间窗口导出，**最终结果只有 746 行**——却跑了 5 分钟以上被杀。

这是典型的报表类 SQL 病症：**结果集很小，中间过程很贵**。

## 二、先看数据规模

涉及 5 张表：

| 表 | 行数 | 数据体积 | 索引体积 | 角色 |
| --- | --- | --- | --- | --- |
| `order_details`（订单明细） | 2344 万 | **485 GB** | 28 GB | 宽表，含商品名等字段 |
| `orders`（订单） | 2423 万 | 63 GB | 34 GB | 订单头 |
| `order_send_bill_detail`（发货明细） | 2657 万 | 17 GB | 10 GB | 带 `supplier_id` |
| `order_refund_details`（退款明细） | 424 万 | 2.4 GB | 1.3 GB | 退款行 |
| `orders_refund`（退款单） | 233 万 | 0.9 GB | 0.9 GB | 退款头 |

注意那个 **485 GB** 的订单明细表，后面所有故事都围绕它展开。

原始 SQL（简化保留结构）：

```sql
SELECT
    ho.order_id, hod.order_detail_id, hosbd.order_send_bill_id,
    hod.product_name, hod.product_size, hod.product_amount,
    hor.order_refund_status, hord.create_time, hord.refund_amount / 100,
    spu.if_no_reason_return, spu.if_return_shipping_free
FROM order_details hod
LEFT JOIN orders ho ON ho.order_id = hod.order_id
LEFT JOIN (
    SELECT * FROM orders_refund WHERE order_refund_status > 0
) hor ON hor.order_id = ho.order_id
LEFT JOIN order_refund_details hord ON hord.order_refund_id = hor.order_refund_id
LEFT JOIN order_send_bill_detail hosbd ON hosbd.order_detail_id = hod.order_detail_id
LEFT JOIN product_spus spu ON spu.product_spu_id = hod.product_spu_id
WHERE hor.order_refund_status > 0
  AND hosbd.supplier_id = ?
  AND hod.create_time >= ?
  AND hod.create_time <= ?
```

## 三、第一刀：EXPLAIN 暴露驱动表选错了

```
table           | type   | possible_keys                | rows      | filtered | Extra
orders_refund   | ALL    | PRIMARY,index_order_id       | 2,338,747 | 11.11    | Using where
hod             | ref    | PRIMARY,idx_create_time,...  | 1         | 16.49    | Using index condition; Using where
hosbd           | ref    | idx_supplier_id,idx_order_detail_id | 1  | 4.33     | Using where
spu             | eq_ref | PRIMARY                      | 1         | 100.0    | Using index
hord            | ref    | index_order_refund_id        | 2         | 100.0    |
ho              | eq_ref | PRIMARY                      | 1         | 100.0    | Using index
```

第一行就是问题：**`type=ALL`，全表扫描 233 万行，而且它是驱动表**。

后面所有表都是拿这 233 万行去逐个探测的。

### 为什么索引用不上？两个原因叠加

**原因 ①：隐式类型转换**

`order_refund_status` 的真实类型是 **`varchar(2)`**，而 SQL 写的是：

```sql
WHERE order_refund_status > 0     -- 字符串列 vs 整数
```

MySQL 在比较字符串列和数字时，会把**列值转换成 double** 再比较。列一旦被包上转换语义，B+ 树的有序性就用不上了，范围查找彻底失效。

这类写法的隐蔽之处在于：**它不报错、结果也基本正确**（`'-1' > 0` 为 false，`'4' > 0` 为 true），所以能长期潜伏在代码里。

**原因 ②：组合索引最左前缀缺失**

这张表上其实有个看起来很对口的组合索引：

```
idx_del_flag_order_refund_status (del_flag, order_refund_status)
```

但 SQL 的条件里**没有 `del_flag`**。组合索引必须从最左列开始使用，前导列缺失 → 整个索引用不上。

所以 `possible_keys` 里只剩 `index_order_id`，而 `order_id` 在这条 SQL 里是关联条件、不是过滤条件，于是没得选，只能 `ALL`。

### 一个重要的反例：「加个索引就好了」在这里行不通

我实测了给条件补上 `del_flag = '1'`、让那个组合索引可用的效果：

```sql
SELECT COUNT(*) FROM orders_refund WHERE del_flag = '1' AND order_refund_status > 0;
-- 结果：2,089,548 / 全表 2,403,211 = 87%
```

**命中 87% 的行。** 走索引扫 87% 再逐行回表，比直接全表扫描还慢。

这个教训值得记住：**低区分度的条件，有没有索引都一样。** 优化器在这种情况下选择全表扫描其实是正确决策——问题不在于它选错了索引，而在于**根本不该让这张表当驱动表**。

## 四、第二刀：真正的成本是回表，不是扫描

全表扫描 233 万行虽然难看，但还不是最贵的部分。

看 EXPLAIN 里 `hod`（485 GB 那张表）的 Extra：

```
Using index condition; Using where
```

**没有 `Using index`** —— 意味着需要回表。

因为 SELECT 列表里有 `product_name`、`product_size` 这些宽字段，它们不在任何二级索引里，只能去聚簇索引（主键）取。而 `hod` 的访问路径是按 `order_id` 的 `ref` 查找，连 `idx_create_time` 都用不上，时间过滤只能等行取出来之后再做。

于是真实成本是：

```
233 万次驱动行 × (探测 hod + 对 485GB 表随机回表 + 探测 hosbd + ...)
```

### 一个能证明「回表才是大头」的对照实验

我先跑了一个 `COUNT(*)` 包装版本，只 SELECT 主键 `order_detail_id`：

```
耗时：74.89 秒
```

再跑真实导出版本（SELECT 了 `product_name` 等宽字段）：

```
耗时：> 300 秒，被 MySQL 中断
```

**同一个 SQL 结构、同一批数据，差别只在「取哪些列」，成本差了一个数量级。**

原理：`order_detail_id` 是主键，而 InnoDB 的二级索引叶子节点自带主键，所以 COUNT 版本走的是覆盖索引、**完全不回表**；真实版本要宽字段，**必须回表 485 GB 大表**。

这就是本文最核心的一句话：

> **报表 SQL 的成本往往不在「扫了多少行」，而在「回了多少次表」。**

## 五、v1 优化：换驱动表

既然退款表注定无法有效过滤，就别让它当驱动表。改用有 `create_time` 索引的订单明细表进入，并用 `STRAIGHT_JOIN` 强制固定关联顺序（否则优化器仍会按老估算选回去）：

```sql
FROM order_details hod
STRAIGHT_JOIN orders_refund hor
       ON hor.order_id = hod.order_id AND hor.order_refund_status > 0
STRAIGHT_JOIN order_refund_details hord
       ON hord.order_refund_id = hor.order_refund_id
      AND hord.order_detail_id = hod.order_detail_id
STRAIGHT_JOIN order_send_bill_detail hosbd
       ON hosbd.order_detail_id = hod.order_detail_id AND hosbd.supplier_id = ?
LEFT JOIN orders ho ON ho.order_id = hod.order_id
LEFT JOIN product_spus spu ON spu.product_spu_id = hod.product_spu_id
WHERE hod.create_time >= ? AND hod.create_time <= ?
```

新执行计划，**全链路没有一个 `ALL`**：

```
hod   | range  | idx_create_time       | rows=4,045,060 | Using index condition
hor   | ref    | index_order_id        | rows=1
hord  | ref    | index_order_detail_id | rows=1
hosbd | ref    | idx_order_detail_id   | rows=1
```

**效果：16.4 秒（缓存热）/ 120 秒（缓存冷）。** 从超时变成能出结果了。

### 但为什么冷态还要 120 秒？

因为驱动表还是 `order_details`，182 万行驱动，**每行依然要回表取 `product_name`**。这一版只是把「233 万次随机回表」换成了「182 万次随机回表」，量级没变。

**铁证**：我换了一个该供应商完全没有售后单的月份去跑——

```
结果：0 行
耗时：120.22 秒
```

**返回 0 行，照样跑 120 秒。**

这说明成本完全由「时间窗口内全平台订单明细行数」决定，跟最终结果有多少行毫无关系。而供应商导出这个场景，绝大部分驱动行注定会被过滤掉。

## 六、v2 优化：延迟关联

核心洞察一句话：

> **182 万行里最终只有 746 行活下来，为什么要为剩下那 182 万行付回表代价？**

把「取宽字段」这件事，推迟到关联收敛之后：

```sql
SELECT
    ho.order_id, hod.order_detail_id, hosbd.order_send_bill_id,
    hod.product_name, hod.product_size, hod.product_amount,
    hor.order_refund_status, hord.create_time,
    hord.refund_amount / 100 AS refund_amount,
    spu.if_no_reason_return, spu.if_return_shipping_free
FROM (
    SELECT order_detail_id                    -- 只取主键，不碰宽字段
    FROM order_details
    WHERE create_time >= ? AND create_time <= ?
) ids
STRAIGHT_JOIN order_refund_details hord ON hord.order_detail_id = ids.order_detail_id
STRAIGHT_JOIN orders_refund hor ON hor.order_refund_id = hord.order_refund_id
                               AND hor.order_refund_status > 0
STRAIGHT_JOIN order_send_bill_detail hosbd ON hosbd.order_detail_id = ids.order_detail_id
                                          AND hosbd.supplier_id = ?
STRAIGHT_JOIN order_details hod ON hod.order_detail_id = ids.order_detail_id   -- 这里才回表
LEFT JOIN orders ho ON ho.order_id = hod.order_id
LEFT JOIN product_spus spu ON spu.product_spu_id = hod.product_spu_id
WHERE hor.order_id = hod.order_id
```

**效果：6.07 秒（热）/ 12.25 秒（冷）。**

### EXPLAIN 给出了最漂亮的证据

```
id | table           | type   | key                   | rows      | Extra
1  | order_details   | range  | idx_create_time       | 4,045,060 | Using where; Using index   ← 第一次出现
1  | hord            | ref    | index_order_detail_id | 1         | Using where
1  | hor             | eq_ref | PRIMARY               | 1         | Using where
1  | hosbd           | ref    | idx_order_detail_id   | 1         | Using where
1  | hod             | eq_ref | PRIMARY               | 1         | Using where                ← 第二次出现
1  | ho              | eq_ref | PRIMARY               | 1         | Using index
1  | spu             | eq_ref | PRIMARY               | 1         |
```

注意 `order_details` **出现了两次**，扮演完全不同的角色：

**第一次：`type=range` + `Using index`**

`Using index` 就是**覆盖索引**（covering index）的标志——所需列全部能从索引里拿到，**一次都不回表**。

原理是 InnoDB 的二级索引叶子节点除了索引列，还自带主键。内层子查询只 `SELECT order_detail_id`（正好是主键），所以 `WHERE create_time BETWEEN ...` 可以**在索引里顺序读完 182 万条记录就结束**，完全不碰那 485 GB 的主表数据。

旁证：同一个时间窗口单跑 `COUNT(*)` 只要 **0.62 秒**，走的就是这条索引。

**第二次：`type=eq_ref` + `key=PRIMARY`**

这才是真正取 `product_name` 等宽字段的地方，按主键等值查找，而且**只对已经收敛下来的行执行**（此时只剩 746 行）。

### 一个意外之喜：派生表并没有被物化

我原本担心 182 万行的子查询会被物化成临时表，反而增加开销。但看 `select_type` 全是 `SIMPLE`、没有 `DERIVED`——MySQL 5.7 的 `derived_merge` 优化把子查询合并了。

更妙的是，合并之后优化器**自己把同一张表拆成了两段式访问**：先用覆盖索引过滤出候选主键，再按主键回表取宽字段。

既拿到了延迟关联的收益，又没有临时表成本。

### 中间表的剪枝也更高效了

- `hord`（424 万行 / 2.4 GB 的小表）用 `index_order_detail_id` 探测。绝大多数订单明细**根本没有退款记录**，索引探测立即返回空，后面两个 join 直接跳过。这是整条链路最有效的剪枝点。
- `hor` 从原来的 `ref rows=2` 变成 `eq_ref PRIMARY`——通过 `hord.order_refund_id` 直接命中主键，精确一行。

## 七、优化效果汇总

| 阶段 | 驱动路径 | 对 485GB 大表的回表次数 | 热态 | 冷态 |
| --- | --- | --- | --- | --- |
| 原始 SQL | 退款表 233 万行 `ALL` 驱动 | ~233 万 × 多表探测 | **>300s 被杀** | — |
| v1 换驱动表 | 明细表 `create_time` 范围扫描 | ~182 万 | 16.4s | 120s |
| v2 延迟关联 | 覆盖索引取主键 → 收敛后按主键回表 | **746** | **6.07s** | **12.25s** |

驱动行数只降了 22%（233 万 → 182 万），耗时却降了 **12 倍以上**。

冷态从 120 秒降到 12 秒这一点尤其重要：**它说明新写法对 buffer pool 冷热基本免疫**——因为随机 IO 从百万级降到了百级。线上真实场景绝大多数是冷查询，这个特性比热态数字更有价值。

执行路径的变化：

```mermaid
flowchart TD
    subgraph 原始路径
    A1[退款表全表扫描 233 万行] --> A2[逐行探测订单明细]
    A2 --> A3[对 485GB 大表随机回表取宽字段]
    A3 --> A4[探测发货明细并过滤供应商]
    A4 --> A5[超过 300 秒被中断]
    end

    subgraph 优化路径
    B1[覆盖索引顺序读 182 万条主键] --> B2[用主键探测退款明细小表]
    B2 --> B3[绝大部分无退款立即剪枝]
    B3 --> B4[主键命中退款单与发货明细]
    B4 --> B5[仅对 746 行按主键回表取宽字段]
    B5 --> B6[6 秒返回]
    end
```

## 八、顺手修掉的两个正确性 Bug

性能排查过程中还发现两个跟性能无关、但同样致命的问题。

### Bug 1：一对多 JOIN 缺明细级关联键，导出全是重复行

```sql
-- 错误：只按退款单关联
LEFT JOIN order_refund_details hord ON hord.order_refund_id = hor.order_refund_id

-- 正确：必须再按订单明细关联
INNER JOIN order_refund_details hord ON hord.order_refund_id = hor.order_refund_id
                                    AND hord.order_detail_id = hod.order_detail_id
```

这条 SQL 同时叠了三条一对多关联（退款单按 `order_id`、退款明细按 `order_refund_id`、发货明细按 `order_detail_id`），其中退款明细**没有再关联回订单明细**，于是形成「订单明细 × 该订单全部退款明细」的笛卡尔积。

导出行数公式：

```
行数 = Σ 每条订单明细的 (该明细发货明细数 × 该订单全部退款明细数)
```

生产实测：**1913 行 vs 唯一明细 924 条**；单个订单 8 条明细 × 8 条退款明细 = **64 行**。

更隐蔽的是，它还会**多带出本无退款的商品明细**（924 条里有约 181 条根本没有退款记录，是被交叉连接顺带捞出来的）。

**排查手法**：`COUNT(*)` 与 `COUNT(DISTINCT 明细主键)` 一比，放大倍数立刻现形。

### Bug 2：表达式没有别名，字段一直映射不上

```sql
-- 错误
hord.refund_amount / 100,

-- 正确
hord.refund_amount / 100 AS refund_amount,
```

MySQL 对无别名表达式返回的列名就是**字面量** `"hord.refund_amount / 100"`（可以用 JSON 格式查询验证，key 里带空格和斜杠）。ORM 按列名映射到 `refundAmount` 属性时匹配不上，结果导出的「退款金额」列**一直是空的**。

这类 bug 的特点是：**不报错、不抛异常、字段静默为 null**，可能已经存在很久了。

## 九、容易被忽略的一步：优化会引入新风险，必须配套防御

延迟关联让驱动表变成了 `order_details` 的 `create_time` 范围扫描。这意味着：

> **时间条件一旦为空，驱动表就退化成 2344 万行全表扫描——比优化前更糟。**

而原始 SQL 里时间条件是可选的：

```xml
<if test="dto.createStartTime != null and dto.createStartTime != ''">
    AND create_time >= #{dto.createStartTime}
</if>
```

前端不传，这段直接消失。

所以配套在 Controller 加了强制校验：时间必填、格式校验、起止顺序校验、**跨度上限 31 天**。

上限怎么定的？成本与窗口内明细行数成正比：30 天约 182–229 万行、冷态 12 秒；线性外推 92 天约 600 万行，冷态可能到 300 秒以上——**又会撞上同一个超时**。所以按最坏情况留足余量，定在 31 天。

这是我认为整件事里最有价值的一条工程经验：

> **性能优化改变了 SQL 的成本模型，就必须同步检查「什么输入会让新模型退化」，并把约束固化到代码里。**

## 十、为什么最后没有加索引

排查过程中一度考虑给发货明细表加复合索引 `(supplier_id, order_id)`，让查询先按供应商收敛。最终没做，原因：

1. 该表 2657 万行 / 17 GB，线上 DDL 有锁表和主从延迟风险，需要 DBA 评审和变更窗口
2. 实测证明纯 SQL 改写已经到 6 秒，收益不匹配风险
3. 延迟关联不需要任何 schema 变更，可以立即上线

顺便记录一个反直觉的实测：我曾试过用发货明细表（带 `supplier_id` 索引）当驱动表，想「先按供应商收敛」，结果**反而更慢（116 秒）**——因为 `idx_supplier_id` 是单列索引，51 万行必须逐行回表拿 `order_detail_id`。**「先按最强的业务条件过滤」这个直觉，在缺覆盖索引时是错的。**

## 十一、可复用的检查清单

**写 SQL 时**

- [ ] `varchar` 状态字段**禁止**与整数直接比较（`status > 0`），改用字符串字面量或 `IN` 列表
- [ ] 组合索引要检查最左前缀是否被用到
- [ ] 低区分度条件（命中 >30%）不要指望索引，要换思路
- [ ] 有 2 条以上一对多 JOIN 时，每条关联都必须补全**明细级关联键**
- [ ] SELECT 里的表达式**必须显式起别名**
- [ ] 大表当驱动表时，警惕「为了取宽字段而逐行回表」

**排查时**

- [ ] `EXPLAIN` 先看第一行的 `type`，出现 `ALL` 且 `rows` 是百万级就要警觉
- [ ] 看 `Extra`：有 `Using index` 是覆盖索引（好），只有 `Using where` 说明要回表
- [ ] 用 `COUNT(*)` vs `COUNT(DISTINCT 主键)` 定位笛卡尔积放大倍数
- [ ] 用「只 SELECT 主键」和「SELECT 全部列」两个版本对比，能量化回表成本
- [ ] 找一个结果为 0 行的时间窗口跑一次，能验证成本是否与结果集无关

**优化手法优先级**

1. 换驱动表（`STRAIGHT_JOIN` 固定顺序）——先让全表扫描消失
2. **延迟关联**（覆盖索引取主键 → 收敛后回表）——把回表次数从百万级降到结果集大小
3. 加索引——最后再考虑，大表 DDL 成本高
4. 架构层（异步导出、强制时间范围、分页）——兜底

延迟关联的适用形态可以概括成一句话：

> **大表 + 多条件过滤 + 结果集小 → 先用覆盖索引把候选主键捞出来，等关联收敛后再按主键回表取宽字段。**

---

## 附：本文涉及的实测数据一览

| 实验 | 结果 |
| --- | --- |
| 原 SQL 完整导出 | > 300 秒，error 3024 被中断 |
| 原 SQL 的 COUNT 包装（只取主键） | 74.89 秒 |
| `max_execution_time` | 300000 ms |
| 退款表全表 / 命中 `del_flag='1' AND status>0` | 240 万 / 208 万（87%） |
| 30 天窗口订单明细行数 | 182 万 |
| 6 月窗口订单明细行数 | 229 万 |
| v1 STRAIGHT_JOIN（30 天，热 / 冷） | 16.4s / 120s |
| v1 STRAIGHT_JOIN（6 月窗口，结果 0 行） | 120.22 秒 |
| v2 延迟关联（30 天，热 / 冷） | 6.07s / 12.25s |
| v2 延迟关联（6 月窗口热 / 5 月全新冷） | 6.99s / 12.25s |
| 单月 `COUNT(*)` 走覆盖索引 | 0.62 秒 |
| 发货明细表当驱动表（单列索引回表） | 116 秒 |
| 重复行放大 | 1913 行 vs 924 条唯一明细 |
| 最终结果行数（改写前后一致） | 746 |
