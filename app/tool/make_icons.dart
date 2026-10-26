// 图标切图：抹掉生成器右下角的「Qoder AI生成」水印，再按 Contents.json 出全套尺寸。
//
// 用法（在 VM 上跑，本机没有 Dart）：
//   dart run tool/make_icons.dart assets/icon/master-b.png
//
// 水印用「按行线性插值」抹：背景是平滑渐变，同一行左右两端取样填中间，肉眼看不出接缝。
// 尺寸表不写死，直接读 asset catalog 的 Contents.json，模板换了也不用改这里。
import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// 水印包围盒，按源图比例取（留了余量，别缩）。
/// 底边要到 1.0：「Qoder AI生成」压在最下面一行，只到 0.97 会留半截。
const double _wmLeft = 0.78;
const double _wmTop = 0.86;
const double _wmRight = 0.972;
const double _wmBottom = 1.0;
const int _anchorPad = 28;

const String _catalog = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

void main(List<String> args) {
  final srcPath = args.isEmpty ? 'assets/icon/master.png' : args.first;
  final src = File(srcPath);
  if (!src.existsSync()) {
    stderr.writeln('!! 找不到源图 $srcPath');
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
  if (master.width < 1024) {
    stderr.writeln('!! 源图太小（${master.width}px），1024 槽位会糊');
    exit(1);
  }

  _killWatermark(master);
  final clean = img.encodePng(master);
  File('assets/icon/master-clean.png').writeAsBytesSync(clean);
  stdout.writeln(
      '水印已抹: assets/icon/master-clean.png (${master.width}x${master.height} alpha=${master.hasAlpha})');

  final manifest =
      jsonDecode(File('$_catalog/Contents.json').readAsStringSync()) as Map<String, dynamic>;
  final entries = (manifest['images'] as List).cast<Map<String, dynamic>>();
  final done = <int>{};
  for (final entry in entries) {
    final name = entry['filename'] as String?;
    if (name == null) continue;
    final points = double.parse((entry['size'] as String).split('x').first);
    final scale = double.parse((entry['scale'] as String).replaceAll('x', ''));
    final px = (points * scale).round();
    final out = img.copyResize(master, width: px, height: px, interpolation: img.Interpolation.cubic);
    File('$_catalog/$name').writeAsBytesSync(img.encodePng(out));
    done.add(px);
    stdout.writeln('  ${px}px  $name');
  }
  stdout.writeln('共 ${entries.length} 个槽位、${done.length} 种尺寸 -> $_catalog');
}

void _killWatermark(img.Image image) {
  final w = image.width;
  final h = image.height;
  final x0 = (w * _wmLeft).round();
  final x1 = (w * _wmRight).round().clamp(0, w - 1);
  final y0 = (h * _wmTop).round();
  final y1 = (h * _wmBottom).round().clamp(0, h - 1);
  final left = (x0 - _anchorPad).clamp(0, w - 1);
  final right = (x1 + _anchorPad).clamp(0, w - 1);
  final span = (right - left).toDouble();

  for (var y = y0; y <= y1; y++) {
    final a = image.getPixel(left, y);
    final b = image.getPixel(right, y);
    final ar = a.r.toDouble(), ag = a.g.toDouble(), ab = a.b.toDouble();
    final br = b.r.toDouble(), bg = b.g.toDouble(), bb = b.b.toDouble();
    for (var x = x0; x <= x1; x++) {
      final t = (x - left) / span;
      image.setPixelRgba(
        x,
        y,
        (ar + (br - ar) * t).round().clamp(0, 255),
        (ag + (bg - ag) * t).round().clamp(0, 255),
        (ab + (bb - ab) * t).round().clamp(0, 255),
        255,
      );
    }
  }
}
