import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'platform_notes.dart';

/// 后端不可用 / 认证失败 / 返回体不符合预期时统一抛这个。
class ApiFailure implements Exception {
  ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isAuth => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// 会话 + 传输层。UI 只认这一个入口，图片/视频请求也从这里拿 header。
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this._secure);

  static const String defaultServerUrl = 'http://192.168.1.17:8083';
  static const String defaultUsername = 'admin';

  /// PiGallery2 的接口前缀，见 `Config.Server.apiPath`。
  static const String apiPath = '/pgapi';

  /// 对外只露这一个目录，相当于 OpenList 里的 `/local/gallery`。
  /// 库里存的路径不带前导斜杠，所以这里也不带。
  static const String visibleRoot = 'gallery';

  /// 隐藏模式下把整棵树（`/local` == 图库根）都放开。
  static const String fullRoot = '';

  static const _kServerUrl = 'server_url';
  static const _kUsername = 'username';
  static const _kThumbSize = 'thumb_size';
  static const _kRecursive = 'default_recursive';
  static const _kSortField = 'sort_field';
  static const _kSortDesc = 'sort_desc';
  static const _kGuest = 'guest_mode';
  static const _kSession = 'pg2_session';
  static const _kCsrf = 'pg2_csrf';
  static const _kPassword = 'pg2_password';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  final http.Client _client = http.Client();

  String _serverUrl = defaultServerUrl;
  String _username = defaultUsername;
  String? _cookies;
  String? _csrfToken;
  String? _password;
  bool _busy = false;
  String? _lastError;

  int _thumbSize = 320;
  bool _defaultRecursive = false;
  SortField _sortField = SortField.date;
  bool _sortDesc = true;
  bool _guestMode = false;
  bool _hiddenMode = false;

  int get thumbSize => _thumbSize;
  bool get defaultRecursive => _defaultRecursive;
  SortField get sortField => _sortField;
  bool get sortDesc => _sortDesc;
  bool get guestMode => _guestMode;

  /// 隐藏模式只活在内存里：杀进程就回到普通模式，落盘反而危险。
  bool get hiddenMode => _hiddenMode;

  /// 首页的根：普通模式只看 `gallery`，隐藏模式看整棵树。
  String get rootPath => _hiddenMode ? fullRoot : visibleRoot;

  /// 普通模式下所有列表结果必须落在这个前缀里，null 表示不限制。
  String? get visiblePrefix => _hiddenMode ? null : '$visibleRoot/';

  /// 游客模式下没有会话也允许进图库（后端可能配成公开）。
  bool get canBrowse => hasSession || _guestMode;
  bool get busy => _busy;
  String? get lastError => _lastError;
  String get serverUrl => _serverUrl;
  String get username => _username;

  /// 有用户名和密码才谈得上自动续期；游客库可以没有会话直接读。
  bool get hasCredentials => _password != null && _password!.isNotEmpty;

  bool get hasSession => _cookies != null && _cookies!.isNotEmpty;

  static Future<AppState> load() async {
    final state = AppState._(await SharedPreferences.getInstance(), const FlutterSecureStorage());
    await state._restore();
    return state;
  }

  Future<void> _restore() async {
    _serverUrl = _prefs.getString(_kServerUrl) ?? defaultServerUrl;
    _username = _prefs.getString(_kUsername) ?? defaultUsername;
    _thumbSize = _prefs.getInt(_kThumbSize) ?? 320;
    _defaultRecursive = _prefs.getBool(_kRecursive) ?? false;
    _sortField = SortField.values[_prefs.getInt(_kSortField) ?? 0];
    _sortDesc = _prefs.getBool(_kSortDesc) ?? true;
    _guestMode = _prefs.getBool(_kGuest) ?? false;
    try {
      _cookies = await _secure.read(key: _kSession);
      _csrfToken = await _secure.read(key: _kCsrf);
      _password = await _secure.read(key: _kPassword);
    } on Exception catch (e) {
      // 越狱/重签名后 Keychain 条目可能失效：只影响登录态，不让 App 起不来。
      debugPrint('secure storage unavailable: $e');
    }
  }

  // ---- 配置写入 ----

  Future<void> setThumbSize(int size) async {
    _thumbSize = size;
    await _prefs.setInt(_kThumbSize, size);
    notifyListeners();
  }

  Future<void> setDefaultRecursive(bool value) async {
    _defaultRecursive = value;
    await _prefs.setBool(_kRecursive, value);
    notifyListeners();
  }

  Future<void> setSort(SortField field, bool descending) async {
    _sortField = field;
    _sortDesc = descending;
    await _prefs.setInt(_kSortField, field.index);
    await _prefs.setBool(_kSortDesc, descending);
    notifyListeners();
  }

  /// 进出隐藏模式。内存态，靠 root key 变化让首页重建。
  void setHiddenMode(bool value) {
    if (_hiddenMode == value) return;
    _hiddenMode = value;
    notifyListeners();
  }

  // ---- 会话 ----

  /// 只剥掉 `path`/`HttpOnly` 这类属性，留下 PiGallery2 的两个 cookie：
  /// `pigallery2-session` 与 `pigallery2-session.sig`。
  static String extractSessionCookies(Map<String, String> responseHeaders) {
    final raw = responseHeaders['set-cookie'] ?? '';
    if (raw.isEmpty) return '';
    final parts = raw.split(',').expand((chunk) => chunk.split(';')).map((e) => e.trim());
    return parts.where((e) => e.toLowerCase().startsWith('pigallery')).join('; ');
  }

  Future<void> signIn({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    _setBusy(true);
    // catch 里也要拿到这个地址报错，所以声明在 try 外面。
    final url = _normalizeServerUrl(serverUrl);
    try {
      final body = jsonEncode({
        'loginCredential': {'username': username, 'password': password},
      });
      final response = await _client
          .post(
            Uri.parse('$url$apiPath/user/login'),
            headers: const {'Content-Type': 'application/json; charset=UTF-8'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      final decoded = _decode(response);
      if (response.statusCode != 200 || decoded['error'] != null) {
        throw ApiFailure(
          _errorText(decoded, response.statusCode),
          statusCode: response.statusCode,
        );
      }

      final cookies = extractSessionCookies(response.headers);
      if (cookies.isEmpty) {
        throw ApiFailure('登录成功但没有拿到会话 cookie，检查服务端是否启用了不同的 cookie 名');
      }

      final result = decoded['result'] as Map<String, dynamic>?;
      _serverUrl = url;
      _username = username;
      _cookies = cookies;
      _csrfToken = result?['csrfToken'] as String?;
      _password = password;
      _guestMode = false;

      await _prefs.setString(_kServerUrl, url);
      await _prefs.setString(_kUsername, username);
      await _prefs.setBool(_kGuest, false);
      await _secure.write(key: _kSession, value: cookies);
      if (_csrfToken != null) {
        await _secure.write(key: _kCsrf, value: _csrfToken!);
      }
      await _secure.write(key: _kPassword, value: password);
      _lastError = null;
    } on ApiFailure {
      rethrow;
    } on Exception catch (e) {
      throw ApiFailure(describeSocketError(e, Uri.tryParse(url)?.host ?? url));
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    _cookies = null;
    _csrfToken = null;
    _password = null;
    _guestMode = false;
    // 退出登录等于回到起点，隐藏态没必要留着。
    _hiddenMode = false;
    await _prefs.setBool(_kGuest, false);
    for (final key in [_kSession, _kCsrf, _kPassword]) {
      try {
        await _secure.delete(key: key);
      } on Exception catch (_) {
        // Keychain 不可用时内存里已经清掉了，够用的。
      }
    }
    notifyListeners();
  }

  /// 公开图库：不登录直接进，缩略图请求不带 cookie 也能出图。
  Future<void> enterAsGuest(String serverUrl) async {
    _serverUrl = _normalizeServerUrl(serverUrl);
    _guestMode = true;
    await _prefs.setString(_kServerUrl, _serverUrl);
    await _prefs.setBool(_kGuest, true);
    notifyListeners();
  }

  /// 游客可访问的库：试探一次目录列表，成功就记住这个地址。
  Future<bool> probeAnonymous(String serverUrl) async {
    final previous = _serverUrl;
    _serverUrl = _normalizeServerUrl(serverUrl);
    try {
      await listDirectory('');
      return true;
    } on Exception {
      _serverUrl = previous;
      return false;
    }
  }

  // ---- Header / URL ----

  Map<String, String> get headers {
    final map = <String, String>{};
    if (hasSession) map['Cookie'] = _cookies!;
    if (_csrfToken != null && _csrfToken!.isNotEmpty) map['CSRF-Token'] = _csrfToken!;
    return map;
  }

  /// 给 CachedImageProvider 用：每次取当前会话，续期后不需要重建 provider。
  HeadersProvider get headersForImage => () => headers;

  String mediaUrl(String relativePath) =>
      '$_serverUrl$apiPath/gallery/content/${encodeApiPath(relativePath)}';

  String thumbnailUrl(String relativePath, {int? size}) =>
      '${mediaUrl(relativePath)}/${size ?? _thumbSize}';

  /// 后端路由是 `:mediaPath(*)`，所以 `/` 要保留，其它字符按 PiGallery2 的口径转义。
  static String encodeApiPath(String relativePath) {
    return Uri.encodeFull(relativePath)
        .replaceAll('#', '%23')
        .replaceAll(r'$', '%24')
        .replaceAll("'", '%27')
        .replaceAll('(', '%28')
        .replaceAll(')', '%29')
        .replaceAll('?', '%3F');
  }

  static String _normalizeServerUrl(String value) {
    var url = value.trim();
    if (url.isEmpty) return defaultServerUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url.replaceAll(RegExp(r'/+$'), '');
  }

  String get _serverHost => Uri.tryParse(_serverUrl)?.host ?? _serverUrl;

  /// 「连不上」的几种典型形态，文案得能直接指路，不然只能瞎试。
  /// iOS errno 65 = EHOSTDOWN：本地网络权限被拒、或端上代理把局域网路由吞了，都会是这个。
  static String describeSocketError(Object error, String host) {
    final text = error.toString();
    if (text.contains('No route to host') || text.contains('errno = 65')) {
      return PlatformNotes.noRoute(host);
    }
    if (text.contains('Connection refused') || text.contains('errno = 61')) {
      return '$host 那个端口没在听（errno 61）。确认服务起来了、端口没填错，'
          '以及手机和服务器在同一个局域网。';
    }
    if (text.contains('timed out') ||
        text.contains('Network is unreachable') ||
        text.contains('errno = 51')) {
      return '连不上 $host：手机和服务器大概不在同一个网段，或者 WiFi 开了设备隔离（访客网络常见）。';
    }
    return '连不上服务器：$text';
  }

  // ---- 请求 ----

  Future<dynamic> _getJson(Uri uri, {int? retryDepth}) async {
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw ApiFailure(describeSocketError(e, _serverHost));
    }

    if (response.statusCode == 401 && retryDepth == null && hasCredentials) {
      // 会话过期：用存着的密码重登一次，再重试。
      await signIn(serverUrl: _serverUrl, username: _username, password: _password!);
      return _getJson(uri, retryDepth: 1);
    }

    final decoded = _decode(response);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ApiFailure('需要登录', statusCode: response.statusCode);
    }
    if (decoded['error'] != null) {
      throw ApiFailure(_errorText(decoded, response.statusCode), statusCode: response.statusCode);
    }
    return decoded['result'];
  }

  Future<GalleryListing> listDirectory(String path) async {
    final uri = Uri.parse('$_serverUrl$apiPath/gallery/content/${encodeApiPath(path)}');
    final result = await _getJson(uri);
    if (result is! Map<String, dynamic>) return GalleryListing.empty;
    // 目录接口本身按路径取，越不出 `gallery`；这层过滤只是兜底，防以后新增入口时漏。
    return _restrictToVisibleRoot(parseDirectoryListing(result, path));
  }

  /// 走 search 接口把整个目录树摊平，`type: 102` = directory。
  Future<GalleryListing> flattenDirectory(String path) async {
    final query = {'type': 102, 'value': path.isEmpty ? '.' : path};
    return _search(query);
  }

  /// 全文检索，`type: 100` = any_text。
  Future<GalleryListing> searchAll(String text) async {
    return _search({'type': 100, 'value': text});
  }

  Future<GalleryListing> _search(Map<String, dynamic> query) async {
    final uri = Uri.parse('$_serverUrl$apiPath/search/${encodeApiPath(jsonEncode(query))}');
    final result = await _getJson(uri);
    if (result is! Map<String, dynamic>) return GalleryListing.empty;
    return _restrictToVisibleRoot(parseSearchListing(result));
  }

  /// 服务端的 directory / any_text 搜索是「路径或目录名子串匹配」，
  /// 用 `gallery` 当值时会把 `1/6/.../natsu_2_Photo_Gallery_-_EPORNER/`
  /// 这类八竿子打不着的目录也捞回来，所以普通模式下所有走 search 的
  /// 列表都要在客户端按前缀再筛一遍。
  GalleryListing _restrictToVisibleRoot(GalleryListing listing) {
    final prefix = visiblePrefix;
    if (prefix == null) return listing;

    bool inside(String path) => path == visibleRoot || path.startsWith(prefix);

    final folders = listing.folders.where((f) => inside(f.apiPath)).toList();
    final media = listing.media.where((m) => inside(m.apiPath)).toList();
    if (folders.length == listing.folders.length && media.length == listing.media.length) {
      return listing;
    }
    return GalleryListing(folders: folders, media: media, overflow: listing.overflow);
  }

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) {
      throw ApiFailure('空响应', statusCode: response.statusCode);
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiFailure('返回体不是 JSON（可能被反代拦了）', statusCode: response.statusCode);
    }
  }

  String _errorText(Map<String, dynamic> decoded, int statusCode) {
    final error = decoded['error'];
    if (error is Map && error['detailsStr'] != null) {
      return '${error['detailsStr']}';
    }
    if (error is String && error.isNotEmpty) return error;
    if (statusCode == 401) return '需要登录';
    if (statusCode == 404) return '路径不存在';
    return '请求失败（HTTP $statusCode）';
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  void setError(String? message) {
    _lastError = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

typedef HeadersProvider = Map<String, String> Function();

/// 隐藏口令：设置页备注框里输入当前的 HHmm 才解锁（与 Vault 的做法一致）。
/// 分钟可能在输入的过程中正好跳走，所以额外接受上一分钟。
bool matchesUnlockCode(String input, {DateTime? now}) {
  if (input.length != 4 || int.tryParse(input) == null) return false;
  final moment = now ?? DateTime.now();
  String code(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';
  return input == code(moment) || input == code(moment.subtract(const Duration(minutes: 1)));
}
