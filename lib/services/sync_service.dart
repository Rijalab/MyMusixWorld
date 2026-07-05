import 'dart:async';
import 'package:uuid/uuid.dart';
import '../core/enums/enums.dart';
import '../core/errors/exceptions.dart';
import '../models/song.dart';
import 'storage_provider.dart';
import 'database_service.dart';

class SyncService {
  final StorageProvider _storage;
  final DatabaseService _database;
  final _uuid = const Uuid();
  final _syncStateController = StreamController<SyncStatus>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  Stream<SyncStatus> get syncStateStream => _syncStateController.stream;
  Stream<double> get progressStream => _progressController.stream;

  SyncStatus _status = SyncStatus.idle;

  SyncService({
    required StorageProvider storage,
    required DatabaseService database,
  })  : _storage = storage,
        _database = database;

  SyncStatus get status => _status;

  Future<void> sync() async {
    if (_status == SyncStatus.syncing || _status == SyncStatus.scanning) return;

    try {
      _updateStatus(SyncStatus.scanning);
      _progressController.add(0.0);

      final storageFiles = await _storage.listFiles('');
      if (storageFiles.isEmpty) {
        _updateStatus(SyncStatus.completed);
        _progressController.add(1.0);
        return;
      }

      _updateStatus(SyncStatus.syncing);

      final existingSongs = await _database.getAllSongs();
      final existingDriveIds = existingSongs
          .map((s) => s.driveFileId)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
      final existingByDriveId = {
        for (final s in existingSongs)
          if (s.driveFileId != null) s.driveFileId!: s
      };

      final totalFiles = storageFiles.length;
      var processed = 0;

      final newSongs = <Song>[];
      final updatedSongs = <Song>[];

      for (final file in storageFiles) {
        final song = _createSongFromFile(file);
        if (existingDriveIds.contains(file.id)) {
          final existing = existingByDriveId[file.id]!;
          if (existing.title != song.title ||
              existing.artist != song.artist ||
              existing.album != song.album) {
            updatedSongs.add(song.copyWith(
              id: existing.id,
              dateAdded: existing.dateAdded,
            ));
          }
        } else {
          newSongs.add(song);
        }
        processed++;
        _progressController.add(processed / totalFiles);
      }

      if (newSongs.isNotEmpty) {
        await _database.insertSongs(newSongs);
      }
      for (final song in updatedSongs) {
        await _database.updateSong(song);
      }

      final currentDriveIds = storageFiles.map((f) => f.id).toSet();
      await _database.deleteSongsNotIn(currentDriveIds.toList());

      await _database.rebuildAlbums();
      await _database.rebuildArtists();

      _updateStatus(SyncStatus.completed);
      _progressController.add(1.0);
    } catch (e) {
      _updateStatus(SyncStatus.error);
      throw SyncException('Sync failed: $e');
    }
  }

  Song _createSongFromFile(StorageFile file) {
    final pathParts = file.path.split('/');
    final fileName = file.name;
    final title = _extractTitle(fileName);

    String artist = 'Unknown Artist';
    String? album;

    final albumsIdx = pathParts.indexOf('Albums');
    final artistsIdx = pathParts.indexOf('Artists');

    if (albumsIdx != -1 && albumsIdx + 1 < pathParts.length) {
      album = pathParts[albumsIdx + 1];
    }

    if (artistsIdx != -1 && artistsIdx + 1 < pathParts.length) {
      artist = pathParts[artistsIdx + 1];
    }

    return Song(
      id: _uuid.v4(),
      title: title,
      artist: artist,
      album: album,
      duration: Duration.zero,
      filePath: file.path,
      fileName: fileName,
      fileExtension: _getExtension(fileName),
      fileSize: file.size,
      driveFileId: file.id,
      dateAdded: DateTime.now(),
    );
  }

  String _extractTitle(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) return filename;
    return filename.substring(0, dotIndex);
  }

  String _getExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return filename.substring(dotIndex + 1).toLowerCase();
  }

  void _updateStatus(SyncStatus status) {
    _status = status;
    _syncStateController.add(status);
  }

  void dispose() {
    _syncStateController.close();
    _progressController.close();
  }
}
