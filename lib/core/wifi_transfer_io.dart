import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class WifiTransfer {
  WifiTransfer({required this.onUpload});
  final Future<void> Function(String, Uint8List) onUpload;
  HttpServer? _server;
  final _token = List.generate(16, (_) => Random.secure().nextInt(16).toRadixString(16)).join();
  static const maxBytes = 40 * 1024 * 1024;
  Future<String> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8765);
    _server!.listen(_handle);
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    final addresses = interfaces.expand((n) => n.addresses).where((a) => !a.isLoopback).toList();
    String? nativeAddress;
    if (Platform.isAndroid) {
      try {
        nativeAddress = await const MethodChannel('equali/network')
            .invokeMethod<String>('getAddress');
      } on MissingPluginException {
        /* The desktop test uses NetworkInterface instead. */
      }
    }
    final ip = nativeAddress ?? addresses.firstOrNull?.address ?? '127.0.0.1';
    if ((Platform.isAndroid || Platform.isIOS) && ip == '127.0.0.1') {
      await stop();
      throw const SocketException('Connect to Wi-Fi before starting a transfer.');
    }
    return 'http://$ip:8765/$_token';
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.uri.path != '/$_token') {
        request.response.statusCode = 404;
        return;
      }
      if (request.method == 'GET') {
        request.response.headers.contentType = ContentType.html;
        request.response.write(_page);
        return;
      }
      if (request.method != 'POST') {
        request.response.statusCode = 405;
        return;
      }
      final name = request.uri.queryParameters['name'] ?? '';
      if (!RegExp(r'\.(mp3|m4a|wav|flac|ogg|aac|mp4|mov)$', caseSensitive: false).hasMatch(name)) {
        request.response.statusCode = 415;
        request.response.write('Choose a supported audio file.');
        return;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in request) {
        if (builder.length + chunk.length > maxBytes) {
          request.response.statusCode = 413;
          request.response.write('Maximum file size is 40 MB.');
          return;
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) {
        request.response.statusCode = 400;
        return;
      }
      await onUpload(name, bytes);
      request.response.write('Added to your Equali library.');
    } catch (_) {
      request.response.statusCode = 500;
      request.response.write('Transfer failed. Please try again.');
    } finally {
      await request.response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  String get _page => '''<!doctype html><html><meta name="viewport" content="width=device-width,initial-scale=1"><meta charset="UTF-8">
<title>Equali · Wi-Fi Transfer</title><style>body{background:#e9f0f7;color:#303745;font:16px system-ui;margin:10vh auto;padding:24px;max-width:480px}h1{color:#5b66f2;font-size:44px}button{background:#5b66f2;border:0;border-radius:24px;color:white;padding:14px 24px;font-size:16px;margin-top:24px}input{padding:20px 0}p{line-height:1.7;color:#596882}</style>
<h1>Equali</h1><h2>Your music, one tap away.</h2><p>Choose an audio file to add it to your phone. Maximum 40 MB. Keep Equali open during the transfer.</p>
<input id="file" type="file" accept="audio/*,.mp4,.mov"><br><button id="send">Send to Equali</button><p id="status"></p>
<script>document.getElementById('send').onclick=async()=>{const f=document.getElementById('file').files[0],s=document.getElementById('status'),b=document.getElementById('send');if(!f){s.textContent='Choose a file first.';return;}if(f.size>41943040){s.textContent='Maximum file size is 40 MB.';return;}b.disabled=true;s.textContent='Sending…';try{const r=await fetch(location.pathname+'?name='+encodeURIComponent(f.name),{method:'POST',body:f});s.textContent=await r.text();}catch(e){s.textContent='Connection lost. Please try again.';}b.disabled=false;};</script></html>''';
}
