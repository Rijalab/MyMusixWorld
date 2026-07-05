import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final String? artworkUrl;
  final int albumCount;
  final int songCount;

  const Artist({
    required this.id,
    required this.name,
    this.artworkUrl,
    this.albumCount = 0,
    this.songCount = 0,
  });

  Artist copyWith({
    String? id,
    String? name,
    String? artworkUrl,
    int? albumCount,
    int? songCount,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      albumCount: albumCount ?? this.albumCount,
      songCount: songCount ?? this.songCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artwork_url': artworkUrl,
      'album_count': albumCount,
      'song_count': songCount,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String,
      name: map['name'] as String,
      artworkUrl: map['artwork_url'] as String?,
      albumCount: map['album_count'] as int? ?? 0,
      songCount: map['song_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, artworkUrl, albumCount, songCount];
}
