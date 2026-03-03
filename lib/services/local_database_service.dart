// Deprecated stub: Local sqlite-based cache was removed in favor of
// `LocalCacheService` which uses SharedPreferences for lightweight
// offline caching and syncing to Firestore. This file is kept as a stub
// to avoid build failures in case of imports; prefer using
// `lib/services/local_cache_service.dart` instead.

class LocalDatabaseService {
  LocalDatabaseService._();

  static final instance = LocalDatabaseService._();

  Future<void> saveHistory(dynamic _) async {
    // no-op
  }

  Future<List<dynamic>> getHistory() async => [];

  Future<void> deleteHistory(String _) async {}

  Future<void> clearHistory() async {}
}
