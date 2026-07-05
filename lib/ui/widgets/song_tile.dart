import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/helpers.dart';
import '../../models/song.dart';
import '../../models/download_entry.dart';
import '../../core/enums/enums.dart';
import '../../providers/player/player_provider.dart';
import '../../providers/favorites/favorites_provider.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/database/playlists_provider.dart';
import '../../providers/database/database_provider.dart';
import '../../providers/database/songs_provider.dart';

class SongTile extends ConsumerWidget {
  final Song song;
  final int? index;
  final VoidCallback? onTap;
  final bool showArtwork;
  final bool showIndex;
  final Widget? trailing;
  final List<Song>? songs;

  const SongTile({
    super.key,
    required this.song,
    this.index,
    this.onTap,
    this.showArtwork = true,
    this.showIndex = false,
    this.trailing,
    this.songs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final favSongs = ref.watch(favoritesProvider).valueOrNull ?? [];
    final isFav = favSongs.any((s) => s.id == song.id);
    final isCached = ref.watch(isSongCachedProvider(song.id)).valueOrNull ?? false;

    final isCurrentlyPlaying = currentSong?.id == song.id && isPlaying;
    final isCurrentlyLoading = currentSong?.id == song.id && isLoading;

    return ListTile(
      leading: showArtwork
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 44,
                height: 44,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withAlpha(30),
            child: isCurrentlyLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : isCurrentlyPlaying
                    ? const Icon(Icons.equalizer, size: 24)
                    : const Icon(Icons.music_note, size: 24),
              ),
            )
          : null,
      title: Text(
        song.title,
        style: TextStyle(
          fontWeight:
              isCurrentlyPlaying ? FontWeight.bold : FontWeight.w500,
          color: isCurrentlyPlaying
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${song.artist}${song.album != null ? ' • ${song.album}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCached)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.download_done, size: 14, color: Colors.grey),
                ),
              if (song.duration.inMilliseconds > 0)
                Text(
                  formatDuration(song.duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                  size: 20,
                ),
                onPressed: () async {
                  final favorites =
                      ref.read(favoritesProvider.notifier);
                  await favorites.toggleFavorite(song);
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 18),
                onPressed: () => _showSongMenu(context, ref),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
      onTap: onTap ?? () async {
        final player = ref.read(playerServiceProvider);
        await player.playSong(song, queue: songs);
      },
    );
  }

  void _showSongMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              song.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () {
              Navigator.pop(ctx);
              _showPlaylistPicker(context, ref);
            },
          ),
          if (song.driveFileId != null)
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(ctx);
                _downloadSong(context, ref);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _downloadSong(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(googleDriveStorageProvider);
    final db = ref.read(databaseServiceProvider);
    try {
      final stream = await storage.downloadFile(song.driveFileId!);
      final dir = await getApplicationDocumentsDirectory();
      final localPath =
          '${dir.path}/downloads/${song.fileName}';
      final file = File(localPath);
      await file.create(recursive: true);
      final sink = file.openWrite();
      await stream.pipe(sink);
      await sink.flush();
      await sink.close();

      final entry = DownloadEntry(
        id: const Uuid().v4(),
        songId: song.id,
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: localPath,
        totalBytes: await file.length(),
        receivedBytes: await file.length(),
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );
      await db.insertDownload(entry);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _showPlaylistPicker(BuildContext context, WidgetRef ref) {
    final playlists = ref.read(allPlaylistsProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add to Playlist',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No playlists yet. Create one!'),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (ctx, i) {
                  final playlist = playlists[i];
                  final alreadyAdded = playlist.songIds.contains(song.id);
                  return ListTile(
                    title: Text(playlist.name),
                    subtitle: Text('${playlist.songCount} songs'),
                    trailing: alreadyAdded
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.add_circle_outline),
                    onTap: () {
                      if (!alreadyAdded) {
                        ref
                            .read(allPlaylistsProvider.notifier)
                            .addSongToPlaylist(playlist.id, song.id);
                      }
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create New Playlist'),
            onTap: () {
              Navigator.pop(ctx);
              _showCreatePlaylistDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(allPlaylistsProvider.notifier)
                    .createPlaylist(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
