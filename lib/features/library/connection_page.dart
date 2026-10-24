import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_controller.dart';
import '../../core/wifi_transfer.dart';
import '../../data/media_files.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'library_pages.dart';

Future<void> importAudio(BuildContext context, {bool video = false}) async {
  final app = AppScope.of(context);
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: video
          ? ['mp4', 'mov', 'm4a']
          : ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'],
    );
    var count = 0;
    for (final file in files) {
      if ((await file.length() ?? 0) > 40 * 1024 * 1024) {
        throw const FormatException('Please choose files smaller than 40 MB.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 40 * 1024 * 1024) {
        throw const FormatException('Choose a non-empty audio file under 40 MB.');
      }
      await addAudio(app, file.name, bytes);
      count++;
    }
    if (context.mounted && count > 0) {
      toast(context, '$count ${count == 1 ? 'file' : 'files'} added to My Upload');
    }
  } catch (error) {
    if (context.mounted) {
      toast(
        context,
        error is FormatException
            ? error.message
            : 'Could not import this file. Use the Android or iOS app and try again.',
      );
    }
  }
}

Future<void> addAudio(AppController app, String name, Uint8List bytes) async {
  final source = await saveAudio(name, bytes);
  app.addImport(
    Track(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
      artist: 'My Upload',
      cover: 'space',
      source: source,
      imported: true,
    ),
  );
  await app.flush();
}

class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const PageHeader('Connect'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _ConnectionTile(
                  Icons.layers_rounded,
                  'Dropbox',
                  onTap: () => showEqualiSheet(
                    context,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_outlined, size: 48, color: EqualiColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Music from your cloud',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose Dropbox in your system file picker if the Dropbox app is installed. Files are copied into your local library.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: EqualiColors.muted, height: 1.7),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            'Choose audio files',
                            onPressed: () {
                              Navigator.pop(context);
                              importAudio(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _ConnectionTile(
                  Icons.videocam_rounded,
                  'Video',
                  onTap: () => importAudio(context, video: true),
                ),
                _ConnectionTile(
                  Icons.wifi_tethering_rounded,
                  'Wifi Transfer',
                  key: const ValueKey('wifi-transfer'),
                  onTap: () => openPage(context, const WifiTransferPage()),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'Bring your own music. Keep it close.',
              style: TextStyle(fontSize: 11, color: EqualiColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile(this.icon, this.title, {super.key, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: NeuBox(child: Icon(icon, color: EqualiColors.primary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          NeuIcon(Icons.chevron_right_rounded, label: title, onTap: onTap),
        ],
      ),
    ),
  );
}

class UploadsPage extends StatelessWidget {
  const UploadsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final songs = AppScope.of(context).tracks.where((s) => s.imported).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              'My Upload',
              trailing: NeuIcon(
                Icons.add_rounded,
                key: const ValueKey('import-audio'),
                label: 'Import audio files',
                onTap: () => importAudio(context),
              ),
            ),
            Expanded(
              child: songs.isEmpty
                  ? EmptyState(
                      icon: Icons.cloud_upload_outlined,
                      title: 'A home for your music',
                      message: 'Import audio from your phone or transfer\nit over Wi-Fi. Available offline, always.',
                      action: PrimaryButton(
                        'Import audio',
                        icon: Icons.add_rounded,
                        onPressed: () => importAudio(context),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: songs.length,
                      itemBuilder: (context, i) => TrackTile(songs[i], tracks: songs),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class WifiTransferPage extends StatefulWidget {
  const WifiTransferPage({super.key});
  @override
  State<WifiTransferPage> createState() => _WifiTransferPageState();
}

class _WifiTransferPageState extends State<WifiTransferPage> {
  WifiTransfer? _server;
  String? _address, _error;
  bool _starting = false;
  int _count = 0;
  Future<void> _toggle() async {
    if (_server != null) {
      await _server!.stop();
      _server = null;
      if (mounted) setState(() => _address = null);
      return;
    }
    final app = AppScope.of(context);
    setState(() {
      _starting = true;
      _error = null;
    });
    final server = WifiTransfer(
      onUpload: (name, bytes) async {
        await addAudio(app, name, bytes);
        if (mounted) setState(() => _count++);
      },
    );
    try {
      final address = await server.start();
      if (!mounted) {
        await server.stop();
        return;
      }
      setState(() {
        _server = server;
        _address = address;
      });
    } catch (_) {
      await server.stop();
      if (mounted) {
        setState(() => _error = 'Could not start. Check your Wi-Fi connection or try again.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  void dispose() {
    unawaited(_server?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const PageHeader('Wifi Transfer'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const NeuBox(
                    radius: 40,
                    padding: EdgeInsets.all(36),
                    child: Icon(
                      Icons.wifi_tethering_rounded,
                      size: 72,
                      color: EqualiColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Less cables. More music.', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const Text(
                    'Connect both devices to the same Wi-Fi.\nOpen the address below on your computer\nand send your audio files.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EqualiColors.muted, height: 1.8),
                  ),
                  const SizedBox(height: 28),
                  if (_address != null) ...[
                    NeuBox(
                      pressed: true,
                      radius: 16,
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        _address!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: EqualiColors.primary),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _address!));
                        if (context.mounted) toast(context, 'Address copied');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy address'),
                    ),
                    Text(
                      '$_count files received',
                      style: const TextStyle(color: EqualiColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      _starting
                          ? 'Starting…'
                          : _address == null
                          ? 'Start transfer'
                          : 'Stop transfer',
                      key: const ValueKey('start-transfer'),
                      onPressed: _starting ? null : _toggle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Transfer stops when you leave this screen.\nUse a trusted Wi-Fi network. Maximum 40 MB per file.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: EqualiColors.muted, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
