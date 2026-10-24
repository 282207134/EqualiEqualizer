import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveAudio(String name, Uint8List bytes) async {
  final root = await getApplicationDocumentsDirectory();
  final directory = await Directory('${root.path}/audio').create(recursive: true);
  final safeName = name.replaceAll(RegExp(r'[^\w.\-]'), '_');
  final file = File('${directory.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return file.uri.toString();
}

Future<void> deleteAudio(String source) async {
  final uri = Uri.tryParse(source);
  if (uri?.scheme != 'file') return;
  final file = File.fromUri(uri!);
  if (!await file.exists()) return;
  final root = await getApplicationDocumentsDirectory();
  if (file.path.startsWith('${root.path}${Platform.pathSeparator}audio${Platform.pathSeparator}') &&
      await file.exists()) {
    await file.delete();
  }
}
