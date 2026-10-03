import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<String>((ref) => 'system');
final hardwareAccelerationProvider = StateProvider<bool>((ref) => true);
final defaultSubtitleLanguageProvider = StateProvider<String>((ref) => 'en');
