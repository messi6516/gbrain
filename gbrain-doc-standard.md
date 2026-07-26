---
title: GBrain 文档编写规范
tags: [guide, standard]
aliases:
  - gbrain markdown spec
  - gbrain 文档规范
---

# GBrain 文档编写规范

本文档定义了一套 markdown 写作规范。按照本规范编写的文档可以被 gbrain 系统正确解析、分块、索引和检索。

> **对 LLM 的指示：** 在编写任何将被 gbrain 摄入的 markdown 文件时，你必须严格遵循本规范。下文每一节都是强制性要求，除非特别注明"可选"。

---

## 目录

1. [文件基本结构](#1-文件基本结构)
2. [Frontmatter 元数据](#2-frontmatter-元数据)
3. [正文写作规范](#3-正文写作规范)
4. [时间线分隔](#4-时间线分隔)
5. [实体链接](#5-实体链接)
6. [结构化数据围栏](#6-结构化数据围栏)
7. [页面类型模板](#7-页面类型模板)
8. [分块友好的写作技巧](#8-分块友好的写作技巧)
9. [全文检查清单](#9-全文检查清单)

---

## 1. 文件基本结构

一个标准的 gbrain 文档由三部分组成：

```markdown
---
# 第一部分：YAML frontmatter（元数据）
title: 页面标题
type: person
tags: [tag1, tag2]
aliases:
  - 别名1
  - 别名2
---

# 第二部分：正文（compiled_truth）
核心结论性内容放在这里。

<!-- timeline -->

# 第三部分：时间线（timeline）
按时间顺序的事件流水放在这里。
```

**规则：**
- 第一部分和第二部分是**必需的**。第三部分是可选的。
- 三部分之间的顺序不能颠倒。
- 如果不加 `<!-- timeline -->` 分隔线，则整个正文都视为第二部分（compiled_truth），第三部分为空。

---

## 2. Frontmatter 元数据

文件必须以 `---` 包裹的 YAML frontmatter 开头，放在文件第一行。

### 标准字段

```markdown
---
title: 页面标题
type: person
tags: [startup, ai, 2024]
aliases:
  - 别名A
  - 别名B
  - 别名C
---
```

| 字段 | 必需 | 说明 |
|------|------|------|
| `title` | 是 | 页面标题。尽量简短明确。搜索时有标题短语加分。 |
| `type` | 推荐 | 页面类型。可选值见下文。不写则 gbrain 会尝试从路径推断。 |
| `tags` | 可选 | 标签列表。支持 `list_pages --tag` 按标签过滤。 |
| `aliases` | 可选 | 别名列表。搜索时用户输入别名也能找到本页。 |

### 可用的 `type` 值

| type 值 | 适用场景 | 示例 |
|---------|---------|------|
| `person` | 人物 | 创始人、员工、联系人 |
| `company` | 公司 | 初创公司、企业 |
| `deal` | 交易/融资轮次 | Series A、种子轮 |
| `fund` | 投资基金 | VC、风投机构 |
| `meeting` | 会议记录 | 1:1、董事会 |
| `concept` | 概念/知识 | 技术概念、理论 |
| `project` | 项目 | 开源项目、内部项目 |
| `media` | 媒体内容 | 文章、视频、播客 |
| `source` | 信息来源 | 数据库、API、文档 |
| `note` | 通用笔记 | 以上都不符合时 |

### 关系声明字段（高级）

通过 frontmatter 中的特定字段，可以声明当前页与其他实体之间的关系。gbrain 会自动将这些关系转换为**带类型的图边**，支持图遍历查询。

**注意：** 下面字段中引用的实体名必须是已存在的页面 slug，或者是 gbrain 能解析到的页面名。

```markdown
---
# person 类型的页面
type: person
company: Acme Inc                   # 表示此人"工作于"Acme
companies: [Acme Inc, Stripe]       # 多公司写法
founded: Acme Inc                   # 表示此人"创立了"Acme

# company 类型的页面
type: company
key_people: [Alice Chen, Bob Wang]  # 表示这些人"工作于"本公司
investors: [Fund-A, Sequoia]        # 表示这些投资方"投资了"本公司

# deal 类型的页面
type: deal
investors: [Fund-A, Fund-B]         # 表示这些投资方"投资了"本交易
lead: Sequoia                       # 表示该方是"领投方"

# meeting 类型的页面
type: meeting
attendees: [Alice Chen, Bob Wang]   # 表示这些人"参加了"本次会议

# 任何类型
related: [topic/ai, project/gbrain] # 表示本页与目标页"相关"
source: media/yc-article            # 表示本页信息"来源于"该来源
sources: [media/article1, media/article2]
---
```

关系声明字段速查表：

| 字段 | 适用页面类型 | 生成的图边类型 | 方向 | 目标建议类型 |
|------|-------------|---------------|------|------------|
| `company` / `companies` | person | `works_at` | 本页 → 目标 | company |
| `founded` | person | `founded` | 本页 → 目标 | company |
| `key_people` | company | `works_at` | 目标 → 本页 | person |
| `partner` | company | `yc_partner` | 目标 → 本页 | person |
| `investors` | company / deal | `invested_in` | 目标 → 本页 | company / fund / person |
| `lead` | deal | `led_round` | 目标 → 本页 | company / fund / person |
| `attendees` | meeting | `attended` | 目标 → 本页 | person |
| `source` | 任意 | `source` | 本页 → 目标 | media |
| `sources` | 任意 | `discussed_in` | 目标 → 本页 | media |
| `related` / `see_also` | 任意 | `related_to` | 本页 → 目标 | 任意 |

---

## 3. 正文写作规范

正文（`<!-- timeline -->` 之上的部分）是搜索召回的核心区域。必须遵循以下规范。

### 3.1 结论前置

每段的**第一句话**必须是该段的核心结论。后续句子补充细节。

```markdown
## ✅ 正确写法

Acme 在 2024 年 12 月获得 500 万美金融资，投资方是 Fund-A 和 Fund-B。
本轮资金将用于产品研发和市场拓展。

## ❌ 错误写法

经过长达六个月的谈判和多轮尽职调查，最终 Fund-A 和 Fund-B 联合向 Acme 投资了 500 万美金。
```

**原因：** gbrain 搜索时返回的是 ~300 token 的 chunk。如果 chunk 在段落中间被截断，结论放在段首可以确保关键信息不丢失。

### 3.2 实体显式命名

**禁止**在可能跨段落的情况下使用代词（他、她、它、该公司、其等）指代前文实体。

```markdown
## ✅ 正确写法

Alice Chen 是 Acme 的 CEO，2021 年加入。Alice 负责公司整体战略。

Bob Wang 是 Acme 的 CTO，2022 年加入。Bob 直接向 Alice 汇报。

## ❌ 错误写法

Alice Chen 是 Acme 的 CEO，2021 年加入。她负责公司整体战略。

Bob Wang 后来也加入了，他向她汇报。
（"他/她"跨段后无法确定指代对象）
```

### 3.3 每段自包含

每个段落应在 ~200 字内独立传达完整信息。不依赖前文才能理解。

```markdown
## ✅ 正确写法

Alice Chen 是 Acme 的 CEO。Acme 是一家企业 AI 公司，2019 年由 Alice 创立。

Bob Wang 是 Acme 的 CTO。Bob 2022 年加入，直接向 CEO Alice 汇报。

## ❌ 错误写法

Alice 是 CEO，也是创始人。公司做企业 AI，2019 年成立。
（不知道"公司"指什么）
Bob 后来加入做 CTO，汇报给她。
（"她"是谁？）
```

### 3.4 段落分隔

不同主题必须用**空行**（`\n\n`）分隔。同一主题内的句子连续书写。

```markdown
## ✅ 正确写法

Alice Chen 是 Acme 的 CEO。她 2021 年加入，负责公司整体战略和融资。

Acme 是一家企业 AI 公司，主要产品是客服机器人。2024 年收入达 500 万美元。

## ❌ 错误写法

Alice Chen 是 Acme 的 CEO。她 2021 年加入，负责公司整体战略和融资。Acme 是一家企业 AI 公司，主要产品是客服机器人。2024 年收入达 500 万美元。
（四个不同主题挤在同一段，如果被切散，各 chunk 失去上下文）
```

### 3.5 使用标题组织层级

使用 `##` 和 `###` 组织二级和三级标题。标题本身不产生额外的搜索权重，但好的标题结构使同一节下的内容主题内聚，减少被跨主题分割的概率。

```markdown
## 团队

### Alice Chen — CEO
Alice Chen 是 Acme 的 CEO，2021 年加入。

### Bob Wang — CTO
Bob Wang 是 Acme 的 CTO，2022 年加入，向 Alice 汇报。
```

---

## 4. 时间线分隔

如果页面中包含时间线（按时间顺序的事件记录），必须用分隔线与正文隔开。

### 4.1 分隔线写法

```markdown
正文到这里结束。

<!-- timeline -->

时间线从这里开始。
```

支持三种分隔线写法：

| 写法 | 推荐度 | 说明 |
|------|--------|------|
| `<!-- timeline -->` | **推荐** | HTML 注释风格，最明确 |
| `--- timeline ---` | 兼容 | 视觉上较醒目 |
| `---`（后面紧跟 `## Timeline` 或 `## History` 标题） | 向后兼容 | 不推荐新文件使用 |

### 4.2 时间线内容格式

```markdown
<!-- timeline -->

- 2024-12-15：Acme A 轮融资 close，资金到账
- 2024-11-01：与 Fund-A 签署 term sheet
- 2024-10-15：开始与 Fund-A 接触
```

**规则：**
- 每行以 `- `（减号加空格）开头
- 日期优先用 `YYYY-MM-DD` 格式
- 日期和时间描述之间用 `：` 或 `—` 分隔

### 4.3 重要注意事项

```markdown
<!-- timeline -->

- 2024-12-15：融资到账
```

**不要把核心结论性信息只放在时间线里。** 搜索的默认模式（`detail: low`）不搜索时间线区域，常规模式（`detail: medium`）中时间线内容的权重减半。结论性信息必须放在正文部分。

```markdown
## ✅ 正确：结论在正文，细节在时间线

（正文）
Acme 在 2024 年 12 月完成 500 万美金融资，由 Fund-A 领投。

<!-- timeline -->

- 2024-12-15：wire transfer 到账
- 2024-11-01：签署 SPV

## ❌ 错误：核心事实只写在了时间线

<!-- timeline -->

- 2024-12：Acme 完成 500 万美金融资，由 Fund-A 领投
```
（搜索默认模式搜不到这条信息）

---

## 5. 实体链接

在正文中链接到其他 gbrain 页面时，gbrain 会自动识别并创建图边，支撑图遍历搜索。

### 5.1 标准 Markdown 链接

```markdown
了解更多请查看 [Alice Chen](/people/alice-chen) 的页面。
```

目标路径必须是已知的实体目录（`people/`、`companies/`、`funds/` 等）加 slug。

### 5.2 Obsidian 风格 Wikilink（推荐）

```markdown
了解更多请查看 [[people/alice-chen]] 的页面。

带显示名：[[people/alice-chen|Alice Chen]]
```

### 5.3 跨源 Wikilink

```markdown
引用另一个数据源的页面：[[source-id:people/alice-chen]]
```

### 5.4 通用 Wikilink（无路径前缀）

```markdown
[[bare-name]]
```

gbrain 会尝试自动匹配到真实页面的 slug。当名称唯一时效果好，不唯一时可能需改用完整路径。

### 5.5 通过上下文推断关系类型

gbrain 会从链接周围的文本中自动判断关系类型。无需手动标注类型。

```markdown
Alice Chen founded Acme Inc.
→ 图边: alice-chen → acme-inc 类型: founded

Alice Chen works at Acme Inc.
→ 图边: alice-chen → acme-inc 类型: works_at

Fund-A invested in Acme Inc.
→ 图边: fund-a → acme-inc 类型: invested_in
```

### 5.6 链接最佳实践

```markdown
## ✅ 正确写法

Alice Chen 是 [[companies/acme|Acme Inc]] 的 CEO，她在 2021 年创立了这家公司。
（gbrain 自动识别 "创立了" 并创建 founded 边）

## ❌ 避免的做法

点击这里查看公司的详细信息。
（没有实际链接，不会被索引）
```

---

## 6. 结构化数据围栏

对于需要精确查询的结构化数据，使用围栏（fenced table）格式。

### 6.1 Facts 围栏

用于存放关于实体的**客观事实**。搜索时不可见（分块前自动剥离），但可通过 `recall` 工具精确查询。

```markdown
## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | Founded Acme in 2017 | fact | 1.0 | world | high | 2017-01-01 | | linkedin | |
| 2 | Prefers async communication | preference | 0.85 | private | medium | 2026-04-29 | | meeting 2026-04-29 | |
<!--- gbrain:facts:end -->
```

列说明：

| 列名 | 必需 | 说明 | 有效值 |
|------|------|------|--------|
| `#` | 是 | 行号，从 1 开始递增，不要手动改 | 正整数 |
| `claim` | 是 | 事实陈述。用 `~~内容~~` 表示该事实已过期 | 文本 |
| `kind` | 是 | 事实类型 | `fact` / `preference` / `commitment` / `belief` |
| `confidence` | 是 | 确信度 | 0 到 1 之间的小数 |
| `visibility` | 是 | 可见性 | `world` / `private` |
| `notability` | 是 | 重要性 | `low` / `medium` / `high` |
| `valid_from` | 推荐 | 事实生效日期 | YYYY-MM-DD 或留空 |
| `valid_until` | 可选 | 事实失效日期（空白表示仍有效） | YYYY-MM-DD 或留空 |
| `source` | 推荐 | 信息来源 | 文本（如 `linkedin` / `meeting 2026-04-29`） |
| `context` | 可选 | 附加上下文。`forgotten: 原因` 表示遗忘，`superseded by #N` 表示被第 N 行取代 | 文本 |

过期/更正写法：

```markdown
| 3 | ~~Will hit $10M ARR by Q4~~ | commitment | 0.55 | world | medium | 2026-06-01 | 2026-12-31 | bo call | superseded by #4 |
| 4 | Will hit $8M ARR by Q4 | commitment | 0.65 | world | medium | 2026-09-01 | | board meeting | |
```

### 6.2 Takes 围栏

用于存放**主观判断**——某人何时对某事做出了多确信的判断。

```markdown
## Takes

<!--- gbrain:takes:begin -->
| # | claim | kind | who | weight | since | source |
|---|-------|------|-----|--------|-------|--------|
| 1 | CEO of Acme | fact | world | 1.0 | 2017-01 | Crustdata |
| 2 | Strong technical founder | take | alice | 0.85 | 2026-04-29 | OH 2026-04-29 |
| 3 | ~~Will reach $50B~~ | bet | alice | 0.7 | 2026-04-29 → 2026-06 | superseded by #4 |
| 4 | Will reach $30B | bet | alice | 0.55 | 2026-06 | revised after Q2 numbers |
<!--- gbrain:takes:end -->
```

列说明：

| 列名 | 必需 | 说明 | 有效值 |
|------|------|------|--------|
| `#` | 是 | 行号，从 1 开始递增 | 正整数 |
| `claim` | 是 | 判断陈述。用 `~~内容~~` 表示已失效 | 文本 |
| `kind` | 是 | 判断类型 | `fact` / `take` / `bet` / `hunch` 或自定义 |
| `who` | 是 | 做出此判断的人（page slug 或 `world`） | slug / `world` |
| `weight` | 是 | 确信度权重 | 0 到 1 之间的小数 |
| `since` | 是 | 起始时间（或时间范围用 `→` 连接） | YYYY-MM / YYYY-MM-DD |
| `source` | 推荐 | 信息来源 | 文本 |

### 6.3 围栏使用原则

```markdown
## ✅ 适合放 Facts/Takes 的信息

- "Acme 成立于 2017 年" → Facts fence（固定事实）
- "Alice 偏好异步沟通" → Facts fence（主观评估）
- "我认为 Acme 会达到 $30B" → Takes fence（带权重的判断）

## ❌ 不适合放围栏的信息

- 已经写在正文中的结论
- 临时性的笔记草稿
- 不适合结构化表格的长文本
```

---

## 7. 页面类型模板

以下是为常见页面类型准备的完整模板，可以直接参考使用。

### 7.1 人物页（type: person）

```markdown
---
title: Alice Chen
type: person
tags: [founder, ai]
aliases:
  - Alice
  - Alice Chen
company: Acme Inc
founded: Acme Inc
---

# Alice Chen

Alice Chen 是 [[companies/acme|Acme Inc]] 的 CEO 和联合创始人。她在 2017 年与 Bob Wang 共同创立了 Acme。

Alice 负责公司整体战略和融资。她在 2021 年全职加入 Acme，此前她在 Google 担任 AI 研究员。

Alice 拥有 Stanford 大学计算机科学博士学位。她在自然语言处理领域有 10 年以上经验。

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | CEO of Acme Inc | fact | 1.0 | world | high | 2021-01-01 | | linkedin | |
| 2 | Founded Acme in 2017 | fact | 1.0 | world | high | 2017-01-01 | | linkedin | |
<!--- gbrain:facts:end -->

<!-- timeline -->

- 2024-12-15：主导 Acme A 轮融资 close
- 2021-01-01：全职加入 Acme 担任 CEO
- 2017-06-01：与 Bob Wang 共同创立 Acme
```

### 7.2 公司页（type: company）

```markdown
---
title: Acme Inc
type: company
tags: [ai, enterprise, series-a]
aliases:
  - Acme
  - Acme Inc
key_people: [Alice Chen, Bob Wang]
investors: [Fund-A, Fund-B]
---

# Acme Inc

Acme Inc 是一家企业 AI 公司，2017 年由 [[people/alice-chen|Alice Chen]] 创立。公司主要产品是 AI 驱动的客服平台。

Acme 在 2024 年 12 月完成了 500 万美金的 A 轮融资，由 [[funds/fund-a|Fund-A]] 领投，Fund-B 跟投。

公司目前团队 20 人，分布在旧金山和纽约。主要客户包括三家 Fortune 500 企业。

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | AI客服平台 | fact | 1.0 | world | high | 2017-01-01 | | website | |
| 2 | 2024年500万美金A轮融资 | fact | 1.0 | world | high | 2024-12-15 | | press release | |
| 3 | 团队20人 | fact | 0.9 | world | medium | 2024-12-01 | | alice | |
<!--- gbrain:facts:end -->

<!-- timeline -->

- 2024-12-15：完成 500 万美金 A 轮融资，Fund-A 领投
- 2024-11-01：签署 Fund-A term sheet
- 2017-06-01：Alice Chen 创立 Acme
```

### 7.3 会议页（type: meeting）

```markdown
---
title: 2024-12-15 Acme 融资同步会
type: meeting
tags: [meeting, funding]
attendees: [Alice Chen, Garry Tan]
---

# Acme 融资同步会

2024 年 12 月 15 日与 Alice Chen 的同步会议。

Alice 汇报 Acme 的 A 轮融资已经 close，500 万美金已到账。下一轮预计在 2025 年 Q3。

Garry 建议 Acme 在 Q1 重点招聘销售 VP。

## 行动项

- Alice 下周五前发送投资人 deck 更新版
- Garry 介绍候选人给 Alice

<!-- timeline -->

- 2024-12-15 14:00：会议开始
- 2024-12-15 14:45：会议结束
```

---

## 8. 分块友好的写作技巧

gbrain 将每页内容按 ~300 tokens（约 200 汉字）切分为 chunk 进行搜索。以下技巧可确保每个独立 chunk 都能传达有效信息。

### 8.1 每 ~200 字是一个独立单元

```markdown
## ✅ 好：每段 ~200 字，自包含

Alice Chen 是 Acme 的 CEO。Acme 是一家 AI 客服公司。Alice 在 2021 年加入前曾在 Google 工作。
（约 50 字，完整落在单 chunk 内）

Bob Wang 是 Acme 的 CTO。他 2022 年加入 Acme，直接向 CEO Alice Chen 汇报。
（约 40 字，完整落在单 chunk 内）
```

### 8.2 结论放段首，细节放段尾

```markdown
## ✅ 好：段首是结论

Acme 在 2024 年 12 月完成了 500 万美金融资。本轮由 Fund-A 领投，Fund-B 跟投。资金将用于产品研发、市场拓展和团队扩充。

## ❌ 差：核心信息藏在末尾

经过 Fund-A 和 Fund-B 的尽调和条款谈判，在签署了 SPV 文件并完成交割后，Acme 终于在 2024 年 12 月收到了 500 万美金。
```

### 8.3 不依赖跨 chunk 的上下文

```markdown
## ✅ 好：每个段落独立可读

Acme 是一家企业 AI 公司。

Acme 在 2024 年完成 500 万美金融资。

## ❌ 差：段落之间互相依赖

Acme 是一家企业 AI 公司。它的主要产品是客服机器人。这家公司成立于 2017 年。它在 2024 年完成融资。
（如果 "这家公司成立于..." 被切到下一 chunk，新 chunk 开头是 "这家公司"，不知道指谁）
```

### 8.4 段落长度参考

| 内容类型 | 建议段落长度 | 说明 |
|---------|-------------|------|
| 一句话概述 | 10-20 字 | 实体定义、角色描述 |
| 标准段落 | 50-100 字 | 最常见的段落长度 |
| 长段落 | 100-200 字 | 复杂描述，需要确保自包含 |
| 超过 200 字 | **务必分段** | 超过 200 字一定会被 gbrain 切分为多个 chunk |

---

## 9. 全文检查清单

完成文档编写后，逐条检查：

### 基本结构

- [ ] 文件以 `---` 包裹的 YAML frontmatter 开头
- [ ] `title` 字段已填写
- [ ] `type` 字段已填写（可选但推荐）
- [ ] 如果页面有别名，`aliases` 字段已填写
- [ ] 如果页面有关联实体，关系声明字段已填写

### 正文质量

- [ ] 每段第一句是核心结论
- [ ] 不存在只用"他/她/它/该/其"指代前文实体的情况（人名至少每段显式出现一次）
- [ ] 每段可在脱离上下文的情况下独立理解
- [ ] 不同语义的主题用空行 `\n\n` 分隔
- [ ] 使用 `##` / `###` 标题组织层级结构

### 时间线

- [ ] 使用了 `<!-- timeline -->` 分隔线
- [ ] 核心结论性信息**同时**出现在正文中，而不仅出现在时间线里
- [ ] 时间线条目格式正确（`- YYYY-MM-DD：描述`）

### 链接

- [ ] 正文中引用的实体应使用 `[[dir/slug]]` 链接
- [ ] 链接目标存在于正确的目录中（`people/`、`companies/`、`funds/` 等）

### 围栏（如使用）

- [ ] Facts/Takes 围栏的 HTML 标记（`<!--- gbrain:facts:begin -->`）正确
- [ ] 表格列数和列名与规范一致
- [ ] 行号从 1 开始递增
- [ ] 过期行使用了 `~~~~` 包裹

### 分块友好度

- [ ] 没有超过 200 字且无段落分隔的长文本块
- [ ] 每个段落的开头都能独立回答问题
- [ ] 没有依赖前文才能理解的代词引用

---

*本规范文档本身也是符合 gbrain 标准的 markdown 文件。*
