class AppConstants {
  static const String appName = 'MyMusixWorld';
  static const String musicFolderName = 'MyMusic';
  static const int defaultCacheSizeMB = 2048;
  static const int searchDebounceMs = 300;
  static const int preloadBufferCount = 2;
  static const double defaultPlaybackSpeed = 1.0;

  static const List<String> supportedFormats = [
    'mp3', 'm4a', 'aac', 'flac', 'wav', 'ogg',
  ];

  static const List<String> supportedExtensions = [
    '.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg',
  ];
}
