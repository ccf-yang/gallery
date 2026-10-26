import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/image_cache.dart';
import '../core/models.dart';
import 'widgets/media_grid.dart';
import 'widgets/video_view.dart';

/// 全屏看图 / 播视频。横向划动在当前这份列表里翻页。
class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key, required this.media, required this.initialIndex});

  final List<MediaItem> media;
  final int initialIndex;

  static Route<void> open({required List<MediaItem> media, required int initialIndex}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => ViewerPage(media: media, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late final PageController _pager;
  late int _index;
  bool _chrome = true;

  // ---- 下滑退出 ----
  // 这里用 Listener 而不是 GestureDetector：Listener 不进手势竞技场，
  // 既不会抢 PhotoView 的缩放平移，也不会抢 PageView 的横滑翻页。
  int _pointers = 0;
  int? _trackedPointer;
  Offset? _downAt;
  double _dragY = 0;
  bool _dragging = false; // 手指还按着：跟手直出，不带动画
  bool _swipingDown = false; // 已判定为下滑退出
  bool _atRest = true; // 图片处在适配位（没放大）才允许下滑关页

  // 轻推就走：判定门槛压到 10 像素，关页只要屏高 10%，
  // 或者干脆往下甩一把（速度够快就不用拖距离）。
  static const double _swipeStart = 14;
  static const double _closeFraction = 0.10;
  static const double _flingVelocity = 700; // 像素/秒

  Duration? _lastMoveAt;
  double _lastMoveDy = 0;
  double _velocityY = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.media.length - 1);
    _pager = PageController(initialPage: _index);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pager.dispose();
    super.dispose();
  }

  void _toggleChrome() => setState(() => _chrome = !_chrome);

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
      _dragY = 0;
      _swipingDown = false;
      _atRest = true;
      _velocityY = 0;
      _lastMoveAt = null;
    });
  }

  /// 视频控制条那一圈是进度条和按钮的地盘，竖向拖动不该当成下滑退出。
  bool _swipeZoneAllowed(Offset where) {
    if (!_chrome || !widget.media[_index].isVideo) return true;
    final Size size = MediaQuery.sizeOf(context);
    final double topInset = MediaQuery.paddingOf(context).top;
    if (where.dy > size.height - 120) return false;
    if (where.dy < topInset + 60) return false;
    return true;
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers++;
    // 第二根手指落下＝大概率在捏合，这次下滑作废；放大状态下也不接管。
    if (_pointers > 1 || !_atRest || !_swipeZoneAllowed(event.position)) {
      _abandonSwipe();
      return;
    }
    _trackedPointer = event.pointer;
    _downAt = event.position;
    _dragging = true;
    _swipingDown = false;
    _velocityY = 0;
    _lastMoveAt = null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _trackedPointer) return;
    final Offset? start = _downAt;
    if (start == null || !_dragging) return;

    final double dy = event.position.dy - start.dy;
    final double dx = (event.position.dx - start.dx).abs();

    // 顺手估一下纵向速度（一阶低通滤波），松手时用来认「甩一下」。
    // 注意 PointerEvent.timeStamp 是 Duration（自开机起算），不是 DateTime。
    final Duration now = event.timeStamp;
    final Duration? previous = _lastMoveAt;
    if (previous != null) {
      final int ms = (now - previous).inMilliseconds;
      if (ms > 0) {
        final double instant = (dy - _lastMoveDy) / ms * 1000;
        _velocityY = _velocityY * 0.5 + instant * 0.5;
      }
    }
    _lastMoveAt = now;
    _lastMoveDy = dy;

    if (!_swipingDown) {
      // 只认「明显向下」，横滑和斜划留给 PageView 翻页。
      if (dy < _swipeStart || dy < dx * 1.4) return;
      _swipingDown = true;
      if (_chrome) _toggleChrome();
      return;
    }
    final double shift = dy - _swipeStart;
    setState(() => _dragY = shift < 0 ? 0 : shift);
  }

  void _onPointerUp(PointerUpEvent event) => _finishPointer(event.pointer);

  void _onPointerCancel(PointerCancelEvent event) => _finishPointer(event.pointer);

  void _finishPointer(int pointer) {
    _pointers = _pointers > 0 ? _pointers - 1 : 0;
    if (pointer != _trackedPointer) {
      _abandonSwipe();
      return;
    }
    _dragging = false;
    _trackedPointer = null;
    _downAt = null;
    if (!_swipingDown) return;
    _swipingDown = false;

    final double height = MediaQuery.sizeOf(context).height;
    final bool flung = _velocityY > _flingVelocity;
    if (_dragY >= height * _closeFraction || flung) {
      // 先甩出屏幕再关页，收尾有个动作而不是硬切。
      setState(() => _dragY = height);
      Future<void>.delayed(const Duration(milliseconds: 160), () {
        if (mounted) Navigator.of(context).maybePop();
      });
      return;
    }
    setState(() => _dragY = 0);
  }

  /// 放弃这次下滑：指针已经不是跟的那根、或中途开始捏合。
  void _abandonSwipe() {
    _downAt = null;
    _trackedPointer = null;
    _dragging = false;
    _velocityY = 0;
    if (!_swipingDown) return;
    _swipingDown = false;
    setState(() => _dragY = 0);
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    if (media.isEmpty) {
      return Scaffold(backgroundColor: Colors.black, body: const Center(child: Text('没有内容')));
    }
    final current = media[_index];
    final double screenHeight = MediaQuery.sizeOf(context).height;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              // 跟手期间零延迟直出，松手回弹/甩出才走动画。
              duration: _dragging ? Duration.zero : const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              tween: Tween<double>(begin: 0, end: _dragY),
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, value),
                child: Transform.scale(
                  scale: 1 - (value / screenHeight).clamp(0.0, 1.0) * 0.12,
                  child: child,
                ),
              ),
              child: PageView.builder(
                controller: _pager,
                onPageChanged: _onPageChanged,
                itemCount: media.length,
                itemBuilder: (context, index) {
                  final item = media[index];
                  // 只给相邻页做预热，中间页保持「划到才下载」。
                  if (item.isVideo) {
                    return VideoStage(
                      media: item,
                      controlsVisible: _chrome,
                      onToggleControls: _toggleChrome,
                      // 放大后纵向平移归 InteractiveViewer，下滑退出让路。
                      onZoomChanged: (zoomed) => _atRest = !zoomed,
                    );
                  }
                  return _PhotoStage(
                    media: item,
                    onScaleStateChanged: (state) {
                      // zoomedIn/covering/originalSize 时纵向平移归 PhotoView。
                      _atRest = state == PhotoViewScaleState.initial;
                    },
                  );
                },
              ),
            ),
            IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                opacity: _chrome ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Column(
                  children: [
                    _TopBar(
                      title: current.name,
                      counter: '${_index + 1}/${media.length}',
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    _BottomInfo(media: current),
                  ],
                ),
              ),
            ),
            // 只声明 onTap：这样点击能收起遮罩，横向划动仍然交给 PageView。
            Positioned.fill(
              child: IgnorePointer(
                // 视频且控制条正显示时让路，不然这一层会跟暂停、±10s、
                // 进度条抢 tap，表现就是「点了屏幕中央按钮还杵在那」。
                ignoring: _chrome && current.isVideo,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleChrome,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.counter, required this.onBack});

  final String title;
  final String counter;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.close, color: Colors.white)),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(counter, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _BottomInfo extends StatelessWidget {
  const _BottomInfo({required this.media});

  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (media.width > 0 && media.height > 0) '${media.width}×${media.height}',
      humanFileSize(media.fileSize),
      '${media.createdAt.year}-${_two(media.createdAt.month)}-${_two(media.createdAt.day)} '
          '${_two(media.createdAt.hour)}:${_two(media.createdAt.minute)}',
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 14, top: 22),
      child: Column(
        children: [
          Text(
            parts.join('  ·  '),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              media.apiPath,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// 图片分三档退让：原图 → 服务端 1080 预览 → 320 缩略图。
/// RAW（DNG/ARW/TIFF…）iOS 解不开，直接从 1080 预览开始。
class _PhotoStage extends StatefulWidget {
  const _PhotoStage({required this.media, this.onScaleStateChanged});

  final MediaItem media;

  /// 把缩放档位变化透给上层，上层据此决定「下滑退出」要不要接管手势。
  final ValueChanged<PhotoViewScaleState>? onScaleStateChanged;

  @override
  State<_PhotoStage> createState() => _PhotoStageState();
}

class _PhotoStageState extends State<_PhotoStage> {
  int _stage = 0;

  static const int _maxStage = 2;

  @override
  void initState() {
    super.initState();
    if (widget.media.isRawPhoto) _stage = 1;
  }

  ImageProvider _provider(AppState state) {
    switch (_stage) {
      case 0:
        return CachedImageProvider(
          url: state.mediaUrl(widget.media.apiPath),
          cacheManager: GalleryCache.fullRes,
          headers: state.headersForImage,
        );
      case 1:
        return CachedImageProvider(
          url: state.thumbnailUrl(widget.media.apiPath, size: 1080),
          cacheManager: GalleryCache.previews,
          headers: state.headersForImage,
        );
      default:
        return CachedImageProvider(
          url: state.thumbnailUrl(widget.media.apiPath, size: 320),
          cacheManager: GalleryCache.thumbs,
          headers: state.headersForImage,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return PhotoView(
      // stage 进 key：换档要绕开上一次失败的缓存。
      key: ValueKey('${widget.media.apiPath}#$_stage'),
      imageProvider: _provider(state),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      gaplessPlayback: true,
      scaleStateChangedCallback: (scaleState) {
        if (mounted) widget.onScaleStateChanged?.call(scaleState);
      },
      loadingBuilder: (context, event) => _Progress(chunk: event),
      errorBuilder: (context, error, stackTrace) {
        if (_stage < _maxStage) {
          // 自动降档重试一次。
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _stage++);
          });
          return const _Progress();
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.white30),
              const SizedBox(height: 10),
              const Text('这张图打不开', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: () => setState(() => _stage = widget.media.isRawPhoto ? 1 : 0),
                child: const Text('重试'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({this.chunk});

  final ImageChunkEvent? chunk;

  @override
  Widget build(BuildContext context) {
    final event = chunk;
    double? value;
    if (event != null && (event.expectedTotalBytes ?? 0) > 0) {
      value = event.cumulativeBytesLoaded / event.expectedTotalBytes!;
    }
    return Center(
      child: SizedBox(
        width: 120,
        child: value == null
            ? const CircularProgressIndicator()
            : LinearProgressIndicator(value: value),
      ),
    );
  }
}
