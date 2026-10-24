import 'dart:typed_data';

class WifiTransfer {
  WifiTransfer({required this.onUpload});
  final Future<void> Function(String, Uint8List) onUpload;
  Future<String> start() async =>
      throw UnsupportedError('Wi-Fi transfer is available in the mobile app.');
  Future<void> stop() async {}
}
