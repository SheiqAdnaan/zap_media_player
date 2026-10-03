import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenSubtitlesApi {
  static const String baseUrl = 'https://api.opensubtitles.com/api/v1';
  final String apiKey;

  OpenSubtitlesApi({required this.apiKey});

  Future<List<dynamic>> searchSubtitles({String? movieHash, String? query}) async {
    final uri = Uri.parse('$baseUrl/subtitles');
    Map<String, String> queryParams = {};
    if (movieHash != null) queryParams['moviehash'] = movieHash;
    if (query != null) queryParams['query'] = query;

    final response = await http.get(
      uri.replace(queryParameters: queryParams),
      headers: {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] as List<dynamic>;
    } else {
      throw Exception('Failed to load subtitles');
    }
  }
  
  Future<String> downloadSubtitle(int fileId) async {
    final uri = Uri.parse('$baseUrl/download');
    final response = await http.post(
      uri,
      headers: {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode({'file_id': fileId}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['link']; // Returns the download link
    } else {
      throw Exception('Failed to get download link');
    }
  }
}
