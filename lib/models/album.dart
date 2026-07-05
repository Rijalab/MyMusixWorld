import 'package:equatable/equatable.dart';

class Album extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final int? year;
  final int songCount;
  final Duration totalDuration;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.year,
    this.songCount = 0,
    this.totalDuration = Duration.zero,
  });

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    String? artworkUrl,
    int? year,
    int? songCount,
    Duration? totalDuration,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      year: year ?? this.year,
      songCount: songCount ?? this.songCount,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artwork_url': artworkUrl,
      'year': year,
      'song_count': songCount,
      'total_duration_ms': totalDuration.inMilliseconds,
    };
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? 'Unknown Artist',
      artworkUrl: map['artwork_url'] as String?,
      year: map['year'] as int?,
      songCount: map['song_count'] as int? ?? 0,
      totalDuration: Duration(milliseconds: map['total_duration_ms'] as int? ?? 0),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        artworkUrl,
        year,
        songCount,
        totalDuration,
      ];
}
