import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late final TextEditingController _url;
  late final TextEditingController _username;
  final TextEditingController _password = TextEditingController();
  String? _error;
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _url = TextEditingController(text: state.serverUrl);
    _username = TextEditingController(text: state.username);
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    try {
      await context.read<AppState>().signIn(
            serverUrl: _url.text,
            username: _username.text.trim(),
            password: _password.text,
          );
      // 成功后根组件会自己切到图库，这里不用导航。
    } on ApiFailure catch (e) {
      setState(() => _error = e.message);
    } on Exception catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _guest() async {
    setState(() => _probing = true);
    final state = context.read<AppState>();
    final ok = await state.probeAnonymous(_url.text);
    if (!mounted) return;
    setState(() => _probing = false);
    if (ok) {
      await state.enterAsGuest(_url.text);
    } else {
      setState(() => _error = '这个地址需要登录，游客进不去');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AppState>().busy;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.photo_library_outlined, size: 44, color: Color(0xFF64B5FF)),
                  const SizedBox(height: 14),
                  const Text(
                    'Gallery',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '连到你自己的 PiGallery2',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white38),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: '服务器地址',
                      hintText: 'http://192.168.1.17:8083',
                      helperText: '局域网 http 地址即可，App 已放行非 HTTPS',
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _username,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                    decoration: const InputDecoration(
                      labelText: '密码',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A1D1D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy || _probing ? null : _login,
                    child: busy
                        ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('登录'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _probing || busy ? null : _guest,
                    child: Text(_probing ? '正在试探…' : '以游客身份进入（公开图库）'),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '会话 cookie 与密码存在 iOS 钥匙串里；退出登录会一并清掉。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
