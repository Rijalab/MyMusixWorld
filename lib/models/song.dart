import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? genre;
  final Duration duration;
  final String? artworkUrl;
  final int? trackNumber;
  final int? year;
  final String filePath;
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final String? driveFileId;
  final String? mimeType;
  final bool isFavorite;
  final DateTime? dateAdded;
  final DateTime? lastPlayed;
  final int playCount;
  final String? localCachePath;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.genre,
    this.duration = Duration.zero,
    this.artworkUrl,
    this.trackNumber,
    this.year,
    required this.filePath,
    required this.fileName,
    this.fileExtension = 'mp3',
    this.fileSize = 0,
    this.driveFileId,
    this.mimeType,
    this.isFavorite = false,
    this.dateAdded,
    this.lastPlayed,
    this.playCount = 0,
    this.localCachePath,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? genre,
    Duration? duration,
    String? artworkUrl,
    int? trackNumber,
    int? year,
    String? filePath,
    String? fileName,
    String? fileExtension,
    int? fileSize,
    String? driveFileId,
    String? mimeType,
    bool? isFavorite,
    DateTime? dateAdded,
    DateTime? lastPlayed,
    int? playCount,
    String? localCachePath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      duration: duration ?? this.duration,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      driveFileId: driveFileId ?? this.driveFileId,
      mimeType: mimeType ?? this.mimeType,
      isFavorite: isFavorite ?? this.isFavorite,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playCount: playCount ?? this.playCount,
      localCachePath: localCachePath ?? this.localCachePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration_ms': duration.inMilliseconds,
      'artwork_url': artworkUrl,
      'track_number': trackNumber,
      'year': year,
      'file_path': filePath,
      'file_name': fileName,
      'file_extension': fileExtension,
      'file_size': fileSize,
      'drive_file_id': driveFileId,
      'mime_type': mimeType,
      'is_favorite': isFavorite ? 1 : 0,
      'date_added': dateAdded?.millisecondsSinceEpoch,
      'last_played': lastPlayed?.millisecondsSinceEpoch,
      'play_count': playCount,
      'local_cache_path': localCachePath,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String? ?? map['file_name'] as String,
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String?,
      genre: map['genre'] as String?,
      duration: Duration(milliseconds: map['duration_ms'] as int? ?? 0),
      artworkUrl: map['artwork_url'] as String?,
      trackNumber: map['track_number'] as int?,
      year: map['year'] as int?,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      fileExtension: map['file_extension'] as String? ?? 'mp3',
      fileSize: map['file_size'] as int? ?? 0,
      driveFileId: map['drive_file_id'] as String?,
      mimeType: map['mime_type'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      dateAdded: map['date_added'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int)
          : null,
      lastPlayed: map['last_played'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played'] as int)
          : null,
      playCount: map['play_count'] as int? ?? 0,
      localCachePath: map['local_cache_path'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        genre,
        duration,
        artworkUrl,
        trackNumber,
        year,
        filePath,
        fileName,
        fileExtension,
        fileSize,
        driveFileId,
        mimeType,
        isFavorite,
        dateAdded,
        lastPlayed,
        playCount,
        localCachePath,
      ];
}
