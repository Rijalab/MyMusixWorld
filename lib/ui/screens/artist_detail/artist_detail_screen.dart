import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/artist.dart';
import '../../../providers/database/songs_provider.dart';
import '../../../providers/player/player_provider.dart';
import '../../widgets/song_tile.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final Artist artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsByArtistProvider(artist.name));

    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
      ),
      body: songsAsync.when(
        data: (songs) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 72,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(25),
                      child: Text(
                        artist.name.isNotEmpty
                            ? artist.name[0].toUpperCase()
                            : '?',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      artist.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${artist.albumCount} albums • ${songs.length} songs',
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
                child: Center(child: Text('No songs by this artist')),
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
