#!/usr/bin/env bash
#
# Restore files that are part of the current project but were removed to keep
# the repository minimal. Files are pulled from the upstream PiGallery2 repo.
#
# It does NOT restore test/, docs/, benchmark/, sample extensions, feature code
# or extra translations: those are not part of this trimmed project.
#
# Usage:
#   ./restore-upstream-assets.sh                    # translations + docker files
#   ./restore-upstream-assets.sh --diagnostics      # + format test images
#   ./restore-upstream-assets.sh --all              # + diagnostics images
#   ./restore-upstream-assets.sh --ref v3.6.0       # pin upstream version
#   ./restore-upstream-assets.sh --lockfile         # regenerate package-lock.json
#   ./restore-upstream-assets.sh --force            # overwrite existing files
#
set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/bpatrik/PiGallery2.git}"
CLONE_DIR="${CLONE_DIR:-/tmp/pigallery2-upstream}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REF="master"
FORCE=0
DO_DIAGNOSTICS=0
DO_LOCKFILE=0

usage() {
  cat <<'EOF'
Restore files of the current (trimmed) project from the upstream repository.

Usage:
  ./restore-upstream-assets.sh                    # translations + docker files
  ./restore-upstream-assets.sh --diagnostics      # + format test images
  ./restore-upstream-assets.sh --all              # + diagnostics images
  ./restore-upstream-assets.sh --ref v3.6.0       # pin upstream version
  ./restore-upstream-assets.sh --lockfile         # regenerate package-lock.json
  ./restore-upstream-assets.sh --force            # overwrite existing files

What is restored:
  - src/frontend/translate/messages.en.xlf, messages.cn.xlf (needed to build)
  - docker/** without markdown docs
  - format test images only with --diagnostics
  - package-lock.json only with --lockfile (requires npm/network)

What is never restored: test/, docs/, benchmark/, extension/, extra
translations, and source code of removed features.
Env: UPSTREAM_URL, CLONE_DIR
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --ref)
      [ $# -ge 2 ] || { echo "错误：--ref 需要一个参数" >&2; exit 1; }
      REF="$2"
      shift 2
      ;;
    --diagnostics) DO_DIAGNOSTICS=1; shift ;;
    --lockfile)    DO_LOCKFILE=1; shift ;;
    --all)         DO_DIAGNOSTICS=1; shift ;;
    --force)       FORCE=1; shift ;;
    -h|--help)     usage ;;
    *)
      echo "错误：未知参数 '$1'（用 --help 查看用法）" >&2
      exit 1
      ;;
  esac
done

command -v git >/dev/null 2>&1 || { echo "错误：未安装 git" >&2; exit 1; }

echo "==> 上游仓库: $UPSTREAM_URL"
echo "==> 版本:     $REF"
echo "==> 克隆目录: $CLONE_DIR"
echo "==> 项目目录: $PROJECT_DIR"

# ---------- 克隆或更新上游仓库 ----------
if [ ! -d "$CLONE_DIR/.git" ]; then
  if [ -e "$CLONE_DIR" ] && [ -n "$(ls -A "$CLONE_DIR" 2>/dev/null)" ]; then
    echo "错误：$CLONE_DIR 已存在且不是 git 仓库，请先移走或删除它" >&2
    exit 1
  fi
  echo "==> 克隆上游仓库（首次会较慢）..."
  git clone "$UPSTREAM_URL" "$CLONE_DIR"
else
  echo "==> 更新已有克隆..."
  git -C "$CLONE_DIR" fetch --tags --prune origin
fi

echo "==> 切换到 $REF ..."
if ! git -C "$CLONE_DIR" checkout -f "$REF" 2>/dev/null; then
  echo "错误：无法切换到 '$REF'。可用的 tag 有：" >&2
  git -C "$CLONE_DIR" tag | tail -20 >&2
  exit 1
fi

# ---------- 辅助函数 ----------
copy_file() {
  local src="$1" dest="$2"
  if [ ! -f "$src" ]; then
    echo "    警告：上游缺少 ${src#$CLONE_DIR/}" >&2
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "    跳过（已存在）: ${dest#$PROJECT_DIR/}"
    return 0
  fi
  cp -a "$src" "$dest"
  echo "    复制: ${dest#$PROJECT_DIR/}"
}

# ---------- 1. 中英文翻译（构建必需） ----------
echo "==> 恢复翻译文件..."
for lang in en cn; do
  copy_file "$CLONE_DIR/src/frontend/translate/messages.$lang.xlf" \
            "$PROJECT_DIR/src/frontend/translate/messages.$lang.xlf"
done

# ---------- 2. docker 配置（不含 markdown 文档） ----------
echo "==> 恢复 docker 配置..."
SRC_DOCKER="$CLONE_DIR/docker"
if [ -d "$SRC_DOCKER" ]; then
  while IFS= read -r -d '' f; do
    rel="${f#$SRC_DOCKER/}"
    copy_file "$f" "$PROJECT_DIR/docker/$rel"
  done < <(find "$SRC_DOCKER" -type f ! -name '*.md' -print0)
  # keep the local fix: system ffmpeg instead of bundled static binaries
  if [ -f "$PROJECT_DIR/docker/docker_builder.sh" ]; then
    sed -i 's#npm run create-release -- --skip-opt-packages=ffmpeg-static,ffprobe-static --force-opt-packages#npm run create-release#' \
      "$PROJECT_DIR/docker/docker_builder.sh"
  fi
else
  echo "    警告：上游不存在 docker/，跳过" >&2
fi

# ---------- 3. 格式诊断测试图（可选） ----------
if [ "$DO_DIAGNOSTICS" -eq 1 ]; then
  echo "==> 恢复格式诊断测试图..."
  SRC_IMG="$CLONE_DIR/src/backend/model/diagnostics/image_formats"
  if [ -d "$SRC_IMG" ]; then
    while IFS= read -r -d '' f; do
      rel="${f#$SRC_IMG/}"
      copy_file "$f" "$PROJECT_DIR/src/backend/model/diagnostics/image_formats/$rel"
    done < <(find "$SRC_IMG" -type f -print0)
  else
    echo "    警告：上游不存在 image_formats/，跳过" >&2
  fi
fi

# ---------- 4. package-lock.json（可选，需要 npm/网络） ----------
if [ "$DO_LOCKFILE" -eq 1 ]; then
  echo "==> 生成 package-lock.json..."
  ( cd "$PROJECT_DIR" && npm install --package-lock-only --ignore-scripts )
fi

echo
echo "==> 完成。上游克隆保留在 $CLONE_DIR（不需要时可删除）。"
echo "==> 下一步："
echo "    npm install          # 或 npm ci（有 package-lock.json 时）"
echo "    npx tsc --noEmit"
echo "    npm run build"
echo "==> 若 node_modules 在 /tmp/pg2-deps/node_modules，可先执行："
echo "    mv /tmp/pg2-deps/node_modules node_modules"
