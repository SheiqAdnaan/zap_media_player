import 'package:drift/drift.dart';

class VideoFiles extends Table {
  TextColumn get path => text()();
  TextColumn get name => text()();
  IntColumn get size => integer()();
  IntColumn get durationMs => integer().named('duration_ms').nullable()();
  TextColumn get format => text().nullable()();
  TextColumn get codec => text().nullable()();
  TextColumn get resolution => text().nullable()();
  IntColumn get audioChannels => integer().named('audio_channels').nullable()();
  BlobColumn get thumbnailBlob => blob().named('thumbnail_blob').nullable()();
  BoolColumn get isNew => boolean().named('is_new').withDefault(const Constant(true))();
  DateTimeColumn get lastPlayed => dateTime().named('last_played').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {path};
}

class PlaybackState extends Table {
  TextColumn get videoPath => text().named('video_path').references(VideoFiles, #path)();
  IntColumn get positionMs => integer().named('position_ms').withDefault(const Constant(0))();
  RealColumn get volume => real().withDefault(const Constant(100.0))();
  RealColumn get speed => real().withDefault(const Constant(1.0))();
  IntColumn get audioTrackIndex => integer().named('audio_track_index').nullable()();
  IntColumn get subtitleTrackIndex => integer().named('subtitle_track_index').nullable()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {videoPath};
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
}

class PlaylistItems extends Table {
  IntColumn get playlistId => integer().named('playlist_id').references(Playlists, #id)();
  TextColumn get videoPath => text().named('video_path').references(VideoFiles, #path)();
  IntColumn get sortOrder => integer().named('sort_order')();

  @override
  Set<Column> get primaryKey => {playlistId, videoPath};
}

class ScannedFolders extends Table {
  TextColumn get path => text()();
  IntColumn get videoCount => integer().named('video_count').withDefault(const Constant(0))();
  IntColumn get totalSizeBytes => integer().named('total_size_bytes').withDefault(const Constant(0))();
  DateTimeColumn get lastScanned => dateTime().named('last_scanned').nullable()();

  @override
  Set<Column> get primaryKey => {path};
}

class VaultSettings extends Table {
  TextColumn get pinHash => text().named('pin_hash')();
  BoolColumn get isEnabled => boolean().named('is_enabled').withDefault(const Constant(false))();
}

class VaultFiles extends Table {
  TextColumn get videoPath => text().named('video_path').references(VideoFiles, #path)();
  DateTimeColumn get addedAt => dateTime().named('added_at').withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {videoPath};
}
