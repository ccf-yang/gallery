import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/models.dart';
import '../../state/browse_controller.dart';
import 'viewer_page.dart';
import 'widgets/media_grid.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({
    super.key,
    required this.mode,
    this.path = '',
    this.query = '',
  });

  final BrowseMode mode;
  final String path;
  final String query;

  static Route<void> openFolder(FolderItem folder) => MaterialPageRoute(
        builder: (_) => BrowsePage(mode: BrowseMode.folder, path: folder.apiPath),
      );

  static Route<void> openSearch(String query) => MaterialPageRoute(
        builder: (_) => BrowsePage(mode: BrowseMode.search, query: query),
      );

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  late final BrowseController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BrowseController(
      state: context.read<AppState>(),
      mode: widget.mode,
      path: widget.path,
      query: widget.query,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openMedia(List<MediaItem> list, int index) {
    Navigator.of(context).push(ViewerPage.open(media: list, initialIndex: index));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BrowseController>.value(
      value: _controller,
      child: Consumer<BrowseController>(
        builder: (context, controller, _) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(controller.headline),
            actions: [
              if (controller.mode == BrowseMode.folder)
                IconButton(
                  tooltip: controller.recursive ? '只看本级' : '含子目录',
                  icon: Icon(controller.recursive ? Icons.account_tree_outlined : Icons.folder_outlined),
                  onPressed: () => controller.setRecursive(!controller.recursive),
                ),
              IconButton(
                tooltip: '排序',
                icon: const Icon(Icons.sort),
                onPressed: () => _showSortSheet(context, controller),
              ),
              IconButton(
                tooltip: '搜索',
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(context),
              ),
              IconButton(
                tooltip: '设置',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ),
          body: _Body(controller: controller, onOpenMedia: _openMedia),
        ),
      ),
    );
  }

  Future<void> _showSortSheet(BuildContext context, BrowseController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final field in SortField.values)
              ListTile(
                leading: Icon(field == SortField.date ? Icons.schedule : Icons.sort_by_alpha),
                title: Text(field == SortField.date ? '按时间' : '按文件名'),
                trailing: controller.sortField == field
                    ? Icon(controller.sortDesc ? Icons.arrow_downward : Icons.arrow_upward)
                    : null,
                onTap: () {
                  controller.setSort(field);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSearchDialog(BuildContext context) async {
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('搜索图库'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: '文件名或关键字'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
    if (query == null || query.trim().isEmpty) return;
    if (!context.mounted) return;
    Navigator.of(context).push(BrowsePage.openSearch(query.trim()));
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller, required this.onOpenMedia});

  final BrowseController controller;
  final void Function(List<MediaItem> media, int index) onOpenMedia;

  @override
  Widget build(BuildContext context) {
    if (controller.loading && controller.listing.totalCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null && controller.listing.totalCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: controller.load,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.isEmpty) {
      return const Center(child: Text('这里没有内容', style: TextStyle(color: Colors.white38)));
    }

    final folders = controller.folders;
    final media = controller.media;
    final crossAxisCount = gridCrossAxisCount(MediaQuery.sizeOf(context).width);
    final state = context.read<AppState>();

    return RefreshIndicator(
      onRefresh: controller.load,
      child: CustomScrollView(
        slivers: [
          if (controller.overflow)
            const SliverToBoxAdapter(
              child: _OverflowBanner(),
            ),
          if (controller.showsFolders && folders.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FolderTile(
                    folder: folders[index],
                    onTap: () => Navigator.of(context).push(BrowsePage.openFolder(folders[index])),
                  ),
                  childCount: folders.length,
                ),
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.all(2),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => MediaTile(
                  media: media[index],
                  onTap: () => onOpenMedia(media, index),
                ),
                childCount: media.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _Footer(
              text: '${humanCount(media.length)} 张'
              '${controller.showsFolders && folders.isNotEmpty ? ' · ${folders.length} 个目录' : ''}'
              ' · ${state.serverUrl.replaceAll('http://', '')}',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverflowBanner extends StatelessWidget {
  const _OverflowBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2C12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '结果过多，服务端已截断。进子目录或搜索可以缩小范围。',
        style: TextStyle(fontSize: 12, color: Color(0xFFFFC46B)),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white30)),
      ),
    );
  }
}
