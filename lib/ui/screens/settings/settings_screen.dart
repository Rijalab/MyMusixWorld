import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/enums/enums.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/settings/settings_provider.dart';
import '../../../providers/database/songs_provider.dart';
import '../../../providers/database/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final songCount = ref.watch(songCountProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        // Profile
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withAlpha(30),
              child: Text(
                (auth.userName?.isNotEmpty == true)
                    ? auth.userName![0].toUpperCase()
                    : 'G',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            title: Text(auth.userName ?? 'User'),
            subtitle: Text(auth.userEmail ?? ''),
          ),
        ),
        const SizedBox(height: 24),
        Text('Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                trailing: DropdownButton<ThemeModePreference>(
                  value: settings.themeMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeModePreference.dark,
                      child: Text('Dark'),
                    ),
                    DropdownMenuItem(
                      value: ThemeModePreference.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeModePreference.system,
                      child: Text('System'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(v);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Audio Quality',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.wifi),
                title: const Text('Streaming Quality'),
                subtitle: const Text('Higher quality uses more data'),
                trailing: DropdownButton<StreamingQuality>(
                  value: settings.streamingQuality,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: StreamingQuality.low,
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: StreamingQuality.medium,
                      child: Text('Medium'),
                    ),
                    DropdownMenuItem(
                      value: StreamingQuality.high,
                      child: Text('High'),
                    ),
                    DropdownMenuItem(
                      value: StreamingQuality.lossless,
                      child: Text('Lossless'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setStreamingQuality(v);
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download Quality'),
                subtitle: const Text('Higher quality uses more storage'),
                trailing: DropdownButton<StreamingQuality>(
                  value: settings.downloadQuality,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: StreamingQuality.low,
                      child: Text('Low'),
                    ),
                    DropdownMenuItem(
                      value: StreamingQuality.medium,
                      child: Text('Medium'),
                    ),
                    DropdownMenuItem(
                      value: StreamingQuality.high,
                      child: Text('High'),
                    ),
                    DropdownMenuItem(
                      value: StreamingQuality.lossless,
                      child: Text('Lossless'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setDownloadQuality(v);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Storage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.library_music_outlined),
                title: const Text('Library Size'),
                trailing: Text('${songCount.valueOrNull ?? 0} songs'),
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Cache Size'),
                subtitle: Text('${settings.cacheSizeMB} MB'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCacheDialog(context, ref, settings),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear Cache'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Cache'),
                      content: const Text(
                          'Are you sure? Cached songs will need to be downloaded again.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final db = ref.read(databaseServiceProvider);
                    final cachedIds = await db.getAllCachedSongIds();
                    final dir = await getApplicationDocumentsDirectory();
                    final cacheDir = Directory('${dir.path}/cache');
                    if (await cacheDir.exists()) {
                      await cacheDir.delete(recursive: true);
                    }
                    await db.clearAllCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cleared ${cachedIds.length} cached songs')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out'),
            subtitle: const Text('Disconnect Google account'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text(
                      'Are you sure? You will need to sign in again to access your music.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final db = ref.read(databaseServiceProvider);
                await db.clearAllData();
                await ref.read(authProvider.notifier).signOut();
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        Text('About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Built with Flutter'),
                subtitle: const Text('MyMusixWorld - Personal Music Cloud'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showCacheDialog(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    final controller =
        TextEditingController(text: settings.cacheSizeMB.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cache Size (MB)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final size = int.tryParse(controller.text);
              if (size != null && size > 0) {
                ref.read(settingsProvider.notifier).setCacheSize(size);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
