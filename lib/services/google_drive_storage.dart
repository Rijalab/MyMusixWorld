import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';
import 'storage_provider.dart';

class GoogleDriveStorage extends StorageProvider {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentAccount;
  drive.DriveApi? _driveApi;
  http.Client? _httpClient;

  GoogleSignIn get googleSignIn => _googleSignIn;
  GoogleSignInAccount? get currentAccount => _currentAccount;

  @override
  String get providerName => 'Google Drive';

  @override
  bool get isAuthenticated => _driveApi != null;

  @override
  Future<void> initialize() async {
    await _googleSignIn.initialize(
      clientId: '390765702395-otrqcldpjs962bvmk6fcv8i8d7n0pdia.apps.googleusercontent.com',
      serverClientId: '390765702395-i44sooo5cplb14ejd418qrvid99h66v8.apps.googleusercontent.com',
    );
    final result = await _googleSignIn.attemptLightweightAuthentication();
    if (result != null) {
      _currentAccount = result;
      final authHeaders = await result.authorizationClient.authorizationHeaders(
        [drive.DriveApi.driveReadonlyScope],
        promptIfNecessary: true,
      );
      if (authHeaders != null) {
        _httpClient = _GoogleAuthClient(http.Client(), authHeaders);
        _driveApi = drive.DriveApi(_httpClient!);
      }
    }
  }

  Future<void> signIn() async {
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: [drive.DriveApi.driveReadonlyScope],
      );
      _currentAccount = account;

      final authHeaders = await account.authorizationClient.authorizationHeaders(
        [drive.DriveApi.driveReadonlyScope],
        promptIfNecessary: true,
      );
      if (authHeaders == null) {
        throw AuthException('Failed to obtain authorization');
      }

      _httpClient?.close();
      _httpClient = _GoogleAuthClient(http.Client(), authHeaders);
      _driveApi = drive.DriveApi(_httpClient!);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in: $e');
    }
  }

  Future<String> getMusicFolderId() async {
    if (_driveApi == null) throw StorageException('Not authenticated');

    final response = await _driveApi!.files.list(
      q: "name = '${AppConstants.musicFolderName}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
    );

    if (response.files != null && response.files!.isNotEmpty) {
      return response.files!.first.id!;
    }

    throw StorageException('Music folder "${AppConstants.musicFolderName}" not found in Google Drive');
  }

  @override
  Future<List<StorageFile>> listFiles(String path) async {
    if (_driveApi == null) throw StorageException('Not authenticated');

    final folderId = await getMusicFolderId();
    final allFiles = await _listAllFilesInFolder(folderId);
    return _filterAudioFiles(folderId, allFiles, 'MyMusic');
  }

  Future<List<drive.File>> _listAllFilesInFolder(String folderId) async {
    if (_driveApi == null) throw StorageException('Not authenticated');

    List<drive.File> allFiles = [];
    List<String> subfolderIds = [];
    String? nextPageToken;

    do {
      final response = await _driveApi!.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        pageToken: nextPageToken,
        pageSize: 1000,
        $fields: 'files(id,name,size,mimeType,modifiedTime,createdTime,parents),nextPageToken',
      );

      if (response.files != null) {
        for (final file in response.files!) {
          if (file.mimeType == 'application/vnd.google-apps.folder') {
            subfolderIds.add(file.id!);
          }
          allFiles.add(file);
        }
      }
      nextPageToken = response.nextPageToken;
    } while (nextPageToken != null);

    for (final subId in subfolderIds) {
      allFiles.addAll(await _listAllFilesInFolder(subId));
    }

    return allFiles;
  }

  List<StorageFile> _filterAudioFiles(String folderId, List<drive.File> allFiles, String currentPath) {
    final result = <StorageFile>[];

    final folders = allFiles.where((f) =>
        f.mimeType == 'application/vnd.google-apps.folder' &&
        (f.parents?.contains(folderId) ?? false));

    final audioFiles = allFiles.where((f) =>
        f.mimeType != 'application/vnd.google-apps.folder' &&
        isAudioFile(f.name ?? '') &&
        (f.parents?.contains(folderId) ?? false));

    for (final file in audioFiles) {
      result.add(StorageFile(
        id: file.id!,
        name: file.name!,
        path: '$currentPath/${file.name}',
        size: int.tryParse(file.size ?? '0') ?? 0,
        mimeType: file.mimeType,
        modifiedDate: file.modifiedTime != null
            ? DateTime.tryParse(file.modifiedTime!.toIso8601String())
            : null,
        createdDate: file.createdTime != null
            ? DateTime.tryParse(file.createdTime!.toIso8601String())
            : null,
      ));
    }

    for (final folder in folders) {
      final subFiles = _filterAudioFiles(
        folder.id!,
        allFiles,
        '$currentPath/${folder.name}',
      );
      result.addAll(subFiles);
    }

    return result;
  }

  bool isAudioFile(String name) {
    final ext = name.toLowerCase();
    return AppConstants.supportedExtensions.any((e) => ext.endsWith(e));
  }

  @override
  Future<StorageFile?> getFile(String id) async {
    if (_driveApi == null) throw StorageException('Not authenticated');
    final result = await _driveApi!.files.get(
      id,
      $fields: 'id,name,size,mimeType,modifiedTime,createdTime',
    );
    final file = result as dynamic;
    return StorageFile(
      id: file.id as String,
      name: file.name as String,
      path: file.name!,
      size: int.tryParse(file.size ?? '0') ?? 0,
      mimeType: file.mimeType,
      modifiedDate: file.modifiedTime != null
          ? DateTime.tryParse(file.modifiedTime!.toIso8601String())
          : null,
      createdDate: file.createdTime != null
          ? DateTime.tryParse(file.createdTime!.toIso8601String())
          : null,
    );
  }

  @override
  Future<Stream<List<int>>> downloadFile(String fileId) async {
    if (_driveApi == null) throw StorageException('Not authenticated');

    final account = _currentAccount;
    if (account == null) throw StorageException('Not authenticated');

    final authHeaders = await account.authorizationClient.authorizationHeaders(
      [drive.DriveApi.driveReadonlyScope],
      promptIfNecessary: true,
    );
    if (authHeaders == null) throw StorageException('Failed to obtain authorization');

    final url = 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media';
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(authHeaders);

    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      throw StorageException('Failed to download file: ${response.statusCode}');
    }
    return response.stream;
  }

  @override
  Future<({String url, Map<String, String> headers})> getDownloadUrl(String fileId) async {
    if (_driveApi == null) throw StorageException('Not authenticated');
    final account = _currentAccount;
    if (account == null) throw StorageException('Not authenticated');

    final authHeaders = await account.authorizationClient.authorizationHeaders(
      [drive.DriveApi.driveReadonlyScope],
      promptIfNecessary: true,
    );
    if (authHeaders == null) throw StorageException('Failed to obtain authorization');

    final url = 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media';
    return (url: url, headers: authHeaders);
  }

  @override
  Future<List<StorageFile>> searchFiles({
    required String query,
    String? mimeType,
  }) async {
    if (_driveApi == null) throw StorageException('Not authenticated');

    final folderId = await getMusicFolderId();
    String searchQuery = "'$folderId' in parents and trashed = false and name contains '$query'";
    if (mimeType != null) {
      searchQuery += " and mimeType = '$mimeType'";
    }

    final response = await _driveApi!.files.list(
      q: searchQuery,
      spaces: 'drive',
      pageSize: 100,
    );

    if (response.files == null) return [];

    return response.files!
        .where((f) => isAudioFile(f.name ?? ''))
        .map((f) => StorageFile(
              id: f.id!,
              name: f.name!,
              path: f.name!,
              size: int.tryParse(f.size ?? '0') ?? 0,
              mimeType: f.mimeType,
            ))
        .toList();
  }

  @override
  Future<void> logout() async {
    _driveApi = null;
    _httpClient?.close();
    _httpClient = null;
    _currentAccount = null;
    await _googleSignIn.disconnect();
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final http.Client _inner;
  final Map<String, String> _authHeaders;

  _GoogleAuthClient(this._inner, this._authHeaders);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_authHeaders);
    return _inner.send(request);
  }
}
