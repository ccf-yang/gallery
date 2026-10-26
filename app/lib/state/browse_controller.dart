import 'package:flutter/foundation.dart';

import '../core/app_state.dart';
import '../core/models.dart';

enum BrowseMode {
  /// 只看当前目录：子目录 + 本级媒体。
  folder,

  /// 走 search 接口把子树摊平，只看媒体。
  flatten,

  /// 全文检索结果。
  search,
}

/// 数字按数值比较，`2.jpg` 排在 `10.jpg` 前面；中文按码位排。
int naturalCompare(String a, String b) {
  final ai = RegExp(r'\d+').allMatches(a).toList();
  final bi = RegExp(r'\d+').allMatches(b).toList();
  final limit = ai.length < bi.length ? ai.length : bi.length;
  for (var i = 0; i < limit; i++) {
    final an = int.parse(ai[i].group(0)!);
    final bn = int.parse(bi[i].group(0)!);
    if (an != bn) return an.compareTo(bn);
    final preA = a.substring(i == 0 ? 0 : ai[i - 1].end, ai[i].start);
    final preB = b.substring(i == 0 ? 0 : bi[i - 1].end, bi[i].start);
    final cmp = preA.compareTo(preB);
    if (cmp != 0) return cmp;
  }
  if (ai.length != bi.length) return ai.length.compareTo(bi.length);
  return a.compareTo(b);
}

/// 一个浏览/搜索结果屏幕的数据源。屏幕持有自己的实例，
/// 返回上层时不会互相踩缓存。
class BrowseController extends ChangeNotifier {
  BrowseController({
    required this.state,
    required this.mode,
    this.path = '',
    this.query = '',
  }) : _recursive = mode == BrowseMode.flatten;

  final AppState state;
  final BrowseMode mode;

  /// 目录模式下的目录路径；摊平模式下是子树根。
  final String path;
  final String query;

  GalleryListing _listing = GalleryListing.empty;
  bool _loading = true;
  String? _error;
  bool _recursive;
  int _generation = 0;

  bool get loading => _loading;
  String? get error => _error;
  bool get recursive => _recursive;
  GalleryListing get listing => _listing;

  SortField get sortField => state.sortField;
  bool get sortDesc => state.sortDesc;

  /// 服务端把结果截断了（`Search.maxMediaResult`）。
  bool get overflow => _listing.overflow;

  /// 摊平与检索模式没有「本级子目录」可看。
  bool get showsFolders => mode == BrowseMode.folder && !_recursive;

  String get headline {
    switch (mode) {
      case BrowseMode.folder:
        if (path.isEmpty) return '全部';
        return path.split('/').where((e) => e.isNotEmpty).last;
      case BrowseMode.flatten:
        return path.isEmpty ? '全部（含子目录）' : '$path（含子目录）';
      case BrowseMode.search:
        return '搜索：$query';
    }
  }

  /// 面包屑用的父路径，根目录返回 null。
  String? get parentPath {
    if (mode != BrowseMode.folder || path.isEmpty) return null;
    final segments = path.split('/').where((e) => e.isNotEmpty).toList();
    if (segments.length <= 1) return '';
    segments.removeLast();
    return segments.join('/');
  }

  Future<void> load() async {
    final generation = ++_generation;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final GalleryListing result;
      if (mode == BrowseMode.folder && !_recursive) {
        result = await state.listDirectory(path);
      } else if (mode == BrowseMode.folder) {
        result = await state.flattenDirectory(path);
      } else if (mode == BrowseMode.flatten) {
        result = await state.flattenDirectory(path);
      } else {
        result = await state.searchAll(query);
      }
      if (generation != _generation) return;
      _listing = result;
      _error = null;
    } on ApiFailure catch (e) {
      if (generation != _generation) return;
      _error = e.isAuth ? '登录已失效，重新登录即可' : e.message;
    } catch (e) {
      if (generation != _generation) return;
      _error = '加载失败：$e';
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setRecursive(bool value) async {
    if (_recursive == value) return;
    _recursive = value;
    notifyListeners();
    await load();
  }

  Future<void> setSort(SortField field) async {
    if (field == state.sortField) {
      await state.setSort(field, !state.sortDesc);
    } else {
      await state.setSort(field, state.sortDesc);
    }
    notifyListeners();
  }

  List<FolderItem> get folders {
    final list = List<FolderItem>.from(_listing.folders);
    list.sort((a, b) {
      final int cmp;
      if (state.sortField == SortField.name) {
        cmp = naturalCompare(a.name, b.name);
      } else {
        cmp = a.lastModifiedMs.compareTo(b.lastModifiedMs);
      }
      return state.sortDesc ? -cmp : cmp;
    });
    return list;
  }

  List<MediaItem> get media {
    final list = List<MediaItem>.from(_listing.media);
    list.sort((a, b) {
      final int cmp;
      if (state.sortField == SortField.name) {
        cmp = naturalCompare(a.name, b.name);
      } else {
        cmp = a.createdMs.compareTo(b.createdMs);
      }
      return state.sortDesc ? -cmp : cmp;
    });
    return list;
  }

  bool get isEmpty => !_loading && _error == null && folders.isEmpty && media.isEmpty;

  @override
  void dispose() {
    // 让在途请求的结果作废，避免 dispose 后 notifyListeners。
    _generation++;
    super.dispose();
  }
}
