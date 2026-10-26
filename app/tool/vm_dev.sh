#!/usr/bin/env bash
# 本机 ↔ macOS VM 的开发回路：推源码 → pub get → flutter analyze。
# 本机没有 Flutter/Dart，analyze 只能借 VM 的 SDK 跑；出包不归这里管
# （iOS 走 GitHub Actions 的 build-ios.yml，或本机构建中心一键出包上盒子）。
# 用法: bash tool/vm_dev.sh
set -euo pipefail

# 工程根 = 本脚本所在目录的上一层，仓库搬到哪都不用改。
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_HOST="192.168.17.129"
VM_USER="yang"
KEY="$HOME/.ssh/id_ed25519_macvm"
SSH="ssh -i $KEY -o IdentitiesOnly=yes -o ConnectTimeout=8 $VM_USER@$VM_HOST"
SCP="scp -i $KEY -o IdentitiesOnly=yes -q"
# 单独一个目录：和构建中心用的 ~/src/gallery 隔开，analyze 不会跟构建抢同一份 build/。
REMOTE_DIR="src/gallery_dev"

cd "$ROOT"
echo "-- [1/3] 打包源码（$ROOT，排除 build/Pods/android/产物）"
tar czf /tmp/gallery-dev-src.tgz \
  --exclude='.dart_tool' --exclude='build' --exclude='android' \
  --exclude='ios/Pods' --exclude='ios/.symlinks' --exclude='ios/Flutter/ephemeral' \
  --exclude='*.ipa' --exclude='*.apk' --exclude='ios/Podfile.lock' \
  .
$SCP /tmp/gallery-dev-src.tgz "$VM_USER@$VM_HOST:dl/gallery-dev-src.tgz"

echo "-- [2/3] 解包到 VM ~/$REMOTE_DIR"
$SSH "mkdir -p ~/$REMOTE_DIR && tar xzf ~/dl/gallery-dev-src.tgz -C ~/$REMOTE_DIR"

echo "-- [3/3] pub get + analyze"
$SSH "cd ~/$REMOTE_DIR && . ~/devenv.sh >/dev/null 2>&1 && flutter pub get >/dev/null && flutter analyze" |
  sed 's/^/   /'
