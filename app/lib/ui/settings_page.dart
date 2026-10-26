import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/image_cache.dart';
import '../core/models.dart';
import 'widgets/media_grid.dart' show humanFileSize;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _cacheBytes;
  bool _clearing = false;
  final TextEditingController _note = TextEditingController();

  static const List<int> _thumbOptions = [320, 540, 1080];

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// 隐藏入口：备注框里敲进当前的 HHmm 就开启，敲错了什么都不发生。
  void _onNoteChanged(AppState state, String value) {
    final input = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (input.length != 4) return;
    if (!matchesUnlockCode(input)) return;
    _note.clear();
    state.setHiddenMode(true);
  }

  Future<void> _measure() async {
    final bytes = await GalleryCache.totalBytes();
    if (mounted) setState(() => _cacheBytes = bytes);
  }

  Future<void> _clear() async {
    setState(() => _clearing = true);
    await GalleryCache.clearAll();
    await _measure();
    if (mounted) setState(() => _clearing = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionTitle('连接'),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(state.serverUrl),
            subtitle: Text(state.guestMode ? '游客（未登录）' : '账号：${state.username}'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.account_tree_outlined),
            title: const Text('根目录默认含子目录'),
            subtitle: const Text('打开后首页直接摊平整棵树，翻页更顺，但首屏要等 search 接口'),
            value: state.defaultRecursive,
            onChanged: (value) => state.setDefaultRecursive(value),
          ),
          const _SectionTitle('出图'),
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: const Text('网格缩略图尺寸'),
            subtitle: const Text('盒子只预生成了 320，选更大会现场生成，慢且吃 CPU'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: [
                for (final size in _thumbOptions)
                  ButtonSegment(value: size, label: Text('$size')),
              ],
              selected: {state.thumbSize},
              onSelectionChanged: (selection) => state.setThumbSize(selection.first),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.sort),
            title: const Text('排序'),
            subtitle: Text(state.sortField == SortField.date ? '按拍摄时间' : '按文件名'),
            trailing: Text(state.sortDesc ? '降序' : '升序'),
          ),
          const _SectionTitle('存储'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('清除图片缓存'),
            subtitle: Text(_cacheBytes == null
                ? '统计中…'
                : '当前 ${humanFileSize(_cacheBytes!)}（原图与缩略图都算在内）'),
            trailing: _clearing
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _cacheBytes == 0 ? null : _clear,
                  ),
          ),
          const _SectionTitle('账户'),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            subtitle: const Text('清掉钥匙串里的会话与密码'),
            onTap: () async {
              await state.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 20),
          const _SectionTitle('备注'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _note,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: '输入文字…',
                helperText: '随手记点什么，比如今天的天气。',
                filled: true,
                fillColor: const Color(0xFF151515),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _onNoteChanged(state, value),
            ),
          ),
          if (state.hiddenMode) ...[
            const _SectionTitle('隐藏模式'),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('退出隐藏模式'),
              subtitle: const Text('恢复成只看 gallery 目录'),
              onTap: () => state.setHiddenMode(false),
            ),
          ],
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Gallery · PiGallery2 客户端\n仅本机部署使用',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.white24),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64B5FF)),
      ),
    );
  }
}
