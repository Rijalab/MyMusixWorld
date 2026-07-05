import 'dart:async';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../core/enums/enums.dart';
import '../core/errors/exceptions.dart' as exc;
import '../models/song.dart';
import 'storage_provider.dart';
import 'database_service.dart';

class PlayerService {
  final AudioPlayer _player = AudioPlayer();
  final StorageProvider _storage;
  DatabaseService? _db;
  final _playerStateController = StreamController<AudioPlayState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _songChangedController = StreamController<Song?>.broadcast();

  void setDatabase(DatabaseService db) { _db = db; }

  List<Song> _queue = [];
  int _currentIndex = -1;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffled = false;
  List<int> _shuffleOrder = [];
  double _playbackSpeed = 1.0;

  Stream<AudioPlayState> get playerStateStream => _playerStateController.stream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Song?> get songChangedStream => _songChangedController.stream;

  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;
  double get playbackSpeed => _playbackSpeed;
  bool get playing => _player.playing;
  Duration? get position => _player.position;
  Duration? get duration => _player.duration;

  PlayerService({required StorageProvider storage}) : _storage = storage {
    _player.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
          _playerStateController.add(AudioPlayState.idle);
          break;
        case ProcessingState.loading:
          _playerStateController.add(AudioPlayState.loading);
          break;
        case ProcessingState.buffering:
          _playerStateController.add(AudioPlayState.loading);
          break;
        case ProcessingState.ready:
          if (_player.playing) {
            _playerStateController.add(AudioPlayState.playing);
          } else {
            _playerStateController.add(AudioPlayState.paused);
          }
          break;
        case ProcessingState.completed:
          _onTrackComplete();
          break;
      }
    });

    _player.positionStream.listen((pos) {
      _positionController.add(pos);
    });

    _player.durationStream.listen((dur) {
      if (dur != null) _durationController.add(dur);
    });
  }

  Future<void> init() async {}

  Future<void> playSong(Song song, {List<Song>? queue}) async {
    try {
      if (queue != null) {
        _queue = queue;
        _currentIndex = queue.indexOf(song);
      } else {
        if (!_queue.contains(song)) {
          _queue.add(song);
          _currentIndex = _queue.length - 1;
        } else {
          _currentIndex = _queue.indexOf(song);
        }
      }

      if (_isShuffled) _buildShuffleOrder();

      await _playCurrent();
    } catch (e) {
      throw exc.MusicPlayerException('Failed to play song: $e');
    }
  }

  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue = List.from(songs);
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    if (_isShuffled) _buildShuffleOrder();
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    final song = _queue[_currentIndex];
    if (song.driveFileId == null) throw exc.MusicPlayerException('No file ID');

    _songChangedController.add(song);

    try {
      final cachePath = await _db?.getCachePath(song.id);
      final isCached = cachePath != null && File(cachePath).existsSync();

      if (isCached) {
        _playerStateController.add(AudioPlayState.idle);
        await _player.setAudioSource(
          AudioSource.file(cachePath, tag: song),
        );
      } else {
        _playerStateController.add(AudioPlayState.loading);
        final source = await _storage.getDownloadUrl(song.driveFileId!);
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(source.url),
            headers: source.headers,
            tag: song,
          ),
        );
        _cacheSongInBackground(song);
      }
      await _player.setSpeed(_playbackSpeed);
      await _player.play();
    } catch (e) {
      _playerStateController.add(AudioPlayState.stopped);
      rethrow;
    }
  }

  Future<void> _cacheSongInBackground(Song song) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);
      final localPath = '${cacheDir.path}/${song.id}.${song.fileExtension}';
      final file = File(localPath);
      if (await file.exists()) return;

      final stream = await _storage.downloadFile(song.driveFileId!);
      final sink = file.openWrite();
      await stream.pipe(sink);
      await sink.flush();
      await sink.close();

      if (_db != null) {
        await _db!.setCachePath(song.id, localPath);
      }
    } catch (_) {}
  }

  Future<void> play() async {
    if (_player.playerState.processingState == ProcessingState.completed) {
      await seek(Duration.zero);
    }
    await _player.play();
  }

  Future<void> pause() async => await _player.pause();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (_queue.isEmpty) return;

    if (_isShuffled) {
      final shuffledIndex = _shuffleOrder.indexOf(_currentIndex);
      if (shuffledIndex < _shuffleOrder.length - 1) {
        _currentIndex = _shuffleOrder[shuffledIndex + 1];
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _shuffleOrder.first;
      } else {
        return;
      }
    } else {
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = 0;
      } else {
        return;
      }
    }

    await _playCurrent();
  }

  Future<void> previous() async {
    if (_queue.isEmpty) return;

    if (_player.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }

    if (_isShuffled) {
      final shuffledIndex = _shuffleOrder.indexOf(_currentIndex);
      if (shuffledIndex > 0) {
        _currentIndex = _shuffleOrder[shuffledIndex - 1];
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _shuffleOrder.last;
      } else {
        _currentIndex = _shuffleOrder.first;
      }
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _queue.length - 1;
      } else {
        return;
      }
    }

    await _playCurrent();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekToSong(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _playCurrent();
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    switch (mode) {
      case RepeatMode.off:
        _player.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _buildShuffleOrder();
    } else {
      _shuffleOrder = [];
    }
  }

  void _buildShuffleOrder() {
    _shuffleOrder = List.generate(_queue.length, (i) => i);
    _shuffleOrder.shuffle();
    if (_currentIndex >= 0) {
      _shuffleOrder.remove(_currentIndex);
      _shuffleOrder.insert(0, _currentIndex);
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
  }

  void _onTrackComplete() {
    if (_repeatMode == RepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
      return;
    }

    if (_repeatMode == RepeatMode.all || _currentIndex < _queue.length - 1) {
      next();
    } else {
      _playerStateController.add(AudioPlayState.completed);
    }
  }

  Future<void> addToQueue(Song song) async {
    _queue.add(song);
    if (_isShuffled) _buildShuffleOrder();
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_isShuffled) _buildShuffleOrder();
    }
  }

  Future<void> clearQueue() async {
    _queue.clear();
    _currentIndex = -1;
    await _player.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _songChangedController.close();
  }
}
