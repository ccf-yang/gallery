import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../core/platform_notes.dart';

/// 全屏播一段视频。这里只负责「当前这一页」的视频，
/// 划走即销毁，PageView 默认不保留离屏页面，播放器不会堆积。
///
/// 控制条的显隐由外层（ViewerPage 的遮罩状态）驱动，自己不再留一份
/// `_showControls`：两份状态各点各的，会出现「点了屏幕中央按钮还在」。
class VideoStage extends StatefulWidget {
  const VideoStage({
    super.key,
    required this.media,
    required this.controlsVisible,
    required this.onToggleControls,
    this.onZoomChanged,
  });

  final MediaItem media;
  final bool controlsVisible;
  final VoidCallback onToggleControls;

  /// 双指放大/缩回时告诉上层，好让「下滑退出」让位给画面平移。
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<VideoStage> {
  VideoPlayerController? _controller;
  String? _error;
  bool _initializing = true;
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
    _init();
  }

  /// InteractiveViewer 的变换矩阵变化，取轴向最大缩放判断有没有被放大。
  void _onTransformChanged() {
    final bool zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    _zoomed = zoomed;
    widget.onZoomChanged?.call(zoomed);
  }

  Future<void> _init() async {
    final state = context.read<AppState>();
    // 视频接口本身支持 Range（已实测 206），直接给 AVPlayer 带 cookie。
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(state.mediaUrl(widget.media.apiPath)),
      httpHeaders: state.headers,
    );
    try {
      await controller.initialize().timeout(const Duration(seconds: 45));
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      controller.addListener(_onTick);
      await controller.play();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = PlatformNotes.videoInitFailed(e);
      });
    }
  }

  void _onTick() {
    if (!mounted) return;
    if (_controller == null) return;
    // 进度、缓冲、播放/暂停图标都靠这个回调刷新。
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    super.dispose();
  }

  Future<void> _seekRelative(Duration delta) async {
    final controller = _controller;
    if (controller == null) return;
    final target = controller.value.position + delta;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > controller.value.duration ? controller.value.duration : target);
    await controller.seekTo(clamped);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 40, color: Colors.white30),
              const SizedBox(height: 12),
              Text(_error ?? '无法播放', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: () {
                setState(() {
                  _initializing = true;
                  _error = null;
                });
                _init();
              }, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final value = controller.value;

    return GestureDetector(
      // 控制条收起时不注册 tap，把点击让给外层的「重新唤出遮罩」层，
      // 否则两层都在手势竞技场里，点一下会切两回。
      onTap: widget.controlsVisible ? widget.onToggleControls : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 双指放大画面。控制条是 Stack 的兄弟节点，不参与变换，
          // 缩放时暂停键、±10s、进度条都还在原位。
          InteractiveViewer(
            transformationController: _transform,
            minScale: 1,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(140),
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0 ? 1 : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          if (widget.controlsVisible) ...[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent, Colors.black87],
                  stops: [0, 0.5, 1],
                ),
              ),
              child: SizedBox.expand(),
            ),
            // 中间一行：退 10 秒 / 暂停继续 / 进 10 秒，省得每次都拖进度条。
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 34,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () => _seekRelative(const Duration(seconds: -10)),
                  ),
                  const SizedBox(width: 28),
                  IconButton(
                    iconSize: 62,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
                    icon: Icon(
                      value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Colors.white,
                    ),
                    onPressed: () => value.isPlaying ? controller.pause() : controller.play(),
                  ),
                  const SizedBox(width: 28),
                  IconButton(
                    iconSize: 34,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () => _seekRelative(const Duration(seconds: 10)),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF64B5FF),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_fmt(value.position)} / ${_fmt(value.duration)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = duration.inHours;
    final m = two(duration.inMinutes.remainder(60));
    final s = two(duration.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
