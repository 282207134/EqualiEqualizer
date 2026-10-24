import 'dart:io';
import 'dart:typed_data';

import 'package:equali/core/wifi_transfer_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Wi-Fi transfer accepts audio, rejects bad paths and unsupported files, then closes',
    () async {
      String? name;
      Uint8List? received;
      final server = WifiTransfer(
        onUpload: (n, b) async {
          name = n;
          received = b;
        },
      );
      final address = Uri.parse(await server.start());
      final endpoint = address.replace(host: '127.0.0.1');
      final client = HttpClient();
      try {
        final page = await client.getUrl(endpoint);
        expect((await page.close()).statusCode, 200);
        final bad = await client.postUrl(
          endpoint.replace(queryParameters: {'name': 'script.html'}),
        );
        bad.add([1, 2]);
        final badResponse = await bad.close();
        expect(badResponse.statusCode, 415);
        await badResponse.drain<void>();
        final request = await client.postUrl(
          endpoint.replace(queryParameters: {'name': 'test.wav'}),
        );
        request.add([1, 2, 3, 4]);
        final response = await request.close();
        expect(response.statusCode, 200);
        await response.drain<void>();
        expect(name, 'test.wav');
        expect(received, [1, 2, 3, 4]);
        final unknown = await client.getUrl(endpoint.replace(path: '/incorrect-token'));
        final unknownResponse = await unknown.close();
        expect(unknownResponse.statusCode, 404);
        await unknownResponse.drain<void>();
      } finally {
        client.close(force: true);
        await server.stop();
      }
    },
  );
}
