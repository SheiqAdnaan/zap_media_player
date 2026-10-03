import 'dart:io';
import 'package:path/path.dart' as p;

class FileScanner {
  static const List<String> supportedExtensions = [
    '.mp4', '.mkv', '.avi', '.mov', '.flv', '.wmv', '.webm', '.m4v'
  ];

  Future<List<File>> scanDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    final List<File> videoFiles = [];
    
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext)) {
            videoFiles.add(entity);
          }
        }
      }
    } catch (e) {
      print('Error scanning directory: $e');
    }

    return videoFiles;
  }
}
