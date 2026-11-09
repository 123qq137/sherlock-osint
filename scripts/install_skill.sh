#!/usr/bin/env bash
# install_skill.sh - 从 git 仓库或本地目录安装 skill 到 ~/.workbuddy/skills/
# 用法: bash install_skill.sh <git-url | local-dir> [--name <override>] [--yes]
set -uo pipefail

SRC="${1:-}"
if [ -z "$SRC" ]; then
  echo "[FAIL] 用法: install_skill.sh <git-url | local-dir> [--name <override>] [--yes]" >&2
  exit 2
fi
shift
OVERRIDE=""
ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --name) OVERRIDE="${2:?}"; shift 2 ;;
    --yes|-y) ASSUME_YES=1; shift ;;
    *) echo "[FAIL] 未知参数: $1" >&2; exit 2 ;;
  esac
done

SKILLS_ROOT="${HOME}/.workbuddy/skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== 1. 获取源码 =="
if [ -d "$SRC" ]; then
  echo "[INFO] 本地目录，直接复制"
  SRC_DIR="$SRC"
else
  echo "[INFO] 克隆: $SRC"
  if ! git clone --depth 1 "$SRC" "$TMP/src" 2>&1 | tail -3; then
    echo "[FAIL] 克隆失败。检查地址、网络或访问权限。" >&2
    exit 1
  fi
  SRC_DIR="$TMP/src"
fi

# 允许仓库把 skill 放在子目录
if [ ! -f "$SRC_DIR/SKILL.md" ]; then
  CAND="$(find "$SRC_DIR" -maxdepth 3 -name SKILL.md -not -path '*/.git/*' | head -n 1)"
  if [ -n "$CAND" ]; then
    SRC_DIR="$(dirname "$CAND")"
    echo "[INFO] SKILL.md 位于子目录: ${SRC_DIR#$TMP/}"
  else
    echo "[FAIL] 源码里找不到 SKILL.md" >&2
    exit 1
  fi
fi

echo "== 2. 结构校验 =="
if [ -f "$SRC_DIR/scripts/validate_skill.sh" ]; then
  bash "$SRC_DIR/scripts/validate_skill.sh" "$SRC_DIR" || true
fi

NAME="$OVERRIDE"
if [ -z "$NAME" ]; then
  NAME="$(sed -n 's/^name:[[:space:]]*//p' "$SRC_DIR/SKILL.md" | head -n 1 | sed -E 's/^"(.*)"$/\1/' | tr -d '\r')"
fi
NAME="${NAME:-$(basename "$SRC_DIR")}"

DEST="$SKILLS_ROOT/$NAME"
echo "== 3. 目标位置 =="
echo "[INFO] $DEST"

mkdir -p "$SKILLS_ROOT"

if [ -e "$DEST" ]; then
  TS="$(date +%Y%m%d-%H%M%S)"
  BK="$SKILLS_ROOT/.backup/${NAME}-${TS}"
  echo "[WARN] 目标已存在，先备份到 ${BK#$SKILLS_ROOT/}"
  if [ "$ASSUME_YES" -ne 1 ]; then
    printf "       继续覆盖？[y/N] "
    read -r ans </dev/tty || ans="n"
    case "$ans" in y|Y) ;; *) echo "[ABORT] 用户取消"; exit 1 ;; esac
  fi
  mkdir -p "$(dirname "$BK")"
  mv "$DEST" "$BK"
  echo "[OK]   已备份"
fi

cp -R "$SRC_DIR" "$DEST"
rm -rf "$DEST/.git"

echo "== 4. 完成 =="
echo "[OK]   已安装到 $DEST"
if [ -f "$DEST/SKILL.md" ]; then
  echo "[INFO] 触发说明:"
  sed -n 's/^description_zh:[[:space:]]*"\(.*\)"$/\1/p' "$DEST/SKILL.md" | head -n 1 | sed 's/^/       /'
fi
echo "[NEXT] 重启会话或新开对话，skill 才会被加载。"
