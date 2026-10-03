import '../database/database.dart' as db;

class PlaylistModel {
  final int id;
  final String name;
  final DateTime createdAt;

  PlaylistModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory PlaylistModel.fromDb(db.Playlist data) {
    return PlaylistModel(
      id: data.id,
      name: data.name,
      createdAt: data.createdAt,
    );
  }
}

class PlaylistItemModel {
  final int playlistId;
  final String videoPath;
  final int sortOrder;

  PlaylistItemModel({
    required this.playlistId,
    required this.videoPath,
    required this.sortOrder,
  });

  factory PlaylistItemModel.fromDb(db.PlaylistItem data) {
    return PlaylistItemModel(
      playlistId: data.playlistId,
      videoPath: data.videoPath,
      sortOrder: data.sortOrder,
    );
  }
}
