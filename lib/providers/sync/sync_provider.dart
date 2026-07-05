import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/sync_service.dart';
import '../../core/enums/enums.dart';
import '../auth/auth_provider.dart';
import '../database/database_provider.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final storage = ref.watch(googleDriveStorageProvider);
  final database = ref.watch(databaseServiceProvider);
  final syncService = SyncService(
    storage: storage,
    database: database,
  );
  ref.onDispose(() => syncService.dispose());
  return syncService;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.syncStateStream;
});

final syncProgressProvider = StreamProvider<double>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.progressStream;
});
