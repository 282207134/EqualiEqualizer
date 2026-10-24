import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_controller.dart';
import 'core/audio_controller.dart';
import 'data/local_store.dart';
import 'features/library/home_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: EqualiColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final controller = AppController(store: LocalStore(), audio: AudioController());
  await controller.load();
  runApp(EqualiApp(controller: controller));
}

class EqualiApp extends StatefulWidget {
  const EqualiApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<EqualiApp> createState() => _EqualiAppState();
}

class _EqualiAppState extends State<EqualiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(widget.controller.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    controller: widget.controller,
    child: MaterialApp(
      title: 'Equali',
      debugShowCheckedModeBanner: false,
      theme: equaliTheme(),
      home: const HomePage(),
    ),
  );
}
