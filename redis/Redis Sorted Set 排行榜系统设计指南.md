# **Redis Sorted Set 排行榜系统设计指南**

> 文档版本：v1.0
> 最后更新：2026-03-18
> 适用场景：游戏、电商、社交、直播等排行榜场景

------

## **目录**

1. [概述](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#1-概述)
2. [为什么选择 Sorted Set](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#2-为什么选择-sorted-set)
3. [核心数据结构设计](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#3-核心数据结构设计)
4. [核心命令详解](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#4-核心命令详解)
5. [代码实现示例](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#5-代码实现示例)
6. [分数更新策略](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#6-分数更新策略)
7. [持久化设计方案](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#7-持久化设计方案)
8. [性能优化最佳实践](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#8-性能优化最佳实践)
9. [常见问题解决方案](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#9-常见问题解决方案)
10. [架构设计参考](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#10-架构设计参考)
11. [总结](https://www.qianwen.com/chat/8f65ac5c10934af4a5d392dd166445b3#11-总结)

------

## **1. 概述**

Redis Sorted Set（ZSET）是实现排行榜系统的**最佳数据结构**，具有自动排序、高效查询、支持并发更新等特性。本文档详细介绍如何使用 Redis Sorted Set 设计一个完整的、可生产使用的排行榜系统。

### **核心特性**





| 特性           | 说明                        |
| :------------- | :-------------------------- |
| **时间复杂度** | 插入/更新/查询均为 O(log N) |
| **自动排序**   | 根据分数自动维护顺序        |
| **唯一成员**   | 同一成员不会重复            |
| **范围查询**   | 支持高效的分页和范围获取    |
| **高并发**     | 支持每秒数万次更新操作      |

------

## **2. 为什么选择 Sorted Set**

### **2.1 与其他数据结构对比**





| 数据结构       | 插入复杂度 | 查询TopN     | 查询排名 | 适用场景     |
| :------------- | :--------- | :----------- | :------- | :----------- |
| **Redis ZSET** | O(log N)   | O(log N + M) | O(log N) | ✅ 排行榜     |
| Redis List     | O(1)       | O(N)         | O(N)     | ❌ 不适合     |
| MySQL 排序     | O(N log N) | O(N log N)   | O(N)     | ❌ 性能差     |
| 内存排序       | O(N log N) | O(N)         | O(N)     | ❌ 无法持久化 |

### **2.2 适用场景**

- 🎮 游戏天梯/段位排名
- 🛒 电商销量/积分排名
- 📱 社交影响力排名
- 🎬 直播打赏榜
- 📊 内容热度榜

------

## **3. 核心数据结构设计**

### **3.1 Key 命名规范**





```
格式：leaderboard:{业务}:{周期}:{维度}

示例：
├── leaderboard:game:season5          # 游戏赛季总榜
├── leaderboard:game:daily:2026-03-17 # 游戏日榜
├── leaderboard:game:weekly:2026-W12  # 游戏周榜
├── leaderboard:shop:monthly:2026-03  # 电商月榜
└── leaderboard:live:global           # 直播全局榜
```

### **3.2 数据模型**





```
Key: leaderboard:game:season5
├── Member: user_id_001    → Score: 15800
├── Member: user_id_002    → Score: 14500
├── Member: user_id_003    → Score: 13200
└── ...
```

### **3.3 多维度排行榜设计**





```bash
# 不同维度的排行榜使用不同 Key
leaderboard:game:season5:total_score    # 总积分榜
leaderboard:game:season5:win_count      # 胜利次数榜
leaderboard:game:season5:login_days     # 活跃天数榜
leaderboard:game:season5:level          # 等级榜
```

------

## **4. 核心命令详解**

### **4.1 基础操作**





```bash
# 添加/更新用户分数
ZADD leaderboard:game:season5 15800 "user_001"

# 批量添加（使用pipeline提升性能）
ZADD leaderboard:game:season5 15800 "user_001" 14500 "user_002" 13200 "user_003"

# 增加分数（增量更新）
ZINCRBY leaderboard:game:season5 100 "user_001"

# 删除用户
ZREM leaderboard:game:season5 "user_001"

# 获取用户数量
ZCARD leaderboard:game:season5

# 设置过期时间
EXPIRE leaderboard:game:season5 7776000  # 90天
```

### **4.2 查询操作**





```bash
# 获取 Top N（降序）
ZREVRANGE leaderboard:game:season5 0 9 WITHSCORES

# 获取用户排名（从0开始）
ZREVRANK leaderboard:game:season5 "user_001"

# 获取用户分数
ZSCORE leaderboard:game:season5 "user_001"

# 获取分数范围内的用户
ZREVRANGEBYSCORE leaderboard:game:season5 20000 10000 LIMIT 0 10

# 统计分数范围内的用户数
ZCOUNT leaderboard:game:season5 10000 20000

# 获取用户所在页（分页查询）
ZREVRANK leaderboard:game:season5 "user_001"
ZREVRANGE leaderboard:game:season5 [rank] [rank+9] WITHSCORES
```

------

## **5. 代码实现示例**

### **5.1 Java 实现**





```java
@Service
public class LeaderboardService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    private static final String KEY_PREFIX = "leaderboard:game:";
    
    /**
     * 更新用户分数
     */
    public void updateScore(String season, String userId, long score) {
        String key = KEY_PREFIX + season;
        redisTemplate.opsForZSet().add(key, userId, score);
        redisTemplate.expire(key, 90, TimeUnit.DAYS);
    }
    
    /**
     * 增量更新分数
     */
    public void incrementScore(String season, String userId, long delta) {
        String key = KEY_PREFIX + season;
        redisTemplate.opsForZSet().incrementScore(key, userId, delta);
    }
    
    /**
     * 获取 Top N
     */
    public List<LeaderboardEntry> getTopN(String season, int n) {
        String key = KEY_PREFIX + season;
        Set<ZSetOperations.TypedTuple<String>> tuples = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, 0, n - 1);
        
        return tuples.stream()
            .map(t -> new LeaderboardEntry(t.getValue(), t.getScore()))
            .collect(Collectors.toList());
    }
    
    /**
     * 获取用户排名
     */
    public Long getUserRank(String season, String userId) {
        String key = KEY_PREFIX + season;
        Long rank = redisTemplate.opsForZSet().reverseRank(key, userId);
        return rank != null ? rank + 1 : null;
    }
    
    /**
     * 获取用户所在页（分页）
     */
    public List<LeaderboardEntry> getUserPage(String season, String userId, int pageSize) {
        String key = KEY_PREFIX + season;
        Long rank = redisTemplate.opsForZSet().reverseRank(key, userId);
        if (rank == null) return Collections.emptyList();
        
        long startPage = (rank / pageSize) * pageSize;
        Set<ZSetOperations.TypedTuple<String>> tuples = 
            redisTemplate.opsForZSet().reverseRangeWithScores(key, startPage, startPage + pageSize - 1);
        
        return tuples.stream()
            .map(t -> new LeaderboardEntry(t.getValue(), t.getScore()))
            .collect(Collectors.toList());
    }
}
```

### **5.2 Python 实现**





```python
import redis

class Leaderboard:
    def __init__(self, redis_client, season):
        self.redis = redis_client
        self.key = f"leaderboard:game:{season}"
    
    def update_score(self, user_id, score):
        """更新用户分数"""
        self.redis.zadd(self.key, {user_id: score})
        self.redis.expire(self.key, 90 * 24 * 3600)
    
    def increment_score(self, user_id, delta):
        """增量更新分数"""
        self.redis.zincrby(self.key, delta, user_id)
    
    def get_top_n(self, n):
        """获取 Top N"""
        return self.redis.zrevrange(self.key, 0, n-1, withscores=True)
    
    def get_user_rank(self, user_id):
        """获取用户排名（从1开始）"""
        rank = self.redis.zrevrank(self.key, user_id)
        return rank + 1 if rank is not None else None
    
    def get_user_score(self, user_id):
        """获取用户分数"""
        return self.redis.zscore(self.key, user_id)
    
    def get_user_page(self, user_id, page_size=10):
        """获取用户所在页"""
        rank = self.redis.zrevrank(self.key, user_id)
        if rank is None:
            return []
        
        start_page = (rank // page_size) * page_size
        return self.redis.zrevrange(self.key, start_page, start_page + page_size - 1, withscores=True)
    
    def remove_user(self, user_id):
        """删除用户"""
        self.redis.zrem(self.key, user_id)
```

------

## **6. 分数更新策略**

### **6.1 三种策略对比**





| 策略           | 适用场景                     | 优点                         | 缺点                | 延迟          |
| :------------- | :--------------------------- | :--------------------------- | :------------------ | :------------ |
| **实时更新**   | 游戏竞技、直播打赏、秒杀排名 | 用户体验最佳，排名即时可见   | Redis压力大，成本高 | <10ms         |
| **MQ异步更新** | 电商积分、任务奖励、社交点赞 | 削峰填谷，系统解耦，容错性好 | 有短暂延迟          | 100ms~5s      |
| **定时任务**   | 日榜/周榜结算、非核心排名    | 实现简单，资源可控           | 实时性差            | 分钟级~小时级 |

### **6.2 混合更新策略（推荐）**





```
┌─────────────────────────────────────────────────────────────────────────┐
│                        分数更新混合架构                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐            │
│   │  核心行为     │    │  普通行为     │    │  批量行为     │            │
│   │  (实时)      │    │  (异步)      │    │  (定时)      │            │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘            │
│          │                   │                   │                      │
│          ▼                   ▼                   ▼                      │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐            │
│   │  ZADD直接写  │    │  消息队列    │    │  定时聚合    │            │
│   │  Redis ZSET  │    │  Kafka/RocketMQ│  │  批量写入    │            │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘            │
│          │                   │                   │                      │
│          └───────────────────┼───────────────────┘                      │
│                              ▼                                          │
│                    ┌─────────────────┐                                  │
│                    │   Redis ZSET    │                                  │
│                    │   (排行榜缓存)   │                                  │
│                    └────────┬────────┘                                  │
│                             │                                           │
│                             ▼                                           │
│                    ┌─────────────────┐                                  │
│                    │   MySQL/PG      │                                  │
│                    │   (持久化存储)   │                                  │
│                    └─────────────────┘                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

### **6.3 实时更新实现**





```java
@Service
public class RealTimeScoreService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @Autowired
    private ScoreMapper scoreMapper;
    
    /**
     * 核心行为：实时写入Redis + 异步持久化
     */
    @Transactional
    public void updateScoreRealTime(String userId, long delta) {
        String key = "leaderboard:season:5";
        
        // 1. 实时写入Redis（主流程，<10ms）
        redisTemplate.opsForZSet().incrementScore(key, userId, delta);
        
        // 2. 异步持久化到数据库（不阻塞主流程）
        CompletableFuture.runAsync(() -> {
            scoreMapper.incrementScore(userId, delta);
        });
        
        // 3. 发送消息到MQ（用于数据备份和审计）
        scoreEventProducer.send(new ScoreEvent(userId, delta, System.currentTimeMillis()));
    }
}
```

### **6.4 MQ异步更新实现**



```java
// 1. 生产者：业务方发送消息
@Component
public class ScoreEventProducer {
    
    @Autowired
    private KafkaTemplate<String, ScoreUpdateEvent> kafkaTemplate;
    
    public void sendScoreUpdate(String userId, long delta, String bizType) {
        ScoreUpdateEvent event = ScoreUpdateEvent.builder()
            .userId(userId)
            .delta(delta)
            .bizType(bizType)
            .timestamp(System.currentTimeMillis())
            .build();
        
        kafkaTemplate.send("score-update-topic", event);
    }
}

// 2. 消费者：批量消费更新Redis
@Component
public class ScoreUpdateConsumer {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @KafkaListener(topics = "score-update-topic", groupId = "score-group")
    public void consume(List<ScoreUpdateEvent> events) {
        // 批量聚合同一用户的分数
        Map<String, Long> userScoreMap = aggregateByUser(events);
        
        // Pipeline批量写入Redis
        redisTemplate.executePipelined((RedisCallback<Object>) connection -> {
            String key = "leaderboard:season:5";
            for (Map.Entry<String, Long> entry : userScoreMap.entrySet()) {
                connection.zIncrBy(key.getBytes(), entry.getValue().doubleValue(), entry.getKey().getBytes());
            }
            return null;
        });
        
        // 批量持久化到数据库
        scoreMapper.batchUpdate(userScoreMap);
    }
}
```

### **6.5 定时任务实现**





```java
@Component
public class LeaderboardScheduleTask {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @Autowired
    private LeaderboardHistoryMapper historyMapper;
    
    /**
     * 每日凌晨结算日榜
     */
    @Scheduled(cron = "0 0 2 * * ?")
    public void dailySettlement() {
        String yesterday = LocalDate.now().minusDays(1)
            .format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        
        String dailyKey = "leaderboard:daily:" + yesterday;
        
        // 1. 获取昨日Top 1000
        Set<ZSetOperations.TypedTuple<String>> topUsers = 
            redisTemplate.opsForZSet().reverseRangeWithScores(dailyKey, 0, 999);
        
        // 2. 归档到数据库
        List<LeaderboardHistory> records = topUsers.stream()
            .map(t -> LeaderboardHistory.builder()
                .date(yesterday)
                .userId(t.getValue())
                .score(t.getScore().longValue())
                .rank(...)
                .build())
            .collect(Collectors.toList());
        
        historyMapper.batchInsert(records);
        
        // 3. 清理过期数据
        redisTemplate.delete("leaderboard:daily:" + LocalDate.now().minusDays(8).format(...));
    }
}
```

### **6.6 策略选择决策树**



```
                        ┌─────────────────┐
                        │  用户需要实时   │
                        │  看到排名变化？ │
                        └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    │ YES                     │ NO
                    ▼                         ▼
            ┌───────────────┐         ┌───────────────┐
            │  更新频率     │         │  定时任务     │
            │  >1000次/秒？ │         │  (小时/天级)  │
            └───────┬───────┘         └───────────────┘
                    │
        ┌───────────┴───────────┐
        │ YES                   │ NO
        ▼                       ▼
┌───────────────┐       ┌───────────────┐
│ MQ异步 + 批量 │       │  实时更新     │
│ (削峰填谷)    │       │  (直接写Redis)│
└───────────────┘       └───────────────┘
```

------

## **7. 持久化设计方案**

### **7.1 持久化三层架构**



```
┌────────────────────────────────────────────────────────────────────────┐
│                         持久化三层架构                                  │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   Layer 1: Redis内存 (热数据)                                          │
│   ┌──────────────────────────────────────────────────────────────┐    │
│   │  ZSET: leaderboard:season:5    TTL:90天                       │    │
│   │  ZSET: leaderboard:daily:2026-03-17    TTL:7天               │    │
│   └──────────────────────────────────────────────────────────────┘    │
│                          │                                             │
│                          │ RDB+AOF双持久化                             │
│                          ▼                                             │
│   Layer 2: Redis持久化 (灾难恢复)                                      │
│   ┌──────────────────────────────────────────────────────────────┐    │
│   │  dump.rdb (快照) + appendonly.aof (追加日志)                  │    │
│   └──────────────────────────────────────────────────────────────┘    │
│                          │                                             │
│                          │ 异步同步                                    │
│                          ▼                                             │
│   Layer 3: 数据库 (永久存储)                                           │
│   ┌──────────────────────────────────────────────────────────────┐    │
│   │  MySQL/PostgreSQL                                             │    │
│   │  - user_score_total (用户总分表)                              │    │
│   │  - leaderboard_history (排行榜历史表)                         │    │
│   │  - score_change_log (分数变更日志表)                          │    │
│   └──────────────────────────────────────────────────────────────┘    │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

### **7.2 数据库表设计**



```sql
-- 1. 用户总分表（当前赛季）
CREATE TABLE user_score_total (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(64) NOT NULL,
    season_id INT NOT NULL,
    total_score BIGINT NOT NULL DEFAULT 0,
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_season (user_id, season_id),
    INDEX idx_score (total_score DESC)
) ENGINE=InnoDB;

-- 2. 排行榜历史表（每日快照）
CREATE TABLE leaderboard_history (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    date DATE NOT NULL,
    season_id INT NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    score BIGINT NOT NULL,
    rank INT NOT NULL,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_date_user (date, season_id, user_id),
    INDEX idx_date_rank (date, rank)
) ENGINE=InnoDB;

-- 3. 分数变更日志表（审计用）
CREATE TABLE score_change_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(64) NOT NULL,
    delta_score BIGINT NOT NULL,
    biz_type VARCHAR(32) NOT NULL,
    biz_id VARCHAR(64),
    before_score BIGINT,
    after_score BIGINT,
    created_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_time (user_id, created_time),
    INDEX idx_biz (biz_type, biz_id)
) ENGINE=InnoDB;
```

### **7.3 异步双写实现**





```java
@Service
public class ScorePersistenceService {
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @Autowired
    private UserScoreTotalMapper scoreMapper;
    
    @Autowired
    private ScoreChangeLogMapper logMapper;
    
    @Autowired
    private ThreadPoolTaskExecutor asyncExecutor;
    
    public void updateScoreWithPersistence(String userId, long delta, String bizType, String bizId) {
        String key = "leaderboard:season:5";
        
        // 1. 先写Redis（快速响应用户）
        Long newScore = redisTemplate.opsForZSet().incrementScore(key, userId, delta);
        
        // 2. 异步持久化到MySQL
        asyncExecutor.execute(() -> {
            try {
                Long oldScore = newScore - delta;
                
                // 写入分数变更日志
                ScoreChangeLog log = ScoreChangeLog.builder()
                    .userId(userId)
                    .deltaScore(delta)
                    .bizType(bizType)
                    .bizId(bizId)
                    .beforeScore(oldScore)
                    .afterScore(newScore)
                    .build();
                logMapper.insert(log);
                
                // 更新总分表
                scoreMapper.upsertScore(userId, 5, delta);
                
            } catch (Exception e) {
                log.error("Score persistence failed for user: {}", userId, e);
            }
        });
    }
}
```

### **7.4 Redis持久化配置**





```yaml
# redis.conf 配置
# RDB快照
save 900 1
save 300 10
save 60 10000

# AOF持久化
appendonly yes
appendfsync everysec

# 内存策略
maxmemory 4gb
maxmemory-policy allkeys-lru

# 集群配置
cluster-enabled yes
cluster-node-timeout 5000
```

### **7.5 数据一致性保障**





```
┌─────────────────────────────────────────────────────────────────┐
│                     数据一致性保障机制                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. 最终一致性                                                   │
│     Redis写入 → MQ消息 → 消费者异步写DB → 失败重试               │
│                                                                 │
│  2. 对账机制（每日）                                             │
│     Redis总分 vs DB总分 → 差异报警 → 自动修复                    │
│                                                                 │
│  3. 补偿机制                                                     │
│     死信队列存储失败消息 → 定时任务重试 → 人工介入               │
│                                                                 │
│  4. 监控告警                                                     │
│     Redis-DB分数差异 > 阈值 → 钉钉/企业微信告警                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```





```java
// 对账任务示例
@Scheduled(cron = "0 0 3 * * ?")
public void reconcileScore() {
    String redisKey = "leaderboard:season:5";
    
    // 随机抽样1000个用户进行对账
    Set<String> sampleUsers = redisTemplate.opsForZSet().reverseRange(redisKey, 0, 999);
    
    for (String userId : sampleUsers) {
        Double redisScore = redisTemplate.opsForZSet().score(redisKey, userId);
        Long dbScore = scoreMapper.selectTotalScore(userId, 5);
        
        if (redisScore == null || dbScore == null || 
            Math.abs(redisScore - dbScore) > 0.01) {
            log.warn("Score mismatch: userId={}, redis={}, db={}", 
                     userId, redisScore, dbScore);
            alertService.sendScoreAlert(userId, redisScore, dbScore);
        }
    }
}
```

------

## **8. 性能优化最佳实践**

### **8.1 优化建议表**

| 优化项                 | 建议                                         |
| :--------------------- | :------------------------------------------- |
| **Key 命名规范**       | `lb:v1:season5:global`（带版本号和业务前缀） |
| **单个 ZSET 元素数量** | 控制在 5000 万以内                           |
| **批量操作**           | 使用 Pipeline 批量添加/更新                  |
| **过期时间**           | 设置合理的 TTL，避免内存泄漏                 |
| **分页查询**           | 避免一次性获取大量数据，每次≤100条           |
| **内存优化**           | 定期清理过期数据，使用 Redis 集群            |
| **监控指标**           | 监控 ZSET 大小、内存使用、QPS                |

### **8.2 Pipeline 批量操作**

```java
// Java Pipeline 批量更新
redisTemplate.executePipelined((RedisCallback<Object>) connection -> {
    for (ScoreUpdate update : updates) {
        connection.zAdd(key.getBytes(), update.getScore(), update.getUserId().getBytes());
    }
    return null;
});
```

### **8.3 分段排行榜（超大规模优化）**

```
# 当用户量超过5000万时，采用分片策略
def get_shard_key(user_id, shard_count=1024):
    return f"leaderboard:shard:{user_id % shard_count}"

# 查询时需要合并多个分片结果
```

### **8.4 并列排名处理**

```python
def get_rank_with_ties(redis_client, key, user_id):
    """处理相同分数并列排名"""
    score = redis_client.zscore(key, user_id)
    # 计算有多少用户分数高于当前用户
    higher_count = redis_client.zcount(key, score + 0.0001, '+inf')
    return higher_count + 1
```

------

## **9. 常见问题解决方案**

### **9.1 相同分数排序问题**

| 方案           | 实现方式                   | 适用场景 |
| :------------- | :------------------------- | :------- |
| 时间戳次要排序 | 分数 = 主分数 + 时间戳小数 | 先到先得 |
| ZCOUNT计算并列 | 统计高于当前分数的用户数   | 允许并列 |
| 随机扰动       | 分数 + 微小随机值          | 避免并列 |

### **9.2 大数据量优化**

- ✅ 采用分片策略（user_id % 1024）
- ✅ 使用 Redis Cluster 分布式部署
- ✅ 冷热数据分离（活跃用户放 Redis，历史数据归档）

### **9.3 数据持久化**

- ✅ 开启 RDB + AOF 双持久化
- ✅ 定期备份到 MySQL/PostgreSQL
- ✅ 赛季结束后归档历史数据

### **9.4 内存溢出处理**

```bash
# 监控内存使用
INFO memory

# 设置最大内存
CONFIG SET maxmemory 4gb

# 设置淘汰策略
CONFIG SET maxmemory-policy allkeys-lru

# 清理过期数据
MEMORY PURGE
```

------

## **10. 架构设计参考**

### **10.1 整体架构图**

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   客户端     │────▶│  API 网关     │────▶│ 排行榜服务   │
└─────────────┘     └──────────────┘     └──────┬──────┘
                                                │
                    ┌───────────────────────────┼───────────────────────────┐
                    │                           │                           │
              ┌─────▼─────┐             ┌──────▼──────┐            ┌──────▼──────┐
              │  Redis    │             │   MySQL     │            │   消息队列   │
              │  ZSET     │             │  (持久化)   │            │  (异步更新)  │
              └───────────┘             └─────────────┘            └─────────────┘
```

### **10.2 高可用架构**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           高可用架构                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐            │
│   │  Redis Master│────▶│ Redis Slave │     │ Redis Slave │            │
│   │  (写操作)   │     │  (读操作)   │     │  (读操作)   │            │
│   └─────────────┘     └─────────────┘     └─────────────┘            │
│          │                   │                   │                      │
│          └───────────────────┼───────────────────┘                      │
│                              │                                          │
│                              ▼                                          │
│                    ┌─────────────────┐                                  │
│                    │   Sentinel/     │                                  │
│                    │   Cluster       │                                  │
│                    │   (故障转移)    │                                  │
│                    └─────────────────┘                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

------

## **11. 总结**

### **11.1 核心要点**

| 要点         | 说明                             |
| :----------- | :------------------------------- |
| **数据结构** | ZSET 是最佳选择，O(log N) 复杂度 |
| **Key 设计** | 按业务、赛季、周期合理划分       |
| **性能优化** | Pipeline、分片、过期时间         |
| **功能完整** | 支持 TopN、排名查询、分页、并列  |
| **可扩展性** | 支持百万级用户，高并发更新       |

### **11.2 生产环境配置建议**

| 场景       | 更新策略 | 持久化方案 |
| :--------- | :------- | :--------- |
| 🎮 游戏竞技 | 实时更新 | 异步双写   |
| 🛒 电商积分 | MQ异步   | 定时同步   |
| 📊 统计分析 | 定时任务 | 事件溯源   |

### **11.3 性能指标参考**

| 指标           | 目标值  |
| :------------- | :------ |
| 单次更新延迟   | <10ms   |
| Top100查询延迟 | <50ms   |
| 排名查询延迟   | <20ms   |
| 支持QPS        | 10万+   |
| 支持用户数     | 5000万+ |

### **11.4 监控告警建议**

```yml
# 关键监控指标
- redis_memory_used_ratio      # 内存使用率 >80% 告警
- redis_zset_cardinality       # ZSET元素数量
- redis_operation_qps          # 操作QPS
- redis_db_sync_lag            # 主从同步延迟
- redis_db_score_diff          # Redis-DB分数差异

# 告警渠道
- 钉钉/企业微信
- 邮件
- 短信（P0级）
```

------

## **附录**

### **A. Redis 命令速查表**

表格



| 命令      | 说明             | 时间复杂度   |
| :-------- | :--------------- | :----------- |
| ZADD      | 添加成员         | O(log N)     |
| ZINCRBY   | 增量更新         | O(log N)     |
| ZREM      | 删除成员         | O(log N)     |
| ZREVRANGE | 范围查询（降序） | O(log N + M) |
| ZREVRANK  | 获取排名         | O(log N)     |
| ZSCORE    | 获取分数         | O(1)         |
| ZCOUNT    | 统计数量         | O(log N)     |
| ZCARD     | 获取元素数       | O(1)         |

### **B. 相关资源**

- [Redis 官方文档 - Sorted Set](https://redis.io/docs/data-types/sorted-sets/)
- [Redis 性能最佳实践](https://redis.io/docs/management/optimization/)
- [Redis Cluster 部署指南](https://redis.io/docs/management/scaling/)

