import 'dart:io' show Platform;

/// iOS 和安卓共用同一份 lib，凡是「只在某个系统上成立」的说法都收在这里，
/// 免得正文里到处散落 `Platform.isIOS`。
abstract final class PlatformNotes {
  static bool get isIos => Platform.isIOS;

  static String get osName {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return '本机';
  }

  /// 凭据落在哪：iOS 是钥匙串，安卓是 Keystore 加密的私有文件。
  static String get credentialHint => Platform.isIOS
      ? '会话 cookie 与密码存在 iOS 钥匙串里；退出登录会一并清掉。'
      : '会话 cookie 与密码存在应用私密的加密存储里；退出登录会一并清掉。';

  static String get signOutHint =>
      Platform.isIOS ? '清掉钥匙串里的会话与密码' : '清掉加密存储里的会话与密码';

  /// 「连不上」的第一大原因，两个系统给的提示完全不同。
  static String noRoute(String host) {
    if (Platform.isIOS) {
      return '手机到 $host 没有路由（errno 65）。iOS 上通常是这两条之一：\n'
          '① 没给「本地网络」权限 —— 设置 → 隐私与安全性 → 本地网络 → 打开 Gallery；'
          '列表里找不到 Gallery 就卸载重装，首次点登录会弹框，选「允许」。\n'
          '② 手机上的代理/VPN（TUN 全局）把局域网吞了 —— 把 $host 加进直连规则，或先关掉代理再试。';
    }
    return '手机到 $host 没有路由。安卓上先看这两条：\n'
        '① WiFi 是不是开了「隐私/随机 MAC」或访客网络的设备隔离 —— 换成连 $host 那台机器的同一个网络；\n'
        '② 代理/VPN（全局 TUN）把局域网吞了 —— 把 $host 加进直连规则，或先关掉代理再试。';
  }

  /// 播放器起不来的兜底文案。安卓用 ExoPlayer，能吃的容器比 AVKit 宽得多。
  static String videoInitFailed(Object error) {
    if (Platform.isIOS) {
      return '这个格式 iPhone 播不了：$error';
    }
    return '这台机器解不开这个封装：$error';
  }
}
