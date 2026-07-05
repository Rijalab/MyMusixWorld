import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/player_service.dart';
import '../../services/storage_provider.dart';
import '../../models/song.dart';
import '../../core/enums/enums.dart';
import '../auth/auth_provider.dart';
import '../database/database_provider.dart';

final playerServiceProvider = Provider<PlayerService>((ref) {
  final storage = ref.watch(googleDriveStorageProvider) as StorageProvider;
  final db = ref.watch(databaseServiceProvider);
  final service = PlayerService(storage: storage);
  service.setDatabase(db);
  ref.onDispose(() => service.dispose());
  return service;
});

final playerStateProvider = StreamProvider<AudioPlayState>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.playerStateStream;
});

final currentSongProvider = StreamProvider<Song?>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.songChangedStream;
});

final playerPositionProvider = StreamProvider<Duration>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.positionStream;
});

final playerDurationProvider = Provider<Duration?>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.duration;
});

final isPlayingProvider = Provider<bool>((ref) {
  final state = ref.watch(playerStateProvider).valueOrNull;
  return state == AudioPlayState.playing;
});

final isLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(playerStateProvider).valueOrNull;
  return state == AudioPlayState.loading;
});

final queueProvider = Provider<List<Song>>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.queue;
});

final repeatModeProvider = Provider<RepeatMode>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.repeatMode;
});

final isShuffledProvider = Provider<bool>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.isShuffled;
});

final playbackSpeedProvider = Provider<double>((ref) {
  final player = ref.watch(playerServiceProvider);
  return player.playbackSpeed;
});
