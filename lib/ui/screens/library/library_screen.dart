import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/database/songs_provider.dart';
import '../../../providers/database/albums_provider.dart';
import '../../../providers/database/artists_provider.dart';
import '../../../providers/database/playlists_provider.dart';
import '../../../providers/favorites/favorites_provider.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/album_card.dart';
import '../../widgets/playlist_card.dart';

enum LibraryTab {
  songs('Songs', Icons.music_note),
  albums('Albums', Icons.album),
  artists('Artists', Icons.person),
  playlists('Playlists', Icons.queue_music),
  favorites('Favorites', Icons.favorite),
  downloads('Downloads', Icons.download);

  final String label;
  final IconData icon;
  const LibraryTab(this.label, this.icon);
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryTab _selectedTab = LibraryTab.songs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: LibraryTab.values.length,
            itemBuilder: (ctx, i) {
              final tab = LibraryTab.values[i];
              final isSelected = tab == _selectedTab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tab.label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTab = tab),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case LibraryTab.songs:
        return _buildSongsList();
      case LibraryTab.albums:
        return _buildAlbumsGrid();
      case LibraryTab.artists:
        return _buildArtistsList();
      case LibraryTab.playlists:
        return _buildPlaylistsGrid();
      case LibraryTab.favorites:
        return _buildFavoritesList();
      case LibraryTab.downloads:
        return _buildDownloadsList();
    }
  }

  Widget _buildSongsList() {
    final songs = ref.watch(allSongsProvider);
    return songs.when(
      data: (data) => data.isEmpty
          ? _emptyState('No songs found')
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (ctx, i) => SongTile(song: data[i], index: i + 1, songs: data),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Widget _buildAlbumsGrid() {
    final albums = ref.watch(allAlbumsProvider);
    return albums.when(
      data: (data) => data.isEmpty
          ? _emptyState('No albums found')
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: data.length,
              itemBuilder: (ctx, i) => AlbumCard(album: data[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Widget _buildArtistsList() {
    final artists = ref.watch(allArtistsProvider);
    return artists.when(
      data: (data) => data.isEmpty
          ? _emptyState('No artists found')
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (ctx, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Text(
                    data[i].name.isNotEmpty
                        ? data[i].name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(data[i].name),
                subtitle: Text('${data[i].songCount} songs'),
                onTap: () => context.push('/artists/${data[i].name}'),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Widget _buildPlaylistsGrid() {
    final playlists = ref.watch(allPlaylistsProvider);
    return playlists.when(
      data: (data) {
        if (data.isEmpty) return _emptyState('No playlists created yet');
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: data.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return _CreatePlaylistCard(onTap: () => _showCreatePlaylistDialog());
            }
            return PlaylistCard(playlist: data[i - 1]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Widget _buildFavoritesList() {
    final favorites = ref.watch(favoritesProvider);
    return favorites.when(
      data: (data) => data.isEmpty
          ? _emptyState('No favorite songs yet')
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (ctx, i) => SongTile(song: data[i], songs: data),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _errorState(e.toString()),
    );
  }

  Widget _buildDownloadsList() {
    return _emptyState('Downloads coming soon');
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_music_outlined, size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(77)),
          const SizedBox(height: 16),
          Text(message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  )),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(child: Text('Error: $message'));
  }

  void _showCreatePlaylistDialog() {
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

class _CreatePlaylistCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreatePlaylistCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(51),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create Playlist',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          const Text('Create a new playlist'),
        ],
      ),
    );
  }
}
