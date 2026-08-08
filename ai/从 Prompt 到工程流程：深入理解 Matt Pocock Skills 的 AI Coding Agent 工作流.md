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
- 完整技能地图：ask-matt 与流程体系
- 工单机制：Status 流转与任务指定
- 企业级扩展：设计评审文档

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
└── refund-feature/
    ├── spec.md
    └── issues/
        ├── 01-create-refund-table.md
        └── 02-refund-state-machine.md
```

一个功能一个目录。

每张工单一个文件，绝不合成一个大文件。

------

# 十七、triage-labels.md

定义任务的分诊状态。

默认五个标签：

```
needs-triage      等待维护者评估
needs-info        等待报告者补充信息
ready-for-agent   已完全明确，AI Agent 可直接领走执行
ready-for-human   需要人来实施
wontfix           不会处理
```

注意：

它们不是 "bug / feature" 这类分类标签。

而是：

> 分诊状态。

描述一个任务当前能不能被领走执行。

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

实际上，在 Matt Skills 中，

CONTEXT.md 更核心的角色是：

> 项目领域词汇表（glossary）。

每个词条固定格式：

术语 + 定义 + 禁用同义词（Avoid）。

例如：

```
**退款单**：
已支付订单退款成功后生成的退款记录。
_Avoid_：退款单、退款流水
```

目的：

让人和 AI、文档和会话之间用词一致。

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

另外注意 ADR 的布局：

> 扁平、按序号排，不按功能分子目录。

因为 ADR 记录的是"难以反悔的决定"。

跨越所有功能持续生效。

唯一的例外是多上下文仓库：

根目录有 CONTEXT-MAP.md 时，

每个上下文有自己的 src/<context>/docs/adr/。

------

# 二十、完整技能地图：不止五个技能

前面只介绍了主干。

Matt Skills 其实是一张完整的地图。

还有一个专门的路由技能：

> ask-matt

不知道用哪个技能时，问它。

## 主流程（idea → ship）

```
grill-with-docs

↓

to-spec

↓

to-tickets

↓

implement

↓

code-review
```

## 入口（on-ramps）

三种会"生成工作"的起点：

```
triage

处理堆积的外来 bug / 需求单


diagnosing-bugs

诊断难缠的 bug

先建立紧密反馈循环，再谈理论


wayfinder

为大而模糊的项目绘制路线图

产出的是决策，不是交付物
```

## 代码库健康

```
improve-codebase-architecture

有空时扫描代码库

发现"深化机会"
```

## 词汇层

运行在所有技能底下的两份词汇表：

```
domain-modeling

管理 CONTEXT.md 的领域术语


codebase-design

深模块设计词汇

接口、缝隙、深度
```

## 独立技能

```
prototype

用一次性原型回答设计问题


research

把调研工作委托给后台 agent


handoff

写可移植的交接文档


resolving-merge-conflicts

解决合并冲突


wizard

为"只有人能做的步骤"生成交互脚本


wait-what

让 AI 用你听得懂的话重说一遍
```

## 阶段边界

两个阶段之间，有五个选项：

```
继续

清空上下文（/clear）

写交接文档（/handoff）

派子代理（subagent）

压缩上下文（/compact）
```

默认是 compact。

最先排除的应该是"继续"。

------

# 二十一、本地工单的真实结构

每张工单一个文件。

从 01 开始编号，按依赖顺序排。

固定模板：

```markdown
# 01 — 创建退款表

**What to build:** 从用户视角描述的端到端行为

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] 验收标准 1
- [ ] 验收标准 2
```

三个关键点：

工单是"曳光弹"式的垂直切片。

每一刀都切穿所有层：

```
schema

API

UI

测试
```

而不是按层做水平拆分。

完成的切片必须可以独立演示或验证。

------

# 二十二、Status 流转：谁写 ready-for-agent，谁消费它

这是整套机制里最容易误解的一点。

## 写入端：自动

```
to-spec

写完 spec 后自动打上 ready-for-agent


to-tickets

每张工单生成时就带 ready-for-agent


triage

外来的 raw issue 评估合格后移入 ready-for-agent
```

注意：

to-tickets 产出的工单已经是 agent-ready。

不要再过 triage。

## 消费端：手动

implement 不会自动扫描 ready-for-agent 的工单。

它在等你把工单递过去：

```
实现 .scratch/refund-feature/issues/01-create-refund-table.md
```

官方的说法是：

> work the frontier, blockers-first, by hand

本地 markdown 工单没有后台进程。

把选取权留给人，正好配合依赖顺序的控制。

不过这套约定是机器可读的：

Status 行 + Blocked by 行，

足够让 agent 自己算出执行顺序。

想要自动批量执行时，下这样的指令即可。

------

# 二十三、运行每个技能时，需要明确指定任务吗？

分情况：

| 技能 | 是否需要指定 |
| --- | --- |
| to-spec | 不需要，直接综合当前对话 |
| to-tickets | 一般不需要，吃同一会话的上下文 |
| implement | 需要，给工单路径或编号 |
| code-review | 需要给对比基准，spec 会按顺序自动查找 |

code-review 查找 spec 的顺序：

```
1. commit message 里的 issue 引用

2. 用户传入的路径

3. .scratch/ 下匹配分支名的 spec 文件

4. 都找不到，问用户
```

由此得到 Matt 的"上下文管理"建议：

```
grill → to-spec → to-tickets

留在同一个上下文窗口


每个 implement

新开会话，只带一张工单


工单之间

/clear
```

------

# 二十四、工单完成后，Status 会变吗？

默认不会。

implement 的收尾动作是：

```
跑测试

↓

code-review

↓

commit 到当前分支
```

完成信号是那个 commit，不是状态变更。

更根本的原因：

五个分诊标签里本来就没有 "done"。

它们描述的是"能不能被领走"，不是生命周期。

想在本地追踪完成情况，可以自己定约定：

```
验收标准勾选为 - [x]

**Status:** 改为 done

## Comments 里记录 commit hash
```

把这条约定写进 docs/agents/issue-tracker.md。

所有技能开工前都读这份文档。

以后 implement 收尾时就会自动执行。

------

# 二十五、企业级扩展：设计评审文档的缺口

企业开发中通常有技术设计评审：

```
接口文档

数据库设计 / ER 图

流程图 / 时序图

详细设计
```

Matt Skills 的流程不产出这些。

而且是刻意不产出：

> avoid specific file paths or code snippets — they go stale fast

它隐含了一个假设：

> 审批人就是坐在对话里的你。

企业评审打破了这个假设：

评审人不在上下文窗口里。

他们需要一份自包含的、可离线阅读的快照。

## 建议：to-tickets 之后生成评审文档

此时时机最好：

spec、tickets 和所有决策的"为什么"都还在同一个上下文里。

综合成文档的成本最低。

但有三个坑：

```
1. 细节缺口

评审需要的 DDL、接口签名并不在 spec 里

必须从代码库现状推导，或显式标注"待定"

不允许凭空发明


2. 快照 vs 活文档

评审通过后冻结版本

不要让 implement 去维护它


3. 格式每次重述

把模板固化成自定义技能
```

## 建议的技能形态：/to-design-doc

```
输入：

spec + tickets + ADR + 代码库探索


输出：

docs/design/<feature>.md

顶部 Status: draft / approved


图表：

Mermaid

可 diff、可版本化


硬约束：

术语用 CONTEXT.md 的词

每个章节标注来源

无法确定的进"待定项"清单


门禁：

Status 变为 approved 之前

不允许开始 /implement
```

最后建议分级：

```
小功能：跳过

中等功能：只出接口 + 数据库部分

大功能：完整版
```

否则流程会把自己压死。

------

# 二十六、最终理解

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
