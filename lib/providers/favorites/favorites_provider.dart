import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../database/database_provider.dart';
import '../database/songs_provider.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Song>>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return FavoritesNotifier(db, () {
    ref.invalidate(allSongsProvider);
  });
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  final DatabaseService _db;
  final VoidCallback _onChanged;

  FavoritesNotifier(this._db, this._onChanged)
      : super(const AsyncValue.loading()) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final songs = await _db.getFavoriteSongs();
      state = AsyncValue.data(songs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final updated = song.copyWith(isFavorite: !song.isFavorite);
    await _db.updateSong(updated);
    _onChanged();
    await _loadFavorites();
  }

  Future<bool> isFavorite(String songId) async {
    final song = await _db.getSong(songId);
    return song?.isFavorite ?? false;
  }

  Future<void> refresh() => _loadFavorites();
}
