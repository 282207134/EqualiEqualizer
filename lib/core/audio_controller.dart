import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';

class AudioController extends ChangeNotifier {
  AudioController({this.enableAudio = true}) {
    if (!enableAudio) return;
    _player = AudioPlayer();
    _subscriptions.addAll([
      _player!.positionStream.listen((value) {
        position = value;
        notifyListeners();
      }),
      _player!.durationStream.listen((value) {
        duration = value ?? Duration.zero;
        notifyListeners();
      }),
      _player!.playerStateStream.listen((value) {
        playing = value.playing && value.processingState != ProcessingState.completed;
        loading = value.processingState == ProcessingState.loading;
        notifyListeners();
        if (value.processingState == ProcessingState.completed) {
          unawaited(next(completed: true));
        }
      }),
      _player!.androidAudioSessionIdStream.listen((id) async {
        if (id == null || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
          return;
        }
        try {
          final support = await _effects.invokeMapMethod<String, dynamic>('attach', {
            'session': id,
          });
          equalizerAvailable = support?['equalizer'] == true;
          bassAvailable = support?['bass'] == true;
          spatialAvailable = support?['virtualizer'] == true;
          await applySound();
        } on PlatformException {
          equalizerAvailable = false;
        }
        notifyListeners();
      }),
      _player!.errorStream.listen((event) {
        error = 'Unable to play this file. Try another audio file.';
        playing = false;
        notifyListeners();
      }),
    ]);
  }
  final bool enableAudio;
  static const _effects = MethodChannel('equali/audio_effects');
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final sound = SoundSettings();
  Track? current;
  List<Track> queue = [];
  Duration position = Duration.zero, duration = Duration.zero;
  bool playing = false, loading = false, shuffle = false, repeat = false;
  bool equalizerAvailable = false, bassAvailable = false, spatialAvailable = false;
  String? error;
  int _request = 0;

  Future<void> play(Track track, {List<Track>? tracks}) async {
    final request = ++_request;
    current = track;
    error = null;
    if (tracks != null) queue = List.of(tracks);
    if (queue.isEmpty || !queue.any((s) => s.id == track.id)) queue = [track];
    position = Duration.zero;
    duration = Duration.zero;
    loading = true;
    notifyListeners();
    try {
      if (_player != null) {
        if (track.source.startsWith('assets/')) {
          await _player!.setAsset(track.source);
        } else {
          await _player!.setUrl(track.source);
        }
        if (request != _request) return;
        await _player!.setVolume(sound.volume);
        unawaited(_player!.play());
      } else {
        playing = true;
        duration = const Duration(seconds: 32);
      }
    } catch (_) {
      error = 'Unable to play this file. Try another audio file.';
      playing = false;
    }
    if (request == _request) {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (current == null) return;
    if (_player != null) {
      if (_player!.playing) {
        await _player!.pause();
      } else {
        if (position >= duration) await _player!.seek(Duration.zero);
        unawaited(_player!.play());
      }
    } else {
      playing = !playing;
      notifyListeners();
    }
  }

  Future<void> seek(double fraction) async {
    final target = Duration(milliseconds: (duration.inMilliseconds * fraction.clamp(0, 1)).round());
    position = target;
    notifyListeners();
    await _player?.seek(target);
  }

  Future<void> remove(Track track) async {
    queue.removeWhere((item) => item.id == track.id);
    if (current?.id != track.id) return;
    _request++;
    current = null;
    playing = false;
    position = Duration.zero;
    duration = Duration.zero;
    await _player?.stop();
    notifyListeners();
  }

  Future<void> next({bool previous = false, bool completed = false}) async {
    if (queue.isEmpty) return;
    if (repeat && completed) {
      await seek(0);
      if (_player != null) unawaited(_player!.play());
      return;
    }
    final index = queue.indexWhere((s) => s.id == current?.id);
    final nextIndex = shuffle && queue.length > 1
        ? (index + 1 + Random().nextInt(queue.length - 1)) % queue.length
        : (index + (previous ? -1 : 1)) % queue.length;
    await play(queue[nextIndex]);
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    repeat = !repeat;
    notifyListeners();
  }

  Future<void> applySound() async {
    await _player?.setVolume(sound.volume);
    if (enableAudio && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _effects.invokeMethod<void>('update', sound.toJson());
      } on PlatformException {
        error = 'This device could not apply the selected audio effect.';
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player?.dispose());
    super.dispose();
  }
}
