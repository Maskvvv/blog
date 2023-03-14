# 一、sql

## 1.1 时间

### 时间戳

#### 某天

```sql
-- 某天时间时间戳
SELECT unix_timestamp(FROM_UNIXTIME(1637287200000/1000,"%Y-%m-%d %H:%i:%s")) * 1000;
-- 某天日期时间戳
SELECT unix_timestamp(FROM_UNIXTIME(1637287200000/1000,"%Y-%m-%d")) * 1000;
```

#### 当天

```sql
-- 当前时间时间戳
unix_timestamp(now()) * 1000
-- 当前日期时间戳
unix_timestamp(CURRENT_DATE()) * 1000
```

**测试**

```sql
SELECT now(), timestamp(now()), unix_timestamp(now()), unix_timestamp(now()) * 1000, unix_timestamp(timestamp(now())) * 1000
```

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701780-1644565259916-1644565260751.png)

### 增减天数时间戳

#### 当天

```sql
-- 当前时间7天前时间戳
unix_timestamp(date_add(now(), interval -7 day)) * 1000
-- 当前日期7天前时间戳
unix_timestamp(date_add(CURRENT_DATE(), interval -7 day)) * 1000
```

#### 某天

```sql
-- 某天时间
unix_timestamp(date_add(FROM_UNIXTIME(1637287200000/1000,"%Y-%m-%d %H:%i:%s"), interval -7 day)) * 1000
-- 某天日期
unix_timestamp(date_add(FROM_UNIXTIME(1637287200000/1000,"%Y-%m-%d"), interval -7 day)) * 1000
```

## 1.2 排序

### 多条件排序

```sql
ORDER BY
CASE jf.`status` WHEN 0 THEN 0 WHEN 1 THEN 2 WHEN 2 THEN 1 WHEN 3 THEN 3 END ASC,
jf.`start_timestamp` ASC
```

## 1.3 判断

```sql
CASE WHEN count(*) > 0 THEN count(*) ELSE NULL END
IF(1>2,2,3)
```

# 二、Mybatis

### choose

choose 标签是按顺序判断其内部 when 标签中的 test 条件出否成立，**如果有一个成立，则 choose 结束**。当 choose 中所有 when 的条件都不满则时，则执行 otherwise 中的 sql。类似于Java 的 switch 语句，choose 为 switch，when 为 case，otherwise 则为 default。

```xml
<choose>
    <when test="details != null and details.contains('mini')">
        CASE ct.`status` WHEN 0 THEN 0 WHEN 1 THEN 1 WHEN 2 THEN 4 WHEN 3 THEN 3 WHEN 4 THEN 4 WHEN 5
        THEN 5 END ASC, ct.`start_timestamp` ASC
    </when>
    <otherwise>
        ct.`create_at` DESC
    </otherwise>
</choose>
```

### resultMap

```xml
<resultMap id="CareerTalkMap" type="com.qst.ourea.portal.context.model.recruitment.CareerTalkModel">
    <id property="id" column="id"/>
    <result property="companyId" column="company_id"/>
    <collection property="occupations" columnPrefix="occupation_"
                resultMap="com.qst.ourea.portal.database.mapper.recruitment.CareerTalkOccupationMapper.CareerTalkOccupationMap"/>
</resultMap>
```

### include

```xml
<sql id="sqlExtraColumns">

</sql>

<include refid="sqlExtraColumns"/>
```

### bind

```xml
<bind name="searchLike" value="'%' + search + '%'"/>
 #{searchLike}
```

### collection 

```xml
<collection property="occupations" columnPrefix="occupation_"
            resultMap="com.qst.ourea.portal.database.mapper.recruitment.InternProgramOccupationMapper.internProgramOccupationMap"/>
```

```xml
<collection property="cities" ofType="java.lang.String">
    <constructor>
        <arg column="cities"/>
    </constructor>
</collection>
```

#### <>

```xml
<![CDATA[<= ]]>
```

#### UPDATE OR INSERT

```xml
<update id="upsertOccupations">
INSERT INTO `intern_delivery_occupation`
(<include refid="sqlAllColumns"/>)
VALUES
<foreach collection="list" item="item" separator=",">
(#{item.id}, #{item.deliveryRecordId}, #{item.internProgramId}, #{item.internOccupationId}, #{item.sequence}, #{item.createBy}, #{item.createAt})
</foreach>
ON DUPLICATE KEY UPDATE
`delivery_record_id` = VALUES(`delivery_record_id`),
`intern_program_id` = VALUES(`intern_program_id`),
`intern_occupation_id` = VALUES(`intern_occupation_id`),
`sequence` = VALUES(`sequence`)
</update>
```

