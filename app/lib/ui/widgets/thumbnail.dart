import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/image_cache.dart';

/// 带会话 cookie 的服务端图片。尺寸默认取设置里的缩略图规格（后端 320 起最省盒子算力）。
class Thumbnail extends StatefulWidget {
  const Thumbnail({
    super.key,
    required this.apiPath,
    this.size,
    this.fit = BoxFit.cover,
    this.cacheManager,
  });

  final String apiPath;
  final int? size;
  final BoxFit fit;

  /// 网格用 thumbs，全屏兜底用 previews。
  final CacheManager? cacheManager;

  @override
  State<Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  int _attempt = 0;

  @override
  void didUpdateWidget(covariant Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.apiPath != widget.apiPath || oldWidget.size != widget.size) {
      _attempt = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final manager = widget.cacheManager ?? GalleryCache.thumbs;
    // 网格永远只要缩略图；原图是 viewer 里另走一档，不从这里出。
    final url = state.thumbnailUrl(widget.apiPath, size: widget.size);

    return Image(
      // attempt 进 key：失败后重试要绕开 ImageCache 里那条失败的 record。
      key: ValueKey('$url#$_attempt'),
      image: CachedImageProvider(url: url, cacheManager: manager, headers: state.headersForImage),
      fit: widget.fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSync) {
        if (wasSync || frame != null) return child;
        return const ColoredBox(
          color: Color(0xFF141414),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stack) {
        final auth = error.toString().contains('401') || error.toString().contains('403');
        return _ThumbError(
          auth: auth,
          onRetry: () => setState(() => _attempt++),
        );
      },
    );
  }
}

class _ThumbError extends StatelessWidget {
  const _ThumbError({required this.auth, required this.onRetry});

  final bool auth;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onRetry,
      child: ColoredBox(
        color: const Color(0xFF141414),
        child: Center(
          child: Icon(
            auth ? Icons.lock_outline : Icons.broken_image_outlined,
            size: 20,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }
}
