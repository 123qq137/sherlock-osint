#!/usr/bin/env bash
# check_env.sh - 检查 sherlock 是否可运行
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$SKILL_DIR/.venv"

pick_python() {
  if [ -x "$VENV/Scripts/python.exe" ]; then echo "$VENV/Scripts/python.exe"; return; fi
  if [ -x "$VENV/bin/python" ]; then echo "$VENV/bin/python"; return; fi
  command -v python3 2>/dev/null || command -v python 2>/dev/null || echo ""
}

PY="$(pick_python)"
echo "== 1. Python =="
if [ -z "$PY" ]; then
  echo "[FAIL] 找不到 python，请先安装 Python 3.10+"
  echo "RESULT=FAIL"; exit 1
fi
echo "[OK]   $PY"
"$PY" --version 2>&1 | sed 's/^/       /'

echo "== 2. venv =="
if [ -x "$VENV/Scripts/python.exe" ] || [ -x "$VENV/bin/python" ]; then
  echo "[OK]   本地 venv: ${VENV#$HOME/}"
else
  echo "[INFO] 无本地 venv，使用系统 Python"
fi

echo "== 3. 源码位置 =="
SRC="${SHERLOCK_HOME:-}"
if [ -z "$SRC" ] && [ -f "$SKILL_DIR/.sherlock_home" ]; then
  CAND="$(tr -d '\r\n' < "$SKILL_DIR/.sherlock_home")"
  [ -f "$CAND/sherlock_project/sherlock.py" ] && SRC="$CAND"
fi
if [ -z "$SRC" ] && [ -f "$SKILL_DIR/vendor/sherlock/sherlock_project/sherlock.py" ]; then
  SRC="$SKILL_DIR/vendor/sherlock"
fi

MODE=""
if [ -n "$SRC" ]; then
  echo "[OK]   $SRC"
  MODE="local"
else
  echo "[INFO] 无本地源码，尝试使用已安装的 sherlock-project 包"
  MODE="pip"
fi

echo "== 4. 依赖与导入 =="
if "$PY" - "$SRC" <<'EOF' >/dev/null 2>&1
import sys
src = sys.argv[1] if len(sys.argv) > 1 else ""
if src:
    sys.path.insert(0, src)
import sherlock_project  # noqa: F401
EOF
then
  echo "[OK]   sherlock_project 可导入"
  if [ "$MODE" = "local" ] && [ -f "$SRC/sherlock_project/resources/data.json" ]; then
    echo "[OK]   本地 data.json 存在（运行时自动加 --local，不依赖外网拉取）"
  fi
  echo
  echo "RESULT=READY"
  echo "[NEXT] bash scripts/run_sherlock.sh <username>"
  exit 0
else
  echo "[FAIL] 依赖缺失或源码不可用"
  echo
  echo "RESULT=NOT_READY"
  echo "[NEXT] bash scripts/setup_deps.sh --from-local <sherlock_src_dir>"
  echo "       或：    bash scripts/setup_deps.sh   （从 PyPI 安装 sherlock-project）"
  exit 1
fi
