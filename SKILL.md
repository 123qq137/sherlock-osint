---
name: sherlock-osint
description: "按用户名在 400+ 社交网络与站点上批量排查账号是否存在（基于 Sherlock）。当用户需要查某个用户名在哪些平台注册过、做自身账号暴露面自查、或做经授权的 OSINT 用户名关联调查时使用。"
description_zh: "用户名跨平台账号排查（基于 Sherlock），输出命中站点清单，支持 JSON/CSV 导出与代理"
description_en: "Username enumeration across social networks via Sherlock, with JSON/CSV export and proxy support"
version: 1.0.0
display_name: "用户名账号排查"
display_name_en: "Username Recon"
allowed-tools: Bash,Read,Write
---

# 用户名账号排查（Sherlock）

按用户名在数百个站点上探测账号是否存在。底层是 Sherlock（MIT，上游 `sherlock-project/sherlock`），本 skill 只做环境适配、参数规范化与结果整理，不修改其探测逻辑。

## 使用前提

依赖必须就绪。检查：

```
bash scripts/check_env.sh
```

未就绪时执行 `bash scripts/setup_deps.sh`（建本地 venv 并安装依赖，不改动系统 Python 环境）。

源码位置解析顺序：

1. 环境变量 `SHERLOCK_HOME` 指向的目录
2. `<skill_dir>/vendor/sherlock/`（若随仓库内置）
3. 已 `pip install sherlock-project` 的当前 Python 环境

## 基本调用

```
bash scripts/run_sherlock.sh <username> [额外 sherlock 参数]
```

默认已带 `--no-color --print-found`，只输出命中项，便于解析。

常用组合：

| 目的 | 命令 |
| --- | --- |
| 快速查一个用户名 | `run_sherlock.sh alice` |
| 同时查多个 | `run_sherlock.sh alice bob carol` |
| 导出 JSON | `run_sherlock.sh alice --json` 会与 `--output` 冲突，改用 `--output out.txt` |
| 存 CSV | `run_sherlock.sh alice --csv --folderoutput ./out` |
| 只查指定站点 | `run_sherlock.sh alice --site GitHub --site Reddit` |
| 走代理 | `run_sherlock.sh alice --proxy socks5://127.0.0.1:1080` |
| 放宽超时 | `run_sherlock.sh alice --timeout 120` |
| 含 NSFW 站点 | `run_sherlock.sh alice --nsfw` |
| 排查误报 | 加 `--verbose` 看 HTTP 状态与判定依据 |

## 结果解读

- `[+] SiteName: https://...` —— 命中，账号大概率存在
- 未命中默认不输出（`--print-found`）
- `[?]` / 超时 —— 无法判定，不等于不存在

判定基于「响应内容里是否出现用户名」，**存在误报**。命中项在正式使用前应人工打开确认一次，尤其是常用于重定向或统一报错页的站点。

## 输出整理约定

用户要「报告」时，按此结构给：

1. **结论一句话**：查到 N 个平台有该用户名
2. **命中清单**：按类别分组（社交、代码托管、论坛、电商、其他），每条带可点击链接
3. **不确定项**：超时/被墙的站点单独列出，说明未验证
4. **建议**：哪些该注销、哪些建议改用户名、哪些需要开二次验证

## 边界与合规（重要）

1. **仅限合法用途**：自查自身账号暴露面、经书面授权的安全评估、公开信息关联分析。
2. **不做骚扰性聚合**：不把结果用于人肉、跟踪、骚扰或身份定位。用户提出此类需求时说明边界并拒绝。
3. **不自动深挖**：不做密码尝试、不绕过登录、不抓取私密内容。本 skill 只做「该用户名在此站点是否存在」这一件事。
4. **结果可能失真**：对方可注册同名账号，同名≠同一人。报告里必须写明这一点。
5. **不代跑大规模扫描**：批量用户名超过 20 个或需要高频请求时，提示用户注意目标站点的速率限制与服务条款，并建议分批。

## 不适用场景

密码/凭据验证、人脸或图片反查、手机号/邮箱反查、暗网数据检索、自动化注册或登录。
