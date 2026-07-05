import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/enums/enums.dart';
import 'providers/settings/settings_provider.dart';
import 'ui/router/app_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return createRouter();
});

class MyMusixWorld extends ConsumerWidget {
  const MyMusixWorld({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    final themeMode = switch (settings.themeMode) {
      ThemeModePreference.light => ThemeMode.light,
      ThemeModePreference.dark => ThemeMode.dark,
      ThemeModePreference.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'MyMusixWorld',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
