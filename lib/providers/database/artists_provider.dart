import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/artist.dart';
import '../database/database_provider.dart';

final allArtistsProvider = FutureProvider<List<Artist>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getAllArtists();
});
