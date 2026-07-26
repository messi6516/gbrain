---
title: GBrain Markdown 编写模板
type: guide
tags: [guide, template, gbrain]
aliases:
  - gbrain 模板
  - gbrain writing template
  - llm wiki 模板
---

# GBrain Markdown 编写模板

本模板基于 [GBrain Markdown 编写最佳实践](./gbrain-markdown-best-practices.md)，覆盖常见页面类型的编写范式。每个模板都是可直接复制修改的**自包含示例**。

> **LLM 指令：** 在为用户创建新的 gbrain 页面时，从以下模板中选择最匹配的一个，替换占位符（`{{...}}`），然后删除本提示块。

---

## 模板 1：概念/知识页 (concept)

用于技术概念、理论知识、百科条目。

```markdown
---
title: {{概念名称}}
type: concept
tags: [{{标签1}}, {{标签2}}]
aliases:
  - {{别名1}}
  - {{别名2}}
---

# {{概念名称}}

{{概念名称}} 是一种 {{一句话定义}}。它由 {{提出者/创始组织}} 在 {{YYYY}} 年提出，核心思想是 {{核心思想的一句话总结}}。

{{概念名称}} 的主要特点包括：{{特点1}}、{{特点2}} 和 {{特点3}}。它与 [[concepts/{{相关概念}}]] 密切相关，但区别在于 {{关键区别}}。

## 工作原理

{{概念名称}} 的工作流程分为 {{N}} 个阶段。

第一阶段是 {{阶段1名称}}。在这个阶段，系统会 {{阶段1的描述}}。输入的数据经过 {{处理方式}} 后进入下一阶段。

第二阶段是 {{阶段2名称}}。{{阶段2的描述}}，最终产出 {{输出物}}。

## 应用场景

{{概念名称}} 在 {{领域1}} 中有广泛应用。例如 {{具体案例1}}，通过使用 {{概念名称}} 实现了 {{效果}}。

在 {{领域2}} 中，{{概念名称}} 被用于 {{具体案例2}}，解决了 {{问题}}。

## 与其他概念的关系

{{概念名称}} 是 [[concepts/{{父概念}}]] 的一个实现。它借鉴了 [[concepts/{{相关概念A}}]] 的 {{借鉴点A}}，并与 [[concepts/{{相关概念B}}]] 互补——前者侧重 {{侧重A}}，后者侧重 {{侧重B}}。

## 参考资料

- [Source: {{来源名称}}, {{YYYY-MM-DD}}] {{来源描述}}
- [Source: {{来源名称2}}, {{YYYY-MM-DD}}] {{来源描述2}}

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | {{概念名称}} 由 {{提出者}} 在 {{YYYY}} 年提出 | fact | 1.0 | world | high | {{YYYY}}-01-01 | | {{来源}} | |
<!--- gbrain:facts:end -->
```

---

## 模板 2：人物页 (person)

用于人物档案、联系人信息。

```markdown
---
title: {{人物全名}}
type: person
tags: [{{角色标签1}}, {{角色标签2}}]
aliases:
  - {{常用名/昵称}}
company: {{当前公司}}
---

# {{人物全名}}

{{人物全名}} 是 [[companies/{{公司slug}}|{{当前公司}}]] 的 {{职位}}。{{一句话描述其角色或成就}}。

{{人物全名}} 在 {{YYYY}} 年加入 {{当前公司}}，负责 {{职责范围}}。在此之前，{{简称}} 曾在 {{前公司}} 担任 {{前职位}}。

{{简称}} 拥有 {{教育背景}}。{{简称}} 在 {{专业领域}} 领域有 {{N}} 年以上经验。

## 投资与顾问

{{简称}} 投资了 [[companies/{{被投公司1}}]] 和 [[companies/{{被投公司2}}]]。{{简称}} 也是 [[companies/{{顾问公司}}]] 的顾问。

## 联系方式

- Email: {{邮箱}}
- 偏好沟通方式：{{async/sync}}

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | {{职位}} at {{当前公司}} | fact | 1.0 | world | high | {{YYYY-MM-DD}} | | linkedin | |
| 2 | Previously {{前职位}} at {{前公司}} | fact | 1.0 | world | medium | | | linkedin | |
| 3 | Prefers {{偏好}} communication | preference | 0.8 | private | medium | | | direct observation | |
<!--- gbrain:facts:end -->

<!-- timeline -->

- **{{YYYY-MM-DD}}** — 加入 {{当前公司}} 担任 {{职位}}
- **{{YYYY-MM-DD}}** — {{重要事件2}}
- **{{YYYY-MM-DD}}** — {{重要事件3}}
```

---

## 模板 3：公司/组织页 (company)

用于公司、产品、组织。

```markdown
---
title: {{公司全名}}
type: company
tags: [{{行业标签}}, {{阶段标签}}]
aliases:
  - {{简称}}
  - {{英文名}}
key_people: [{{创始人1}}, {{创始人2}}]
investors: [{{投资方1}}, {{投资方2}}]
---

# {{公司全名}}

{{公司全名}} 是一家 {{一句话定义}}，{{YYYY}} 年由 [[people/{{创始人slug}}|{{创始人名}}]] 在 {{城市}} 创立。公司的核心产品是 {{产品的一句话描述}}。

{{公司全名}} 在 {{YYYY-MM}} 完成了 {{金额}} 的 {{轮次}} 融资，由 [[companies/{{领投方slug}}|{{领投方}}]] 领投{{#if 跟投方}}，{{跟投方}} 跟投{{/if}}。截至 {{YYYY-MM}}，公司团队 {{N}} 人。

## 产品

{{产品名}} 是一个 {{产品类型}}，核心功能是 {{功能描述}}。主要客户包括 {{客户类型1}} 和 {{客户类型2}}。

## 团队

[[people/{{创始人slug}}|{{创始人名}}]] 是 CEO，负责整体战略和融资。

[[people/{{CTO slug}}|{{CTO 名}}]] 是 CTO，{{YYYY}} 年加入，负责工程团队。

## 市场与竞争

{{公司全名}} 在 {{市场规模}} 的市场中竞争。主要竞品包括 [[companies/{{竞品1}}]] 和 [[companies/{{竞品2}}]]。差异化在于 {{差异点}}。

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | {{一句话描述主营业务}} | fact | 1.0 | world | high | {{YYYY-MM-DD}} | | website | |
| 2 | {{金额}} {{轮次}}融资 | fact | 1.0 | world | high | {{YYYY-MM-DD}} | | press release | |
| 3 | 团队 {{N}} 人 | fact | 0.9 | world | medium | {{YYYY-MM-DD}} | | {{创始人名}} | |
<!--- gbrain:facts:end -->

<!-- timeline -->

- **{{YYYY-MM-DD}}** — {{金额}} {{轮次}}融资 close，{{领投方}} 领投
- **{{YYYY-MM-DD}}** — {{重要事件2}}
- **{{YYYY-MM-DD}}** — {{创始人}} 在 {{城市}} 创立 {{公司全名}}
```

---

## 模板 4：会议记录 (meeting)

用于 1:1、团队会议、董事会等。

```markdown
---
title: {{YYYY-MM-DD}} {{会议主题}}
type: meeting
tags: [meeting, {{主题标签}}]
aliases:
  - {{日期}} {{简称}}
attendees: [{{参会人1}}, {{参会人2}}]
event_date: {{YYYY-MM-DD}}
---

# {{会议主题}}

{{YYYY}} 年 {{MM}} 月 {{DD}} 日与 {{参会人}} 的 {{会议类型}}。

## 要点总结

{{要点1}}。{{一句话提炼的核心信息}}。

{{要点2}}。{{一句话提炼的核心信息}}。

{{要点3}}。{{一句话提炼的核心信息}}。

## 讨论详情

### {{议题1}}

{{详细讨论内容。每段自包含，~150 字。}}

[[people/{{发言人}}]] 提议 {{建议内容}}。

### {{议题2}}

{{详细讨论内容。}}

## 行动项

- [ ] {{负责人}}：{{任务描述}}，DDL {{YYYY-MM-DD}}
- [ ] {{负责人}}：{{任务描述}}，DDL {{YYYY-MM-DD}}

## 下次会议

- 时间：{{YYYY-MM-DD HH:MM}}
- 议题：{{计划讨论的议题}}

<!-- timeline -->

- **{{YYYY-MM-DD}}** — {{会议开始}}
- **{{YYYY-MM-DD}}** — {{关键节点}}
```

---

## 模板 5：融资/交易记录 (deal)

用于投资轮次、交易记录。

```markdown
---
title: {{公司名}} {{轮次}} 融资
type: deal
tags: [funding, {{轮次标签}}, {{年份}}]
aliases:
  - {{公司名}} {{轮次}}
investors: [{{投资方1}}, {{投资方2}}]
lead: {{领投方}}
event_date: {{YYYY-MM-DD}}
---

# {{公司名}} {{轮次}} 融资

{{公司名}} 在 {{YYYY}} 年 {{MM}} 月完成了 {{金额}} 的 {{轮次}} 融资。本轮由 [[companies/{{领投方slug}}|{{领投方}}]] 领投，{{跟投方列表}} 跟投。

融资资金将用于 {{用途1}}、{{用途2}} 和 {{用途3}}。公司在 {{YYYY}} 年 {{MM}} 启动本轮融资，{{YYYY}} 年 {{MM}} close。

## 投资方

[[companies/{{领投方slug}}|{{领投方}}]] 是领投方。{{领投方简介}}。

[[companies/{{跟投方slug}}|{{跟投方}}]] 参与了本轮。{{跟投方简介}}。

## 公司状态（融资时）

截至融资时，{{公司名}} 的 ARR 为 {{ARR}}，团队 {{N}} 人，主要客户包括 {{客户类型}}。

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | {{公司名}} {{轮次}} {{金额}} | fact | 1.0 | world | high | {{YYYY-MM-DD}} | | term sheet | |
| 2 | {{领投方}} 领投 | fact | 1.0 | world | high | {{YYYY-MM-DD}} | | term sheet | |
<!--- gbrain:facts:end -->

<!-- timeline -->

- **{{YYYY-MM-DD}}** — {{金额}} wire transfer 到账
- **{{YYYY-MM-DD}}** — 签署最终文件
- **{{YYYY-MM-DD}}** — Term sheet 签署
- **{{YYYY-MM-DD}}** — 开始与 {{领投方}} 接触
```

---

## 模板 6：项目页 (project)

用于开源项目、内部项目、工作流。

```markdown
---
title: {{项目名}}
type: project
tags: [{{技术栈标签}}, {{领域标签}}]
aliases:
  - {{缩写}}
  - {{项目代号}}
---

# {{项目名}}

{{项目名}} 是一个 {{一句话定义}}。项目的目标是 {{目标的一句话描述}}。

{{项目名}} 由 [[people/{{负责人slug}}|{{负责人}}]] 在 {{YYYY}} 年发起。当前状态是 {{状态}}。

## 技术架构

{{项目名}} 使用 {{技术栈}} 构建。核心组件包括：

{{组件A}} 负责 {{职责A}}。{{一句话描述如何工作}}。

{{组件B}} 负责 {{职责B}}。{{一句话描述如何工作}}。

## 当前进展

截至 {{YYYY-MM}}，{{项目名}} 已完成 {{里程碑描述}}。下一步计划是 {{下一步计划}}。

## 相关资源

- 代码仓库：{{repo URL}}
- 相关文档：[[concepts/{{相关概念}}]]、[[projects/{{相关项目}}]]

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | {{项目名}} 由 {{负责人}} 发起 | fact | 1.0 | world | high | {{YYYY-MM-DD}} | | | |
| 2 | 技术栈 {{技术栈}} | fact | 1.0 | world | medium | {{YYYY-MM-DD}} | | repo | |
<!--- gbrain:facts:end -->

<!-- timeline -->

- **{{YYYY-MM-DD}}** — {{里程碑3}}
- **{{YYYY-MM-DD}}** — {{里程碑2}}
- **{{YYYY-MM-DD}}** — {{里程碑1}}（项目启动）
```

---

## 模板 7：通用笔记 (note)

当以上类型都不适用时使用。

```markdown
---
title: {{笔记标题}}
type: note
tags: [{{标签1}}, {{标签2}}]
aliases:
  - {{别名}}
date: {{YYYY-MM-DD}}
---

# {{笔记标题}}

{{核心结论的一句话}}。

{{支撑细节段落。每段 ~150 字，自包含。}}

{{第二段。不同主题用空行分隔。}}

## {{子主题1}}

{{子主题1的内容。关键实体用 [[wikilink]] 链接。}}

## {{子主题2}}

{{子主题2的内容。}}

## Facts

<!--- gbrain:facts:begin -->
| # | claim | kind | confidence | visibility | notability | valid_from | valid_until | source | context |
|---|-------|------|------------|------------|------------|------------|-------------|--------|---------|
| 1 | {{事实}} | fact | 1.0 | world | high | {{YYYY-MM-DD}} | | {{来源}} | |
<!--- gbrain:facts:end -->
```

---

## 模板 8：写作/文章 (writing)

用于原创文章、博客、草稿。

```markdown
---
title: {{文章标题}}
type: writing
tags: [{{主题标签}}]
aliases:
  - {{简称}}
published: {{YYYY-MM-DD}}
---

# {{文章标题}}

{{一句话论点/核心观点}}。

## 背景

{{为什么写这篇文章。背景信息，~150 字。}}

## 论点展开

### {{论点1}}

{{论点1的阐述。每段首句是子结论。}}

### {{论点2}}

{{论点2的阐述。}}

## 结论

{{总结性的结论段落。}}

## 参考资料

- [Source: {{来源}}, {{YYYY-MM-DD}}] {{来源中的重要数据或观点}}
- [Source: {{来源2}}, {{YYYY-MM-DD}}] {{来源中的重要数据或观点}}
```

---

## 通用写作守则

无论使用哪个模板，以下规则**始终适用**：

### 段落构造

```markdown
## ✅ 正确
Alice Chen 是 Acme 的 CEO，2021 年加入，负责公司整体战略和融资。她此前在 Google 担任 AI 研究员。

Acme 是一家企业 AI 公司，主要产品是客服机器人。2024 年收入达 500 万美元。

## ❌ 错误（多主题挤在一段 + 代词跨段）
Alice Chen 是 Acme 的 CEO，2021 年加入，负责公司战略和融资，她此前在 Google
担任 AI 研究员。Acme 是一家企业 AI 公司，主要产品是客服机器人，2024 年收入
达 500 万美元。后来 Bob 也加入了公司做 CTO，直接向她汇报。
```

### 链接使用

```markdown
## ✅ 正确
Alice Chen 是 [[companies/acme|Acme Inc]] 的 CEO。她在 2021 年创立了这家公司。

Fund-A 领投了 Acme 的 A 轮，[[people/bob-wang|Bob Wang]] 也参与了本轮。

## ❌ 避免
Alice Chen 是 Acme Inc 的 CEO。
（没有 wikilink，图边不会被创建）
```

### 时间线位置

```markdown
## ✅ 正确（结论在正文，流水在时间线）

（正文）Acme 在 2024 年 12 月完成 500 万美金融资，由 Fund-A 领投。

<!-- timeline -->

- **2024-12-15** — wire transfer 到账
- **2024-11-01** — 签署 term sheet

## ❌ 错误（结论只在时间线）

<!-- timeline -->

- **2024-12** — Acme 完成 500 万美金融资，由 Fund-A 领投
```

---

*本模板集基于 [GBrain Markdown 编写最佳实践](./gbrain-markdown-best-practices.md)。所有模板本身也是符合 gbrain 规范的 markdown 文件。*
