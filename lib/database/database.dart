import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  VideoFiles,
  PlaybackState,
  Playlists,
  PlaylistItems,
  ScannedFolders,
  VaultSettings,
  VaultFiles,
], daos: [
  VideoFilesDao,
  PlaybackStateDao,
  PlaylistsDao,
  ScannedFoldersDao,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zap_media_player', 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftAccessor(tables: [VideoFiles])
class VideoFilesDao extends DatabaseAccessor<AppDatabase> with _$VideoFilesDaoMixin {
  VideoFilesDao(AppDatabase db) : super(db);

  Future<List<VideoFile>> getAllVideos() => select(videoFiles).get();
  Future<VideoFile?> getVideoByPath(String path) => (select(videoFiles)..where((t) => t.path.equals(path))).getSingleOrNull();
  Future<List<VideoFile>> searchVideos(String query) => (select(videoFiles)..where((t) => t.name.like('%$query%'))).get();
  Future<List<VideoFile>> getVideosByFolder(String folderPath) => (select(videoFiles)..where((t) => t.path.like('$folderPath%'))).get();
  Future<int> insertVideo(VideoFilesCompanion video) => into(videoFiles).insert(video, mode: InsertMode.insertOrReplace);
  Future<void> insertVideos(List<VideoFilesCompanion> videos) async {
    await batch((batch) {
      batch.insertAll(videoFiles, videos, mode: InsertMode.insertOrReplace);
    });
  }
  Future<int> deleteVideo(String path) => (delete(videoFiles)..where((t) => t.path.equals(path))).go();
}

@DriftAccessor(tables: [PlaybackState])
class PlaybackStateDao extends DatabaseAccessor<AppDatabase> with _$PlaybackStateDaoMixin {
  PlaybackStateDao(AppDatabase db) : super(db);

  Future<PlaybackStateData?> getState(String videoPath) => (select(playbackState)..where((t) => t.videoPath.equals(videoPath))).getSingleOrNull();
  Future<int> saveState(PlaybackStateCompanion state) => into(playbackState).insert(state, mode: InsertMode.insertOrReplace);
}

@DriftAccessor(tables: [Playlists, PlaylistItems])
class PlaylistsDao extends DatabaseAccessor<AppDatabase> with _$PlaylistsDaoMixin {
  PlaylistsDao(AppDatabase db) : super(db);

  Future<List<Playlist>> getAllPlaylists() => select(playlists).get();
  Future<int> createPlaylist(PlaylistsCompanion playlist) => into(playlists).insert(playlist);
  Future<int> deletePlaylist(int id) => (delete(playlists)..where((t) => t.id.equals(id))).go();
  
  Future<List<PlaylistItem>> getPlaylistItems(int playlistId) => 
      (select(playlistItems)..where((t) => t.playlistId.equals(playlistId))..orderBy([(t) => OrderingTerm(expression: t.sortOrder)])).get();
  Future<int> addPlaylistItem(PlaylistItemsCompanion item) => into(playlistItems).insert(item);
  Future<int> removePlaylistItem(int playlistId, String videoPath) => 
      (delete(playlistItems)..where((t) => t.playlistId.equals(playlistId) & t.videoPath.equals(videoPath))).go();
}

@DriftAccessor(tables: [ScannedFolders])
class ScannedFoldersDao extends DatabaseAccessor<AppDatabase> with _$ScannedFoldersDaoMixin {
  ScannedFoldersDao(AppDatabase db) : super(db);

  Future<List<ScannedFolder>> getAllFolders() => select(scannedFolders).get();
  Future<int> addFolder(ScannedFoldersCompanion folder) => into(scannedFolders).insert(folder, mode: InsertMode.insertOrReplace);
  Future<int> removeFolder(String path) => (delete(scannedFolders)..where((t) => t.path.equals(path))).go();
}
