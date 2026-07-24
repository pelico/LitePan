# LitePan Code Wiki

> 版本：`0.3.2-Beta`  
> 生成日期：2026-07-24  
> 适用范围：项目整体架构、模块职责、关键类与函数、依赖关系、运行方式及 armv7l 可行性评估。

---

## 1. 项目概述

**LitePan** 是一个轻量级多网盘聚合与管理工具，采用 **FastAPI + Vue3** 技术栈。它通过统一驱动层对接多种云盘（115、123、百度、夸克、光鸭、移动、天翼、OneDrive、WebDAV 等），对外提供：

- Web 管理界面与文件浏览
- WebDAV 挂载服务
- STRM 生成与播放（适配 Emby / Jellyfin）
- 媒体整理（Media Organize）
- 跨盘秒传 / 跨盘转存
- 插件系统（资源搜索等）
- 缓存保持与持久化

---

## 2. 技术栈

| 层级 | 技术 |
|------|------|
| 后端框架 | Python 3.11 + FastAPI + Uvicorn |
| 异步 IO | asyncio + aiohttp |
| 数据库 | aiosqlite (SQLite) |
| 缓存 | 自研 LRU + TTL + 持久化 + 内存压力感知 |
| 认证 | 自研 Session + OAuth 代理 |
| 前端 | Vue 3 + Vite + Element Plus + Pinia |
| 构建 | Docker 多阶段构建 (Node 20 + Python 3.11 slim) |
| 部署 | Docker / Docker Compose |

---

## 3. 目录结构与架构概览

```
LitePan
├── main.py                 # 程序入口：装配 FastAPI、路由、生命周期、WebDAV、静态资源
├── config.py               # 全局配置与 ConfigManager（数据库优先 + 默认值兜底）
├── requirements.txt        # Python 依赖
├── Dockerfile              # 多阶段构建：Node 构建前端 -> Python Runtime
├── docker-compose.yml      # Docker Compose 模板
│
├── api/                    # HTTP API 层（FastAPI Router）
│   ├── admin.py            # 账号管理、系统设置
│   ├── files.py            # 文件列表、下载、上传、删除、移动、重命名
│   ├── auth.py             # 登录、登出、Session 刷新
│   ├── strm.py / strm_admin.py   # STRM 生成与播放接口
│   ├── emby_proxy.py       # Emby 反代管理
│   ├── plugins.py          # 插件扫描、启用、搜索任务
│   ├── cross_transfer.py   # 跨盘传输任务管理
│   ├── media_organize.py   # 媒体整理任务管理
│   ├── local_fs.py         # 本地文件系统浏览
│   ├── cache_retention.py  # 缓存保持任务管理
│   └── ...
│
├── core/                   # 核心业务逻辑
│   ├── lifespan.py         # 应用生命周期（启动/关闭顺序编排）
│   ├── base.py             # 驱动基础数据模型（FileItem、OperationResult、DriverInfo）
│   ├── driver_base.py      # BaseDriver 抽象基类（节流、缓存注入、秒传接口）
│   ├── driver_service.py   # 驱动获取与下载公共服务（resolve_download、下载模式判定）
│   ├── registry.py         # DriverRegistry（自动发现、实例池、配置指纹）
│   ├── auth_manager.py     # 认证系统与 Token 刷新调度
│   ├── session_manager.py  # Session 管理
│   ├── security.py         # 密码哈希、CORS、STRM 签名
│   ├── plugin_system.py    # PluginManager（插件加载、搜索任务、前端资源）
│   ├── strm_sync_manager.py    # STRM 同步任务调度器
│   ├── cache_retention_manager.py  # 缓存保持任务调度器
│   ├── upload_task_manager.py      # 上传任务队列与并发控制
│   ├── operation_wrapper.py        # 操作装饰器（缓存自动清理、认证检查）
│   ├── range_proxy.py      # Range 代理下载（多片并发）
│   ├── emby_proxy_server.py# Emby 反代监听管理
│   ├── log_manager.py      # 结构化日志（按模块、自动清理）
│   └── ...
│
├── drivers/                # 网盘驱动（每个子目录一个驱动）
│   ├── 115_Open/
│   ├── 123_Open/
│   ├── 123_Reverse/
│   ├── 139_Cloud/
│   ├── 189_Cloud/
│   ├── Baidu_Open/
│   ├── Guangya/
│   ├── LocalFs/
│   ├── OneDrive/
│   ├── Quark_Reverse/
│   └── WebDAV/
│   # 每个驱动通常包含：driver.py（实现）、api.py（HTTP 封装）、config.py（配置 Schema）、models.py
│
├── database/
│   └── db.py               # AsyncDatabase：基于 aiosqlite 的异步 CRUD + 表迁移
│
├── cache/                  # 缓存系统
│   ├── cache_manager.py    # 全局缓存管理器（LRU、TTL、内存上限、持久化）
│   ├── cache_types.py      # 缓存类型与常量定义
│   ├── cache_keys.py       # 缓存键生成与校验
│   ├── cache_cleaner.py    # 缓存清理器（文件增删改后自动失效）
│   └── hit_tracker.py      # 缓存命中率统计
│
├── webdav/                 # WebDAV 服务实现
│   ├── server.py           # FastAPIWebDAVServer（PROPFIND/GET/PUT/DELETE/MKCOL/MOVE/COPY）
│   ├── chunk_manager.py    # 分块上传管理
│   └── utils.py            # WebDAV XML/HTML 生成、路径解析
│
├── cross_transfer/         # 跨盘传输
│   ├── service.py          # 跨盘传输业务（源端扫描、指纹匹配、目标端秒传/上传）
│   ├── relay.py            # 中继下载（源端直链 -> 目标端上传）
│   ├── relay_task_manager.py   # 中继任务调度
│   └── methods.py          # 秒传方法注册（MD5/SHA1）
│
├── mediaorganize/          # 媒体整理
│   ├── manager.py          # 任务调度、日志、进度、启停控制
│   ├── planner.py          # 整理计划生成（TMDB + guessit + ffprobe）
│   ├── executor.py         # 计划执行（下载元数据、移动/重命名）
│   └── rules.py            # 命名规则与标签提取
│
└── web/                    # 前端源码与构建产物
    ├── src/                # Vue3 源码
    │   ├── views/          # 页面（Index / Admin / Login）
    │   ├── components/     # 组件（文件表格、任务面板、管理后台各模块）
    │   ├── composables/    # 组合式逻辑（上传任务、跨盘中继、Modal）
    │   ├── stores/         # Pinia Store（admin）
    │   └── router/         # Vue Router
    ├── static/             # Vite 构建产物（部署时由 main.py 挂载）
    └── package.json        # 前端依赖
```

---

## 4. 核心模块详解

### 4.1 入口与生命周期

**[main.py](file:///workspace/main.py)**
- 创建 `FastAPI` 实例，注册 lifespan（`core.lifespan`）。
- 挂载静态资源（`web/static`）。
- 注册所有 API Router（`api.*`）。
- 提供 WebDAV 根路径与通配路径处理器（`/dav`、`/dav/{path:path}`）。
- 启动 Uvicorn，支持 IPv4/IPv6 双栈自动检测，可通过环境变量覆盖监听地址与端口。

**[core/lifespan.py](file:///workspace/core/lifespan.py)**
- 启动顺序：日志 → 数据库 → 配置初始化 → 上传/中继清理 → 缓存系统 → 驱动自动发现 → 认证系统 → 操作包装器 → 缓存保持 → 插件系统 → STRM 同步 → Emby 反代。
- 关闭顺序：并行停止各管理器 → 关闭驱动实例 → 关闭 Range Proxy Session → 关闭数据库 → 停止日志。
- 通过 `ShutdownStep` 与超时预算控制优雅退出，避免容器被强制杀死。

### 4.2 配置系统

**[config.py](file:///workspace/config.py)**
- `Settings` 类：定义所有配置项的默认值与元数据（类型、描述、分类、范围）。
- `ConfigManager` 类：数据库优先，支持同步/异步双入口。内部使用 `_cache` 字典加速读取；首次读取时自动从 `configs` 表加载并初始化缺失项。
- `SECRET_KEY` 来源优先级：环境变量 `SECRET_KEY` > `data/.secret_key` 文件 > 随机生成并落盘。

### 4.3 数据库层

**[database/db.py](file:///workspace/database/db.py)**
- `AsyncDatabase` 封装 `aiosqlite.Connection`。
- 启动时自动建表：`cloud_accounts`、`configs`、`cache_retention_configs`、`strm_sync_tasks`、`strm_sync_branches`、`emby_proxy_configs`、`media_organize_tasks`。
- 包含 legacy 表/列清理与字段迁移逻辑（ALTER TABLE ADD COLUMN），保证旧版本数据库兼容升级。
- 提供账号 CRUD、配置 CRUD、缓存保持/STRM/Emby/媒体整理任务的完整 CRUD。

### 4.4 驱动架构

**[core/base.py](file:///workspace/core/base.py)**
- 定义 `FileItem`（文件元数据）、`OperationResult`（操作结果）、`DriverInfo`（驱动信息）。
- `CANONICAL_DRIVER_CAPABILITIES` 与 `CAPABILITY_ALIAS_MAP`：统一能力命名（list、download、upload、delete、rename、move、copy、chunk_download、resume_download、share 等）。
- `get_driver_capabilities` / `driver_supports`：运行时鸭子类型探测驱动实际能力。

**[core/driver_base.py](file:///workspace/core/driver_base.py)**
- `BaseDriver` 抽象基类：
  - 构造函数接收 `config`（dataclass），注入 `account_id`、`cache_manager`、logger。
  - `wait_for_request_interval()`：基于 `operation_delay` 与协程级 `_extra_api_delay` 的异步节流锁，防止 API 请求过快。
  - `test_connection()` / `init()` / `close()` 必须子类实现。
  - `resolve_transfer_hash()` / `rapid_upload_by_hash()`：跨盘秒传通用接口。
  - `purge_file()`：彻底删除（默认 fallback 到 `delete_file`）。

**[core/registry.py](file:///workspace/core/registry.py)**
- `DriverRegistry`：
  - `auto_discover_drivers()`：扫描 `drivers/` 目录下各子包，动态 import 并读取 `DRIVER_INFO`  manifest。
  - `get_driver_instance()`：基于账号配置指纹（排除 token/cookie 等动态字段）管理实例池，避免频繁重建；同时支持动态字段（access_token、cookie）热更新到已有实例。
  - 支持 cookie 驱动刷新后的持久化回调（落库并恢复账号状态为 active）。
  - `cleanup_idle_instances()`：回收空闲实例，但保护已注册到 `auth_scheduler` 的实例。

**[core/driver_service.py](file:///workspace/core/driver_service.py)**
- `get_account_driver()` / `get_account_driver_instance()`：根据账号 ID 获取驱动实例，自动校验账号存在与激活状态。
- `resolve_download()`：解析文件下载直链，内部带 1s 兜底缓存与并发锁，防止同一时刻重复请求上游 CDN。
- `get_effective_download_mode()`：判定本次下载使用 `redirect`（302 直链）还是 `proxy`（Range 代理）。
- `build_upstream_download_headers()`：构造带 Range、User-Agent、Accept-Encoding 的上游请求头。

### 4.5 缓存系统

**[cache/cache_manager.py](file:///workspace/cache/cache_manager.py)**
- 全局缓存管理器：基于 `OrderedDict` 的 LRU + TTL + 内存上限感知。
- 支持按 `CacheType` 分类：`file_list`、`file_info`、`download_url`、`path_mapping`、`webdav_metadata`、`search_result`。
- 自动序列化/反序列化 `FileItem`。
- 内存压力达到上限 80% 时触发淘汰。
- 支持按前缀批量清除（用于文件增删改后的缓存失效）。

**[cache/cache_cleaner.py](file:///workspace/cache/cache_cleaner.py)**
- 监听文件创建/删除/重命名/移动事件，自动清除相关缓存前缀，保证数据一致性。

### 4.6 WebDAV 服务

**[webdav/server.py](file:///workspace/webdav/server.py)**
- `FastAPIWebDAVServer`：
  - 支持 `OPTIONS`、`PROPFIND`、`GET`、`HEAD`、`PUT`、`DELETE`、`MKCOL`、`MOVE`、`COPY`。
  - WebDAV Basic Auth 复用管理员用户名/密码，密码必须已哈希（明文直接拒绝）。
  - 根路径 `/dav` 列出所有已启用账号；子路径按 `/{account_name}/{file_path...}` 路由到对应驱动。
  - `PROPFIND` 支持 Depth 与缓存（`webdav_metadata_cache`）。
  - `GET` 文件时根据驱动下载模式选择 `302 Redirect` 或 `Range Proxy`。
  - `PUT` 先写临时文件再调用驱动上传，避免大文件驻留内存。
  - `MOVE` 只支持同账号内；`COPY` 统一返回 501（云盘普遍不支持复制）。
  - 针对 macOS 元数据（`.DS_Store`、`.` 开头文件）自动静默处理，避免报错。

### 4.7 STRM 同步

**[core/strm_sync_manager.py](file:///workspace/core/strm_sync_manager.py)**
- `StrmSyncManager`：调度器 + 任务执行器。
- 任务来源：`strm_sync_tasks` 表；支持 `window`（按间隔+时间段）与 `daily`（每日定时）两种调度模式。
- 启动延迟 100s（+ 15s 缓存保持优先延迟），避免启动瞬间打爆 API。
- 扫描策略：
  - `incremental_missing`：只生成本地缺失的 STRM。
  - `incremental_update`：对比 URL 变化并更新，同时清理已不存在的文件。
  - `full_sync`：全量扫描差异清理。
- 分支检查（`branch_check_enabled`）：基础分支浅层探测，自动为新增子目录创建临时分支（30 天过期），避免全量递归。
- 元数据同步：独立生产者-消费者模型（串行 resolve + 并发 CDN 下载），支持完整性校验与直链重刷新。
- 同名冲突策略：`size_desc`（默认）、`size_asc`、`name_asc`。
- 账号禁用/认证失效时自动暂停关联任务，恢复后自动重启。

### 4.8 缓存保持

**[core/cache_retention_manager.py](file:///workspace/core/cache_retention_manager.py)**
- `CacheRetentionManager`：周期性调用 `driver.list_files()` 刷新指定目录，保证缓存不过期。
- 支持单层（`scan_depth=1`）或多层递归（`1..5` 层或无限 `-1`）。
- 与 STRM 调度器互斥：同一账号不可同时执行 STRM 与缓存保持任务，防止 API 限流。
- 同样支持时间段窗口与自动暂停/恢复机制。

### 4.9 跨盘传输

**[cross_transfer/service.py](file:///workspace/cross_transfer/service.py)**
- 源端驱动扫描文件树，按指定 hash 方法（MD5/SHA1）计算指纹。
- 目标端优先尝试 `rapid_upload_by_hash()`（秒传）；秒传失败则进入中继下载（源端直链下载 → 本地临时文件 → 目标端上传）。
- 限制：最大扫描 3000 个文件、最大深度 40 层、目录并发 6。

### 4.10 媒体整理

**[mediaorganize/manager.py](file:///workspace/mediaorganize/manager.py)**
- 任务驱动：读取 `media_organize_tasks` 表，生成整理计划（`planner.py`）并执行（`executor.py`）。
- 支持暂停/恢复/停止；日志环形缓冲区（`deque maxlen=800`）；进度实时更新。

**[mediaorganize/planner.py](file:///workspace/mediaorganize/planner.py)**
- 使用 `guessit` 解析文件名，调用 TMDB API 匹配影视信息，使用 `ffprobe` 提取媒体标签。
- 输出整理计划：目标路径、重命名规则、元数据下载清单。

**[mediaorganize/executor.py](file:///workspace/mediaorganize/executor.py)**
- 按计划执行：下载海报/NFO/字幕，调用驱动接口移动/重命名文件，回写结果。

### 4.11 插件系统

**[core/plugin_system.py](file:///workspace/core/plugin_system.py)**
- `PluginManager`：
  - 扫描 `plugins/` 目录，读取 `manifest.json`。
  - 支持 `create_plugin` 工厂函数或 `Plugin` 类。
  - 插件可暴露前端入口（`frontend_entry`），支持 `module`（JS）或 `iframe` 模式。
  - 搜索任务采用异步 Job 模型（`start_search_job` → `_run_search_job`），支持流式结果累积与取消。

### 4.12 前端

**[web/src/](file:///workspace/web/src)**
- Vue 3 + Composition API + Vite。
- `views/`：Index（文件浏览）、Admin（后台管理）、Login（登录）。
- `components/admin/`：账号管理、缓存中心、STRM 生成、跨盘传输、插件中心、系统监控等。
- `composables/`：抽离上传任务、跨盘中继、Modal、文件夹选择等逻辑。
- `stores/admin.js`：Pinia 管理后台状态。
- 构建产物输出到 `web/static/`，由 FastAPI `StaticFiles` 挂载。

---

## 5. 关键类与函数说明

### 5.1 数据模型

| 类/函数 | 位置 | 说明 |
|---------|------|------|
| `FileItem` | [core/base.py](file:///workspace/core/base.py#L11) | 文件/文件夹元数据（id, name, path, size, is_dir, modified, download_url 等） |
| `OperationResult` | [core/base.py](file:///workspace/core/base.py#L30) | 驱动操作结果（success, message, data） |
| `DriverInfo` | [core/base.py](file:///workspace/core/base.py#L37) | 驱动信息（name, display_name, version, capabilities） |
| `ResolvedDownload` | [core/driver_service.py](file:///workspace/core/driver_service.py#L65) | 下载解析结果（download_url, file_name, file_size, headers, effective_mode） |
| `StrmSyncTask` | [core/strm_sync_manager.py](file:///workspace/core/strm_sync_manager.py#L35) | STRM 任务运行时对象 |
| `CacheRetentionTask` | [core/cache_retention_manager.py](file:///workspace/core/cache_retention_manager.py#L24) | 缓存保持任务运行时对象 |

### 5.2 驱动层核心

| 类/函数 | 位置 | 说明 |
|---------|------|------|
| `BaseDriver` | [core/driver_base.py](file:///workspace/core/driver_base.py#L15) | 所有网盘驱动的抽象基类 |
| `BaseDriver.wait_for_request_interval` | [core/driver_base.py](file:///workspace/core/driver_base.py#L32) | 异步请求节流（operation_delay + extra_api_delay） |
| `BaseDriver.rapid_upload_by_hash` | [core/driver_base.py](file:///workspace/core/driver_base.py#L90) | 指纹秒传通用接口 |
| `DriverRegistry` | [core/registry.py](file:///workspace/core/registry.py#L13) | 驱动注册中心（自动发现、实例池、配置指纹） |
| `DriverRegistry.get_driver_instance` | [core/registry.py](file:///workspace/core/registry.py#L79) | 获取/复用驱动实例，热更新动态字段 |
| `get_account_driver` | [core/driver_service.py](file:///workspace/core/driver_service.py#L27) | 根据账号 ID 获取驱动实例（含校验） |
| `resolve_download` | [core/driver_service.py](file:///workspace/core/driver_service.py#L74) | 解析下载直链（带锁与缓存） |

### 5.3 任务调度器

| 类/函数 | 位置 | 说明 |
|---------|------|------|
| `StrmSyncManager` | [core/strm_sync_manager.py](file:///workspace/core/strm_sync_manager.py#L71) | STRM 任务调度与执行 |
| `StrmSyncManager._scheduler_loop` | [core/strm_sync_manager.py](file:///workspace/core/strm_sync_manager.py#L365) | 主调度循环（启动延迟、时间窗口、并发控制） |
| `StrmSyncManager._run_task` | [core/strm_sync_manager.py](file:///workspace/core/strm_sync_manager.py#L1542) | 单次 STRM 任务执行（扫描、冲突解决、写文件、元数据下载） |
| `CacheRetentionManager` | [core/cache_retention_manager.py](file:///workspace/core/cache_retention_manager.py#L68) | 缓存保持任务调度与执行 |
| `CacheRetentionManager._refresh_cache_recursive` | [core/cache_retention_manager.py](file:///workspace/core/cache_retention_manager.py#L449) | 递归刷新目录缓存（BFS，支持深度限制） |
| `PluginManager` | [core/plugin_system.py](file:///workspace/core/plugin_system.py#L50) | 插件生命周期管理与搜索任务调度 |

### 5.4 WebDAV

| 类/函数 | 位置 | 说明 |
|---------|------|------|
| `FastAPIWebDAVServer` | [webdav/server.py](file:///workspace/webdav/server.py#L78) | WebDAV 请求总入口 |
| `FastAPIWebDAVServer.handle_request` | [webdav/server.py](file:///workspace/webdav/server.py#L206) | 分派 METHOD 到具体 handler |
| `FastAPIWebDAVServer._resolve_path_to_file` | [webdav/server.py](file:///workspace/webdav/server.py#L1576) | 路径解析（支持路径缓存与陈旧缓存重试） |
| `FastAPIWebDAVServer._handle_file_download` | [webdav/server.py](file:///workspace/webdav/server.py#L1054) | 文件下载（Redirect / Range Proxy） |

### 5.5 工具与公共服务

| 类/函数 | 位置 | 说明 |
|---------|------|------|
| `ConfigManager` | [config.py](file:///workspace/config.py#L397) | 配置读写（数据库优先，兼容 sync/async） |
| `AsyncDatabase` | [database/db.py](file:///workspace/database/db.py#L17) | 异步 SQLite 数据库封装 + 迁移 |
| `APIResponse` | [core/response.py](file:///workspace/core/response.py) | 统一 API 响应格式 |
| `get_writer` | [core/log_manager.py](file:///workspace/core/log_manager.py) | 按模块获取结构化 logger |
| `build_strm_play_path` / `build_strm_v2_play_path` | [core/strm_security.py](file:///workspace/core/strm_security.py) | STRM 播放地址与签名生成 |

---

## 6. 依赖关系

### 6.1 后端依赖

```text
fastapi                    # Web 框架
uvicorn[standard]          # ASGI 服务器（含 uvloop、httptools、websockets）
aiohttp                    # 异步 HTTP 客户端（上游请求、元数据下载）
pydantic                   # 数据校验
python-multipart           # 文件上传解析
psutil                     # 系统/内存监控（缓存压力感知）
aiosqlite                  # 异步 SQLite
qrcode[pil]                # 二维码生成（部分驱动扫码登录）
guessit                    # 媒体文件名解析
tmdbsimple                 # TMDB API 客户端
PySocks                    # SOCKS 代理支持
pycryptodome               # 加密/解密（部分驱动签名、STRM 签名）
```

### 6.2 前端依赖

```text
vue ^3.3.8
vue-router ^4.2.5
pinia ^2.1.7
element-plus ^2.4.4
axios ^1.6.2
gsap ^3.15.0
vite ^5.0.0
```

### 6.3 模块调用关系（文字描述）

```
main.py
  ├── lifespan
  │     ├── cache (cache_manager / cache_cleaner)
  │     ├── database (db)
  │     ├── config (config_manager)
  │     ├── core.registry (driver_registry)
  │     ├── core.auth_manager
  │     ├── core.plugin_system (plugin_manager)
  │     ├── core.strm_sync_manager
  │     ├── core.cache_retention_manager
  │     └── core.upload_task_manager
  ├── api.* routers
  │     ├── core.driver_service → core.registry → drivers.*
  │     ├── core.operation_wrapper → cache.cache_cleaner
  │     └── database.db
  └── webdav.server
        ├── core.driver_service
        ├── core.range_proxy
        └── cache.cache_manager
```

---

## 7. 项目运行方式

### 7.1 本地开发（前后端分离）

```bash
# 1. 安装 Python 依赖
pip install -r requirements.txt

# 2. 启动后端（默认端口 5211）
python main.py

# 3. 前端开发（另开终端）
cd web
npm install
npm run dev
```

前端 dev server 通过 Vite 代理到后端 API；生产环境则使用 `npm run build` 生成到 `web/static/`。

### 7.2 Docker 部署（推荐）

```bash
docker run -d \
  --name litepan \
  --restart unless-stopped \
  --network host \
  -e TZ=Asia/Shanghai \
  -p 5211:5211 \
  -v ./data:/app/data \
  -v ./log:/app/log \
  -v ./strm:/app/strm \
  -v ./plugins:/app/plugins \
  ponphil/litepan:latest
```

**关键挂载卷**：
- `/app/data`：SQLite 数据库、上传临时文件、密钥文件。
- `/app/log`：结构化日志。
- `/app/strm`：STRM 生成目录（可直接映射到 Emby/Jellyfin）。
- `/app/plugins`：插件目录。

### 7.3 Docker Compose

项目根目录已提供 [docker-compose.yml](file:///workspace/docker-compose.yml)，可直接：

```bash
docker compose up -d
```

### 7.4 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LITEPAN_PORT` | `5211` | 服务端口 |
| `LITEPAN_WEB_HOST` | `::` | 监听地址（`::` 表示双栈自动检测） |
| `LITEPAN_GRACEFUL_SHUTDOWN` | `3` | 优雅关闭超时（秒） |
| `LITEPAN_SHUTDOWN_TOTAL_TIMEOUT` | `2.0` | 关闭阶段总预算（秒） |
| `LITEPAN_AUTO_CAPTURE_STRM_BASE_URL` | `false` | 是否自动捕获 STRM 基址 |
| `LITEPAN_DEBUG` | `false` | 调试模式 |
| `SECRET_KEY` | 自动生成 | 用于 Session 签名 |

---

## 8. armv7l 支持可行性分析

### 8.1 基础镜像支持

- **Python 3.11 slim**：官方镜像支持 `linux/arm/v7`（armv7l），可用。
- **Node 20 slim**：官方镜像通常支持 `linux/arm/v7`，但部分版本可能存在滞后或构建缓慢问题，需要实际验证。

### 8.2 Python 依赖编译风险

当前 `requirements.txt` 中包含以下**可能需要在 armv7l 上源码编译**的依赖：

| 依赖 | 风险 | 说明 |
|------|------|------|
| `uvicorn[standard]` | **中高** | 额外安装 `uvloop`（C 扩展）和 `httptools`（C 扩展）。在 armv7l 上通常**可以编译通过**，但要求镜像中具备 `gcc`、`python3-dev`、`libffi-dev` 等构建工具。 |
| `psutil` | 中 | 需要编译 C 扩展；有 armv7l wheel 的概率较低，通常需本地编译。 |
| `pycryptodome` | 中 | 需要编译 C 扩展；内存较小的 armv7l 设备（如 512MB RAM）编译时可能 OOM。 |
| `aiohttp` | 低 | 官方通常提供 armv7l wheel。 |
| `qrcode[pil]` → `Pillow` | 低 | 官方提供 armv7l wheel。 |
| `aiosqlite` | 无 | 纯 Python。 |
| `fastapi` / `pydantic` / `guessit` / `tmdbsimple` | 无 | 纯 Python。 |

### 8.3 Dockerfile 适配建议

当前 [Dockerfile](file:///workspace/Dockerfile) 的 Runtime 阶段**没有安装构建工具**，在 armv7l 上直接构建会失败。需要修改如下：

```dockerfile
FROM python:3.11-slim AS runtime

# 安装构建依赖（armv7l 编译 C 扩展必需）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    libffi-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# ... 原有 pip install 逻辑 ...

# 可选：编译完成后删除构建工具以减小镜像体积
# RUN apt-get purge -y gcc libc6-dev libffi-dev python3-dev
```

或采用**多阶段构建**：在独立的 `build` 阶段完成编译，再将 wheel 拷贝到 runtime。

### 8.4 前端构建风险

- Vite + Vue3 在 armv7l 上**可以运行**，但 `npm ci` 与 `vite build` 内存占用较大。
- 建议：在 x86_64 机器上预先执行 `npm run build`，只将产物 `web/static/` 拷贝到 armv7l 运行时镜像中，**避免在 armv7l 设备上执行 Node 构建**。

### 8.5 运行时性能与稳定性

- **SQLite + asyncio**：armv7l 完全支持，无架构限制。
- **缓存内存上限**：建议根据设备内存调低 `CACHE_MEMORY_LIMIT_MB`（默认 512MB），避免小内存设备 OOM。
- **并发连接数**：`uvicorn[standard]` 的 `uvloop` 在 armv7l Linux 上表现正常，但高并发场景 CPU 可能成为瓶颈。

### 8.6 结论

| 评估项 | 结论 |
|--------|------|
| **可行性** | **可行**，但非“开箱即用”。 |
| **主要障碍** | 1) Dockerfile 缺少 C 编译工具链；<br>2) `uvicorn[standard]` 的 `uvloop`/`httptools` 需在 armv7l 上编译；<br>3) 前端构建建议在 x86 交叉完成。 |
| **推荐方案** | ① 修改 Dockerfile 增加 `gcc/python3-dev` 等构建依赖；<br>② 或使用 `uvicorn` 替代 `uvicorn[standard]`（去掉 uvloop/httptools，性能略降但省去编译）；<br>③ 前端采用预构建产物；<br>④ 在内存 < 1GB 的设备上建议关闭部分高并发功能或降低缓存上限。 |

---

## 9. 许可证

本项目采用 [PolyForm Noncommercial License 1.0.0](file:///workspace/LICENSE)。

- 允许：个人学习、研究、测试、非商业 hobby 项目。
- 禁止：任何商业用途（收费服务、集成到商业产品、公司内部商用等）。

---

> 本 Wiki 基于仓库源码自动生成，关键类与函数链接指向本地绝对路径，可在支持 `file:///` 协议的编辑器或 IDE 中直接跳转。
