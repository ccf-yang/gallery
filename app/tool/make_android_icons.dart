// 安卓启动图标：拿 iOS 那套切图剩下的 master-clean.png，出 mipmap-* 五档密度。
//
// 用法（在 VM 上跑，本机没有 Dart）：
//   dart run tool/make_android_icons.dart assets/icon/master-clean.png
//
// 安卓桌面图标是方图直接铺，不需要像 iOS 那样留圆角遮罩；
// adaptive icon（前景/背景分层）也一并出，Android 8.0+ 用的是那一套。
import 'dart:io';

import 'package:image/image.dart' as img;

/// 密度 -> 启动图标边长（px）。
const Map<String, int> _densities = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

/// adaptive icon 前景图层：108dp 画布，安全区只有中间 72dp，所以内容缩到 2/3。
const Map<String, int> _foreground = {
  'mdpi': 108,
  'hdpi': 162,
  'xhdpi': 216,
  'xxhdpi': 324,
  'xxxhdpi': 432,
};

const String _res = 'android/app/src/main/res';

void main(List<String> args) {
  final srcPath = args.isEmpty ? 'assets/icon/master-clean.png' : args.first;
  final src = File(srcPath);
  if (!src.existsSync()) {
    stderr.writeln('!! 找不到源图 $srcPath（先跑 make_icons.dart 生成）');
    exit(1);
  }
  final master = img.decodePng(src.readAsBytesSync());
  if (master == null) {
    stderr.writeln('!! 解不开 PNG $srcPath');
    exit(1);
  }
  if (master.width != master.height) {
    stderr.writeln('!! 源图必须是正方形，当前 ${master.width}x${master.height}');
    exit(1);
  }

  var written = 0;
  for (final entry in _densities.entries) {
    final px = entry.value;
    final out = img.copyResize(master, width: px, height: px, interpolation: img.Interpolation.cubic);
    final dir = Directory('$_res/mipmap-${entry.key}');
    dir.createSync(recursive: true);
    File('${dir.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(out));
    written++;
    stdout.writeln('  ${px}px  mipmap-${entry.key}/ic_launcher.png');
  }

  // adaptive icon：背景走 @color，前景是透明画布上居中的图。
  // 108dp 画布的安全区是中间 72dp（占 2/3），单边留 18% 正好贴进圆形遮罩里。
  for (final entry in _foreground.entries) {
    final px = entry.value;
    final inset = (px * 0.18).round();
    final side = px - inset * 2;
    final glyph = img.copyResize(
      master,
      width: side,
      height: side,
      interpolation: img.Interpolation.cubic,
    );
    final canvas = img.Image(width: px, height: px);
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        final p = glyph.getPixel(x, y);
        canvas.setPixelRgba(inset + x, inset + y, p.r, p.g, p.b, p.a);
      }
    }
    final dir = Directory('$_res/mipmap-${entry.key}');
    dir.createSync(recursive: true);
    File('${dir.path}/ic_launcher_foreground.png').writeAsBytesSync(img.encodePng(canvas));
    written++;
    stdout.writeln('  ${px}px  mipmap-${entry.key}/ic_launcher_foreground.png');
  }

  _writeAdaptiveXmls();
  stdout.writeln('共 $written 张 -> $_res');
}

void _writeAdaptiveXmls() {
  final dir = Directory('$_res/values');
  dir.createSync(recursive: true);
  File('${dir.path}/ic_launcher_background.xml').writeAsStringSync(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<resources>\n'
    '    <color name="ic_launcher_background">#101012</color>\n'
    '</resources>\n',
  );

  final mipmap = Directory('$_res/mipmap-anydpi-v26');
  mipmap.createSync(recursive: true);
  for (final name in ['ic_launcher', 'ic_launcher_round']) {
    File('${mipmap.path}/$name.xml').writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
      '    <background android:drawable="@color/ic_launcher_background"/>\n'
      '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
      '</adaptive-icon>\n',
    );
  }
}
