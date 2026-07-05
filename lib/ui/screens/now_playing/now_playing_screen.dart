import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/enums.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/song.dart';
import '../../../providers/player/player_provider.dart';
import '../../../providers/favorites/favorites_provider.dart';
import '../../../services/player_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isPlaying = ref.watch(isPlayingProvider);
    final repeatMode = ref.watch(repeatModeProvider);
    final isShuffled = ref.watch(isShuffledProvider);
    final playbackSpeed = ref.watch(playbackSpeedProvider);
    final player = ref.read(playerServiceProvider);

    final isLoading = ref.watch(isLoadingProvider);
    final favSongs = ref.watch(favoritesProvider).valueOrNull ?? [];
    final isFav = favSongs.any((s) => s.id == currentSong?.id);

    if (currentSong == null) {
      return const Scaffold(
        body: Center(child: Text('No song playing')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Now Playing',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 1),
                // Artwork
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withAlpha(25),
                      child: const Center(
                        child: Icon(Icons.music_note, size: 96),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 1),
                // Song info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSong.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.artist,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(179),
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : null,
                      ),
                      onPressed: () async {
                        await ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(currentSong);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                _ProgressBar(player: player, song: currentSong),
                const SizedBox(height: 8),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: isShuffled
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => player.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 36),
                      onPressed: () => player.previous(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                          color: Colors.black,
                        ),
                        onPressed: () => player.togglePlayPause(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 36),
                      onPressed: () => player.next(),
                    ),
                    IconButton(
                      icon: Icon(
                        repeatMode == RepeatMode.all
                            ? Icons.repeat
                            : repeatMode == RepeatMode.one
                                ? Icons.repeat_one
                                : Icons.repeat_outlined,
                        color: repeatMode != RepeatMode.off
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () {
                        final modes = RepeatMode.values;
                        final nextIndex =
                            (repeatMode.index + 1) % modes.length;
                        player.setRepeatMode(modes[nextIndex]);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Secondary controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SecondaryControl(
                      icon: Icons.download_outlined,
                      label: 'Download',
                      onTap: () {},
                    ),
                    _SecondaryControl(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () {},
                    ),
                    _SecondaryControl(
                      icon: Icons.speed,
                      label: '${playbackSpeed}x',
                      onTap: () => _showSpeedDialog(context, player, playbackSpeed),
                    ),
                    _SecondaryControl(
                      icon: Icons.timer_outlined,
                      label: 'Sleep',
                      onTap: () {},
                    ),
                    _SecondaryControl(
                      icon: Icons.queue_music_outlined,
                      label: 'Queue',
                      onTap: () => _showQueue(context, ref),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Buffering...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 200.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSpeedDialog(BuildContext context, PlayerService player, double currentSpeed) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            final isSelected = speed == player.playbackSpeed;
            return ListTile(
              title: Text('${speed}x'),
              trailing: isSelected
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                player.setPlaybackSpeed(speed);
                setDialogState(() {});
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context, WidgetRef ref) {
    final queue = ref.read(queueProvider);
    final currentIndex = ref.read(playerServiceProvider).currentIndex;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Queue (${queue.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (ctx, i) {
                final song = queue[i];
                final isCurrent = i == currentIndex;
                return ListTile(
                  leading: isCurrent
                      ? Icon(Icons.play_arrow,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  subtitle: Text(song.artist),
                  onTap: () {
                    ref.read(playerServiceProvider).seekToSong(i);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends ConsumerStatefulWidget {
  final PlayerService player;
  final Song song;

  const _ProgressBar({required this.player, required this.song});

  @override
  ConsumerState<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<_ProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final duration = ref.watch(playerDurationProvider) ?? widget.song.duration;
    final max = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;

    double position;
    if (_isDragging) {
      position = _dragValue;
    } else {
      position = ref.watch(playerPositionProvider).valueOrNull?.inMilliseconds
              .toDouble() ??
          0;
    }

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: position.clamp(0, max),
            max: max,
            onChanged: (v) {
              setState(() => _dragValue = v);
            },
            onChangeStart: (_) {
              setState(() => _isDragging = true);
            },
            onChangeEnd: (v) {
              setState(() => _isDragging = false);
              widget.player.seek(Duration(milliseconds: v.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(
                  Duration(milliseconds: position.toInt())),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                formatDuration(duration),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecondaryControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
