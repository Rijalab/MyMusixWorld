import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/enums.dart';
import '../../../providers/database/songs_provider.dart';
import '../../../providers/database/albums_provider.dart';
import '../../../providers/database/artists_provider.dart';
import '../../../providers/favorites/favorites_provider.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/sync/sync_provider.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/album_card.dart';

final _syncTriggeredProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_syncTriggeredProvider.notifier).state = true;
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        _runSync();
      }
    });
  }

  Future<void> _runSync() async {
    final syncService = ref.read(syncServiceProvider);
    try {
      await syncService.sync();
      if (context.mounted) {
        ref.invalidate(allSongsProvider);
        ref.invalidate(allAlbumsProvider);
        ref.invalidate(allArtistsProvider);
        ref.invalidate(recentlyPlayedProvider);
        ref.invalidate(recentlyAddedProvider);
        ref.invalidate(favoritesProvider);
        ref.invalidate(songCountProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final albums = ref.watch(allAlbumsProvider);
    final favorites = ref.watch(favoritesProvider);
    final songCount = ref.watch(songCountProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return RefreshIndicator(
      onRefresh: _runSync,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(
              'Good ${_greeting()}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () =>
                    context.go('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: syncStatus.when(
              data: (status) {
                if (status == SyncStatus.syncing ||
                    status == SyncStatus.scanning) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LinearProgressIndicator(),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          if (recentlyPlayed.hasValue &&
              recentlyPlayed.value!.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recently Played',
                onSeeAll: () {},
              ),
            ),
          if (recentlyPlayed.hasValue &&
              recentlyPlayed.value!.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentlyPlayed.value!.length,
                  itemBuilder: (ctx, i) => SizedBox(
                    width: 300,
                    child: SongTile(
                      song: recentlyPlayed.value![i],
                      showArtwork: true,
                      songs: recentlyPlayed.value!,
                    ),
                  ),
                ),
              ),
            ),
          if (albums.hasValue && albums.value!.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Albums',
                onSeeAll: () {},
              ),
            ),
          if (albums.hasValue && albums.value!.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: albums.value!.length,
                  itemBuilder: (ctx, i) => SizedBox(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AlbumCard(album: albums.value![i]),
                    ),
                  ),
                ),
              ),
            ),
          if (recentlyAdded.hasValue &&
              recentlyAdded.value!.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Recently Added',
                onSeeAll: () {},
              ),
            ),
          if (recentlyAdded.hasValue &&
              recentlyAdded.value!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => SongTile(
                  song: recentlyAdded.value![i],
                  showIndex: false,
                  songs: recentlyAdded.value!,
                ),
                childCount: recentlyAdded.value!.length.clamp(0, 10),
              ),
            ),
          if (favorites.hasValue && favorites.value!.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Favorites',
                onSeeAll: () {},
              ),
            ),
          if (favorites.hasValue && favorites.value!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => SongTile(
                  song: favorites.value![i],
                  showIndex: false,
                  songs: favorites.value!,
                ),
                childCount: favorites.value!.length.clamp(0, 10),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${songCount.valueOrNull ?? 0} songs in library',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }
}
