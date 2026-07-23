# gbrain CLI 能力全集

> 基于 gbrain v0.42.63.0 的完整 CLI 参考，整理自 `src/commands/*.ts` 共 126 个命令文件 + `src/core/operations.ts` 的 64+ 操作定义。
> 为构建 gbrain 技能套件（Knowledge Management Skill System）提供基础资料。

---

## 目录

1. [架构概要](#架构概要)
2. [安装配置](#1-安装配置)
3. [页面 CRUD](#2-页面-crud)
4. [搜索与检索](#3-搜索与检索)
5. [内容摄入](#4-内容摄入)
6. [链接与图谱](#5-链接与图谱)
7. [标签系统](#6-标签系统)
8. [时间线](#7-时间线)
9. [文件管理](#8-文件管理)
10. [嵌入管理](#9-嵌入管理)
11. [多源管理](#10-多源管理)
12. [代码索引](#11-代码索引)
13. [知识操作](#12-知识操作-takes-推理)
14. [大脑维护周期](#13-大脑维护周期-dream--autopilot)
15. [健康与诊断](#14-健康与诊断)
16. [运维命令](#15-运维命令)
17. [评估系统](#16-评估系统)
18. [思维与洞察](#17-思维与洞察)
19. [架构数据与管理](#18-架构数据与管理)
20. [Schema 包系统](#19-schema-包系统)
21. [信号与异常检测](#20-信号与异常检测)
22. [集成与配方系统](#21-集成与配方系统)
23. [大脑引导与修复](#22-大脑引导与修复)
24. [MCP 服务器](#23-mcp-服务器)
25. [技能系统](#24-技能系统)
26. [命令行别名与简写](#25-命令行别名与简写)

---

## 架构概要

### 核心组织轴

gbrain 沿两个正交轴组织知识：

| 轴 | 含义 | 路由方式 |
|---|---|---|
| **Brain（大脑）** | 哪个数据库 | `--brain`, `GBRAIN_BRAIN_ID`, `.gbrain-mount` 点文件 |
| **Source（源）** | 数据库内的哪个仓库 | `--source`, `GBRAIN_SOURCE`, `.gbrain-source` 点文件 |

### 信任边界

- `OperationContext.remote = false` — 通过 `src/cli.ts` 设置的**受信任本地 CLI** 调用者
- `OperationContext.remote = true` — 通过 `src/mcp/server.ts` 设置的**不受信任的 Agent 调用者**
- 安全敏感操作（如 `file_upload`）在 `remote = true` 时加强文件系统限制

### 操作层（Operations Layer）

`src/core/operations.ts`（~5400 行）定义了 **~64+ CLI 操作 + 更多 MCP 操作**，CLI 和 MCP 服务器均从这一单一来源生成。

---

## 1. 安装配置

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain init` | 创建大脑（默认 PGLite，零配置） | `--pglite`, `--supabase`, `--url` |
| `gbrain reinit-pglite` | 重新初始化 PGLite 引擎（**破坏性操作**，有警告） | - |
| `gbrain config show` | 查看大脑配置 | `[key]` |
| `gbrain config get <key>` | 获取配置项 | - |
| `gbrain config set <key> <val>` | 设置配置项 | - |
| `gbrain migrate --to <supabase\|pglite>` | 迁移大脑存储引擎 | - |
| `gbrain providers` | LLM 提供商配置 | - |
| `gbrain auth` | 认证管理 | - |

---

## 2. 页面 CRUD

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain get <slug>` | 读取页面内容 | - |
| `gbrain put <slug>` | 写入/更新页面（支持 stdin 输入） | `< file.md` |
| `gbrain delete <slug>` | 删除页面（软删除） | - |
| `gbrain restore <slug>` | 恢复已软删除的页面 | - |
| `gbrain list` | 列出页面 | `--type T`, `--tag T`, `-n N` |
| `gbrain history <slug>` | 页面版本历史 | - |
| `gbrain revert <slug> <version-id>` | 回滚到指定版本 | - |
| `gbrain pages purge-deleted` | 永久清除已删除页面 | `--older-than H`, `--dry-run` |

**核心操作（operations.ts）：** `get_page`, `put_page`, `delete_page`, `restore_page`, `list_pages`, `purge_deleted_pages`

---

## 3. 搜索与检索

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain search <query>` | 关键词全文搜索（tsvector） | - |
| `gbrain query <question>` | 混合搜索（RRF + 扩展） | `--no-expand`, `--lang L`, `--symbol-kind K` |
| `gbrain ask <question>` | `query` 的别名（自然语言别名） | `--no-expand` |
| `gbrain search modes` | 搜索模式仪表盘（只读配置） | - |
| `gbrain search stats` | 搜索统计 | - |
| `gbrain search tune` | 搜索调优 | - |
| `gbrain search diagnose` | 搜索诊断（运行实际检索） | - |
| `gbrain search-by-image` | 图片搜索 | - |
| `gbrain query --lang <l>` | 过滤混合搜索到特定编程语言 | - |
| `gbrain query --symbol-kind <k>` | 筛选到符号类型（函数/类/方法等） | - |

**搜索模式：** `gbrain init` 会应用默认搜索模式但打印 9 格成本矩阵（模式 × 下游模型），成本跨度高达 25 倍。
Agent 必须在继续之前向操作者确认搜索模式选择（参见 `INSTALL_FOR_AGENTS.md` Step 3.5）。

**核心操作（operations.ts）：** `search`, `query`

---

## 4. 内容摄入

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain capture <content>` | **主要的人机摄入入口点** | `--file`, `--stdin`, `--slug`, `--type`, `--quiet`, `--json` |
| `gbrain capture --file <path>` | 从文件摄入 | `--who`, `--what`, `--where`, `--kind`, `--depth` |
| `gbrain capture --stdin` | 从标准输入摄入 | - |
| `gbrain import <dir>` | 导入 Markdown 目录 | `--no-embed` |
| `gbrain sync` | Git 到大脑的增量同步 | `--repo`, `--strategy code`, `--all`, `--source` |
| `gbrain sync --watch` | 持续同步（循环直到停止） | `--interval N` |
| `gbrain sync --strategy code` | 同步代码文件到大脑 | - |
| `gbrain export` | 导出为 Markdown | `--dir`, `--restore-only`, `--type`, `--slug-prefix` |
| `gbrain export --restore-only` | 恢复 Supabase-only 文件 | `--repo`, `--type`, `--slug-prefix` |
| `gbrain extract` | 从内容提取链接/时间线（确定性） | - |
| `gbrain extract links` | 提取链接 | `--source fs\|db`, `--dir`, `--dry-run`, `--json`, `--type T`, `--since DATE` |
| `gbrain extract timeline` | 提取时间线条目 | 同上 |
| `gbrain extract all` | 提取所有 | 同上 |
| `gbrain extract-conversation-facts` | 从对话文本提取结构化事实 | 详细 HELP 支持 |
| `gbrain enrich` | 丰富页面内容（LLM 增强） | 有成本提示，支持 `--reenrich-after` |

**capture 命令** 是 gbrain v0.37/v0.38 的人机摄入入口点：
- 默认 slug 为 `inbox/YYYY-MM-DD-<sha8-of-content>`
- 输出 5 行回执（slug, ingested_at, source_kind, content_hash, queue job id）
- `--quiet` 仅输出 slug（适合管道）
- `--json` 输出结构化 JSON（适合 Agent）
- 支持 Life Chronicle 事件（`--type event`, `--who`, `--what`, `--where`, `--kind`）

**核心操作（operations.ts）：** `put_page`, `sync` (hidden)

---

## 5. 链接与图谱

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain link <from> <to>` | 创建类型化链接（别名：`link-add`） | `--link-type T`, `--link-source S` |
| `gbrain unlink <from> <to>` | 移除链接（别名：`link-rm`） | `--link-type T`, `--link-source S` |
| `gbrain link-sources` | 列出已使用的来源来源及其边计数 | - |
| `gbrain backlinks <slug>` | 查看指向某页面的入站链接列表 | - |
| `gbrain graph <slug>` | 遍历链接图（返回节点） | `--depth N` |
| `gbrain graph-query <slug>` | 带类型/方向过滤的边遍历 | `--type T`, `--depth N`, `--direction in\|out\|both` |
| `gbrain reconcile-links` | 批量重算文档↔实现边 | `--dry-run` |

**核心操作（operations.ts）：** `link`, `unlink`, `link_sources`, `backlinks`, `graph`, `traverse_graph`

---

## 6. 标签系统

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain tags <slug>` | 查看页面标签 | - |
| `gbrain tag <slug> <tag>` | 添加标签 | - |
| `gbrain untag <slug> <tag>` | 移除标签 | - |

**核心操作（operations.ts）：** `tag`, `untag`, `tags`

---

## 7. 时间线

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain timeline [<slug>]` | 查看时间线 | - |
| `gbrain timeline-add <slug> <date> <text>` | 添加时间线条目 | - |

**核心操作（operations.ts）：** `timeline`, `timeline_add`

---

## 8. 文件管理

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain files list [slug]` | 列出存储的文件 | - |
| `gbrain files upload <file>` | 上传文件到存储 | `--page <slug>` |
| `gbrain files upload-raw <file>` | 智能上传（大小路由 + `.redirect.yaml`） | `--page <slug>` |
| `gbrain files signed-url <path>` | 生成有效期 1 小时的签名 URL | - |
| `gbrain files sync <dir>` | 批量上传目录 | - |
| `gbrain files verify` | 验证所有上传 | - |
| `gbrain files mirror` | 镜像文件 | - |
| `gbrain files unmirror` | 取消镜像 | - |
| `gbrain files redirect` | 重定向 | - |
| `gbrain files restore` | 恢复文件 | - |
| `gbrain files clean` | 清理文件 | - |

**核心操作（operations.ts）：** 文件操作通过 CLI-only `files` 命令处理

---

## 9. 嵌入管理

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain embed [<slug>]` | 为特定页面生成/刷新嵌入 | - |
| `gbrain embed --all` | 嵌入所有页面（每个分块） | - |
| `gbrain embed --stale` | 仅嵌入过期的（缺少嵌入的）分块 | - |
| `gbrain embed --stale --catch-up` | 连续模式，循环直到所有过期分块被嵌入 | - |
| `gbrain embed --dry-run` | 预览而不实际调用嵌入模型 | - |
| `gbrain embed --priority recent` | 按最近修改顺序优先处理 | - |
| `gbrain embed --batch-size N` | 覆盖默认批量大小（默认 2000，上限 10K） | - |
| `gbrain embed --source-id <id>` | 限定到特定源 | - |

---

## 10. 多源管理

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain sources list` | 查看已注册的源 | `--json` |
| `gbrain sources add <id> --path <p>` | 注册一个源（id 为短名称，如 'wiki'） | `--federated\|--no-federated` |
| `gbrain sources remove <id>` | 移除源及其页面 | `--yes`, `--dry-run`, `--keep-storage` |
| `gbrain sources rename <id> <new-name>` | 重命名源 | - |
| `gbrain sources default <id>` | 设置默认源 | - |
| `gbrain sources attach <id>` | 写入 `.gbrain-source` 到当前工作目录 | - |
| `gbrain sources detach` | 从当前工作目录移除 `.gbrain-source` | - |
| `gbrain sources federate <id>` | 设置源为联邦模式 | - |
| `gbrain sources unfederate <id>` | 取消联邦模式 | - |
| `gbrain sources archive <id>` | 软删除：从搜索中隐藏，72 小时可恢复 | - |
| `gbrain sources restore <id>` | 恢复软删除的源 | - |
| `gbrain sources archived` | 列出软删除的源及其清除到期时间 | - |
| `gbrain sources purge [<id>]` | 永久删除已归档的源 | - |
| `gbrain sources status` | 每个源的仪表盘（同步延迟、嵌入覆盖率） | - |
| `gbrain sources pull --path <dir>` | 拉取源内容（DB 外路径，如 `harden` 定时任务用） | - |
| `gbrain sync --all` | 同步所有有本地路径的源 | - |
| `gbrain sync --source <id>` | 同步特定源 | - |

`repos ...` 是 `sources` 的已弃用别名（v0.19.0 前）

---

## 11. 代码索引

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain code-def <symbol>` | 跨代码页面查找符号的定义 | `--lang l` |
| `gbrain code-refs <symbol>` | 查找符号的所有引用（JSON 优先） | `--lang l` |
| `gbrain code-callers <symbol>` | 谁调用这个符号？ | - |
| `gbrain code-callees <symbol>` | 这个符号调用了什么？ | - |
| `gbrain reconcile-links` | 批量重算文档↔实现边 | `--dry-run` |
| `gbrain reindex-code` | 显式代码页面重索引 | `--source id`, `--yes`, `--dry-run`, `--json`, `--force` |
| `gbrain reindex-search-vector` | 重建全文搜索触发器和回填 | `--dry-run`, `--yes`, `--json` |
| `gbrain reindex --markdown` | 重新摄入过期的 Markdown 分块 | `--limit`, `--dry-run` |
| `gbrain reindex-frontmatter` | 重建 `pages.effective_date` | `--slug-prefix P`, `--source`, `--yes`, `--dry-run` |
| `gbrain reindex-aliases` | 别名索引重建 | - |
| `gbrain reindex-multimodal` | 多模态索引重建 | - |

**核心操作（operations.ts，隐藏的）：** `code_callers`, `code_callees`, `code_def`, `code_refs`, `code_blast`, `code_flow`, `code_traversal_cache_clear`

---

## 12. 知识操作（Takes 推理）

Takes 系统是 gbrain 的**结构化知识推理层**，支持事实声明、观点（take）、预测（bet）和直觉（hunch）。

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain takes <slug>` | 查看页面的 takes 列表 | - |
| `gbrain takes search "<query>"` | 跨所有 takes 进行关键词搜索 | `--who <slug>` |
| `gbrain takes add <slug>` | 追加一个 take（MD + DB 写入） | `--kind fact\|take\|bet\|hunch`, `--content`, `--weight N`, `--source`, `--author`, `--outcome` |
| `gbrain takes update <slug>` | 更新可变字段 | `--row N`, `--content`, `--weight`, `--source` |
| `gbrain takes supersede <slug>` | 划掉旧 take 并追加新的 | `--row N`, `--kind`, `--content`, `--weight`, `--source` |
| `gbrain takes resolve <slug>` | 解析一个 take | `--row N`, `--outcome true\|false`, `--value N`, `--unit u` |
| `gbrain takes-list` | 列出所有 takes | - |
| `gbrain takes-scorecard` | Takes 记分卡 | - |
| `gbrain takes-calibration` | Takes 校准分析 | - |

**核心操作（operations.ts）：** `takes_list`, `takes_search`, `takes_scorecard`, `takes_calibration`

---

## 13. 大脑维护周期（Dream + Autopilot）

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain dream` | **手动运行一次大脑维护周期**（6 阶段：sync→extract→embed→synthesize→patterns→consolidate） | `--json`, `--dry-run`, `--phase P`, `--pull`, `--drain`, `--window N`, `--source <id>` |
| `gbrain dream --phase lint` | 仅运行 lint 阶段 | - |
| `gbrain dream --json` | JSON 报告格式（适合 cron） | - |
| `gbrain autopilot` | **自维护大脑守护进程** | `--repo`, `--interval N`, `--json`, `--inline` |
| `gbrain autopilot --install` | 安装 autopilot 定时任务 | - |
| `gbrain autopilot --uninstall` | 卸载 autopilot | - |
| `gbrain autopilot --status` | 查看 autopilot 运行状态 | `--json` |

**Dream 阶段：** sync → extract → embed → synthesize → patterns → consolidate（v0.36.4.0 起）
- 三个阶段受保护（synthesize / patterns / consolidate）：仅受信任的本地调用者可提交；MCP 不可。
- `--drain` 模式下循环处理积压直到清空或超时

---

## 14. 健康与诊断

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain doctor` | 全面的健康检查（解析器、技能、pgvector、RLS、嵌入） | `--json`, `--fast` |
| `gbrain doctor --fix` | 尝试自动修复发现的问题 | - |
| `gbrain doctor --remediation-plan --json` | 预览修复计划 | - |
| `gbrain doctor --remediate --yes --target-score 90 --max-usd 5` | 按依赖顺序执行修复计划，每步后重检分数 | - |
| `gbrain health` | 大脑健康仪表盘 | - |
| `gbrain status` | 单屏幕健康仪表盘（6 个板块） | `--json`, `--section sync\|cycle\|locks\|workers\|queue\|autopilot` |
| `gbrain stats` | 大脑统计信息 | - |
| `gbrain integrity check` | 完整性扫描报告（链接腐烂等） | - |
| `gbrain integrity auto` | 三桶置信度自动修复 | `--dry-run` |
| `gbrain lint <dir\|file>` | 大脑页面质量检查（确定性） | `--fix`, `--dry-run` |
| `gbrain orphans` | 查找没有入站链接的页面 | `--json`, `--count`, `--include-pseudo` |
| `gbrain check-resolvable` | 验证技能树（可达性/MECE/DRY） | `--json`, `--fix` |
| `gbrain features` | 扫描用法并推荐未使用的功能 | `--json`, `--auto-fix` |

**doctor 命令 v0.36.4.0 起支持目标健康分数：**
- 依赖排序计划：sync 在前，extract 在后，embed 在 consolidate 之后
- 空大脑或未配置的嵌入密钥有 `max_reachable_score` 上限

---

## 15. 运维命令

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain upgrade` | 二进制自更新 + 模式迁移 + 升级后提示 | - |
| `gbrain self-upgrade` | Agent-环境的统一升级入口 | `--check-only`, `--force`, `--json` |
| `gbrain check-update` | 检查新版本 | `--json`, `--refresh-cache` |
| `gbrain apply-migrations` | 仅手动运行模式迁移 | `--yes` |
| `gbrain serve` | MCP stdio 服务器 | - |
| `gbrain serve --http` | HTTP MCP 服务器（含 OAuth 2.1） | `--port`, `--token-ttl`, `--enable-dcr`, `--public-url` |
| `gbrain connect <mcp-url>` | 连接 Claude Code 到远程 gbrain | `--token`, `--install`, `--json` |
| `gbrain watch` | **推式上下文**：管道输入对话轮次，流式输出脑页面 | `--json`, `--window-turns N`, `--max-pages N`, `--min-confidence X` |
| `gbrain call <tool> '<json>'` | 原始工具调用（不经过 CLI 包装） | - |
| `gbrain version` | 版本信息 | - |
| `gbrain --tools-json` | 工具发现（JSON） | - |
| `gbrain config` | 大脑配置管理 | `show\|get\|set <key> [val]` |
| `gbrain cache` | 缓存管理 | - |
| `gbrain storage status` | 存储层级状态和健康 | `--json`, `--repo` |

---

## 16. 评估系统

gbrain 拥有完善的评测系统，用于衡量检索、推理和知识质量。

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain eval` | 评测入口 | - |
| `gbrain eval run-all` | 运行所有评测 | - |
| `gbrain eval compare` | 比较评测结果 | - |
| `gbrain eval export --since 7d` | 导出捕获的查询 | `> base.ndjson` |
| `gbrain eval replay --against base.ndjson` | 回放查询进行比较 | - |
| `gbrain eval longmemeval <dataset.jsonl>` | 长期记忆评估（隔离的 PGLite） | - |
| `gbrain eval retrieval-quality` | 检索质量评测 | - |
| `gbrain eval trajectory <entity-slug>` | 评估实体的轨迹（指标时序） | - |
| `gbrain eval conversation-parser` | 对话解析评测 | - |
| `gbrain eval cross-modal` | 跨模态评测 | - |
| `gbrain eval brainstorm` | 头脑风暴评测 | - |
| `gbrain eval chronicle` | 编年史评测 | - |
| `gbrain eval code-retrieval` | 代码检索评测 | - |
| `gbrain eval suspected-contradictions` | 矛盾检测评测 | - |
| `gbrain eval synthesize-concepts` | 概念合成评测 | - |
| `gbrain eval extract-atoms` | 原子提取评测 | - |
| `gbrain eval takes-quality` | Takes 质量评测 | - |
| `gbrain eval markdown-greenfield` | Markdown 生成评测 | - |
| `gbrain eval schema-authoring` | Schema 创作评测 | - |
| `gbrain eval whoknows` | "谁知道" 评测 | - |
| `gbrain eval gate` | 基线评测门控 | - |
| `gbrain eval prune` | 评测数据裁剪 | - |

**评测方法：** 捕获默认关闭。设置 `GBRAIN_CONTRIBUTOR_MODE=1` 来捕获真实查询进行基准评测。

---

## 17. 思维与洞察

这些是 gbrain 的高级知识操作，结合混合搜索和 LLM 推理。

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain think <question>` | **合成推理**：检索实体子图 → LLM 合成 | `--anchor`, `--rounds N`, `--save`, `--take`, `--model`, `--since`, `--until`, `--json` |
| `gbrain brainstorm <question>` | **创意生成器**：混合搜索 + 远集 + 评判 | `--json`, `--save\|--no-save`, `--limit N` |
| `gbrain lsd <question>` | **横向突触漂移**：反向评判创意生成 | `--json`, `--save\|--no-save`, `--limit N` |
| `gbrain whoknows <topic>` | "关于 X 该找谁？" 专家+关系接近度路由 | `--explain`, `--limit N`, `--json` |
| `gbrain founder scorecard <entity-slug>` | 四位创始人的指标汇总（声明准确性/一致性/增长轨迹/红旗） | `--json`, `--since`, `--until` |

**`think` 命令详情：**
- 需要 `ANTHROPIC_API_KEY` 进行真实合成
- `--save` 持久化合成页到 `synthesis/<slug>-<date>.md`
- `--take` 追加 takes 到锚定页面
- `--with-calibration` 注入活跃校准配置
- 不指定 `--save` 且无 LLM 可用时，采集阶段仍然会打印输入

**`brainstorm` 与 `lsd` 是 v0.37/v0.38 功能：**
- `brainstorm`: 结合混合搜索找到的连接 + 远集（far-set）中的意外联系 + 评判
- `lsd`（Lateral Synaptic Drift）: 反过来，奖励远非显而易见的想法和公理反转

**核心操作（operations.ts）：** `think`, `whoknows`, `find_trajectory`, `find_contradictions`

---

## 18. 架构数据与管理

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain mounts list` | 查看已挂载的大脑 | - |
| `gbrain mounts add` | 添加大脑挂载 | - |
| `gbrain frontmatter validate --fix` | 前置元数据验证与修复 | - |
| `gbrain frontmatter-install-hook` | 安装前置元数据 git hook | - |
| `gbrain check-backlinks <check\|fix>` | 查找/修复缺失的反向链接 | `[dir]` |
| `gbrain repair-jsonb` | 修复 JSONB 数据损坏 | - |
| `gbrain edges-backfill` | 边缘回填 | - |
| `gbrain ze-switch` | 零间接开关 | - |

---

## 19. Schema 包系统

Schema 包**驱动类型推断、链接动词、专家路由、可提取类型、丰富规则和搜索范围**。

| 命令 | 功能 | 关键选项 |
|---|---|---|
| 检查： | | |
| `gbrain schema active` | 查看活跃的 schema 包 | - |
| `gbrain schema list` | 列出所有可用的 schema 包 | - |
| `gbrain schema show <name>` | 显示包的详细信息 | - |
| `gbrain schema validate` | 验证包的一致性 | - |
| `gbrain schema graph` | 可视化包的图谱 | - |
| `gbrain schema lint` | 对包执行 lint 检查 | - |
| `gbrain schema stats` | 包的统计信息 | - |
| `gbrain schema explain` | 解释包的配置 | - |
| `gbrain schema usage` | 显示实际使用情况 | - |
| 激活： | | |
| `gbrain schema use <name>` | 激活一个 schema 包 | - |
| `gbrain schema downgrade` | 降级到上一个版本 | - |
| `gbrain schema reload` | 重新加载当前包 | - |
| 创作： | | |
| `gbrain schema init <name>` | 初始化一个新 schema 包 | - |
| `gbrain schema fork <name>` | 分支现有包 | - |
| `gbrain schema edit <name>` | 编辑包定义 | - |
| `gbrain schema diff <a> <b>` | 比较两个包 | - |
| `gbrain schema add-type` | 添加类型 | - |
| `gbrain schema remove-type` | 移除类型 | - |
| `gbrain schema update-type` | 更新类型 | - |
| `gbrain schema add-alias` | 添加类型别名 | - |
| `gbrain schema remove-alias` | 移除类型别名 | - |
| `gbrain schema add-prefix` | 添加 slug 前缀 | - |
| `gbrain schema remove-prefix` | 移除 slug 前缀 | - |
| `gbrain schema add-link-type` | 添加链接类型 | - |
| `gbrain schema remove-link-type` | 移除链接类型 | - |
| `gbrain schema set-extractable` | 设置类型的可提取性 | - |
| `gbrain schema set-expert-routing` | 设置专家路由配置 | - |
| 发现与修复： | | |
| `gbrain schema detect` | 从现有页面推断类型 | - |
| `gbrain schema suggest` | 提出改进建议 | - |
| `gbrain schema review-candidates` | 审查类型候选 | - |
| `gbrain schema review-orphans` | 审查未归类页面 | - |
| `gbrain schema sync` | 同步包配置到数据库 | - |

---

## 20. 信号与异常检测

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain salience` | **情感 + 活动显著性排名**（0 LLM 调用） | `--days N`, `--limit N`, `--kind PREFIX`, `--json` |
| `gbrain anomalies` | **基于群体的统计异常**（0 LLM 调用） | `--since DATE`, `--sigma N`, `--lookback-days N`, `--json` |
| `gbrain transcripts recent` | 最近的原始 .txt 转录（仅本地） | `--days N` |
| `gbrain on-this-day` | 今日历史回顾 | - |
| `gbrain day <date>` | 查看特定日期的内容 | - |
| `gbrain since <date>` | 查看自某个日期起的内容 | - |
| `gbrain last-seen <entity>` | 实体的最后出现时间 | - |
| `gbrain orient` | 知识定向图 | - |

**`salience` 排名公式（确定性）：**
```
score = emotional_weight × 活跃 takes 数 × 时间衰减
```
- `--kind` 按 slug 前缀过滤（如 `personal`、`wiki/people`）

**`anomalies` 统计方法：**
- 计算每群体×每日的基线（均值、标准差）
- 使用 `generate_series` 零填充，防止稀疏日偏差
- 群体类型：tag、type
- 报告超过 `mean + sigma × stddev` 的群体

**核心操作（operations.ts）：** `salience`, `anomalies`, `on_this_day`, `day`, `since`, `last_seen`

---

## 21. 集成与配方系统

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain integrations` | 集成仪表盘 | - |
| `gbrain integrations list` | 列出可用配方 | - |
| `gbrain integrations show <id>` | 显示配方详情 | - |
| `gbrain integrations status` | 检查秘密 + 心跳 | - |
| `gbrain integrations doctor` | 运行健康检查 | - |
| `gbrain integrations stats` | 聚合心跳 JSONL | - |
| `gbrain integrations test` | 验证配方文件 | - |
| `gbrain integrations install` | 安装配方到宿主 Agent 仓库 | - |

**配方类别：** infra（基础设施）、sense（感知）、reflex（反射）、voice（语音）
- `install_kind`: `local-managed` 或 `copy-into-host-repo`
- 集成存储在 `~/.gbrain/integrations/<id>/heartbeat.jsonl`

---

## 22. 大脑引导与修复

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain onboard` | **大脑引导工具**：计算 + 运行修复计划 | - |
| `gbrain onboard --check` | （默认）预览修复计划 | - |
| `gbrain onboard --auto` | 自动应用修复 | `--max-usd N` |
| `gbrain onboard --auto --yes` | 也提交需要提示的层级 | - |
| `gbrain onboard --history` | 查看最近的迁移影响日志 | - |
| `gbrain onboard --explain` | 用叙述性文字扩展检查结果 | - |
| `gbrain onboard --target-score N` | 设置健康目标分数（默认 90） | - |

---

## 23. MCP 服务器

| 命令 | 功能 | 关键选项 |
|---|---|---|
| `gbrain serve` | MCP stdio 服务器 | - |
| `gbrain serve --http` | HTTP MCP 服务器（Express） | `--port N`, `--token-ttl N` |
| `gbrain serve --http --enable-dcr` | 启用动态客户端注册 | - |
| `gbrain serve --http --enable-dcr-insecure` | 也允许 client_credentials | - |
| `gbrain serve --http --public-url URL` | 反向代理时设置公开 URL | - |
| `gbrain connect <mcp-url>` | 连接 Claude Code 到远程 gbrain | `--token t`, `--install`, `--json` |
| `gbrain call <tool> '<json>'` | 调用 MCP 工具 | - |

**MCP 服务器生成：**
- 工具定义从 `src/core/operations.ts` 自动生成（通过 `tool-defs.ts` 的 `buildToolDefs()`）
- HTTP 服务器包含 OAuth 2.1 授权端点（`/authorize`, `/token`, `/register`, `/revoke`）
- 管理仪表盘在 `/admin`
- SSE 实时活动推送在 `/admin/events`
- 健康检查在 `/health`

---

## 24. 技能系统

gbrain 有一个 **技能（skill）层**——扁平的 Markdown 文件，工具无关，同时适用于 CLI 和插件上下文。

### 技能结构
- 技能目录：`/Users/niko/cdt/code/github/gbrain/skills/`
- 共约 50+ 个技能，每个包含 `SKILL.md` 定义
- 从 `RESOLVER.md` 调度（每消息触发 signal-detector + brain-ops）

### 核心技能触发表

| 触发器 | 技能 |
|---|---|
| 每入站消息（并行 spawn，不阻塞） | `signal-detector` |
| 任意大脑读/写/查找/引用 | `brain-ops` |
| "关于 X 我们知道什么"、"搜索"、"背景信息" | `query` |
| 创建/丰富个人或公司页面 | `enrich` |
| "归档此研究"、"将内容放入大脑" | `eiirp` (Everything In Its Right Place) |
| "保存此想法"、"记住这个"、"捕捉此内容" | `capture` |
| 用户分享链接/文章/推文/创意 | `idea-ingest` |
| "处理此视频"、"摄入此 PDF"、"将此播客保存到大脑" | `media-ingest` |
| 会议转录到达 | `meeting-ingestion` |
| 通用 "摄入这个"（自动路由到上述之一） | `ingest` |
| 修复大脑页面的损坏引用 | `citation-fixer` |
| "研究"、"追踪"、"从电子邮件提取"、"投资者更新" | `data-research` |
| 分享大脑页面作为链接 | `publish` |
| "验证前置元数据"、"检查前置元数据"、"大脑 lint" | `frontmatter-guard` |
| "eval 结果"、"搜索基准" | `gbrain eval run-all` / `gbrain eval compare` |
| 升级后的配置安全 | `gbrain-upgrade` |

### 技能约定（conventions/）
- `brain-routing.md` — Agent 面对决策表：何时切换大脑、何时切换源、跨大脑联邦
- 更多在 `skills/conventions/`

---

## 25. 命令行别名与简写

| 别名 | 目标命令 | 说明 |
|---|---|---|
| `gbrain ask` | `gbrain query` | 自然语言别名，`cli.ts` 中硬编码转换 |
| `gbrain link-add` | `gbrain link` | 添加链接（`operations.ts` 别名） |
| `gbrain link-rm` | `gbrain unlink` | 移除链接（`operations.ts` 别名） |
| `gbrain repos` | `gbrain sources` | 已弃用，v0.19.0 前的旧名称 |

---

## 附录：核心操作 vs CLI-only 命令

### 通过 `operations.ts` 定义（有 `cliHints`）的命令
get, put, delete, restore, purge-deleted, list, search, query, takes-list, takes-search, takes-scorecard, takes-calibration, think, tag, untag, tags, link, unlink, backlinks, link-sources, graph, timeline-add, timeline, stats, health, skills, skill, brain-skillpack, advisor (hidden), history, revert, sync (hidden), orphans (hidden), salience, volunteer-context, anomalies, whoknows, find-contradictions, find-trajectory, transcripts (hidden), whoami, sources_add (hidden), sources_list (hidden), sources_remove (hidden), sources_status (hidden), code_def 等 (hidden), search-by-image, day, on-this-day, since, last-seen, ontology, ontology-add, ontology-dimensions, ontology-contradictions, orient, chronicle-backfill

### CLI-only 命令（绕过 operations 层）
init, reinit-pglite, upgrade, post-upgrade, check-update, integrations, publish, check-backlinks, lint, report, import, export, files, embed, serve, call, config, doctor, migrate, eval, sync (完整), extract, extract-conversation-facts, enrich, features, autopilot, graph-query, jobs, agent, apply-migrations, skillpack-check, skillpack, resolvers, integrity, repair-jsonb, orphans (完整), sources (完整), mounts, dream, check-resolvable, routing-eval, skillify, smoke-test, providers, storage, repos, code-def/refs/callers/callees (完整), reindex, reindex-code, reindex-frontmatter, reindex-search-vector, frontmatter, auth, friction, claw-test, book-mirror, takes (完整), think (完整), salience (完整), anomalies (完整), transcripts, models, remote, recall, forget, edges-backfill, cache, ze-switch, founder, brainstorm, lsd, schema, capture, onboard, conversation-parser, status, connect, skillopt, quarantine, self-upgrade, advisor (完整), watch

---

## 附注：构建技能套件的关键观察

1. **operations.ts 是核心契约** — 所有能力最终需要通过这个操作层，MCP 工具定义由此自动生成
2. **区分信任边界** — 本地 CLI（remote=false）有完全能力；MCP（remote=true）受限，特别是 takes-holder 白名单、文件系统限制和受保护阶段
3. **两轴路由** — Brain × Source 是每个读取操作的基础，必须通过 `sourceScopeOpts(ctx)` 进行
4. **技能层独立** — 技能是胖 Markdown 文件，与工具无关，由 `RESOLVER.md` 调度。技能告诉 Agent *何时* 调用 CLI/MCP 操作
5. **capture 是主要入口** — v0.37/v0.38 起，`capture` 取代了 "调用 put_page、提交文件还是等待 autopilot？" 的困惑
6. **确定性优先** — lint、orphans、salience、anomalies 均为 0 LLM 调用。LLM 调用集中在 think、brainstorm、lsd、enrich、extract-conversation-facts
7. **维护周期分层** — dream（一次性）→ autopilot（持续）→ doctor --remediate（主动修复）
