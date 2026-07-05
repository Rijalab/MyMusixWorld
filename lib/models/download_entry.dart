import 'package:equatable/equatable.dart';
import '../core/enums/enums.dart';

class DownloadEntry extends Equatable {
  final String id;
  final String songId;
  final DownloadStatus status;
  final double progress;
  final String? localPath;
  final int totalBytes;
  final int receivedBytes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const DownloadEntry({
    required this.id,
    required this.songId,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.localPath,
    this.totalBytes = 0,
    this.receivedBytes = 0,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  DownloadEntry copyWith({
    String? id,
    String? songId,
    DownloadStatus? status,
    double? progress,
    String? localPath,
    int? totalBytes,
    int? receivedBytes,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return DownloadEntry(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      totalBytes: totalBytes ?? this.totalBytes,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'song_id': songId,
      'status': status.index,
      'progress': progress,
      'local_path': localPath,
      'total_bytes': totalBytes,
      'received_bytes': receivedBytes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'error_message': errorMessage,
    };
  }

  factory DownloadEntry.fromMap(Map<String, dynamic> map) {
    return DownloadEntry(
      id: map['id'] as String,
      songId: map['song_id'] as String,
      status: DownloadStatus.values[map['status'] as int? ?? 0],
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      localPath: map['local_path'] as String?,
      totalBytes: map['total_bytes'] as int? ?? 0,
      receivedBytes: map['received_bytes'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      errorMessage: map['error_message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        songId,
        status,
        progress,
        localPath,
        totalBytes,
        receivedBytes,
        createdAt,
        completedAt,
        errorMessage,
      ];
}
