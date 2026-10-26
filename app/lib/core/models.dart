import 'package:path/path.dart' as p;

/// 后端支持的视频扩展名，取自 PiGallery2 的
/// `Config.Media.Video.supportedFormats + supportedFormatsWithTranscoding`。
const Set<String> _videoExtensions = {
  'mp4', 'webm', 'ogv', 'ogg',
  'avi', 'mkv', 'mov', 'wmv', 'flv', 'mts', 'm2ts', 'mpg', '3gp', 'm4v',
  'vob', 'divx', 'xvid', 'ts',
};

/// 只能靠服务端 sharp 转码才能看的原格式：原始文件在 iOS 上多半解不开，
/// 全屏时要退回到服务端生成的大尺寸缩略图。
const Set<String> _rawExtensions = {
  'dng', 'arw', 'cr2', 'cr3', 'nef', 'raf', 'rw2', 'orf', 'pgm', 'tiff', 'tif',
};

/// 拼出后端认识的相对路径：去掉 `./` 前缀和多余的斜杠。
String joinApiPath(String parent, String name) {
  String clean(String value) => value
      .trim()
      .replaceAll(RegExp(r'^\./'), '')
      .replaceAll(RegExp(r'^/+'), '')
      .replaceAll(RegExp(r'/+$'), '');
  final a = clean(parent);
  final b = clean(name);
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a/$b';
}

class MediaItem {
  const MediaItem({
    required this.name,
    required this.apiPath,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.createdMs,
  });

  final String name;

  /// 相对图库根目录的路径，例如 `shiyue/a.jpg`，不含服务器地址。
  final String apiPath;
  final int width;
  final int height;
  final int fileSize;
  final int createdMs;

  String get extension => p.extension(name).replaceFirst('.', '').toLowerCase();

  bool get isVideo => _videoExtensions.contains(extension);

  bool get isRawPhoto => _rawExtensions.contains(extension);

  /// 宽高缺失时按 1:1 处理，避免布局除零。
  double get aspectRatio {
    if (width <= 0 || height <= 0) return 1;
    return width / height;
  }

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdMs);

  @override
  bool operator ==(Object other) => other is MediaItem && other.apiPath == apiPath;

  @override
  int get hashCode => apiPath.hashCode;
}

class FolderItem {
  const FolderItem({
    required this.name,
    required this.apiPath,
    required this.mediaCount,
    required this.coverApiPath,
    required this.lastModifiedMs,
  });

  final String name;
  final String apiPath;

  /// 递归统计的媒体数量，后端放在 `cache.recursiveMediaCount`。
  final int mediaCount;

  /// 封面图路径，可能为 null（该目录还没扫描出封面）。
  final String? coverApiPath;
  final int lastModifiedMs;

  DateTime get lastModified => DateTime.fromMillisecondsSinceEpoch(lastModifiedMs);
}

enum SortField { date, name }

class GalleryListing {
  const GalleryListing({
    required this.folders,
    required this.media,
    this.overflow = false,
  });

  static const empty = GalleryListing(folders: [], media: []);

  final List<FolderItem> folders;
  final List<MediaItem> media;

  /// 后端结果被 `Search.maxMediaResult` 截断时为 true。
  final bool overflow;

  int get totalCount => folders.length + media.length;
}

/// ---- JSON 解析 ----
///
/// 后端为了省流量会把列表结果压成短 key（`n`/`m`/`d`/`t`），
/// 完整 key 和短 key 都要能吃下，这样换后端版本不至于白屏。

MediaItem _parseMedia(Map<String, dynamic> json, String parentPath) {
  final name = (json['n'] ?? json['name']) as String? ?? '';
  final meta = (json['m'] ?? json['metadata']) as Map<String, dynamic>? ?? const {};

  int width = 0;
  int height = 0;
  final dims = meta['d'] ?? meta['size'];
  if (dims is List && dims.length >= 2) {
    width = (dims[0] as num?)?.toInt() ?? 0;
    height = (dims[1] as num?)?.toInt() ?? 0;
  } else if (dims is Map) {
    width = (dims['width'] as num?)?.toInt() ?? 0;
    height = (dims['height'] as num?)?.toInt() ?? 0;
  }

  final fileSize = ((meta['s'] ?? meta['fileSize']) as num?)?.toInt() ?? 0;

  // 目录列表里媒体时间戳是「秒」（带小数），别处可能是毫秒，按数量级判断。
  final rawDate = (meta['t'] ?? meta['creationDate']) as num?;
  int createdMs = 0;
  if (rawDate != null) {
    createdMs = rawDate < 100000000000 ? (rawDate * 1000).round() : rawDate.round();
  }

  return MediaItem(
    name: name,
    apiPath: joinApiPath(parentPath, name),
    width: width,
    height: height,
    fileSize: fileSize,
    createdMs: createdMs,
  );
}

FolderItem _parseFolder(Map<String, dynamic> json) {
  final name = (json['n'] ?? json['name']) as String? ?? '';
  final parent = (json['p'] ?? json['path']) as String? ?? '';
  final cache = (json['c'] ?? json['cache']) as Map<String, dynamic>? ?? const {};

  final count = ((cache['rm'] ?? cache['recursiveMediaCount'] ?? cache['mc'] ?? cache['mediaCount'])
      as num?)?.toInt() ?? 0;

  String? coverPath;
  final cover = (cache['cv'] ?? cache['cover']) as Map<String, dynamic>?;
  if (cover != null) {
    final coverName = (cover['n'] ?? cover['name']) as String?;
    final coverDir = (cover['d'] ?? cover['directory']) as Map<String, dynamic>?;
    if (coverName != null && coverDir != null) {
      coverPath = joinApiPath(
        joinApiPath(
          (coverDir['p'] ?? coverDir['path']) as String? ?? '',
          (coverDir['n'] ?? coverDir['name']) as String? ?? '',
        ),
        coverName,
      );
    }
  }

  final lastModified = ((json['lm'] ?? json['lastModified']) as num?)?.toInt() ?? 0;

  return FolderItem(
    name: name,
    apiPath: joinApiPath(parent, name),
    mediaCount: count,
    coverApiPath: coverPath,
    lastModifiedMs: lastModified,
  );
}

/// `/pgapi/gallery/content/<path>` 的响应：`{map, directory}`。
GalleryListing parseDirectoryListing(Map<String, dynamic> result, String requestPath) {
  final directory = (result['directory'] ?? result['d']) as Map<String, dynamic>? ?? const {};

  final foldersJson = (directory['directories'] ?? directory['dirs']) as List<dynamic>?;
  final mediaJson = (directory['media'] ?? directory['m']) as List<dynamic>?;

  return GalleryListing(
    folders: (foldersJson ?? const []).map((e) => _parseFolder(e as Map<String, dynamic>)).toList(),
    // 本级媒体挂在被请求的目录下
    media: (mediaJson ?? const [])
        .map((e) => _parseMedia(e as Map<String, dynamic>, requestPath))
        .toList(),
  );
}

/// `/pgapi/search/<query>` 的响应：`{map, searchResult}`。
/// 搜索结果的媒体不带目录，用 `d` 索引 `map.directories` 找回所属目录。
GalleryListing parseSearchListing(Map<String, dynamic> result) {
  final searchResult = (result['searchResult'] ?? result['sr']) as Map<String, dynamic>? ?? const {};
  final map = (result['map'] ?? const {}) as Map<String, dynamic>;
  final dirTable = (map['directories'] ?? map['d']) as List<dynamic>?;

  String parentFor(dynamic mediaJson) {
    final index = (mediaJson as Map<String, dynamic>)['d'] as int?;
    if (index == null || dirTable == null || index >= dirTable.length) return '';
    final entry = dirTable[index] as Map<String, dynamic>;
    return joinApiPath(
      (entry['p'] ?? entry['path']) as String? ?? '',
      (entry['n'] ?? entry['name']) as String? ?? '',
    );
  }

  final mediaJson = (searchResult['media'] ?? searchResult['m']) as List<dynamic>?;
  final foldersJson = (searchResult['directories']) as List<dynamic>?;

  return GalleryListing(
    folders: (foldersJson ?? const []).map((e) => _parseFolder(e as Map<String, dynamic>)).toList(),
    media: (mediaJson ?? const [])
        .map((e) => _parseMedia(e as Map<String, dynamic>, parentFor(e)))
        .toList(),
    overflow: (searchResult['resultOverflow'] ?? searchResult['ro']) == true,
  );
}
