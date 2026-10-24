class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
    required this.source,
    this.imported = false,
  });
  final String id, title, artist, cover, source;
  final bool imported;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'cover': cover,
    'source': source,
    'imported': imported,
  };
  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    cover: json['cover'] as String,
    source: json['source'] as String,
    imported: json['imported'] == true,
  );
}

class Playlist {
  Playlist({required this.id, required this.name, required this.cover, required this.trackIds});
  final String id;
  String name, cover;
  final List<String> trackIds;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'cover': cover, 'tracks': trackIds};
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'] as String,
    name: json['name'] as String,
    cover: json['cover'] as String,
    trackIds: List<String>.from(json['tracks'] as List),
  );
}

class SoundSettings {
  double volume = .75, bass = .45, virtualizer = .45, surround = .65;
  bool enabled = true, spatial = false;
  String preset = 'Latin';
  List<double> gains = [5, 2, -2, 3, 5];
  static const presets = <String, List<double>>{
    'Flat': [0, 0, 0, 0, 0],
    'Latin': [5, 2, -2, 3, 5],
    'Classical': [4, 2, -2, 2, 4],
    'Dance': [6, 3, 0, 4, 5],
    'Hip Hop': [6, 4, -1, 1, 3],
    'Rock': [5, 2, -3, 2, 5],
  };
  Map<String, dynamic> toJson() => {
    'volume': volume,
    'bass': bass,
    'virtualizer': virtualizer,
    'surround': surround,
    'enabled': enabled,
    'spatial': spatial,
    'preset': preset,
    'gains': gains,
  };
  void restore(Map<String, dynamic> json) {
    double number(String key, double fallback) =>
        ((json[key] as num?)?.toDouble() ?? fallback).clamp(0, 1);
    volume = number('volume', volume);
    bass = number('bass', bass);
    virtualizer = number('virtualizer', virtualizer);
    surround = number('surround', surround);
    enabled = json['enabled'] != false;
    spatial = json['spatial'] == true;
    preset = json['preset'] as String? ?? 'Latin';
    final saved = json['gains'];
    if (saved is List && saved.length == 5) {
      gains = saved.map((e) => (e as num).toDouble().clamp(-10.0, 10.0)).toList();
    }
  }
}
