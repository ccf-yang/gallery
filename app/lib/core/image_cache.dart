import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 三个独立磁盘缓存：网格缩略图要量大、全屏原图要留得住、
/// 兜底用的大尺寸预览单独一份，免得原图把缩略图挤出 LRU。
class GalleryCache {
  GalleryCache._();

  static final CacheManager thumbs = _Manager(Config(
    'pg2_thumbs',
    maxNrOfCacheObjects: 3000,
    stalePeriod: const Duration(days: 30),
  ));

  static final CacheManager previews = _Manager(Config(
    'pg2_previews',
    maxNrOfCacheObjects: 60,
    stalePeriod: const Duration(days: 30),
  ));

  static final CacheManager fullRes = _Manager(Config(
    'pg2_full_res',
    maxNrOfCacheObjects: 30,
    stalePeriod: const Duration(days: 30),
  ));

  static Future<void> clearAll() async {
    for (final manager in [thumbs, previews, fullRes]) {
      await manager.emptyCache();
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static Future<int> totalBytes() async {
    int sum = 0;
    for (final manager in [thumbs, previews, fullRes]) {
      sum += await manager.store.getCacheSize();
    }
    return sum;
  }
}

class _Manager extends CacheManager with ImageCacheManager {
  _Manager(super.config);
}

/// `Image.network` 在 Flutter 里没法带 Cookie，而 PiGallery2 的缩略图接口
/// 是鉴权的。这里走 flutter_cache_manager 发请求（header 随意加），
/// 再把落盘的文件解码成图片，等价于一个「可带 cookie 的网络图片」。
class CachedImageProvider extends ImageProvider<CachedImageProvider> {
  const CachedImageProvider({
    required this.url,
    required this.cacheManager,
    required this.headers,
  });

  final String url;
  final CacheManager cacheManager;

  /// 每次加载时才取 header：会话刚续期也能立刻生效，不用重建 provider。
  final Map<String, String> Function() headers;

  @override
  Future<CachedImageProvider> obtainKey(ImageConfiguration _) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(CachedImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: 1,
      informationCollector: () => <DiagnosticsNode>[ErrorDescription('CachedImageProvider for $url')],
    );
  }

  Future<ui.Codec> _load(CachedImageProvider key, ImageDecoderCallback decode) async {
    final completer = key.cacheManager.getFileStream(key.url, headers: key.headers());
    late FileInfo info;
    await for (final chunk in completer) {
      if (chunk is FileInfo) {
        info = chunk;
        break;
      }
    }
    final bytes = await info.file.readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is CachedImageProvider && other.url == url && other.cacheManager == cacheManager;

  @override
  int get hashCode => Object.hash(url, cacheManager);
}
