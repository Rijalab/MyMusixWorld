import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? artworkUrl;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int songCount;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.artworkUrl,
    this.songIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.songCount = 0,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? artworkUrl,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? songCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songCount: songCount ?? this.songCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'artwork_url': artworkUrl,
      'song_ids': songIds.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'song_count': songIds.length,
    };
  }

  factory Playlist.fromMap(Map<String, dynamic> map) {
    final songIdsRaw = map['song_ids'] as String? ?? '';
    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      artworkUrl: map['artwork_url'] as String?,
      songIds: songIdsRaw.isEmpty ? [] : songIdsRaw.split(','),
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
      songCount: map['song_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        artworkUrl,
        songIds,
        createdAt,
        updatedAt,
        songCount,
      ];
}
