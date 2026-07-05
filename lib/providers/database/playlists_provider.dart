import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../services/database_service.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../services/player_service.dart';
import '../database/database_provider.dart';
import '../player/player_provider.dart';

final allPlaylistsProvider =
    StateNotifierProvider<PlaylistsNotifier, AsyncValue<List<Playlist>>>(
        (ref) {
  final db = ref.watch(databaseServiceProvider);
  final player = ref.watch(playerServiceProvider);
  return PlaylistsNotifier(db, player);
});

class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final DatabaseService _db;
  final PlayerService _player;
  final _uuid = const Uuid();

  PlaylistsNotifier(this._db, this._player) : super(const AsyncValue.loading()) {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlists = await _db.getAllPlaylists();
      state = AsyncValue.data(playlists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPlaylist(String name, {String? description}) async {
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _db.createPlaylist(playlist);
    await _loadPlaylists();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    final playlists = state.valueOrNull ?? [];
    final index = playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final updated = playlists[index].copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
    await _db.updatePlaylist(updated);
    await _loadPlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    await _db.deletePlaylist(id);
    await _loadPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    final playlists = state.valueOrNull ?? [];
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;
    final playlist = playlists[index];
    if (playlist.songIds.contains(songId)) return;
    final updated = playlist.copyWith(
      songIds: [...playlist.songIds, songId],
      updatedAt: DateTime.now(),
    );
    await _db.updatePlaylist(updated);
    await _loadPlaylists();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlists = state.valueOrNull ?? [];
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;
    final playlist = playlists[index];
    final updated = playlist.copyWith(
      songIds: playlist.songIds.where((id) => id != songId).toList(),
      updatedAt: DateTime.now(),
    );
    await _db.updatePlaylist(updated);
    await _loadPlaylists();
  }

  Future<void> reorderPlaylist(
      String playlistId, int oldIndex, int newIndex) async {
    final playlists = state.valueOrNull ?? [];
    final index = playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;
    final playlist = playlists[index];
    final ids = List<String>.from(playlist.songIds);
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    if (newIndex < 0 || newIndex >= ids.length) return;
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
    final updated = playlist.copyWith(
      songIds: ids,
      updatedAt: DateTime.now(),
    );
    await _db.updatePlaylist(updated);
    await _loadPlaylists();
  }

  Future<void> playPlaylist(Playlist playlist) async {
    final songs = <Song>[];
    for (final songId in playlist.songIds) {
      final song = await _db.getSong(songId);
      if (song != null) songs.add(song);
    }
    if (songs.isNotEmpty) {
      await _player.playQueue(songs);
    }
  }

  Future<void> refresh() => _loadPlaylists();
}
