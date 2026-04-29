typedef RefreshCallback = Future<void> Function();

class CustomerRefreshRegistry {
  static final Map<String, RefreshCallback> _callbacks = {};

  static void register(String route, RefreshCallback callback) {
    _callbacks[route] = callback;
  }

  static void unregister(String route, RefreshCallback callback) {
    if (_callbacks[route] == callback) {
      _callbacks.remove(route);
    }
  }

  static Future<void> refreshFor(String location) async {
    final route = _resolveRoute(location);
    final callback = _callbacks[route];
    if (callback != null) {
      await callback();
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  static String _resolveRoute(String location) {
    if (location.isEmpty) return location;
    final base = location.split('?').first;
    if (base.isEmpty || base == '/') return '/store';
    final parts = base.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '/store';
    if (parts.first != 'store') return '/store';
    if (parts.length == 1) return '/store';
    return '/store/${parts[1]}';
  }
}
