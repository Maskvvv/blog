# 从 Prompt 到工程流程：深入理解 Matt Pocock Skills 的 AI Coding Agent 工作流

> 当 AI 编程助手开始进入真实软件开发场景，一个核心问题逐渐暴露：
>
> **AI 会写代码，但它真的会“开发软件”吗？**
>
> 软件开发不仅是写代码，它还包括：
>
> - 理解需求
> - 分析约束
> - 设计方案
> - 拆解任务
> - 实现功能
> - 验证质量
> - 维护长期上下文
>
> Matt Pocock 的 `skills` 项目，就是试图解决这个问题：
>
> **让 AI Agent 不只是代码生成器，而是像一个资深工程师一样工作。**

本文将深入介绍：

- Matt Pocock Skills 是什么
- 它解决什么问题
- 推荐工作流详解
- 与 OpenSpec 的区别
- 如何安装
- setup 初始化生成文件的意义
- 如何构建自己的 AI 开发流程

------

# 一、传统 AI Coding 的问题

很多人使用 AI 写代码的方式：

```text
用户：

帮我增加退款功能


AI：

好的，我创建 RefundService...


生成代码
```

看起来很快。

但是很快会遇到：

## 问题 1：需求理解不足

“退款功能”可能意味着：

- 用户主动退款？
- 管理员退款？
- 自动退款？
- 支持部分退款？
- 退款是否需要审核？
- 退款失败如何处理？
- 是否需要退款流水？

AI 不知道。

------

## 问题 2：架构上下文缺失

AI 可能生成：

```java
@RestController
public class RefundController {

    @PostMapping("/refund")
    public void refund(){
        // do refund
    }
}
```

但是你的项目可能：

- 使用 DDD
- 使用领域服务
- 使用 MQ
- 有统一异常体系

AI 不知道。

------

## 问题 3：代码质量不可控

AI 可以生成代码：

但是：

- 是否符合架构？
- 是否有安全问题？
- 是否覆盖测试？
- 是否考虑边界？

都需要人工检查。

所以：

> AI 编程真正的问题不是“写代码能力”，而是“工程流程能力”。

------

# 二、Matt Pocock Skills 是什么？

仓库：

```
mattpocock/skills
```

它不是一个代码库。

它更像：

> 给 AI Coding Agent 安装的一套工程技能。

结构类似：

```
skills/

├── grill-with-docs
│   └── SKILL.md
│
├── to-spec
│   └── SKILL.md
│
├── to-tickets
│   └── SKILL.md
│
├── implement
│   └── SKILL.md
│
└── code-review
    └── SKILL.md
```

每个 Skill 本质：

```
Skill

=
Prompt规范

+

工作流程

+

工程经验
```

------

# 三、核心思想：让 AI 按软件工程流程工作

Matt 推荐流程：

```
                用户需求

                    |
                    v

          grill-with-docs
          需求澄清

                    |
                    v

              to-spec
          技术规格设计

                    |
                    v

            to-tickets
            任务拆解

                    |
                    v

             implement
             编码实现

                    |
                    v

           code-review
           质量检查
```

这其实就是：

```
产品经理
    ↓
架构师
    ↓
项目经理
    ↓
开发工程师
    ↓
Reviewer
```

全部由 Agent 协作完成。

------

# 四、第一阶段：grill-with-docs

## 什么叫 grill？

英文：

> grill = 盘问、追问

它的作用：

不是写代码。

而是：

**逼 AI 和用户把需求想清楚。**

------

例如：

用户：

> 我要增加订单退款。

普通 AI：

```
创建 RefundService
创建 RefundController
```

------

Grill 模式：

AI：

```
退款针对哪些订单？

已支付订单可以退款吗？

是否支持部分退款？

退款是否需要审核？

退款失败怎么办？

是否需要退款记录？
```

经过讨论：

形成：

```
docs/

refund-feature.md
```

例如：

```markdown
# Refund Feature

目标：

用户取消订单后退款


规则：

1. 已支付订单才能退款
2. 完成订单不能退款
3. 大于1000元需要审核
```

------

# 五、第二阶段：to-spec

需求明确后：

进入技术设计。

区别：

```
grill:

我要做什么？


spec:

具体怎么实现？
```

例如：

需求：

```
增加退款
```

Spec：

```
数据库：

refund_order


字段：

id
order_id
amount
status


接口：

POST /refund


服务：

RefundService


事件：

RefundSuccessEvent
```

类似：

- 技术方案
- RFC
- ADR

------

# 六、第三阶段：to-tickets

不要让 AI 一次写完整功能。

拆任务：

```
退款功能

↓

Ticket 1:

创建退款表


Ticket 2:

实现退款状态机


Ticket 3:

开发 API


Ticket 4:

增加 MQ 通知


Ticket 5:

补充测试
```

好处：

AI 每次处理小任务：

```
上下文更清晰

错误更少

容易回滚
```

------

# 七、第四阶段：implement

终于进入编码。

但是不同于普通 AI：

它不是：

```
需求
 ↓
写代码
```

而是：

```
需求

↓

spec

↓

ticket

↓

代码
```

AI 有明确边界。

------

# 八、第五阶段：code-review

AI 写完：

必须检查。

包括：

## 业务正确性

例如：

需求：

```
超过1000需要审核
```

代码：

```java
refund(amount){

    executeRefund();

}
```

遗漏审核。

------

## 架构一致性

检查：

是否违反：

- 分层
- DDD
- 模块边界

------

## 测试

检查：

是否覆盖：

```
正常退款

重复退款

金额异常

退款失败
```

------

# 九、Matt Skills 与 OpenSpec 的区别

另一个热门方向：

> Spec Driven Development（规格驱动开发）

代表：

OpenSpec。

两者非常像，但是关注点不同。

------

## 一句话区别

```
Matt Skills:

教 AI 怎么工作


OpenSpec:

规定 AI 必须遵守什么规格
```

------

# 十、流程对比

## Matt Skills

```
需求

↓

讨论

↓

设计

↓

拆任务

↓

开发

↓

Review
```

重点：

理解需求。

------

## OpenSpec

```
Proposal

↓

Spec

↓

Plan

↓

Tasks

↓

Implementation
```

重点：

控制变化。

------

# 十一、优缺点比较

|          | Matt Skills  | OpenSpec     |
| -------- | ------------ | ------------ |
| 核心     | Agent 工作流 | 规格管理     |
| 优势     | 需求分析强   | 长期维护强   |
| 灵活性   | 高           | 中           |
| 约束     | 中           | 高           |
| 适合     | 新功能开发   | 大型项目维护 |
| 学习成本 | 低           | 高           |

------

# 十二、最佳实践：两者结合

更成熟的流程：

```
用户想法

    |

    v

Matt grill

需求澄清

    |

    v

OpenSpec

形成规格

    |

    v

to-tickets

任务拆解

    |

    v

implement

编码

    |

    v

code-review

审核
```

也就是：

```
探索阶段：

Matt


治理阶段：

OpenSpec
```

------

# 十三、安装 Matt Pocock Skills

现在推荐方式：

```bash
npx skills@latest add mattpocock/skills
```

安装过程：

选择：

```
✓ grill-with-docs

✓ to-spec

✓ to-tickets

✓ implement

✓ code-review

✓ setup-matt-pocock-skills
```

然后执行：

```
/setup-matt-pocock-skills
```

------

# 十四、setup 初始化做了什么？

初始化后：

生成：

```
AGENTS.md

docs/
└── agents/

    ├── issue-tracker.md

    ├── triage-labels.md

    └── domain.md


.scratch/
```

这些文件不是业务代码。

它们是：

> AI 的项目工作手册。

------

# 十五、AGENTS.md

作用：

告诉 AI：

这个项目如何协作。

类似：

```
员工手册
```

例如：

```
本项目使用 Matt Skills

修改代码前：

1. 查看 docs/agents
2. 创建任务
3. 遵循流程
```

------

# 十六、issue-tracker.md

定义：

任务在哪里管理。

例如：

选择：

```
local markdown tracker
```

那么：

AI 会使用：

```
.scratch/
```

保存任务。

例如：

```
.scratch/

001-login-bug.md

002-add-payment.md
```

------

# 十七、triage-labels.md

定义任务分类。

例如：

```
bug

feature

refactor

docs

question
```

保证 AI 分类一致。

------

# 十八、domain.md

非常重要。

它告诉 AI：

项目知识在哪里。

例如：

```
single-context

根目录 CONTEXT.md

docs/adr/
```

AI 查架构：

先看：

```
CONTEXT.md
```

再看：

```
docs/adr
```

------

# 十九、CONTEXT.md 和 ADR

推荐自己补充：

## CONTEXT.md

记录：

```
项目是什么

技术栈

架构

编码规范

重要约束
```

例如：

```markdown
# Project Context

Backend:

Spring Boot


Database:

PostgreSQL


Architecture:

Controller

↓

Service

↓

Repository
```

------

## ADR

Architecture Decision Record。

记录：

为什么这么设计。

例如：

```
docs/adr/

001-use-postgresql.md

002-event-driven.md
```

未来 AI 可以理解：

为什么这么做。

------

# 二十、最终理解

Matt Pocock Skills 的核心不是：

“让 AI 写更多代码”。

而是：

建立一个：

```
AI 软件工程流程
```

从：

```
Idea
```

到：

```
Reliable Software
```

完整链路：

```
             Idea

              |

              v

       Requirement Agent

              |

              v

        Design Agent

              |

              v

        Planning Agent

              |

              v

        Coding Agent

              |

              v

        Review Agent
```

未来的软件开发，很可能不是：

```
人写代码

AI辅助
```

而是：

```
人负责目标和决策

AI负责执行工程流程
```

Matt Pocock Skills 的价值，就在于它探索了一套让 AI 真正参与软件工程的方法。