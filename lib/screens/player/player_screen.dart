import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme/zmp_theme.dart';
import '../../models/video_file.dart';
import '../../providers/player_provider.dart';
import '../../providers/library_provider.dart';
import 'player_controls.dart';
import 'subtitle_panel.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final VideoFileModel video;

  const PlayerScreen({super.key, required this.video});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isFullscreen = false;
  bool _isSpeedBoosting = false;
  double _savedSpeed = 1.0;
  final FocusNode _focusNode = FocusNode();

  // Volume / brightness drag state
  bool _isDraggingVolume = false;
  bool _isDraggingBrightness = false;
  double _dragStartY = 0;
  double _dragStartValue = 0;

  // Seek drag state
  bool _isDraggingSeek = false;
  double _dragStartX = 0;
  Duration _dragSeekPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);

    // Open the video file
    _player.open(Media(widget.video.path));

    // Restore playback state
    _restoreState();

    // Start hide timer
    _resetHideTimer();

    // Go fullscreen
    _enterFullscreen();

    // Listen to player state changes
    _player.stream.position.listen(_onPositionChanged);
    _player.stream.duration.listen(_onDurationChanged);
    _player.stream.playing.listen(_onPlayingChanged);
  }

  Future<void> _restoreState() async {
    final db = ref.read(databaseProvider);
    final state = await db.playbackStateDao.getState(widget.video.path);
    if (state != null) {
      _player.seek(Duration(milliseconds: state.positionMs));
      _player.setVolume(state.volume);
      ref.read(volumeProvider.notifier).state = state.volume;
    }
  }

  Future<void> _saveState() async {
    final db = ref.read(databaseProvider);
    final position = _player.state.position;
    final volume = ref.read(volumeProvider);
    await db.playbackStateDao.saveState(
      PlaybackStateCompanion.insert(
        videoPath: widget.video.path,
        positionMs: Value(position.inMilliseconds),
        volume: Value(volume),
      ),
    );
  }

  void _onPositionChanged(Duration position) {
    if (!mounted) return;
    ref.read(playbackStateProvider.notifier).state = PlaybackState(
      isPlaying: _player.state.playing,
      position: position,
      duration: _player.state.duration,
    );
  }

  void _onDurationChanged(Duration duration) {
    if (!mounted) return;
    ref.read(playbackStateProvider.notifier).state = PlaybackState(
      isPlaying: _player.state.playing,
      position: _player.state.position,
      duration: duration,
    );
  }

  void _onPlayingChanged(bool playing) {
    if (!mounted) return;
    ref.read(playbackStateProvider.notifier).state = PlaybackState(
      isPlaying: playing,
      position: _player.state.position,
      duration: _player.state.duration,
    );
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (!_controlsVisible) {
      setState(() => _controlsVisible = true);
    }
    _hideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _player.state.playing) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _enterFullscreen() async {
    await windowManager.setFullScreen(true);
    setState(() => _isFullscreen = true);
  }

  void _exitFullscreen() async {
    await windowManager.setFullScreen(false);
    setState(() => _isFullscreen = false);
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      _exitFullscreen();
    } else {
      _enterFullscreen();
    }
  }

  void _togglePlayPause() {
    _player.playOrPause();
    _resetHideTimer();
  }

  void _seek(Duration offset) {
    final newPos = _player.state.position + offset;
    _player.seek(newPos);
    _resetHideTimer();
  }

  void _setVolume(double value) {
    final clamped = value.clamp(0.0, 200.0);
    _player.setVolume(clamped);
    ref.read(volumeProvider.notifier).state = clamped;
  }

  void _startSpeedBoost() {
    if (_isSpeedBoosting) return;
    _isSpeedBoosting = true;
    _savedSpeed = _player.state.rate;
    final boostMultiplier = ref.read(speedBoostMultiplierProvider);
    _player.setRate(boostMultiplier);
    ref.read(isSpeedBoostActiveProvider.notifier).state = true;
  }

  void _stopSpeedBoost() {
    if (!_isSpeedBoosting) return;
    _isSpeedBoosting = false;
    _player.setRate(_savedSpeed);
    ref.read(isSpeedBoostActiveProvider.notifier).state = false;
  }

  void _stepFrame(bool forward) {
    if (_player.state.playing) _player.pause();
    final frameTime = const Duration(milliseconds: 42); // ~24fps
    if (forward) {
      _player.seek(_player.state.position + frameTime);
    } else {
      _player.seek(_player.state.position - frameTime);
    }
  }

  void _handleExit() async {
    await _saveState();
    _exitFullscreen();
    if (mounted) Navigator.of(context).pop();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Speed boost: hold Space
    if (event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyDownEvent) {
        if (event is KeyRepeatEvent) {
          // Hold: speed boost
          _startSpeedBoost();
          return KeyEventResult.handled;
        }
      }
      if (event is KeyUpEvent) {
        if (_isSpeedBoosting) {
          _stopSpeedBoost();
        } else {
          _togglePlayPause();
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _handleExit();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyF:
      case LogicalKeyboardKey.f11:
        _toggleFullscreen();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _seek(const Duration(seconds: -10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _seek(const Duration(seconds: 10));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _setVolume(ref.read(volumeProvider) + 5);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _setVolume(ref.read(volumeProvider) - 5);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.period:
        _stepFrame(true);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.comma:
        _stepFrame(false);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.bracketLeft:
        // A-B repeat: set A
        final ab = ref.read(abRepeatProvider);
        ref.read(abRepeatProvider.notifier).state =
            AbRepeat(a: _player.state.position, b: ab.b);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.bracketRight:
        // A-B repeat: set B
        final ab = ref.read(abRepeatProvider);
        ref.read(abRepeatProvider.notifier).state =
            AbRepeat(a: ab.a, b: _player.state.position);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  void dispose() {
    _saveState();
    _hideTimer?.cancel();
    _player.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSpeedBoosting = ref.watch(isSpeedBoostActiveProvider);
    final boostMultiplier = ref.watch(speedBoostMultiplierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onHover: (_) => _resetHideTimer(),
          cursor: _controlsVisible
              ? SystemMouseCursors.basic
              : SystemMouseCursors.none,
          child: GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTap: _toggleFullscreen,
            // Vertical drag for volume (right) / brightness (left)
            onVerticalDragStart: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx > screenWidth / 2) {
                _isDraggingVolume = true;
                _dragStartY = details.globalPosition.dy;
                _dragStartValue = ref.read(volumeProvider);
              } else {
                _isDraggingBrightness = true;
                _dragStartY = details.globalPosition.dy;
                _dragStartValue = ref.read(brightnessProvider);
              }
            },
            onVerticalDragUpdate: (details) {
              final delta = _dragStartY - details.globalPosition.dy;
              final screenHeight = MediaQuery.of(context).size.height;
              final sensitivity = 200.0 / (screenHeight * 0.7);

              if (_isDraggingVolume) {
                final newVol = (_dragStartValue + delta * sensitivity)
                    .clamp(0.0, 200.0);
                _setVolume(newVol);
              } else if (_isDraggingBrightness) {
                final newBright = (_dragStartValue + delta * sensitivity * 0.5)
                    .clamp(0.0, 100.0);
                ref.read(brightnessProvider.notifier).state = newBright;
              }
            },
            onVerticalDragEnd: (_) {
              _isDraggingVolume = false;
              _isDraggingBrightness = false;
            },
            // Horizontal drag for seeking
            onHorizontalDragStart: (details) {
              _isDraggingSeek = true;
              _dragStartX = details.globalPosition.dx;
              _dragSeekPosition = _player.state.position;
            },
            onHorizontalDragUpdate: (details) {
              if (!_isDraggingSeek) return;
              final delta = details.globalPosition.dx - _dragStartX;
              final screenWidth = MediaQuery.of(context).size.width;
              final duration = _player.state.duration;
              final seekDelta = Duration(
                milliseconds:
                    (delta / screenWidth * duration.inMilliseconds * 0.5)
                        .toInt(),
              );
              _dragSeekPosition = _dragSeekPosition + seekDelta;
              _dragStartX = details.globalPosition.dx;
            },
            onHorizontalDragEnd: (_) {
              if (_isDraggingSeek) {
                _player.seek(_dragSeekPosition);
                _isDraggingSeek = false;
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Video Canvas ─────────────────────────────────────
                Video(
                  controller: _videoController,
                  fill: Colors.black,
                ),

                // ── Brightness overlay ───────────────────────────────
                Consumer(builder: (_, ref, __) {
                  final brightness = ref.watch(brightnessProvider);
                  if (brightness >= 50) return const SizedBox.shrink();
                  return IgnorePointer(
                    child: Container(
                      color: Colors.black
                          .withValues(alpha: (50 - brightness) / 50),
                    ),
                  );
                }),

                // ── Speed Boost HUD ──────────────────────────────────
                if (isSpeedBoosting)
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: ZmpTheme.overlayBlack,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${boostMultiplier.toStringAsFixed(1)}x >>',
                          style: ZmpTheme.titleLarge.copyWith(
                            color: ZmpTheme.accentAmber,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Player Controls HUD ──────────────────────────────
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: PlayerControls(
                      player: _player,
                      videoController: _videoController,
                      video: widget.video,
                      onExit: _handleExit,
                      onToggleFullscreen: _toggleFullscreen,
                      isFullscreen: _isFullscreen,
                    ),
                  ),
                ),

                // ── Volume OSD (right edge) ──────────────────────────
                if (_isDraggingVolume)
                  Positioned(
                    right: 40,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _VolumeOSD(
                        value: ref.watch(volumeProvider),
                        maxValue: 200,
                      ),
                    ),
                  ),

                // ── Brightness OSD (left edge) ───────────────────────
                if (_isDraggingBrightness)
                  Positioned(
                    left: 40,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _BrightnessOSD(
                        value: ref.watch(brightnessProvider),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Volume OSD Widget ───────────────────────────────────────────────────
class _VolumeOSD extends StatelessWidget {
  final double value;
  final double maxValue;

  const _VolumeOSD({required this.value, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 200,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ZmpTheme.overlayBlack,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            value > 100
                ? Icons.volume_up
                : value > 0
                    ? Icons.volume_down
                    : Icons.volume_off,
            color: value > 100 ? ZmpTheme.accentAmber : ZmpTheme.textPrimary,
            size: 18,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: LinearProgressIndicator(
                value: (value / maxValue).clamp(0.0, 1.0),
                backgroundColor: ZmpTheme.seekbarBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  value > 100 ? ZmpTheme.accentAmber : ZmpTheme.accentBlue,
                ),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toInt()}%',
            style: ZmpTheme.badge.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Brightness OSD Widget ───────────────────────────────────────────────
class _BrightnessOSD extends StatelessWidget {
  final double value;

  const _BrightnessOSD({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 200,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: ZmpTheme.overlayBlack,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            value > 50 ? Icons.brightness_high : Icons.brightness_low,
            color: ZmpTheme.textPrimary,
            size: 18,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: LinearProgressIndicator(
                value: (value / 100).clamp(0.0, 1.0),
                backgroundColor: ZmpTheme.seekbarBg,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(ZmpTheme.accentAmber),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toInt()}%',
            style: ZmpTheme.badge.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// Need drift for companions
import 'package:drift/drift.dart' show Value;
import '../../database/database.dart';
