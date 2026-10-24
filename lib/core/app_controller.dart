import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/catalog.dart';
import '../data/local_store.dart';
import '../data/models.dart';
import '../data/media_files.dart';
import 'audio_controller.dart';

class AppController extends ChangeNotifier {
  AppController({required this.store, required this.audio});
  final StateStore store;
  final AudioController audio;
  List<Track> tracks = List.of(catalog);
  List<Playlist> playlists = initialPlaylists();
  Set<String> favorites = {};
  List<String> history = [];
  String name = 'Alex Morgan', email = '';
  bool signedIn = false, rememberSession = true;
  String? storageError;
  Timer? _saveTimer;
  Future<void> _pendingSave = Future.value();
  List<Track> songsFor(Playlist list) =>
      list.trackIds.map((id) => tracks.where((s) => s.id == id).firstOrNull).nonNulls.toList();
  List<Track> search(String query) => tracks
      .where((s) => '${s.title} ${s.artist}'.toLowerCase().contains(query.trim().toLowerCase()))
      .toList();
  Future<void> load() async {
    try {
      final data = await store.read();
      if (data == null) return;
      final savedPlaylists = (data['playlists'] as List?)
          ?.map((e) => Playlist.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final uploads =
          (data['uploads'] as List?)
              ?.map((e) => Track.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      tracks = [...catalog, ...uploads];
      playlists = savedPlaylists ?? initialPlaylists();
      favorites = Set<String>.from(data['favorites'] as List? ?? []);
      history = List<String>.from(data['history'] as List? ?? []);
      name = data['name'] as String? ?? name;
      email = data['email'] as String? ?? '';
      signedIn = data['signedIn'] == true;
      if (data['sound'] is Map) {
        audio.sound.restore(Map<String, dynamic>.from(data['sound'] as Map));
      }
    } catch (_) {
      storageError = 'Saved data could not be loaded. Default library is available.';
    }
    notifyListeners();
  }

  Map<String, dynamic> snapshot() => {
    'version': 1,
    'playlists': playlists.map((s) => s.toJson()).toList(),
    'uploads': tracks.where((s) => s.imported).map((s) => s.toJson()).toList(),
    'favorites': favorites.toList(),
    'history': history,
    'name': name,
    'email': email,
    'signedIn': signedIn && rememberSession,
    'sound': audio.sound.toJson(),
  };
  void changed() {
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), () => unawaited(flush()));
  }

  Future<void> flush() {
    _saveTimer?.cancel();
    final data = snapshot();
    _pendingSave = _pendingSave.then((_) async {
      try {
        await store.write(data);
        storageError = null;
      } catch (_) {
        storageError = 'Changes could not be saved on this device.';
        notifyListeners();
      }
    });
    return _pendingSave;
  }

  Playlist createPlaylist(String title) {
    final list = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: title.trim(),
      cover: 'dj',
      trackIds: [],
    );
    playlists.add(list);
    changed();
    return list;
  }

  void rename(Playlist list, String value) {
    if (value.trim().isEmpty) return;
    list.name = value.trim();
    changed();
  }

  void deletePlaylist(Playlist list) {
    playlists.remove(list);
    changed();
  }

  void addSongs(Playlist list, Iterable<String> ids) {
    final valid = tracks.map((s) => s.id).toSet();
    list.trackIds.addAll(
      ids.where((id) => valid.contains(id) && !list.trackIds.contains(id)).toSet(),
    );
    changed();
  }

  void reorder(Playlist list, int oldIndex, int newIndex) {
    final id = list.trackIds.removeAt(oldIndex);
    list.trackIds.insert(newIndex, id);
    changed();
  }

  void removeSong(Playlist list, Track track) {
    list.trackIds.remove(track.id);
    changed();
  }

  void toggleFavorite(Track track) {
    if (!favorites.add(track.id)) favorites.remove(track.id);
    changed();
  }

  void remember(Track track) {
    history.remove(track.id);
    history.insert(0, track.id);
    history = history.take(8).toList();
    changed();
  }

  void addImport(Track track) {
    tracks.add(track);
    changed();
  }

  Future<void> deleteImport(Track track) async {
    tracks.removeWhere((s) => s.id == track.id);
    favorites.remove(track.id);
    history.remove(track.id);
    for (final list in playlists) {
      list.trackIds.remove(track.id);
    }
    await audio.remove(track);
    try {
      await deleteAudio(track.source);
    } catch (_) {
      storageError = 'The audio file could not be removed from this device.';
    }
    changed();
  }

  void profile(String newName, String newEmail, {bool remember = true}) {
    name = newName.trim();
    email = newEmail.trim();
    signedIn = true;
    rememberSession = remember;
    changed();
  }

  void signOut() {
    signedIn = false;
    changed();
  }

  void updateSound(void Function() update) {
    update();
    unawaited(audio.applySound());
    changed();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    audio.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
    : super(notifier: controller);
  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
