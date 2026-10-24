import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:equali/core/app_controller.dart';
import 'package:equali/core/audio_controller.dart';
import 'package:equali/data/catalog.dart';
import 'package:equali/data/local_store.dart';
import 'package:equali/features/account/account_pages.dart';
import 'package:equali/features/library/connection_page.dart';
import 'package:equali/features/library/home_page.dart';
import 'package:equali/features/library/library_pages.dart';
import 'package:equali/features/library/search_page.dart';
import 'package:equali/main.dart';
import 'package:equali/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android user journeys and complete screen gallery', (tester) async {
    final app = AppController(store: LocalStore(), audio: AudioController());
    // A clean in-memory catalog makes screenshots reproducible; persistence is checked below.
    runApp(EqualiApp(controller: app));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();
    final homeContext = tester.element(find.byType(HomePage));
    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> shot(String name) async {
      ScaffoldMessenger.of(homeContext).hideCurrentSnackBar();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: name);
      await binding.takeScreenshot(name);
    }

    Future<void> tap(String key) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await settle();
    }

    Future<void> home() async {
      Navigator.of(homeContext).popUntil((r) => r.isFirst);
      await settle();
    }

    Future<void> page(Widget page) async {
      await home();
      unawaited(openPage(homeContext, page));
      await settle();
    }

    await shot('01-home');
    await tap('connect');
    await shot('02-connect');
    await tap('wifi-transfer');
    await tap('start-transfer');
    final transferAddress = Uri.parse(
      tester.widget<SelectableText>(find.byType(SelectableText)).data!,
    );
    expect(transferAddress.host, isNot('127.0.0.1'));
    final client = HttpClient();
    final request = await client.getUrl(transferAddress.replace(host: '127.0.0.1'));
    final response = await request.close();
    expect(response.statusCode, 200);
    expect(await utf8.decoder.bind(response).join(), contains('Send to Equali'));
    client.close(force: true);
    await shot('03-wifi-transfer');
    expect(find.text('Stop transfer'), findsOneWidget);
    await tap('start-transfer');
    await page(const UploadsPage());
    await shot('04-uploads-empty');
    final audioBytes = await rootBundle.load('assets/audio/aurora.wav');
    await addAudio(app, 'Evening session.wav', audioBytes.buffer.asUint8List());
    await settle();
    await shot('05-uploads');
    await page(const PlaylistsPage());
    await shot('06-playlists');
    await home();
    await tap('new-playlist');
    await shot('07-new-playlist');
    await tester.enterText(find.byKey(const ValueKey('playlist-name')), 'Night drive');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle();
    await tap('create-playlist');
    final created = app.playlists.last;
    expect(created.name, 'Night drive');
    await tap('add-songs');
    await shot('08-add-songs');
    await tap('select-fantasy');
    await tap('select-lofi');
    await tap('add-done');
    expect(created.trackIds, ['fantasy', 'lofi']);
    await page(PlaylistPage(playlist: app.playlists[1]));
    await shot('09-playlist');
    await tap('playlist-more');
    await shot('10-playlist-menu');
    await tap('menu-rename');
    await shot('11-edit-playlist');
    await tester.enterText(find.byKey(const ValueKey('rename-input')), 'Hip - Hop');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle();
    await tester.tap(find.text('Save changes'));
    await settle();
    await tap('playlist-more');
    await tap('menu-reorder');
    await shot('12-song-order');
    final drag = find.byType(ReorderableDragStartListener).first;
    await tester.drag(drag, const Offset(0, 112));
    await settle();
    expect(app.playlists[1].trackIds.first, isNot('fantasy'));
    await page(
      TrackListPage(title: 'Good Byes', tracks: app.tracks.where((s) => !s.imported).toList()),
    );
    await shot('13-album');
    await tap('more-fantasy');
    await shot('14-song-menu');
    await tap('menu-add');
    await shot('15-add-to-playlist');
    await tester.tap(find.text('Night drive'));
    await settle();
    expect(created.trackIds.where((id) => id == 'fantasy').length, 1);
    await page(TrackListPage(title: 'Today Hits', tracks: catalog));
    await shot('16-today-hits');
    await tap('track-fantasy');
    // Wait for the native decoder and actual audio session, without waiting for the rotating artwork.
    for (var i = 0; i < 30 && app.audio.duration == Duration.zero; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(app.audio.duration.inSeconds, 32);
    expect(app.audio.error, isNull);
    await shot('17-player');
    await tap('play-pause');
    expect(app.audio.playing, false);
    await tap('effect-0');
    await shot('18-volume');
    await tester.drag(find.byKey(const ValueKey('volume-slider')), const Offset(-70, 0));
    await settle();
    expect(app.audio.sound.volume, lessThan(.75));
    await tap('effect-1');
    await shot('19-equalizer');
    await tap('preset-Dance');
    expect(app.audio.sound.preset, 'Dance');
    await tester.drag(find.byKey(const ValueKey('band-0')), const Offset(0, -25));
    await settle();
    expect(app.audio.sound.preset, 'Custom');
    await tap('effect-2');
    await shot('20-virtualizer');
    await tap('effect-3');
    await tap('surround-toggle');
    await shot('21-surround');
    expect(app.audio.sound.spatial, true);
    await tap('next');
    expect(app.audio.current!.id, 'lofi');
    await tap('previous');
    expect(app.audio.current!.id, 'fantasy');
    if (app.audio.playing) await app.audio.toggle();
    await page(const SearchPage());
    await shot('22-search-history');
    await tester.enterText(find.byKey(const ValueKey('search-input')), 'Pure');
    await settle();
    expect(find.text('Pure Music'), findsOneWidget);
    await shot('23-search-results');
    // Update at the text input boundary so the native IME cannot restore its previous composing value.
    final searchField = tester.widget<TextField>(find.byKey(const ValueKey('search-input')));
    searchField.controller!.text = 'not-a-song';
    searchField.onChanged?.call('not-a-song');
    await settle();
    expect(find.text('No results'), findsOneWidget);
    await shot('24-search-empty');
    await page(const ProfilePage());
    await shot('25-profile');
    await tap('edit-profile');
    await shot('26-edit-profile');
    await page(const AuthPage());
    await shot('27-sign-in');
    await tap('auth-submit');
    await shot('28-sign-in-validation');
    await tap('auth-switch');
    await shot('29-register');
    await page(const AuthPage(initialStep: AuthStep.forgot));
    await shot('30-forgot-password');
    await tester.enterText(find.byKey(const ValueKey('email')), 'alex@example.com');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle();
    await tap('auth-submit');
    expect(find.textContaining('alex@example.com'), findsOneWidget);
    await shot('31-verification');
    await tester.enterText(find.byKey(const ValueKey('verification-code')), '1234');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle();
    await tap('auth-submit');
    await shot('32-reset-password');
    await tester.enterText(find.byKey(const ValueKey('password')), 'preview123');
    await tester.enterText(find.byKey(const ValueKey('confirm-password')), 'preview123');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle();
    await tap('auth-submit');
    await shot('33-reset-success');
    await page(const CreateProfilePage(email: 'alex@example.com'));
    await shot('34-create-profile');
    await tester.enterText(find.byKey(const ValueKey('profile-name')), 'Alex Morgan');
    FocusManager.instance.primaryFocus?.unfocus();
    await settle();
    await tap('save-profile');
    expect(app.signedIn, true);
    expect(app.email, 'alex@example.com');
    await app.flush();
    final restored = AppController(store: LocalStore(), audio: AudioController(enableAudio: false));
    await restored.load();
    expect(restored.playlists.last.trackIds, ['fantasy', 'lofi']);
    expect(restored.audio.sound.preset, 'Custom');
    expect(restored.signedIn, true);
    restored.dispose();
    binding.reportData ??= {};
    binding.reportData!['verification'] = {
      'device': 'Android 15 API 35 · 750×1624',
      'screenshotCount': 34,
      'wifiAddress': transferAddress.host,
      'audioDurationSeconds': app.audio.duration.inSeconds,
      'equalizerAvailable': app.audio.equalizerAvailable,
      'bassAvailable': app.audio.bassAvailable,
      'spatialAvailable': app.audio.spatialAvailable,
      'journeys': [
        'playlist CRUD and reorder',
        'native audio playback',
        'all audio panels',
        'search',
        'profile and recovery',
        'persistence',
        'Wi-Fi start/stop',
      ],
    };
    await home();
  });
}
