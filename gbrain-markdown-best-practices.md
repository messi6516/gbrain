---
title: GBrain Markdown 编写最佳实践
type: guide
tags: [guide, standard, markdown, gbrain]
aliases:
  - gbrain markdown best practices
  - gbrain 文档编写规范 v2
  - gbrain doc standard
---

# GBrain Markdown 编写最佳实践

本文档是面向 LLM Wiki 系统的 **markdown 编写权威规范**。每条规则都基于 gbrain 的实际实现 —— 从 markdown 解析 (`src/core/markdown.ts`)、递归分块 (`src/core/chunkers/recursive.ts`)、上下文增强嵌入 (`src/core/embedding-context.ts`)、链接提取 (`src/core/link-extraction.ts`) 到混合检索引擎 (`src/core/search/`) —— 而非主观偏好。

> **核心原则：每 ~200 字一个自包含段落，结论置首，实体显式命名，不同主题用空行分隔。**

---

## 目录

1. [文件结构](#1-文件结构)
2. [Frontmatter 规范](#2-frontmatter-规范)
3. [正文写作规范](#3-正文写作规范)
4. [时间线规范](#4-时间线规范)
5. [实体链接规范](#5-实体链接规范)
6. [结构化数据围栏](#6-结构化数据围栏)
7. [页面类型体系](#7-页面类型体系)
8. [分块与搜索优化](#8-分块与搜索优化)
9. [内容质量门禁](#9-内容质量门禁)
10. [完整检查清单](#10-完整检查清单)

---

## 1. 文件结构

每个 gbrain 页面由 **三个部分** 组成，由解析器 (`parseMarkdown`) 按序提取：

```
┌──────────────────────────────┐
│  YAML Frontmatter            │  ← 元数据：title, type, tags, aliases 等
│  (--- ... ---)               │
├──────────────────────────────┤
│  Compiled Truth (正文)        │  ← 搜索召回的**核心区域**
│                              │
├─ <!-- timeline --> ──────────┤
│  Timeline (时间线)            │  ← 按时间的事件流水（可选）
└──────────────────────────────┘
```

**解析器行为：**

| 分隔线写法                                 | 优先级           | 说明                                          |
| ------------------------------------------ | ---------------- | --------------------------------------------- |
| `<!-- timeline -->`                        | **最高（推荐）** | HTML 注释风格，`serializeMarkdown` 的输出格式 |
| `--- timeline ---`                         | 中               | 装饰性分隔线                                  |
| `---` 后紧跟 `## Timeline` 或 `## History` | 低（向后兼容）   | 仅当下一行是 Timeline/History 标题时          |

**关键规则：**
- 第一部分和第二部分是**必需的**
- 第三部分（时间线）是可选的
- 如果没有分隔线，整个 body 都视为 compiled_truth
- 不要用裸 `---` 做分隔线 —— 它会被当作 markdown 水平分割线

---

## 2. Frontmatter 规范

### 2.1 基本格式

文件必须以 `---` 开头的 YAML frontmatter 起始，**第一行非空行必须是 `---`**。解析器会校验缺失开启/关闭分隔线的情况。

```yaml
---
title: 页面标题           # 必需
type: concept             # 推荐（不写则从路径推断）
tags: [ai, llm, 2024]     # 可选
aliases:                  # 可选，搜索时的免费文本别名
  - AI 大模型
  - LLM 技术
---
```

### 2.2 标准字段速查

| 字段         | 必需   | 类型                       | 说明                                                              |
| ------------ | ------ | -------------------------- | ----------------------------------------------------------------- |
| `title`      | **是** | string                     | 页面标题。搜索时有标题短语加权。优先于 body 中的 H1               |
| `type`       | 推荐   | string                     | 页面类型。不写则从路径推断。见 [§7 页面类型体系](#7-页面类型体系) |
| `tags`       | 可选   | string[] 或逗号分隔 string | 标签。支持 `list_pages --tag` 过滤                                |
| `aliases`    | 可选   | string[]                   | 搜索别名。用户输入别名时直接命中对应页面（alias hop）             |
| `slug`       | 不推荐 | string                     | 覆盖路径派生的 slug（仅当文件名无法产生 slug 时使用）             |
| `date`       | 可选   | ISO 日期                   | 内容日期。用于 effective_date 计算                                |
| `event_date` | 可选   | ISO 日期                   | 事件/会议日期。effective_date 最高优先级                          |
| `published`  | 可选   | ISO 日期                   | 发布日期。用于 writing/ 类型                                      |
| `subtype`    | 可选   | string                     | 子类型（见 [§7.2](#72-子类型-subtype)）                           |
| `id`         | 可选   | string                     | 外部 ID（granola UUID / ULID），用于跨路径去重                    |

### 2.3 日期字段优先级

gbrain 按以下顺序确定页面的 "有效日期"（用于时间过滤和排序）：

```
event_date > date > published > 文件名日期 > updated_at > created_at
```

对于 `daily/` 和 `meetings/` 目录，**文件名日期跃升至第 1 位**。

### 2.4 关系声明字段

通过 frontmatter 声明实体间关系，gbrain 会自动创建带类型的图边：

| 字段                    | 适用页面类型   | 图边类型       | 方向              |
| ----------------------- | -------------- | -------------- | ----------------- |
| `company` / `companies` | person         | `works_at`     | person → company  |
| `founded`               | person         | `founded`      | person → company  |
| `key_people`            | company        | `works_at`     | person → company  |
| `investors`             | company / deal | `invested_in`  | investor → target |
| `lead`                  | deal           | `led_round`    | lead → deal       |
| `attendees`             | meeting        | `attended`     | person → meeting  |
| `source`                | 任意           | `source`       | page → source     |
| `sources`               | 任意           | `discussed_in` | source → page     |
| `related` / `see_also`  | 任意           | `related_to`   | 双向              |

值格式支持：
- 字符串：`company: Acme Inc`
- 数组：`key_people: [Alice Chen, Bob Wang]`
- 对象数组：`investors: [{name: Fund-A, role: Lead}]`
- Obsidian wikilink：`related: ["[[topic/ai]]", "[[project/gbrain]]"]`

### 2.5 Frontmatter 校验错误

解析器在 `validate` 模式下检测以下问题（`gbrain lint` 会报告）：

| 错误码              | 含义                          |
| ------------------- | ----------------------------- |
| `MISSING_OPEN`      | 缺少 `---` 开头               |
| `MISSING_CLOSE`     | 缺少 `---` 闭合               |
| `EMPTY_FRONTMATTER` | frontmatter 块为空            |
| `YAML_PARSE`        | YAML 解析失败                 |
| `NESTED_QUOTES`     | 双引号嵌套（用单引号包裹）    |
| `NON_STRING_FIELD`  | title/type/slug 不是字符串    |
| `NULL_BYTES`        | 内容包含 null 字节            |
| `SLUG_MISMATCH`     | frontmatter slug 与路径不匹配 |

---

## 3. 正文写作规范

正文 (compiled_truth) 是搜索召回的 **核心区域**。gbrain 的三种搜索模式（conservative / balanced / tokenmax）都优先搜索正文。以下是基于分块器实际行为的写作规范：

### 3.1 结论前置（最重要）

每段的 **第一句必须是该段的核心结论**。后续句子补充细节。

```markdown
## ✅ Acme 在 2024 年 12 月完成 500 万美金融资，由 Fund-A 领投。本轮资金将用于产品研发和市场拓展。

## ❌ 经过长达六个月的谈判和多轮尽职调查，最终 Fund-A 联合 Fund-B 向 Acme 投资了 500 万美金。
```

**原因：** gbrain 的分块器在 ~300 tokens（约 200 汉字）边界切分。如果 chunk 在段落中间被截断，结论放在段首可确保关键信息不丢失。此外，上下文增强检索（contextual retrieval）会在 embedding 时给每个 chunk 加上页面标题前缀 —— 段首结论 + 标题前缀的组合是召回率最高的模式。

### 3.2 实体显式命名，禁止跨段代词

**绝对禁止**跨段落使用代词（他、她、它、该公司、其等）指代前文实体。每个段落必须独立可读。

```markdown
## ✅ Alice Chen 是 Acme 的 CEO，2021 年加入。Alice 负责公司整体战略。

## ❌ Alice Chen 是 Acme 的 CEO。她负责公司整体战略。（"她"跨段后无法确定）
```

**原因：** 分块器在 `\n\n`（段落边界）优先切分。如果 "她" 落在下一个 chunk，LLM 无法确定指代对象。

### 3.3 每段自包含（~200 字以内）

每个段落应在 ~200 字内独立传达完整信息。

```markdown
## ✅ Alice Chen 是 Acme 的 CEO。Acme 是一家企业 AI 公司，2019 年由 Alice 创立。

## ❌ Alice 是 CEO，公司做企业 AI。后来 Bob 加入做 CTO，汇报给她。
```

**原因：** 分块器使用 5 级分隔符层次结构递归切分：
1. **L0: `\n\n`**（段落）—— 最高优先级切割点
2. **L1: `\n`**（行）
3. **L2: 句子结束**（`. ` `! ` `? ` 及中文 `。！？`）
4. **L3: 子句**（`; ` `: ` `, ` 及中文 `；：，、`）
5. **L4: 词**（空白符 + CJK 字符切片回退）

段落越短，越可能完整落在一个 chunk 内。

### 3.4 用空行分隔不同主题

不同语义主题必须用空行 `\n\n` 分隔。同一主题内连续书写。

```markdown
## ✅
Alice Chen 是 Acme 的 CEO，2021 年加入，负责公司战略和融资。

Acme 是一家企业 AI 公司，主要产品是客服机器人。2024 年收入 500 万美元。

## ❌
Alice Chen 是 Acme 的 CEO，2021 年加入，负责公司战略和融资。Acme 是一家企业 AI
公司，主要产品是客服机器人。2024 年收入 500 万美元。
（四个不同主题挤在同一段，被切散后各 chunk 丢失上下文）
```

### 3.5 标题组织层级

使用 `##` 和 `###` 组织层级。标题本身不直接产生搜索权重，但好的结构使内容主题内聚，减少跨主题切割的概率。body 中的第一个 `# H1` 会被用作 title 的后备（当前端缺少 `title:` frontmatter 时）。

### 3.6 段落长度参考

| 内容类型        | 建议长度     | 原因                               |
| --------------- | ------------ | ---------------------------------- |
| 实体定义        | 10-20 字     | 一句话概括                         |
| 标准段落        | 50-100 字    | 最常见的有效单元                   |
| 长段落          | 100-200 字   | 复杂描述，需确保自包含             |
| **超过 200 字** | **务必分段** | 超过 ~200 字大概率被切到多个 chunk |

---

## 4. 时间线规范

### 4.1 基本格式

```markdown
<!-- timeline -->

- **2024-12-15** — Acme A 轮融资 close，wire transfer 到账
- **2024-11-01** — 与 Fund-A 签署 term sheet
- **2024-10-15** — 开始与 Fund-A 接触
```

**解析器识别的格式：**
- `- **YYYY-MM-DD** | 摘要`
- `- **YYYY-MM-DD** -- 摘要`
- `- **YYYY-MM-DD** — 摘要`
- `**YYYY-MM-DD** | 摘要`（不需要前导 `-`）

还支持：
- **多行条目**：缩进的续行或非列表行被视为 detail
- **行内引用**：`[Source: 来源名称, YYYY-MM-DD]` 格式的引用会被自动提取

### 4.2 黄金规则

> **核心结论性信息必须同时出现在正文中，不能只放在时间线里。**

搜索的 `detail: low` 模式完全不搜索时间线；`detail: medium` 模式时间线权重减半。结论放正文，流水细节放时间线。

---

## 5. 实体链接规范

gbrain 在每次 `put_page` 写入时自动运行链接提取（`extractEntityRefs`），零 LLM 调用即可构建知识图谱。以下是支持的链接语法：

### 5.1 链接语法速查

| 语法              | 示例                                 | 说明                                                              |
| ----------------- | ------------------------------------ | ----------------------------------------------------------------- |
| 标准 Markdown     | `[Alice Chen](people/alice-chen)`    | 传统格式                                                          |
| Obsidian Wikilink | `[[people/alice-chen]]`              | **推荐**                                                          |
| 带别名的 Wikilink | `[[people/alice-chen\|Alice]]`       | 显示名不同于 slug                                                 |
| 跨源 Wikilink     | `[[other-source:people/alice-chen]]` | 链接到其他数据源                                                  |
| 通用 Wikilink     | `[[bare-name]]`                      | 自动匹配唯一 basename（需开启 `link_resolution.global_basename`） |
| 裸 slug 引用      | `参见 people/alice-chen 了解更多`    | 在文本中自然出现的 slug 也会被识别                                |

### 5.2 自动关系类型推断

gbrain 从链接周围的 ~240 字符上下文中，通过正则推断关系类型：

| 上下文动词                                      | 推断类型                    |
| ----------------------------------------------- | --------------------------- |
| founded / co-founded / founder of               | `founded`                   |
| invested in / led the round / portfolio company | `invested_in`               |
| works at / CEO of / engineer at / joined        | `works_at`                  |
| advises / advisor to / board advisor            | `advises`                   |
| 无匹配动词 + person 页 + partner 角色           | `invested_in`（页面级先验） |
| 无匹配动词 + meeting 页                         | `attended`                  |
| 其他                                            | `mentions`                  |

### 5.3 链接最佳实践

```markdown
## ✅ Alice Chen 是 [[companies/acme\|Acme Inc]] 的 CEO，她在 2021 年创立了这家公司。
（"创立了" → gbrain 自动创建 founded 边）

## ✅ Fund-A 在 2024 年领投了 [[companies/acme\|Acme]] 的 A 轮融资。
（"领投了" → gbrain 自动创建 invested_in 边）

## ❌ 点击这里查看公司的详细信息。
（没有实际链接，图边不会被创建）
```

### 5.4 代码引用

在正文中引用代码文件路径（如 `src/core/sync.ts:42`），gbrain 会自动创建 `documents` / `documented_by` 双向图边：

```markdown
导入逻辑在 src/core/import-file.ts:231 的 importFromContent 函数中实现。
```

识别范围限定在以下目录：`src/`, `lib/`, `app/`, `test/`, `tests/`, `scripts/`, `docs/`, `packages/`, `internal/`, `cmd/`, `examples/`

---

## 6. 结构化数据围栏

### 6.1 Facts 围栏

用于存放关于实体的**客观事实**。`visibility: private` 的事实会在分块前被剥离（不进入搜索索引），但可通过 `recall` 工具精确查询。

```markdown
## Facts

<!--- gbrain:facts:begin -->
| #   | claim                         | kind       | confidence | visibility | notability | valid_from | valid_until | source             | context          |
| --- | ----------------------------- | ---------- | ---------- | ---------- | ---------- | ---------- | ----------- | ------------------ | ---------------- |
| 1   | Acme 2017年由 Alice Chen 创立 | fact       | 1.0        | world      | high       | 2017-01-01 |             | linkedin           |                  |
| 2   | Alice 偏好异步沟通            | preference | 0.85       | private    | medium     | 2026-04-29 |             | meeting 2026-04-29 |                  |
| 3   | ~~Q3 达到 $10M ARR~~          | commitment | 0.55       | world      | medium     | 2026-06-01 | 2026-12-31  | board call         | superseded by #4 |
| 4   | Q3 达到 $8M ARR               | commitment | 0.65       | world      | medium     | 2026-09-01 |             | board meeting      |                  |
<!--- gbrain:facts:end -->
```

**列说明：**

| 列            | 必需 | 说明                                                | 有效值                                          |
| ------------- | ---- | --------------------------------------------------- | ----------------------------------------------- |
| `#`           | 是   | 行号，从 1 递增                                     | 正整数                                          |
| `claim`       | 是   | 事实陈述。`~~内容~~` 表示已过期                     | 文本                                            |
| `kind`        | 是   | 事实类型                                            | `fact` / `preference` / `commitment` / `belief` |
| `confidence`  | 是   | 确信度                                              | 0.0–1.0                                         |
| `visibility`  | 是   | 可见性                                              | `world` / `private`                             |
| `notability`  | 是   | 重要性                                              | `low` / `medium` / `high`                       |
| `valid_from`  | 推荐 | 生效日期                                            | YYYY-MM-DD                                      |
| `valid_until` | 可选 | 失效日期                                            | YYYY-MM-DD                                      |
| `source`      | 推荐 | 信息来源                                            | 自由文本                                        |
| `context`     | 可选 | 附加上下文。`forgotten: 原因` 或 `superseded by #N` | 自由文本                                        |

### 6.2 Takes 围栏

用于存放**主观判断** —— 某人对某事的确信度。

```markdown
## Takes

<!--- gbrain:takes:begin -->
| #   | claim                    | kind | who   | weight | since                | source           |
| --- | ------------------------ | ---- | ----- | ------ | -------------------- | ---------------- |
| 1   | CEO of Acme              | fact | world | 1.0    | 2017-01              | Crustdata        |
| 2   | Strong technical founder | take | alice | 0.85   | 2026-04-29           | OH 2026-04-29    |
| 3   | ~~Will reach $50B~~      | bet  | alice | 0.7    | 2026-04-29 → 2026-06 | superseded by #4 |
| 4   | Will reach $30B          | bet  | alice | 0.55   | 2026-06              | revised after Q2 |
<!--- gbrain:takes:end -->
```

Takes 围栏的内容**始终**在分块前被剥离——它们只能通过 `takes_search` / `takes_list` 工具查询，不进入语义搜索。

### 6.3 围栏使用原则

| 适合放围栏           | 不适合放围栏       |
| -------------------- | ------------------ |
| 可结构化的确定性事实 | 已在正文中的结论   |
| 带有确信度的主观判断 | 临时性笔记草稿     |
| 需要精确查询的数据   | 不适合表格的长文本 |

---

## 7. 页面类型体系

### 7.1 标准类型 (v0.41.22+, gbrain-base-v2)

| 类型       | 原始分类 | 适用场景              | 路径前缀示例                  |
| ---------- | -------- | --------------------- | ----------------------------- |
| `person`   | entity   | 人物                  | `people/`                     |
| `company`  | entity   | 公司/产品/组织        | `companies/`                  |
| `media`    | media    | 文章/视频/播客/书籍   | `media/`                      |
| `tweet`    | media    | 推文                  | `tweets/`                     |
| `analysis` | media    | 分析/研究             | `wiki/analysis/`              |
| `writing`  | media    | 原创写作              | `writing/`                    |
| `source`   | media    | 信息来源/ transcripts | `sources/`                    |
| `deal`     | temporal | 交易/融资             | `deals/`                      |
| `email`    | temporal | 邮件                  | `emails/`                     |
| `slack`    | temporal | Slack 消息            | `slack/`                      |
| `meeting`  | temporal | 会议记录              | `meetings/`                   |
| `concept`  | concept  | 概念/知识             | `wiki/concepts/`, `concepts/` |
| `project`  | concept  | 项目/工作流           | `projects/`                   |
| `note`     | concept  | 通用笔记（兜底）      | `notes/`                      |
| `guide`    | concept  | 指南/教程             | `wiki/guides/`                |

### 7.2 子类型 (subtype)

通过 frontmatter 声明子类型：

```yaml
---
type: media
subtype: video     # article | video | essay | book | podcast | blog
---
```

| 类型      | 可用子类型                                                  |
| --------- | ----------------------------------------------------------- |
| `company` | `company` / `product` / `org`                               |
| `media`   | `video` / `article` / `essay` / `book` / `podcast` / `blog` |
| `tweet`   | `single` / `bundle` / `stub`                                |
| `atom`    | `extraction` / `manual` / `lore`                            |

### 7.3 类型推断

如果不写 `type:` frontmatter，gbrain 从路径推断类型。推断规则：

1. **Schema Pack 的 path_prefixes**（如 `gbrain-base-v2`）优先
2. **回退到内置硬编码表**（向后兼容）

例如：`people/alice-chen.md` → `person`，`companies/acme.md` → `company`，其他 → `concept`

---

## 8. 分块与搜索优化

### 8.1 分块器机制

gbrain 的递归分块器 (`chunkText`) 使用 **5 级分隔符层次结构**：

```
L0: \n\n          → 段落（最优先切此处）
L1: \n            → 行
L2: . ! ? 。！？   → 句子结束
L3: ; : , ；：，、 → 子句
L4: 词             → 空白字符 + CJK 字符切片（最后手段）
```

参数：300 词目标大小，50 词重叠，6000 字符硬上限。CJK（中日韩）文本感知中文句子和子句分隔符。

### 8.2 搜索结果排序信号

gbrain 的混合搜索引擎使用 **四层策略**：

1. **向量相似度** (HNSW on pgvector) — 语义匹配
2. **BM25 关键词** — 精确词匹配
3. **RRF (Reciprocal Rank Fusion)** — 融合向量 + 关键词排名
4. **知识图谱遍历** — 沿图边查找关系

**提升你的页面被召回的概率：**

| 信号               | 如何优化                                                                                        |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| **标题短语匹配**   | 确保 `title:` 包含页面核心主题词。用户搜索词与标题短语匹配时自动加权。                          |
| **别名命中**       | `aliases:` 列表中的每个值都是免费搜索入口。写上同义词、缩写、常见拼写变体。                     |
| **图边密度**       | 多使用 `[[wikilink]]` 链接到相关页面。密集链接的页面在图遍历中更易被发现。                      |
| **来源加权**       | 高质量目录（`concepts/`, `writing/`, `wiki/`）天然比 `daily/`, `chat/` 排名更高。               |
| **语义覆盖**       | 正文中显式写出关键概念的全称和简称（如 "Large Language Model (LLM)"），让向量搜索命中任一形式。 |
| **每页最佳 chunk** | 搜索引擎在每个页面只返回最佳 chunk（per-page max-pool）。确保**核心信息集中在最优质的段落中**。 |

### 8.3 上下文增强检索

gbrain 的 contextual retrieval 功能在 embedding 时自动给每个 chunk 添加页面标题前缀：

```
原始 chunk:  "Alice Chen 是 Acme 的 CEO，负责公司整体战略..."
embedding 输入: "<context>Alice Chen\n</context>\nAlice Chen 是 Acme 的 CEO，负责公司整体战略..."
```

**这意味着：**
- `title:` frontmatter 的质量直接影响**每个 chunk** 的召回率
- title 应该精炼、信息密集、包含页面的核心实体名
- 不要在 title 中放装饰性文字

### 8.4 代码围栏的特殊处理

带有已知语言标签的 fenced code block 会被提取为**独立的代码 chunk**（`chunk_source='fenced_code'`），使用对应语言的 tree-sitter 语法进行代码感知切分。代码 chunk **不参与上下文增强检索**（不加标题前缀）。

这意味着 markdown 文档中的代码示例不会稀释正文的语义搜索质量。

识别语言标签超过 30 种：`ts`, `python`, `go`, `rust`, `java`, `sh`, `bash`, `sql`, `json`, `yaml` 等。

---

## 9. 内容质量门禁

gbrain 在每次导入时运行内容质量评估（`assessContentSanity`），基于以下维度：

| 维度         | 阈值                      | 行为                                                       |
| ------------ | ------------------------- | ---------------------------------------------------------- |
| 文件大小警告 | 可配置 `bytes_warn`       | 超过警告阈值时发出提示                                     |
| 文件大小阻塞 | 可配置 `bytes_block`      | 超过阻塞阈值时**跳过 embedding**（`embed_skip`）           |
| Markup 比率  | 可配置 `max_markup_ratio` | HTML/XML 标签占比过高时标记 `content_flag`                 |
| 垃圾模式     | 内置模式库                | 匹配 CAPTCHA/Cloudflare/垃圾内容时**隔离**（`quarantine`） |
| 操作员字面量 | 自定义                    | 匹配自定义模式时隔离                                       |

**对写作者的启示：**
- 单个 .md 文件不要过大（建议 < 100KB）
- 避免大量 HTML/XML 标签混入 markdown
- 纯 markdown 格式通过率最高

---

## 10. 完整检查清单

### Frontmatter

- [ ] `title:` 已填写，精炼且包含核心实体名
- [ ] `type:` 已填写（推荐），或文件路径在正确的目录下
- [ ] `tags:` 已填写相关标签
- [ ] `aliases:` 已覆盖常见别名、缩写、同义词
- [ ] 如有实体关系，关系字段（`company`, `key_people`, `investors` 等）已填写
- [ ] 日期字段（`date`, `event_date`, `published`）已正确设置

### 正文

- [ ] 每段第一句是核心结论
- [ ] 不存在跨段落代词指代（他/她/它/该公司/其）
- [ ] 每段可在脱离上下文的情况下独立理解（自包含 ~200 字）
- [ ] 不同主题用空行 `\n\n` 分隔
- [ ] 使用 `##` / `###` 标题组织层级
- [ ] 关键实体首次出现时使用 `[[dir/slug]]` 链接

### 时间线

- [ ] 使用 `<!-- timeline -->` 分隔线（如有时）
- [ ] 核心结论**同时**出现在正文，而非仅时间线
- [ ] 格式正确：`- **YYYY-MM-DD** — 描述`

### 围栏

- [ ] Facts/Takes 围栏的 HTML 标记正确（`<!--- gbrain:xxx:begin -->` / `<!--- gbrain:xxx:end -->`）
- [ ] 表格列数和列名与规范一致
- [ ] 行号从 1 开始递增
- [ ] 过期行用 `~~...~~` 包裹

### 分块友好度

- [ ] 没有超过 200 字且无段落分隔的长文本块
- [ ] 每个段落开头能独立回答问题
- [ ] 没有依赖前文才能理解的代词引用
- [ ] 关键概念的全称和简称都在正文中出现

---

*本规范基于 gbrain v0.42.x 的实际实现编写。分块器版本 `MARKDOWN_CHUNKER_VERSION=3`。*
