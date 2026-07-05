import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/search/search_provider.dart';
import '../../../providers/database/songs_provider.dart';
import '../../../models/song.dart';
import '../../widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final allSongs = ref.watch(allSongsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search songs, artists, albums...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchState.query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchProvider.notifier).clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) {
              ref.read(searchProvider.notifier).search(value);
            },
          ),
        ),
        Expanded(
          child: searchState.query.isEmpty
              ? _buildInitialState(allSongs)
              : _buildSearchResults(searchState),
        ),
      ],
    );
  }

  Widget _buildInitialState(AsyncValue<List<Song>> allSongs) {
    return allSongs.when(
      data: (songs) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: songs.length,
        itemBuilder: (ctx, i) => SongTile(song: songs[i]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSearchResults(SearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasResults = state.songs.isNotEmpty ||
        state.albums.isNotEmpty ||
        state.artists.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(77)),
            const SizedBox(height: 16),
            Text('No results for "${state.query}"'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (state.songs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Songs',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                    )),
          ),
          ...state.songs.map((s) => SongTile(song: s)),
        ],
        if (state.artists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Artists',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                    )),
          ),
          ...state.artists.map((a) => ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Text(
                    a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(a.name),
                subtitle: Text('${a.songCount} songs'),
                onTap: () {},
              )),
        ],
        if (state.albums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Albums',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                    )),
          ),
          ...state.albums.map((a) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 44,
                    height: 44,
                    color:
                        Theme.of(context).colorScheme.primary.withAlpha(30),
                    child: const Icon(Icons.album),
                  ),
                ),
                title: Text(a.title),
                subtitle: Text('${a.artist} • ${a.songCount} songs'),
                onTap: () {},
              )),
        ],
      ],
    );
  }
}
