abstract class StorageProvider {
  Future<void> initialize();
  Future<List<StorageFile>> listFiles(String path);
  Future<StorageFile?> getFile(String id);
  Future<Stream<List<int>>> downloadFile(String fileId);
  Future<({String url, Map<String, String> headers})> getDownloadUrl(String fileId);
  Future<List<StorageFile>> searchFiles({
    required String query,
    String? mimeType,
  });
  Future<void> logout();
  bool get isAuthenticated;
  String get providerName;
}

class StorageFile {
  final String id;
  final String name;
  final String path;
  final int size;
  final String? mimeType;
  final DateTime? modifiedDate;
  final DateTime? createdDate;
  final bool isFolder;

  const StorageFile({
    required this.id,
    required this.name,
    required this.path,
    this.size = 0,
    this.mimeType,
    this.modifiedDate,
    this.createdDate,
    this.isFolder = false,
  });
}
