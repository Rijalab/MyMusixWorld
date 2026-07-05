import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';

class CacheService {
  Directory? _cacheDir;
  int maxCacheSizeBytes = AppConstants.defaultCacheSizeMB * 1024 * 1024;

  Future<Directory> get cacheDir async {
    _cacheDir ??= await _initCacheDir();
    return _cacheDir!;
  }

  Future<Directory> _initCacheDir() async {
    final appDir = await getApplicationCacheDirectory();
    final dir = Directory('${appDir.path}/music_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> getCachePath(String fileId) async {
    final dir = await cacheDir;
    return '${dir.path}/$fileId';
  }

  Future<bool> isCached(String fileId) async {
    final path = await getCachePath(fileId);
    return File(path).exists();
  }

  Future<File> cacheFile(String fileId, List<int> bytes) async {
    try {
      await _ensureCacheSpace(bytes.length);
      final path = await getCachePath(fileId);
      final file = File(path);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw CacheException('Failed to cache file: $e');
    }
  }

  Future<File?> getCachedFile(String fileId) async {
    final path = await getCachePath(fileId);
    final file = File(path);
    if (await file.exists()) {
      await _updateAccessTime(fileId);
      return file;
    }
    return null;
  }

  Future<void> removeFromCache(String fileId) async {
    final path = await getCachePath(fileId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _ensureCacheSpace(int neededBytes) async {
    final dir = await cacheDir;
    final currentSize = await _getCacheSize();

    if (currentSize + neededBytes <= maxCacheSizeBytes) return;

    final files = await dir.list().toList();
    files.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return aStat.modified.compareTo(bStat.modified);
    });

    int freed = 0;
    for (final file in files) {
      if (currentSize + neededBytes - freed <= maxCacheSizeBytes) break;
      final stat = file.statSync();
      await file.delete();
      freed += stat.size;
    }
  }

  Future<int> _getCacheSize() async {
    final dir = await cacheDir;
    int totalSize = 0;
    await for (final file in dir.list()) {
      totalSize += file.statSync().size;
    }
    return totalSize;
  }

  Future<int> getCacheSizeBytes() async => _getCacheSize();

  Future<void> clearCache() async {
    final dir = await cacheDir;
    await for (final file in dir.list()) {
      if (file is File) {
        await file.delete();
      }
    }
  }

  Future<void> _updateAccessTime(String fileId) async {
    final path = await getCachePath(fileId);
    final file = File(path);
    if (await file.exists()) {
      await file.setLastModified(DateTime.now());
    }
  }
}
