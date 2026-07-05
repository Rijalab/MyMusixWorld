import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/album.dart';
import '../../../providers/database/songs_provider.dart';
import '../../../providers/player/player_provider.dart';
import '../../widgets/song_tile.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(
      songsByAlbumProvider((albumTitle: album.title, artist: album.artist)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(album.title),
      ),
      body: songsAsync.when(
        data: (songs) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 180,
                        height: 180,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(25),
                        child: const Center(
                          child: Icon(Icons.album, size: 64),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      album.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${album.artist} • ${songs.length} songs',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (songs.isNotEmpty) {
                          ref
                              .read(playerServiceProvider)
                              .playSong(songs.first, queue: songs);
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play All'),
                    ),
                  ],
                ),
              ),
            ),
            if (songs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No songs in this album')),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => SongTile(
                    song: songs[i],
                    index: i + 1,
                    showIndex: true,
                    songs: songs,
                  ),
                  childCount: songs.length,
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
