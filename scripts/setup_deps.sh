#!/usr/bin/env bash
# setup_deps.sh - 在本地 venv 里装好 sherlock 运行依赖，不动系统 Python
# 用法: bash setup_deps.sh [--from-local <sherlock_src_dir>]
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$SKILL_DIR/.venv"
SRC="${SHERLOCK_HOME:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --from-local) SRC="${2:?}"; shift 2 ;;
    *) echo "[FAIL] 未知参数: $1" >&2; exit 2 ;;
  esac
done

BASE_PY="$(command -v python3 2>/dev/null || command -v python 2>/dev/null)"
[ -z "$BASE_PY" ] && { echo "[FAIL] 找不到 python"; exit 1; }

echo "== 1. 创建 venv =="
if [ ! -x "$VENV/Scripts/python.exe" ] && [ ! -x "$VENV/bin/python" ]; then
  "$BASE_PY" -m venv "$VENV" || { echo "[FAIL] venv 创建失败"; exit 1; }
  echo "[OK]   $VENV"
else
  echo "[INFO] venv 已存在，复用"
fi

PY="$VENV/Scripts/python.exe"
[ -x "$PY" ] || PY="$VENV/bin/python"

echo "== 2. 升级 pip =="
"$PY" -m pip install --disable-pip-version-check -q --upgrade pip 2>&1 | tail -2 || true

echo "== 3. 安装依赖 =="
DEPS="certifi colorama PySocks requests requests-futures stem pandas openpyxl tomli"
"$PY" -m pip install --disable-pip-version-check -q $DEPS 2>&1 | tail -5
RC=$?
if [ "$RC" -ne 0 ]; then
  echo "[FAIL] 依赖安装失败。检查网络，或先设 http_proxy/https_proxy。"
  exit 1
fi
echo "[OK]   依赖就绪"

echo "== 4. 验证导入 =="
if [ -n "$SRC" ] && [ -f "$SRC/sherlock_project/sherlock.py" ]; then
  echo "[INFO] 使用本地源码: $SRC"
  if "$PY" -c "
import sys; sys.path.insert(0, r'$SRC')
import sherlock_project
print('import OK')
" 2>&1 | tail -3; then
    echo "[OK]   本地源码可导入"
    printf '%s' "$SRC" > "$SKILL_DIR/.sherlock_home"
    echo "[OK]   已记录源码路径到 .sherlock_home"
    echo "[NEXT] 直接可用： bash scripts/run_sherlock.sh <username>"
  else
    echo "[FAIL] 本地源码导入失败"
    exit 1
  fi
else
  echo "[INFO] 未提供本地源码，安装 PyPI 包"
  "$PY" -m pip install --disable-pip-version-check -q sherlock-project 2>&1 | tail -3
  "$PY" -c "import sherlock_project; print('import OK')" 2>&1 | tail -2
fi

echo
echo "[DONE] 环境就绪。验证： bash scripts/check_env.sh"
