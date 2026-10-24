import 'dart:convert';

import 'package:equali/core/app_controller.dart';
import 'package:equali/core/audio_controller.dart';
import 'package:equali/data/catalog.dart';
import 'package:equali/data/local_store.dart';
import 'package:equali/data/models.dart';
import 'package:equali/features/library/home_page.dart';
import 'package:equali/features/player/player_page.dart';
import 'package:equali/features/account/account_pages.dart';
import 'package:equali/main.dart';
import 'package:equali/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStore implements StateStore {
  String? data;
  @override
  Future<Map<String, dynamic>?> read() async =>
      data == null ? null : jsonDecode(data!) as Map<String, dynamic>;
  @override
  Future<void> write(Map<String, dynamic> value) async {
    data = jsonEncode(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('OpenSans')..addFont(rootBundle.load('assets/fonts/OpenSans.ttf'));
    await loader.load();
  });
  late MemoryStore store;
  late AppController app;
  setUp(() {
    store = MemoryStore();
    app = AppController(store: store, audio: AudioController(enableAudio: false));
  });
  tearDown(() => app.dispose());

  test('playlist changes survive reload, deduplicate IDs, preserve final reorder index', () async {
    final list = app.createPlaylist('  Night drive  ');
    app.addSongs(list, ['fantasy', 'lofi', 'fantasy', 'missing', 'pure']);
    expect(list.trackIds, ['fantasy', 'lofi', 'pure']);
    app.reorder(list, 0, 2);
    expect(list.trackIds, ['lofi', 'pure', 'fantasy']);
    app.rename(list, 'After hours');
    app.toggleFavorite(catalog.first);
    app.remember(catalog[1]);
    app.remember(catalog.first);
    app.remember(catalog[1]);
    await app.flush();
    final restored = AppController(store: store, audio: AudioController(enableAudio: false));
    await restored.load();
    expect(restored.playlists.last.name, 'After hours');
    expect(restored.playlists.last.trackIds, ['lofi', 'pure', 'fantasy']);
    expect(restored.favorites, {'fantasy'});
    expect(restored.history, ['lofi', 'fantasy']);
    restored.deletePlaylist(restored.playlists.last);
    await restored.flush();
    expect(restored.playlists.length, 2);
    restored.dispose();
  });

  test('search matches title and artist without case or padding', () {
    expect(app.search('  FANTASY  ').single.id, 'fantasy');
    expect(app.search('Lisetta').single.id, 'fantasy');
    expect(app.search('missing'), isEmpty);
  });

  test('uploaded track removal cleans dependent data and queue', () async {
    const song = Track(
      id: 'local',
      title: 'Local song',
      artist: 'Me',
      cover: 'space',
      source: 'file:///demo.wav',
      imported: true,
    );
    app.addImport(song);
    app.addSongs(app.playlists.first, ['local']);
    app.toggleFavorite(song);
    app.remember(song);
    app.audio.queue = [song];
    await app.deleteImport(song);
    expect(app.tracks.any((t) => t.id == 'local'), false);
    expect(app.playlists.first.trackIds.contains('local'), false);
    expect(app.favorites, isEmpty);
    expect(app.history, isEmpty);
    expect(app.audio.queue, isEmpty);
    await app.flush();
  });

  test('sound settings clamp persisted values and restore all bands', () async {
    app.audio.sound.restore({
      'volume': 8,
      'bass': -2,
      'gains': [20, -20, 0, 3, 4],
    });
    expect(app.audio.sound.volume, 1);
    expect(app.audio.sound.bass, 0);
    expect(app.audio.sound.gains, [10, -10, 0, 3, 4]);
    await app.flush();
    final restored = AppController(store: store, audio: AudioController(enableAudio: false));
    await restored.load();
    expect(restored.audio.sound.gains, [10, -10, 0, 3, 4]);
    restored.dispose();
  });

  test('manual next moves forward when repeat one is enabled', () async {
    await app.audio.play(catalog.first, tracks: catalog);
    app.audio.toggleRepeat();
    await app.audio.next();
    expect(app.audio.current, catalog[1]);
    await app.audio.next(previous: true);
    expect(app.audio.current, catalog.first);
    app.audio.toggleShuffle();
    await app.audio.next();
    expect(app.audio.current, isNot(catalog.first));
    await app.audio.seek(2);
    expect(app.audio.position, app.audio.duration);
  });

  testWidgets('home and all sound panels fit a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(640, 1280);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(EqualiApp(controller: app));
    await tester.pumpAndSettle();
    expect(find.text('My Music'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(HomePage));
    await app.audio.play(catalog.first, tracks: catalog);
    openPage(context, const PlayerPage());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    for (int panel = 0; panel < 4; panel++) {
      await tester.tap(find.byKey(ValueKey('effect-$panel')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'panel $panel overflowed');
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('search replaces previous input and renders the empty state', (tester) async {
    await tester.pumpWidget(EqualiApp(controller: app));
    await tester.tap(find.byKey(const ValueKey('search')));
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('search-input'));
    await tester.enterText(input, 'Pure');
    await tester.pump();
    expect(find.text('Pure Music'), findsOneWidget);
    await tester.enterText(input, 'not-a-song');
    await tester.pump();
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Pure Music'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('verification retains the submitted recovery email', (tester) async {
    await tester.pumpWidget(EqualiApp(controller: app));
    final context = tester.element(find.byType(HomePage));
    openPage(context, const AuthPage(initialStep: AuthStep.forgot));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('email')), 'alex@example.com');
    await tester.tap(find.byKey(const ValueKey('auth-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('alex@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-code')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
