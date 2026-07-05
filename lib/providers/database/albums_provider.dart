import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/album.dart';
import '../database/database_provider.dart';

final allAlbumsProvider = FutureProvider<List<Album>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllAlbums();
});
