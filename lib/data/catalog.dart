import 'models.dart';

const catalog = <Track>[
  Track(
    id: 'fantasy',
    title: 'Final Fantasy',
    artist: 'Lisetta Carmi',
    cover: 'good-byes',
    source: 'assets/audio/aurora.wav',
  ),
  Track(
    id: 'lofi',
    title: 'Lofi bests',
    artist: 'Piotr Makowski',
    cover: 'lofi',
    source: 'assets/audio/afterglow.wav',
  ),
  Track(
    id: 'pure',
    title: 'Pure Music',
    artist: 'Louis Fratino',
    cover: 'pure',
    source: 'assets/audio/drift.wav',
  ),
  Track(
    id: 'rain',
    title: 'Rain lofi',
    artist: 'Olve Sande',
    cover: 'rain',
    source: 'assets/audio/afterglow.wav',
  ),
  Track(
    id: 'chinese',
    title: 'Chinese',
    artist: 'Zoe Williams',
    cover: 'chinese',
    source: 'assets/audio/drift.wav',
  ),
  Track(
    id: 'city',
    title: 'City Pop',
    artist: 'Sean Townley',
    cover: 'city',
    source: 'assets/audio/aurora.wav',
  ),
  Track(
    id: 'japanese',
    title: 'Japanese',
    artist: 'Srijon Chowdhury',
    cover: 'japanese',
    source: 'assets/audio/drift.wav',
  ),
  Track(
    id: 'english',
    title: 'English',
    artist: 'Ola Vasiljeva',
    cover: 'english',
    source: 'assets/audio/afterglow.wav',
  ),
  Track(
    id: 'space',
    title: 'Space vibes',
    artist: 'Antoine Levi',
    cover: 'space',
    source: 'assets/audio/aurora.wav',
  ),
  Track(
    id: 'heat',
    title: 'New Heat',
    artist: 'Daniel Jacoby',
    cover: 'heat',
    source: 'assets/audio/drift.wav',
  ),
  Track(
    id: 'zico',
    title: 'Zico list',
    artist: 'Francesco Gennari',
    cover: 'zico',
    source: 'assets/audio/afterglow.wav',
  ),
  Track(
    id: 'jay',
    title: 'Jay Chou',
    artist: 'Alina Chaiderov',
    cover: 'blue-night',
    source: 'assets/audio/aurora.wav',
  ),
];

List<Playlist> initialPlaylists() => [
  Playlist(
    id: 'dj',
    name: 'DJ Music',
    cover: 'dj',
    trackIds: catalog.skip(4).map((s) => s.id).toList(),
  ),
  Playlist(
    id: 'hip-hop',
    name: 'Hip - Hop',
    cover: 'hip-hop',
    trackIds: catalog.map((s) => s.id).toList(),
  ),
];
