import 'package:flutter/widgets.dart';

import 'app_log.dart';

/// Mencatat perpindahan halaman, sehingga log menunjukkan layar mana yang
/// sedang dibuka saat sebuah error terjadi.
class LogNavigatorObserver extends NavigatorObserver {
  static const String tag = 'Navigasi';

  static String _name(Route<dynamic>? route) {
    if (route == null) return '-';
    return route.settings.name ?? route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      AppLog.i(tag, 'buka ${_name(route)} (dari ${_name(previousRoute)})');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      AppLog.i(tag, 'tutup ${_name(route)} (kembali ke ${_name(previousRoute)})');

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      AppLog.i(tag, 'ganti ${_name(oldRoute)} -> ${_name(newRoute)}');
}

/// Mencatat perubahan siklus hidup aplikasi (dibuka, ke latar belakang, ditutup).
/// Listener mendaftarkan dirinya ke binding saat dibuat, jadi cukup dipanggil sekali.
AppLifecycleListener createLifecycleLogger() {
  return AppLifecycleListener(onStateChange: (state) => AppLog.i('Lifecycle', state.name));
}
