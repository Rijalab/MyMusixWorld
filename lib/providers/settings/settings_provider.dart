import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../core/enums/enums.dart';
import '../database/database_provider.dart';

class SettingsState {
  final ThemeModePreference themeMode;
  final StreamingQuality streamingQuality;
  final StreamingQuality downloadQuality;
  final int cacheSizeMB;

  const SettingsState({
    this.themeMode = ThemeModePreference.dark,
    this.streamingQuality = StreamingQuality.high,
    this.downloadQuality = StreamingQuality.high,
    this.cacheSizeMB = 2048,
  });

  SettingsState copyWith({
    ThemeModePreference? themeMode,
    StreamingQuality? streamingQuality,
    StreamingQuality? downloadQuality,
    int? cacheSizeMB,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      cacheSizeMB: cacheSizeMB ?? this.cacheSizeMB,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SettingsNotifier(db);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final DatabaseService _db;

  SettingsNotifier(this._db) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeStr = await _db.getSetting('theme_mode');
    final streamStr = await _db.getSetting('streaming_quality');
    final downloadStr = await _db.getSetting('download_quality');
    final cacheStr = await _db.getSetting('cache_size_mb');

    state = SettingsState(
      themeMode: themeStr != null
          ? ThemeModePreference.values[int.tryParse(themeStr) ?? 2]
          : ThemeModePreference.dark,
      streamingQuality: streamStr != null
          ? StreamingQuality.values[int.tryParse(streamStr) ?? 2]
          : StreamingQuality.high,
      downloadQuality: downloadStr != null
          ? StreamingQuality.values[int.tryParse(downloadStr) ?? 2]
          : StreamingQuality.high,
      cacheSizeMB: int.tryParse(cacheStr ?? '2048') ?? 2048,
    );
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    state = state.copyWith(themeMode: mode);
    await _db.setSetting('theme_mode', mode.index.toString());
  }

  Future<void> setStreamingQuality(StreamingQuality quality) async {
    state = state.copyWith(streamingQuality: quality);
    await _db.setSetting('streaming_quality', quality.index.toString());
  }

  Future<void> setDownloadQuality(StreamingQuality quality) async {
    state = state.copyWith(downloadQuality: quality);
    await _db.setSetting('download_quality', quality.index.toString());
  }

  Future<void> setCacheSize(int mb) async {
    state = state.copyWith(cacheSizeMB: mb);
    await _db.setSetting('cache_size_mb', mb.toString());
  }
}
