import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/playlist.dart';
import '../../../models/song.dart';
import '../../../providers/database/playlists_provider.dart';
import '../../../providers/database/songs_provider.dart';
import '../../widgets/song_tile.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(allPlaylistsProvider);
    final songsAsync = ref.watch(allSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playlistsAsync.valueOrNull
                  ?.firstWhere((p) => p.id == playlistId,
                      orElse: () => Playlist(
                            id: '',
                            name: 'Playlist',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          ))
                  .name ??
              'Playlist',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Playlist'),
                  content: const Text(
                      'Are you sure you want to delete this playlist?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(allPlaylistsProvider.notifier)
                    .deletePlaylist(playlistId);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: playlistsAsync.when(
        data: (playlists) {
          final playlist = playlists.firstWhere(
            (p) => p.id == playlistId,
            orElse: () => Playlist(
              id: '',
              name: 'Unknown',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          if (playlist.id.isEmpty) {
            return const Center(child: Text('Playlist not found'));
          }

          return songsAsync.when(
            data: (allSongs) {
              final songMap = {for (final s in allSongs) s.id: s};
              final playlistSongs = playlist.songIds
                  .map((id) => songMap[id])
                  .whereType<Song>()
                  .toList();

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 200,
                            height: 200,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(25),
                            child: const Center(
                              child: Icon(Icons.queue_music, size: 64),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          playlist.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('${playlistSongs.length} songs'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(allPlaylistsProvider.notifier)
                                    .playPlaylist(playlist);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _showAddSongsDialog(
                                  context, ref, playlist, allSongs),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Songs'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: playlistSongs.length,
                      onReorder: (oldIndex, newIndex) {
                        ref
                            .read(allPlaylistsProvider.notifier)
                            .reorderPlaylist(playlistId, oldIndex, newIndex);
                      },
                      itemBuilder: (ctx, i) {
                        final song = playlistSongs[i];
                        return SongTile(
                          key: ValueKey(song.id),
                          song: song,
                          songs: playlistSongs,
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red, size: 20),
                            onPressed: () {
                              ref
                                  .read(allPlaylistsProvider.notifier)
                                  .removeSongFromPlaylist(
                                      playlistId, song.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'New name',
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
                    .renamePlaylist(playlistId, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showAddSongsDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    List<Song> allSongs,
  ) {
    final availableSongs = allSongs
        .where((s) => !playlist.songIds.contains(s.id))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add Songs to ${playlist.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: availableSongs.isEmpty
                  ? const Center(
                      child: Text('All songs are already in this playlist'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: availableSongs.length,
                      itemBuilder: (ctx, i) {
                        final song = availableSongs[i];
                        return ListTile(
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            ref
                                .read(allPlaylistsProvider.notifier)
                                .addSongToPlaylist(playlist.id, song.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
