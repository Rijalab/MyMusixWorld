import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/download_entry.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'mymusixworld.db';
  static const int _dbVersion = 2;

  final _cacheChangedController = StreamController<int>.broadcast();
  int _cacheVersion = 0;
  Stream<int> get cacheChanged => _cacheChangedController.stream;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$_dbName';
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT 'Unknown Artist',
        album TEXT,
        genre TEXT,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        artwork_url TEXT,
        track_number INTEGER,
        year INTEGER,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_extension TEXT NOT NULL DEFAULT 'mp3',
        file_size INTEGER NOT NULL DEFAULT 0,
        drive_file_id TEXT,
        mime_type TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        date_added INTEGER,
        last_played INTEGER,
        play_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE albums (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT 'Unknown Artist',
        artwork_url TEXT,
        year INTEGER,
        song_count INTEGER NOT NULL DEFAULT 0,
        total_duration_ms INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        artwork_url TEXT,
        album_count INTEGER NOT NULL DEFAULT 0,
        song_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE genres (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        song_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        artwork_url TEXT,
        song_ids TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        song_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE downloads (
        id TEXT PRIMARY KEY,
        song_id TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        progress REAL NOT NULL DEFAULT 0.0,
        local_path TEXT,
        total_bytes INTEGER NOT NULL DEFAULT 0,
        received_bytes INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        error_message TEXT,
        FOREIGN KEY (song_id) REFERENCES songs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recently_played (
        song_id TEXT NOT NULL,
        played_at INTEGER NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        searched_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_songs_artist ON songs(artist)
    ''');

    await db.execute('''
      CREATE INDEX idx_songs_album ON songs(album)
    ''');

    await db.execute('''
      CREATE INDEX idx_songs_favorite ON songs(is_favorite)
    ''');

    await db.execute('''
      CREATE INDEX idx_songs_title ON songs(title)
    ''');

    await db.execute('''
      CREATE TABLE song_cache (
        song_id TEXT PRIMARY KEY,
        local_path TEXT NOT NULL,
        cached_at INTEGER NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS song_cache (
          song_id TEXT PRIMARY KEY,
          local_path TEXT NOT NULL,
          cached_at INTEGER NOT NULL,
          FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ----- Songs -----

  Future<void> insertSong(Song song) async {
    final db = await database;
    await db.insert('songs', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertSongs(List<Song> songs) async {
    final db = await database;
    final batch = db.batch();
    for (final song in songs) {
      batch.insert('songs', song.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final maps = await db.query('songs', orderBy: 'title ASC');
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<Song?> getSong(String id) async {
    final db = await database;
    final maps = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Song.fromMap(maps.first);
  }

  Future<void> updateSong(Song song) async {
    final db = await database;
    await db.update('songs', song.toMap(),
        where: 'id = ?', whereArgs: [song.id]);
  }

  Future<void> deleteSong(String id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteSongsNotIn(List<String> driveFileIds) async {
    final db = await database;
    if (driveFileIds.isEmpty) {
      await db.delete('songs');
      return;
    }
    final placeholders = driveFileIds.map((_) => '?').join(',');
    await db.delete('songs',
        where: 'drive_file_id NOT IN ($placeholders)',
        whereArgs: driveFileIds);
  }

  Future<List<Song>> searchSongs(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    final maps = await db.query(
      'songs',
      where:
          'title LIKE ? OR artist LIKE ? OR album LIKE ? OR genre LIKE ? OR file_name LIKE ?',
      whereArgs: [searchTerm, searchTerm, searchTerm, searchTerm, searchTerm],
      limit: 50,
    );
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await database;
    final maps = await db.query('songs',
        where: 'is_favorite = 1', orderBy: 'title ASC');
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<List<Song>> getRecentlyPlayedSongs({int limit = 20}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN recently_played rp ON s.id = rp.song_id
      ORDER BY rp.played_at DESC
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<List<Song>> getRecentlyAddedSongs({int limit = 20}) async {
    final db = await database;
    final maps = await db.query('songs',
        orderBy: 'date_added DESC',
        limit: limit);
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<List<Song>> getSongsByAlbum(String albumTitle, String artist) async {
    final db = await database;
    final maps = albumTitle == 'Unknown Album'
        ? await db.query('songs',
            where: '(album IS NULL OR album = ?) AND artist = ?',
            whereArgs: [albumTitle, artist],
            orderBy: 'track_number ASC, title ASC')
        : await db.query('songs',
            where: 'album = ? AND artist = ?',
            whereArgs: [albumTitle, artist],
            orderBy: 'track_number ASC, title ASC');
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<List<Song>> getSongsByArtist(String artistName) async {
    final db = await database;
    final maps = await db.query('songs',
        where: 'artist = ?',
        whereArgs: [artistName],
        orderBy: 'album ASC, track_number ASC, title ASC');
    return maps.map((m) => Song.fromMap(m)).toList();
  }

  Future<void> addToRecentlyPlayed(String songId) async {
    final db = await database;
    await db.insert('recently_played', {
      'song_id': songId,
      'played_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.delete('recently_played',
        where: 'played_at < ?',
        whereArgs: [
          DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch
        ]);
  }

  Future<int> getSongCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM songs');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ----- Albums -----

  Future<List<Album>> getAllAlbums() async {
    final db = await database;
    final maps = await db.query('albums', orderBy: 'title ASC');
    return maps.map((m) => Album.fromMap(m)).toList();
  }

  Future<void> rebuildAlbums() async {
    final db = await database;
    await db.delete('albums');
    await db.execute('''
      INSERT INTO albums (id, title, artist, artwork_url, year, song_count, total_duration_ms)
      SELECT
        COALESCE(album, 'Unknown Album') || '|' || artist,
        COALESCE(album, 'Unknown Album'),
        artist,
        MIN(artwork_url),
        MAX(year),
        COUNT(*),
        SUM(duration_ms)
      FROM songs
      GROUP BY album, artist
    ''');
  }

  // ----- Artists -----

  Future<List<Artist>> getAllArtists() async {
    final db = await database;
    final maps = await db.query('artists', orderBy: 'name ASC');
    return maps.map((m) => Artist.fromMap(m)).toList();
  }

  Future<void> rebuildArtists() async {
    final db = await database;
    await db.delete('artists');
    await db.execute('''
      INSERT INTO artists (id, name, artwork_url, album_count, song_count)
      SELECT
        artist,
        artist,
        NULL,
        COUNT(DISTINCT COALESCE(album, 'Unknown Album')),
        COUNT(*)
      FROM songs
      GROUP BY artist
    ''');
  }

  // ----- Playlists -----

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final maps = await db.query('playlists', orderBy: 'updated_at DESC');
    return maps.map((m) => Playlist.fromMap(m)).toList();
  }

  Future<void> createPlaylist(Playlist playlist) async {
    final db = await database;
    await db.insert('playlists', playlist.toMap());
  }

  Future<void> updatePlaylist(Playlist playlist) async {
    final db = await database;
    await db.update('playlists', playlist.toMap(),
        where: 'id = ?', whereArgs: [playlist.id]);
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  // ----- Downloads -----

  Future<List<DownloadEntry>> getAllDownloads() async {
    final db = await database;
    final maps = await db.query('downloads', orderBy: 'created_at DESC');
    return maps.map((m) => DownloadEntry.fromMap(m)).toList();
  }

  Future<void> insertDownload(DownloadEntry entry) async {
    final db = await database;
    await db.insert('downloads', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateDownload(DownloadEntry entry) async {
    final db = await database;
    await db.update('downloads', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteDownload(String id) async {
    final db = await database;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  // ----- Settings -----

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ----- Song Cache -----

  Future<String?> getCachePath(String songId) async {
    final db = await database;
    final maps = await db.query('song_cache',
        where: 'song_id = ?', whereArgs: [songId]);
    if (maps.isEmpty) return null;
    return maps.first['local_path'] as String?;
  }

  Future<void> setCachePath(String songId, String localPath) async {
    final db = await database;
    await db.insert('song_cache', {
      'song_id': songId,
      'local_path': localPath,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _cacheVersion++;
    _cacheChangedController.add(_cacheVersion);
  }

  Future<void> removeCache(String songId) async {
    final db = await database;
    await db.delete('song_cache', where: 'song_id = ?', whereArgs: [songId]);
    _cacheVersion++;
    _cacheChangedController.add(_cacheVersion);
  }

  Future<List<String>> getAllCachedSongIds() async {
    final db = await database;
    final maps = await db.query('song_cache');
    return maps.map((m) => m['song_id'] as String).toList();
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('song_cache');
    _cacheVersion++;
    _cacheChangedController.add(_cacheVersion);
  }

  // ----- Search History -----

  Future<List<String>> getSearchHistory({int limit = 10}) async {
    final db = await database;
    final maps = await db.query('search_history',
        orderBy: 'searched_at DESC', limit: limit);
    return maps.map((m) => m['query'] as String).toList();
  }

  Future<void> addSearchHistory(String query) async {
    final db = await database;
    await db.insert('search_history', {
      'query': query,
      'searched_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  // ----- Maintenance -----

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('songs');
    await db.delete('albums');
    await db.delete('artists');
    await db.delete('genres');
    await db.delete('playlists');
    await db.delete('downloads');
    await db.delete('recently_played');
    await db.delete('search_history');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    await _cacheChangedController.close();
  }
}
