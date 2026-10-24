import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/audio_controller.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../library/library_pages.dart';
import 'player_visuals.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with SingleTickerProviderStateMixin {
  late final _rotation = AnimationController(vsync: this, duration: const Duration(seconds: 30))
    ..repeat();
  int _panel = -1;
  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context), audio = app.audio;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: audio,
          builder: (context, child) {
            final song = audio.current;
            if (song == null) {
              return const Column(
                children: [
                  PageHeader('Player'),
                  Expanded(
                    child: EmptyState(
                      icon: Icons.music_note_rounded,
                      title: 'Pick a song',
                      message: 'Your music starts in the library.',
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                PageHeader(
                  song.title,
                  subtitle: song.artist,
                  trailing: NeuIcon(
                    Icons.more_horiz_rounded,
                    key: const ValueKey('player-menu'),
                    label: 'Song options',
                    onTap: () => songMenu(context, song),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(key: ValueKey(_panel), child: _buildPanel(app, audio)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      for (final (i, icon, label) in [
                        (0, Icons.settings_power_rounded, 'Volume'),
                        (1, Icons.tune_rounded, 'Equalizer'),
                        (2, Icons.headphones_rounded, 'Virtualizer'),
                        (3, Icons.spatial_audio_rounded, '3D Surround'),
                      ]) ...[
                        if (i > 0) const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, c) => NeuIcon(
                                  icon,
                                  key: ValueKey('effect-$i'),
                                  label: label,
                                  size: min(74, c.maxWidth),
                                  iconSize: 35,
                                  asset: [
                                    'effect-volume',
                                    'effect-equalizer',
                                    'effect-virtualizer',
                                    'effect-surround',
                                  ][i],
                                  selected: _panel == i,
                                  onTap: () => setState(() => _panel = _panel == i ? -1 : i),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                label,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 10, color: EqualiColors.icon),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(_time(audio.position), style: const TextStyle(fontSize: 9)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Waveform(
                          progress: audio.duration.inMilliseconds == 0
                              ? 0
                              : (audio.position.inMilliseconds / audio.duration.inMilliseconds)
                                    .clamp(0, 1),
                          onSeek: (value) => unawaited(audio.seek(value)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(_time(audio.duration), style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                if (audio.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      audio.error!,
                      style: const TextStyle(fontSize: 10, color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: audio.repeat ? 'Repeat one on' : 'Repeat one off',
                        onPressed: audio.toggleRepeat,
                        icon: Icon(
                          Icons.repeat_rounded,
                          color: audio.repeat ? EqualiColors.primary : EqualiColors.icon,
                          size: 23,
                        ),
                      ),
                      NeuIcon(
                        Icons.skip_previous_rounded,
                        key: const ValueKey('previous'),
                        label: 'Previous song',
                        onTap: () => audio.next(previous: true),
                        circle: true,
                        size: 44,
                        iconSize: 27,
                      ),
                      NeuIcon(
                        audio.loading
                            ? Icons.hourglass_top_rounded
                            : audio.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: const ValueKey('play-pause'),
                        label: audio.playing ? 'Pause' : 'Play',
                        onTap: audio.loading ? null : audio.toggle,
                        circle: true,
                        size: 68,
                        iconSize: 34,
                      ),
                      NeuIcon(
                        Icons.skip_next_rounded,
                        key: const ValueKey('next'),
                        label: 'Next song',
                        onTap: audio.next,
                        circle: true,
                        size: 44,
                        iconSize: 27,
                      ),
                      IconButton(
                        tooltip: audio.shuffle ? 'Shuffle on' : 'Shuffle off',
                        onPressed: audio.toggleShuffle,
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: audio.shuffle ? EqualiColors.primary : EqualiColors.icon,
                          size: 23,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),
              ],
            );
          },
        ),
      ),
    );
  }

  String _time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  Widget _buildPanel(AppController app, AudioController audio) {
    final sound = audio.sound;
    switch (_panel) {
      case 0:
        return Column(
          children: [
            Expanded(
              child: SoundDial(
                value: sound.volume,
                label: 'Volume',
                black: true,
                onChanged: (v) => app.updateSound(() => sound.volume = v),
              ),
            ),
            Slider(
              key: const ValueKey('volume-slider'),
              value: sound.volume,
              label: '${(sound.volume * 100).round()}%',
              onChanged: (v) => app.updateSound(() => sound.volume = v),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 5, bottom: 7),
                    child: Semantics(
                      label: 'Enable equalizer',
                      child: GestureDetector(
                        key: const ValueKey('eq-toggle'),
                        onTap: () => app.updateSound(() => sound.enabled = !sound.enabled),
                        child: NeuBox(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          child: Row(
                            children: [
                              Text(
                                sound.enabled ? 'ON' : 'OFF',
                                style: const TextStyle(color: EqualiColors.primary, fontSize: 12),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sound.enabled ? EqualiColors.primary : EqualiColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final name in SoundSettings.presets.keys)
                    Padding(
                      padding: const EdgeInsets.only(right: 10, top: 5, bottom: 7),
                      child: GestureDetector(
                        key: ValueKey('preset-$name'),
                        onTap: () => app.updateSound(() {
                          sound.preset = name;
                          sound.gains = List.of(SoundSettings.presets[name]!);
                        }),
                        child: NeuBox(
                          radius: 20,
                          color: sound.preset == name ? EqualiColors.primary : null,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Center(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                color: sound.preset == name ? Colors.white : EqualiColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Opacity(
                opacity: sound.enabled ? 1 : .4,
                child: Row(
                  children: [
                    for (int i = 0; i < 5; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            children: [
                              Expanded(
                                child: CustomPaint(
                                  painter: EqualizerTicks(),
                                  child: Center(
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: Slider(
                                        key: ValueKey('band-$i'),
                                        value: sound.gains[i],
                                        min: -10,
                                        max: 10,
                                        label: '${sound.gains[i].round()} dB',
                                        onChanged: !sound.enabled
                                            ? null
                                            : (value) => app.updateSound(() {
                                                sound.gains[i] = value;
                                                sound.preset = 'Custom';
                                              }),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                ['60HZ', '230HZ', '910HZ', '3.6KHZ', '14KHZ'][i],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!audio.equalizerAvailable)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Equalizer needs a supported Android audio device',
                  style: TextStyle(fontSize: 9, color: EqualiColors.muted),
                ),
              ),
          ],
        );
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Row(
                children: [
                  Expanded(
                    child: SoundDial(
                      value: sound.bass,
                      label: 'Bass Booster',
                      onChanged: (value) => app.updateSound(() => sound.bass = value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SoundDial(
                      value: sound.virtualizer,
                      label: 'Virtualizer',
                      onChanged: (value) => app.updateSound(() => sound.virtualizer = value),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final (value, label) in [
                  (sound.bass, 'Bass Booster'),
                  (sound.virtualizer, 'Virtualizer'),
                ])
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${(value * 100).round()}%',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(label, style: const TextStyle(color: EqualiColors.muted)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              audio.spatialAvailable
                  ? 'For the best experience, use headphones'
                  : 'Audio effects depend on Android device support',
              style: const TextStyle(fontSize: 10, color: EqualiColors.muted),
            ),
            const SizedBox(height: 20),
          ],
        );
      case 3:
        return Column(
          children: [
            Expanded(
              child: Image.asset(
                'assets/images/surround.png',
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sound.spatial ? 'Surround on' : '3D Surround',
                  style: const TextStyle(fontSize: 12, color: EqualiColors.icon),
                ),
                const SizedBox(width: 12),
                Switch.adaptive(
                  key: const ValueKey('surround-toggle'),
                  value: sound.spatial,
                  activeTrackColor: EqualiColors.primary,
                  onChanged: (value) => app.updateSound(() => sound.spatial = value),
                ),
              ],
            ),
            const Text(
              'Android spatial widening · Headphones recommended',
              style: TextStyle(fontSize: 9, color: EqualiColors.muted),
            ),
          ],
        );
      default:
        return TickerMode(
          enabled: audio.playing,
          child: AnimatedBuilder(
            animation: _rotation,
            builder: (context, child) => Vinyl(
              cover: audio.current!.cover,
              rotation: audio.playing ? _rotation.value * pi * 2 : 0,
            ),
          ),
        );
    }
  }
}
