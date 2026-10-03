import 'dart:io';

class SubtitleService {
  Future<List<String>> parseSrt(File file) async {
    if (!await file.exists()) return [];
    final lines = await file.readAsLines();
    return lines;
  }
  
  Future<void> saveSubtitle(String url, String destinationPath) async {
    // Download and save logic here
  }
}
