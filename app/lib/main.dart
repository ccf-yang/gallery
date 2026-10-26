import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'state/browse_controller.dart';
import 'ui/browse_page.dart';
import 'ui/settings_page.dart';
import 'ui/setup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 原图解码很吃内存，但网格要留住缩略图；取个折中值。
  PaintingBinding.instance.imageCache.maximumSizeBytes = 160 * 1024 * 1024;
  final state = await AppState.load();
  runApp(GalleryApp(state: state));
}

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key, required this.state});

  final AppState state;

  static const Color _accent = Color(0xFF64B5FF);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        title: 'Gallery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: _accent, brightness: Brightness.dark),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0A0A0A),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
        ),
        home: const _Root(),
        routes: const {
          '/settings': _settingsRoute,
        },
      ),
    );
  }

  static Widget _settingsRoute(BuildContext context) => const SettingsPage();
}

/// 有会话（或选了游客）就进图库，否则停在登录页。
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.canBrowse) return const SetupPage();

    final mode = state.defaultRecursive ? BrowseMode.flatten : BrowseMode.folder;
    // key 里带上 hiddenMode：口令生效那一刻整页要按新的根目录重建，
    // 复用旧 State 会继续拿着上一次的路径。
    return BrowsePage(
      key: ValueKey('root-$mode-${state.hiddenMode}'),
      mode: mode,
      path: state.rootPath,
    );
  }
}
