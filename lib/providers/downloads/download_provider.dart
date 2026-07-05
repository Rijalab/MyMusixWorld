import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/enums/enums.dart';
import '../../models/song.dart';
import '../../models/download_entry.dart';
import '../../services/google_drive_storage.dart';
import '../../services/database_service.dart';
import '../auth/auth_provider.dart';
import '../database/database_provider.dart';

final downloadProvider =
    StateNotifierProvider<DownloadNotifier, AsyncValue<List<DownloadEntry>>>(
        (ref) {
  final storage = ref.watch(googleDriveStorageProvider);
  final db = ref.watch(databaseServiceProvider);
  return DownloadNotifier(storage, db);
});

class DownloadNotifier extends StateNotifier<AsyncValue<List<DownloadEntry>>> {
  final GoogleDriveStorage _storage;
  final DatabaseService _db;
  final _uuid = const Uuid();
  DownloadNotifier(this._storage, this._db)
      : super(const AsyncValue.data([])) {
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      final downloads = await _db.getAllDownloads();
      state = AsyncValue.data(downloads);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String> downloadSong(Song song) async {
    if (song.driveFileId == null) throw Exception('No file ID');

    final existing = await _db.getAllDownloads();
    if (existing.any((d) => d.songId == song.id && d.status == DownloadStatus.completed)) {
      return existing.firstWhere((d) => d.songId == song.id).id;
    }

    final downloadId = _uuid.v4();
    final downloadDir = await getApplicationDocumentsDirectory();
    final localPath = '${downloadDir.path}/downloads/${song.fileName}';

    final entry = DownloadEntry(
      id: downloadId,
      songId: song.id,
      status: DownloadStatus.downloading,
      localPath: localPath,
      createdAt: DateTime.now(),
    );

    await _db.insertDownload(entry);
    await _loadDownloads();

    _startDownload(downloadId, song, localPath);

    return downloadId;
  }

  void _startDownload(String downloadId, Song song, String localPath) {
    final fileDir = Directory(localPath.substring(0, localPath.lastIndexOf('/')));
    fileDir.createSync(recursive: true);

    Future(() async {
      try {
        final stream = await _storage.downloadFile(song.driveFileId!);
        final file = File(localPath);
        final sink = file.openWrite();
        int received = 0;

        await for (final chunk in stream) {
          sink.add(chunk);
          received += chunk.length;
          final entry = DownloadEntry(
            id: downloadId,
            songId: song.id,
            status: DownloadStatus.downloading,
            progress: song.fileSize > 0 ? received / song.fileSize : 0,
            localPath: localPath,
            totalBytes: song.fileSize,
            receivedBytes: received,
            createdAt: DateTime.now(),
          );
          await _db.updateDownload(entry);
        }

        await sink.close();

        final completed = DownloadEntry(
          id: downloadId,
          songId: song.id,
          status: DownloadStatus.completed,
          progress: 1.0,
          localPath: localPath,
          totalBytes: song.fileSize,
          receivedBytes: await file.length(),
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        await _db.updateDownload(completed);
        await _loadDownloads();
      } catch (e) {
        final failed = DownloadEntry(
          id: downloadId,
          songId: song.id,
          status: DownloadStatus.failed,
          errorMessage: e.toString(),
          createdAt: DateTime.now(),
        );
        await _db.updateDownload(failed);
        await _loadDownloads();
      }
    });
  }

  Future<void> deleteDownload(String id) async {
    final downloads = state.valueOrNull ?? [];
    final entry = downloads.where((d) => d.id == id).firstOrNull;
    if (entry?.localPath != null) {
      final file = File(entry!.localPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _db.deleteDownload(id);
    await _loadDownloads();
  }

  Future<void> refresh() => _loadDownloads();
}
