import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_service.dart';
import '../../models/song.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../database/database_provider.dart';

class SearchState {
  final String query;
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.isLoading = false,
  });

  SearchState copyWith({
    String? query,
    List<Song>? songs,
    List<Album>? albums,
    List<Artist>? artists,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SearchNotifier(db);
});

class SearchNotifier extends StateNotifier<SearchState> {
  final DatabaseService _db;
  Timer? _debounce;

  SearchNotifier(this._db) : super(const SearchState());

  void search(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final songs = await _db.searchSongs(query);
        final allAlbums = await _db.getAllAlbums();
        final allArtists = await _db.getAllArtists();

        final albums = allAlbums
            .where((a) =>
                a.title.toLowerCase().contains(query.toLowerCase()) ||
                a.artist.toLowerCase().contains(query.toLowerCase()))
            .toList();

        final artists = allArtists
            .where((a) =>
                a.name.toLowerCase().contains(query.toLowerCase()))
            .toList();

        state = SearchState(
          query: query,
          songs: songs,
          albums: albums,
          artists: artists,
          isLoading: false,
        );

        if (query.isNotEmpty) {
          await _db.addSearchHistory(query);
        }
      } catch (e) {
        state = state.copyWith(isLoading: false);
      }
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
