import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../account/account_pages.dart';
import '../player/player_page.dart';
import 'connection_page.dart';
import 'library_pages.dart';
import 'search_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              children: [
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Profile',
                      child: GestureDetector(
                        key: const ValueKey('profile'),
                        onTap: () => openPage(context, const ProfilePage()),
                        child: const Artwork('avatar', size: 40, radius: 40),
                      ),
                    ),
                    const Spacer(),
                    NeuBox(
                      radius: 9,
                      padding: const EdgeInsets.all(4),
                      child: GestureDetector(
                        key: const ValueKey('connect'),
                        onTap: () => openPage(context, const ConnectionPage()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: EqualiColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add, size: 16, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Connect', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeuIcon(
                      Icons.search_rounded,
                      key: const ValueKey('search'),
                      label: 'Search music',
                      onTap: () => openPage(context, const SearchPage()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'My Music',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 104,
                  child: OverflowBox(
                    maxWidth: MediaQuery.sizeOf(context).width,
                    alignment: Alignment.centerLeft,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: 2,
                      separatorBuilder: (_, i) => const SizedBox(width: 16),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => openPage(
                          context,
                          TrackListPage(
                            title: index == 0 ? 'Backstage sessions' : 'Music for the people',
                            tracks: app.tracks,
                          ),
                        ),
                        child: SizedBox(width: 180, child: _Banner(index)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionTitle('Library'),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    key: const ValueKey('uploads'),
                    onTap: () => openPage(context, const UploadsPage()),
                    child: const SizedBox(
                      width: 98,
                      height: 72,
                      child: NeuBox(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, color: EqualiColors.primary, size: 29),
                            SizedBox(height: 5),
                            Text(
                              'My Upload',
                              maxLines: 1,
                              style: TextStyle(color: EqualiColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionTitle(
                  'Playlists',
                  action: 'See all',
                  onAction: () => openPage(context, const PlaylistsPage()),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    clipBehavior: Clip.none,
                    scrollDirection: Axis.horizontal,
                    itemCount: app.playlists.length + 1,
                    separatorBuilder: (_, i) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          key: const ValueKey('new-playlist'),
                          onTap: () async {
                            final list = await createPlaylist(context);
                            if (context.mounted && list != null) {
                              openPage(context, PlaylistPage(playlist: list));
                            }
                          },
                          child: const SizedBox(
                            width: 72,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 72,
                                  width: 72,
                                  child: NeuBox(
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 42,
                                      color: EqualiColors.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'New Playlist',
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 10, color: EqualiColors.primary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final list = app.playlists[index - 1];
                      return GestureDetector(
                        key: ValueKey('playlist-${list.id}'),
                        onTap: () => openPage(context, PlaylistPage(playlist: list)),
                        child: SizedBox(
                          width: 72,
                          child: Column(
                            children: [
                              Artwork(list.cover, size: 72, radius: 12),
                              const SizedBox(height: 8),
                              Text(
                                list.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: EqualiColors.primary),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SectionTitle(
                  'Today Hits',
                  action: 'See all',
                  onAction: () =>
                      openPage(context, TrackListPage(title: 'Today Hits', tracks: app.tracks)),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, cover, title, artist) in [
                      (0, 'blue-night', 'Blue Neight', 'Post Mony'),
                      (1, 'shades', 'Shades of Love', 'Ania Szarmach'),
                      (2, 'good-byes', 'Good byes', 'Andimoset'),
                    ]) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          key: ValueKey('album-$i'),
                          onTap: () =>
                              openPage(context, TrackListPage(title: title, tracks: app.tracks)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
                                builder: (context, c) =>
                                    Artwork(cover, size: c.maxWidth, radius: 16),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, color: EqualiColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (app.storageError != null)
                  Padding(padding: const EdgeInsets.only(top: 20), child: Text(app.storageError!)),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ListenableBuilder(
                listenable: app.audio,
                builder: (context, child) {
                  final audio = app.audio;
                  final song = audio.current;
                  if (song == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: NeuBox(
                      radius: 18,
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => openPage(context, const PlayerPage()),
                            child: Artwork(song.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => openPage(context, const PlayerPage()),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    song.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(song.artist, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ),
                          NeuIcon(
                            audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            label: 'Play or pause',
                            onTap: audio.toggle,
                          ),
                          NeuIcon(Icons.skip_next_rounded, label: 'Next song', onTap: audio.next),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.index);
  final int index;
  @override
  Widget build(BuildContext context) => NeuBox(
    radius: 16,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Transform.scale(
        scale: 1.10,
        child: Image.asset(
          'assets/images/banner-${index == 0 ? 'stage' : 'bar'}.png',
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}
