import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'cache_manager.g.dart';

class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration ttl)
      : expiresAt = DateTime.now().add(ttl);

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class CacheManager {
  final _store = <String, _CacheEntry<dynamic>>{};
  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null || !entry.isValid) {
      _store.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void set<T>(String key, T data, {Duration ttl = const Duration(minutes: 2)}) {
    _store[key] = _CacheEntry<T>(data, ttl);
  }

  void invalidate(String key) => _store.remove(key);

  void invalidatePrefix(String prefix) =>
      _store.removeWhere((key, _) => key.startsWith(prefix));

  void clear() => _store.clear();
}

@Riverpod(keepAlive: true)
CacheManager cacheManager(Ref ref) => CacheManager();