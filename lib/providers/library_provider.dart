import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_file.dart';
import '../database/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final scannedFoldersProvider = FutureProvider<List<ScannedFolder>>((ref) async {
  final db = ref.read(databaseProvider);
  return db.scannedFoldersDao.getAllFolders();
});

final allVideosProvider = FutureProvider<List<VideoFileModel>>((ref) async {
  final db = ref.read(databaseProvider);
  final videos = await db.videoFilesDao.getAllVideos();
  return videos.map((v) => VideoFileModel.fromDb(v)).toList();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredVideosProvider = Provider<AsyncValue<List<VideoFileModel>>>((ref) {
  final allVideosAsync = ref.watch(allVideosProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return allVideosAsync.whenData((videos) {
    if (query.isEmpty) return videos;
    return videos.where((v) => v.name.toLowerCase().contains(query)).toList();
  });
});

enum SortMode { name, date, size }
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.name);

enum ViewMode { grid, list, folder }
final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.grid);
