#!/usr/bin/env bash
# gallery_ios 本机 ↔ VM 的开发回路：推源码 → (首次) flutter create 生成 ios/ → pub get → analyze
# 用法:
#   bash tool/vm_dev.sh            # 同步 + analyze
#   bash tool/vm_dev.sh --scaffold # 额外做 flutter create 并把 ios/ 拉回本机
set -euo pipefail

REPO="/g/pi/qcode/gallery_ios"
VM_HOST="192.168.17.129"
VM_USER="yang"
KEY="$HOME/.ssh/id_ed25519_macvm"
SSH="ssh -i $KEY -o IdentitiesOnly=yes -o ConnectTimeout=8 $VM_USER@$VM_HOST"
SCP="scp -i $KEY -o IdentitiesOnly=yes -q"
REMOTE_DIR="~/src/gallery_ios"

SCAFFOLD=0
[ "${1:-}" = "--scaffold" ] && SCAFFOLD=1

cd "$REPO"
echo "-- [1/4] 打包源码（排除 build/Pods/产物）"
tar czf /tmp/gallery-ios-src.tgz \
  --exclude='.dart_tool' --exclude='build' --exclude='ios/Pods' \
  --exclude='ios/.symlinks' --exclude='ios/Flutter/ephemeral' \
  --exclude='*.ipa' --exclude='ios/Podfile.lock' \
  .
$SCP /tmp/gallery-ios-src.tgz "$VM_USER@$VM_HOST:dl/gallery-ios-src.tgz"

echo "-- [2/4] 解包到 VM"
$SSH "mkdir -p $REMOTE_DIR && tar xzf ~/dl/gallery-ios-src.tgz -C $REMOTE_DIR"

if [ "$SCAFFOLD" = 1 ]; then
  echo "-- [3/4] flutter create --platforms=ios（只在首次需要）"
  $SSH "cd $REMOTE_DIR && . ~/devenv.sh >/dev/null 2>&1 && \
    flutter config --no-enable-swift-package-manager >/dev/null && \
    flutter create --platforms=ios --org com.ccf --project-name gallery_ios . && \
    rm -f test/widget_test.dart"
fi

echo "-- [3/4] pub get + analyze"
$SSH "cd $REMOTE_DIR && . ~/devenv.sh >/dev/null 2>&1 && flutter pub get && flutter analyze" |
  sed 's/^/   /'

if [ "$SCAFFOLD" = 1 ]; then
  echo "-- [4/4] 把生成的 ios/ 拉回本机"
  $SSH "cd $REMOTE_DIR && tar czf ~/ios-scaffold.tgz --exclude='Pods' --exclude='.symlinks' --exclude='Flutter/ephemeral' ios"
  $SCP "$VM_USER@$VM_HOST:~/ios-scaffold.tgz" /tmp/ios-scaffold.tgz
  tar xzf /tmp/ios-scaffold.tgz -C "$REPO"
  echo "   ios/ 已落到 $REPO/ios"
fi
