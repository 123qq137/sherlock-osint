# 用户名账号排查

把一个用户名丢进数百个站点，看它在哪里注册过。基于 [Sherlock](https://github.com/sherlock-project/sherlock)（MIT），本仓库是 WorkBuddy skill 封装层：负责环境适配、参数规范化、结果整理与合规边界，不修改上游探测逻辑。

## 安装

```bash
git clone https://github.com/<your-name>/sherlock-osint.git
cp -R sherlock-osint ~/.workbuddy/skills/sherlock-osint
```

或直接用仓库内脚本：

```bash
bash scripts/install_skill.sh https://github.com/<your-name>/sherlock-osint.git
```

## 首次使用

```bash
cd ~/.workbuddy/skills/sherlock-osint
bash scripts/setup_deps.sh        # 建 .venv 并装依赖，不动系统 Python
bash scripts/check_env.sh         # 应输出 RESULT=READY
```

若已有本地 Sherlock 源码，用 `SHERLOCK_HOME` 指过去：

```bash
SHERLOCK_HOME=/path/to/sherlock bash scripts/setup_deps.sh --from-local /path/to/sherlock
```

## 跑一次

```bash
bash scripts/run_sherlock.sh alice
bash scripts/run_sherlock.sh alice --site GitHub --site Reddit
bash scripts/run_sherlock.sh alice --csv --folderoutput ./out
```

输出里 `[+] SiteName: https://...` 即命中。默认只打印命中项。

## 触发词

查用户名、账号排查、这个用户名注册过哪些平台、OSINT 用户名、账号暴露面自查。

## 目录

```
SKILL.md                    技能定义（给模型看的）
scripts/check_env.sh        环境自检
scripts/setup_deps.sh       本地 venv 装依赖
scripts/run_sherlock.sh     规范化调用
scripts/install_skill.sh    从 git 仓库安装到本地 skills 目录
```

## 合规声明

本工具仅用于**自身账号暴露面自查**、**经书面授权的安全评估**、**公开信息关联分析**。

不得用于人肉搜索、跟踪骚扰、身份定位，或任何侵犯他人隐私的场景。同名账号不等于同一人，结果需人工核验。

## 许可

本封装层：MIT。上游 Sherlock：MIT，版权归 Sherlock Project 所有，详见 [LICENSE](LICENSE) 与上游仓库。
