import 'dart:typed_data';
import '../database/database.dart' as db;

class VideoFileModel {
  final String path;
  final String name;
  final int size;
  final int? durationMs;
  final String? format;
  final String? codec;
  final String? resolution;
  final int? audioChannels;
  final Uint8List? thumbnailBlob;
  final bool isNew;
  final DateTime? lastPlayed;
  final DateTime createdAt;

  VideoFileModel({
    required this.path,
    required this.name,
    required this.size,
    this.durationMs,
    this.format,
    this.codec,
    this.resolution,
    this.audioChannels,
    this.thumbnailBlob,
    this.isNew = true,
    this.lastPlayed,
    required this.createdAt,
  });

  factory VideoFileModel.fromDb(db.VideoFile data) {
    return VideoFileModel(
      path: data.path,
      name: data.name,
      size: data.size,
      durationMs: data.durationMs,
      format: data.format,
      codec: data.codec,
      resolution: data.resolution,
      audioChannels: data.audioChannels,
      thumbnailBlob: data.thumbnailBlob,
      isNew: data.isNew,
      lastPlayed: data.lastPlayed,
      createdAt: data.createdAt,
    );
  }
}
