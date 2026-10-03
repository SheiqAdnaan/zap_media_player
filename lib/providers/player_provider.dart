import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_file.dart';

final currentVideoProvider = StateProvider<VideoFileModel?>((ref) => null);

class PlaybackState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  PlaybackState({this.isPlaying = false, this.position = Duration.zero, this.duration = Duration.zero});
}

final playbackStateProvider = StateProvider<PlaybackState>((ref) => PlaybackState());

final speedBoostMultiplierProvider = StateProvider<double>((ref) => 2.0);
final isSpeedBoostActiveProvider = StateProvider<bool>((ref) => false);
final volumeProvider = StateProvider<double>((ref) => 100.0);
final brightnessProvider = StateProvider<double>((ref) => 50.0);
final subtitleTrackProvider = StateProvider<int?>((ref) => null);
final audioTrackProvider = StateProvider<int?>((ref) => null);

class AbRepeat {
  final Duration? a;
  final Duration? b;
  AbRepeat({this.a, this.b});
}

final abRepeatProvider = StateProvider<AbRepeat>((ref) => AbRepeat());
