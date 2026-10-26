#!/bin/bash
# Gallery(gallery_ios) 在 macOS VM 里出无签名 IPA。
# 由本机 tool/build_gallery.sh 编排调用；这份是母本，改动会被 scp 到 VM 的 ~/build_ipa_gallery.sh。
# 复刻 So~/拾阅 那套：flutter build --config-only 生成 xcconfig，再直接 xcodebuild，最后 zip 成 ipa。
set -euo pipefail
MARKER="$HOME/gallery_build.done"
on_exit() { [ "$1" -ne 0 ] && echo "FAILED_exit_$1" > "$MARKER"; return 0; }
trap 'on_exit $?' EXIT
. "$HOME/devenv.sh"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
cd "$HOME/src/gallery_ios"

# 从 Windows 同步过来的脚本偶尔带 CRLF，/bin/sh 会当场炸
for f in $(find . -name '*.sh' -not -path './ios/*' -not -path './build/*'); do
  if grep -q $'\r' "$f"; then sed -e 's/\r$//' "$f" > "$f.lf" && mv "$f.lf" "$f" && chmod +x "$f"; fi
done

echo "=== toolchain ==="
xcode-select -p
# 用 sed 取首行而不是 head：脚本开着 pipefail，head 提前关管道会让
# flutter/xcodebuild 收到 SIGPIPE，整个构建以 141 退出（142 那次就是这么栽的）。
xcodebuild -version | sed -n '1p'
flutter --version | sed -n '1p'

echo "--- [1/6] pub get ---"
flutter pub get

echo "--- [2/6] 校验 ios/ 工程（随源码同步过来，不再靠 flutter create 现生成） ---"
test -f ios/Runner.xcodeproj/project.pbxproj || { echo "!! 缺少 ios/ 工程"; exit 1; }
grep -Eq "^\s*platform :ios," ios/Podfile || { echo "!! Podfile 没写 platform :ios"; exit 1; }
python3 - <<'PY'
import re, glob
MIN = 15.0
def bump(m):
    return 'IPHONEOS_DEPLOYMENT_TARGET = %.1f;' % max(float(m.group(1)), MIN)
for p in glob.glob('ios/Runner.xcodeproj/project.pbxproj'):
    s = open(p).read()
    open(p, 'w').write(re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);', bump, s))
PY

echo "--- [3/6] Info.plist 关键项自检 ---"
python3 - <<'PY'
import plistlib
with open('ios/Runner/Info.plist', 'rb') as f:
    d = plistlib.load(f)
ats = d.get('NSAppTransportSecurity', {}).get('NSAllowsArbitraryLoads')
lan = d.get('NSLocalNetworkUsageDescription')
print('name=%s ATS=%s localNetwork=%s bg=%s' % (
    d.get('CFBundleDisplayName'), bool(ats), bool(lan), d.get('UIBackgroundModes')))
if not ats:
    raise SystemExit('!! Info.plist 少了 NSAllowsArbitraryLoads，局域网 http 会被 ATS 拦')
if not lan:
    raise SystemExit('!! Info.plist 少了 NSLocalNetworkUsageDescription，连不上局域网盒子')
PY

echo "--- [4/6] flutter config-only + pod install ---"
flutter build ios --release --config-only --no-codesign
( cd ios && pod install )

echo "--- [5/6] xcodebuild (unsigned) ---"
# 沙箱必须关：Flutter 的 xcode_backend.sh 要写 derivedData 之外的路径
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/ios \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "--- [6/6] 打包 ipa ---"
V=$(grep -m1 '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//' | tr -d '\r')
IPA="gallery-${V%%+*}.ipa"
APP_PATH=$(find build/ios -type d -name Runner.app | sed -n '1p')
test -n "$APP_PATH" && test -d "$APP_PATH"
rm -rf Payload && mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -qr "$IPA" Payload
rm -rf Payload
mkdir -p ~/out
cp "$IPA" ~/out/
ls -lh ~/out/
echo "BUILD_OK $V -> $HOME/out/$IPA"
echo "BUILD_OK $V -> $HOME/out/$IPA" > "$MARKER"
