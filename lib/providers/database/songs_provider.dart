import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';
import '../database/database_provider.dart';

final allSongsProvider = FutureProvider<List<Song>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllSongs();
});

final recentlyPlayedProvider = FutureProvider<List<Song>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getRecentlyPlayedSongs();
});

final recentlyAddedProvider = FutureProvider<List<Song>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getRecentlyAddedSongs();
});

final songCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getSongCount();
});

final songByIdProvider = FutureProvider.family<Song?, String>((ref, id) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getSong(id);
});

final songsByAlbumProvider =
    FutureProvider.family<List<Song>, ({String albumTitle, String artist})>(
        (ref, params) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getSongsByAlbum(params.albumTitle, params.artist);
});

final songsByArtistProvider =
    FutureProvider.family<List<Song>, String>((ref, artist) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getSongsByArtist(artist);
});

final cacheChangedProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.cacheChanged;
});

final isSongCachedProvider = FutureProvider.family<bool, String>((ref, songId) async {
  ref.watch(cacheChangedProvider);
  final db = ref.watch(databaseServiceProvider);
  final path = await db.getCachePath(songId);
  if (path == null) return false;
  return File(path).existsSync();
});
