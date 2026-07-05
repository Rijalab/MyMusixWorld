import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/splash_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/now_playing/now_playing_screen.dart';
import '../screens/playlist_detail/playlist_detail_screen.dart';
import '../screens/album_detail/album_detail_screen.dart';
import '../screens/artist_detail/artist_detail_screen.dart';
import '../../models/album.dart' show Album;
import '../../models/artist.dart' show Artist;
import '../widgets/mini_player.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AuthNotifierForRouter extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  void update(bool authenticated) {
    _isLoading = false;
    _isAuthenticated = authenticated;
    notifyListeners();
  }
}

final authRouterNotifier = AuthNotifierForRouter();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authRouterNotifier,
    redirect: (ctx, state) {
      if (authRouterNotifier.isLoading) return null;
      final isSplash = state.matchedLocation == '/splash';
      if (authRouterNotifier.isAuthenticated && isSplash) return '/home';
      if (!authRouterNotifier.isAuthenticated && !isSplash) return '/splash';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (ctx, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (ctx, state) => _buildPage(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (ctx, state) => _buildPage(state, const SearchScreen()),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (ctx, state) => _buildPage(state, const LibraryScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (ctx, state) => _buildPage(state, const SettingsScreen()),
          ),
          GoRoute(
            path: '/albums/:id',
            builder: (ctx, state) {
              final id = state.pathParameters['id']!;
              final album = Album(
                id: id,
                title: id.contains('|') ? id.split('|')[0] : id,
                artist: id.contains('|') ? id.split('|')[1] : 'Unknown Artist',
              );
              return AlbumDetailScreen(album: album);
            },
          ),
          GoRoute(
            path: '/artists/:id',
            builder: (ctx, state) {
              final id = state.pathParameters['id']!;
              final artist = Artist(id: id, name: id);
              return ArtistDetailScreen(artist: artist);
            },
          ),
          GoRoute(
            path: '/playlists/:id',
            builder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return PlaylistDetailScreen(playlistId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/now-playing',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NowPlayingScreen(),
          transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
    ],
  );
}

Page<Object?> _buildPage(GoRouterState state, Widget child) {
  final offset = Offset(0.0, 0.05 * math.sin(state.path!.length));
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    final isTabRoute = location.startsWith('/home') ||
        location.startsWith('/search') ||
        location.startsWith('/library') ||
        location.startsWith('/settings');

    int currentIndex = 0;
    if (location.startsWith('/home')) currentIndex = 0;
    else if (location.startsWith('/search')) currentIndex = 1;
    else if (location.startsWith('/library')) currentIndex = 2;
    else if (location.startsWith('/settings')) currentIndex = 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            const MiniPlayer(),
            if (isTabRoute)
              BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (i) {
                  switch (i) {
                    case 0: context.go('/home');
                    case 1: context.go('/search');
                    case 2: context.go('/library');
                    case 3: context.go('/settings');
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search_outlined),
                    activeIcon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.library_music_outlined),
                    activeIcon: Icon(Icons.library_music),
                    label: 'Library',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
