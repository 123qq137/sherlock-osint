#!/usr/bin/env bash
# run_sherlock.sh - 规范化调用 sherlock
# 用法: bash run_sherlock.sh <username> [额外的 sherlock 参数...]
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$SKILL_DIR/.venv"

if [ $# -lt 1 ]; then
  echo "[FAIL] 用法: run_sherlock.sh <username> [sherlock 参数...]" >&2
  exit 2
fi

PY="$VENV/Scripts/python.exe"
[ -x "$PY" ] || PY="$VENV/bin/python"
[ -x "$PY" ] || PY="$(command -v python3 2>/dev/null || command -v python 2>/dev/null)"
[ -z "$PY" ] && { echo "[FAIL] 找不到 python，先跑 setup_deps.sh" >&2; exit 1; }

# 源码位置：环境变量 > 本地记录 > vendor
SRC="${SHERLOCK_HOME:-}"
if [ -z "$SRC" ] && [ -f "$SKILL_DIR/.sherlock_home" ]; then
  CAND="$(tr -d '\r\n' < "$SKILL_DIR/.sherlock_home")"
  [ -f "$CAND/sherlock_project/sherlock.py" ] && SRC="$CAND"
fi
if [ -z "$SRC" ] && [ -f "$SKILL_DIR/vendor/sherlock/sherlock_project/sherlock.py" ]; then
  SRC="$SKILL_DIR/vendor/sherlock"
fi

# 清掉本地代理变量：它们会把 requests 引向不可用的 127.0.0.1 代理
# 需要代理时请显式传 --proxy socks5://127.0.0.1:1080
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy 2>/dev/null || true

# 依赖自检，缺失就明确报错而不是抛 Traceback
if ! "$PY" - "$SRC" <<'EOF' >/dev/null 2>&1
import sys
src = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else None
if src:
    sys.path.insert(0, src)
import sherlock_project  # noqa
EOF
then
  echo "[FAIL] sherlock 依赖未就绪。" >&2
  echo "       修复: bash \"$SKILL_DIR/scripts/setup_deps.sh\"" >&2
  [ -n "$SRC" ] && echo "       本地源码: $SRC" >&2
  exit 3
fi

# 统一加默认参数（用户显式传了则不重复加）
EXTRA=()
case " $* " in
  *" --no-color "*) ;;
  *) EXTRA+=(--no-color) ;;
esac
case " $* " in
  *" --print-found "*|*" --print-all "*) ;;
  *) EXTRA+=(--print-found) ;;
esac
# 有本地 data.json 就强制本地，避免从 raw.githubusercontent.com 拉取失败
case " $* " in
  *" --local "*) ;;
  *) [ -n "$SRC" ] && [ -f "$SRC/sherlock_project/resources/data.json" ] && EXTRA+=(--local) ;;
esac

cd "$SRC" 2>/dev/null || true
echo "[INFO] sherlock 开始探测: $*"
echo "----------------------------------------"
"$PY" -m sherlock_project "$@" "${EXTRA[@]}"
RC=$?
echo "----------------------------------------"
echo "[INFO] 退出码: $RC （非 0 通常表示有站点被跳过或参数问题，不代表全部失败）"
exit $RC
