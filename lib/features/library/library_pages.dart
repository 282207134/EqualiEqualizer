import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_controller.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../player/player_page.dart';
import 'search_page.dart';

void playTrack(BuildContext context, Track track, List<Track> queue) {
  final app = AppScope.of(context);
  app.remember(track);
  unawaited(app.audio.play(track, tracks: queue));
  openPage(context, const PlayerPage());
}

class TrackTile extends StatelessWidget {
  const TrackTile(this.track, {super.key, required this.tracks, this.trailing, this.playlist});
  final Track track;
  final List<Track> tracks;
  final Widget? trailing;
  final Playlist? playlist;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            key: ValueKey('track-${track.id}'),
            onTap: () => playTrack(context, track, tracks),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Artwork(track.cover),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: EqualiColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        trailing ??
            NeuIcon(
              Icons.more_horiz_rounded,
              key: ValueKey('more-${track.id}'),
              label: 'More about ${track.title}',
              onTap: () => songMenu(context, track, playlist: playlist),
            ),
      ],
    ),
  );
}

class TrackListPage extends StatelessWidget {
  const TrackListPage({super.key, required this.title, required this.tracks});
  final String title;
  final List<Track> tracks;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          PageHeader(title),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 10, 24),
              itemCount: tracks.length,
              itemBuilder: (context, index) => TrackTile(tracks[index], tracks: tracks),
            ),
          ),
        ],
      ),
    ),
  );
}

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              'Playlists',
              trailing: NeuIcon(
                Icons.add,
                label: 'New playlist',
                onTap: () async {
                  final list = await createPlaylist(context);
                  if (context.mounted && list != null) {
                    openPage(context, PlaylistPage(playlist: list));
                  }
                },
              ),
            ),
            Expanded(
              child: app.playlists.isEmpty
                  ? const EmptyState(
                      icon: Icons.queue_music_rounded,
                      title: 'Your next favorite mix',
                      message: 'Tap + to make a playlist of your own.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: .70,
                      ),
                      itemCount: app.playlists.length,
                      itemBuilder: (context, index) {
                        final list = app.playlists[index];
                        return GestureDetector(
                          onTap: () => openPage(context, PlaylistPage(playlist: list)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
                                builder: (context, c) =>
                                    Artwork(list.cover, size: c.maxWidth, radius: 22),
                              ),
                              const SizedBox(height: 12),
                              Text(list.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                '${list.trackIds.length} songs',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
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

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key, required this.playlist});
  final Playlist playlist;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tracks = app.songsFor(playlist);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  PageHeader(
                    '',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NeuIcon(
                          Icons.search_rounded,
                          label: 'Search playlist',
                          onTap: () => openPage(context, SearchPage(playlist: playlist)),
                        ),
                        NeuIcon(
                          Icons.more_horiz_rounded,
                          key: const ValueKey('playlist-more'),
                          label: 'Playlist options',
                          onTap: () => playlistMenu(context, playlist),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Artwork(playlist.cover, size: 238, radius: 28),
                  const SizedBox(height: 20),
                  Text(playlist.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '${tracks.length} songs  ·  Your personal mix',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: tracks.isEmpty
                                ? null
                                : () {
                                    app.audio.shuffle = true;
                                    playTrack(context, tracks.first, tracks);
                                  },
                            child: const Column(
                              children: [
                                Icon(Icons.shuffle_rounded, color: EqualiColors.muted),
                                SizedBox(height: 5),
                                Text(
                                  'Random play',
                                  style: TextStyle(fontSize: 12, color: EqualiColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: PrimaryButton(
                            'Play',
                            key: const ValueKey('play-playlist'),
                            icon: Icons.play_arrow_rounded,
                            onPressed: tracks.isEmpty
                                ? null
                                : () => playTrack(context, tracks.first, tracks),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            key: const ValueKey('add-songs'),
                            onTap: () => showAddSongs(context, playlist),
                            child: const Column(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: EqualiColors.muted),
                                SizedBox(height: 5),
                                Text(
                                  'Add songs',
                                  style: TextStyle(fontSize: 12, color: EqualiColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            if (tracks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.music_note_rounded,
                  title: 'A fresh start',
                  message: 'Add songs to bring this playlist to life.',
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 10, 24),
              sliver: SliverList.builder(
                itemCount: tracks.length,
                itemBuilder: (context, index) =>
                    TrackTile(tracks[index], tracks: tracks, playlist: playlist),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Playlist?> createPlaylist(BuildContext context) =>
    showEqualiSheet<Playlist>(context, const _CreatePlaylistSheet());

class _CreatePlaylistSheet extends StatefulWidget {
  const _CreatePlaylistSheet();
  @override
  State<_CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<_CreatePlaylistSheet> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('New Playlist', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 28),
        const NeuBox(
          radius: 20,
          padding: EdgeInsets.all(28),
          child: Icon(Icons.queue_music_rounded, size: 48, color: EqualiColors.primary),
        ),
        const SizedBox(height: 28),
        NeuBox(
          pressed: true,
          radius: 24,
          child: TextField(
            key: const ValueKey('playlist-name'),
            controller: _name,
            maxLength: 40,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Playlist name',
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            'Create playlist',
            key: const ValueKey('create-playlist'),
            onPressed: _name.text.trim().isEmpty
                ? null
                : () {
                    Navigator.pop(context, AppScope.of(context).createPlaylist(_name.text));
                  },
          ),
        ),
      ],
    ),
  );
}

Future<void> showAddSongs(BuildContext context, Playlist list) =>
    showEqualiSheet(context, AddSongsSheet(playlist: list), full: true);

class AddSongsSheet extends StatefulWidget {
  const AddSongsSheet({super.key, required this.playlist});
  final Playlist playlist;
  @override
  State<AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<AddSongsSheet> {
  final _query = TextEditingController();
  final Set<String> _selected = {};
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final songs = app.search(_query.text);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              Expanded(
                child: Text(
                  'Add songs',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                key: const ValueKey('add-done'),
                onPressed: () {
                  app.addSongs(widget.playlist, _selected);
                  Navigator.pop(context);
                },
                child: Text(_selected.isEmpty ? 'Done' : 'Done (${_selected.length})'),
              ),
            ],
          ),
          const Divider(height: 24),
          SearchField(controller: _query, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Expanded(
            child: songs.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No songs found',
                    message: 'Try another song or artist.',
                  )
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, i) {
                      final song = songs[i];
                      final existing = widget.playlist.trackIds.contains(song.id);
                      final selected = existing || _selected.contains(song.id);
                      return TrackTile(
                        song,
                        tracks: songs,
                        trailing: NeuIcon(
                          selected ? Icons.check_rounded : Icons.add_rounded,
                          key: ValueKey('select-${song.id}'),
                          label: existing
                              ? 'Already added'
                              : selected
                              ? 'Deselect song'
                              : 'Select song',
                          selected: selected,
                          onTap: existing
                              ? null
                              : () => setState(() {
                                  if (!_selected.add(song.id)) {
                                    _selected.remove(song.id);
                                  }
                                }),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> songMenu(BuildContext context, Track track, {Playlist? playlist}) async {
  final app = AppScope.of(context);
  final action = await showEqualiSheet<String>(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 10, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Artwork(track.cover),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      track.imported ? 'Local audio file' : 'Original demo audio · 32 sec',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              NeuIcon(Icons.close, label: 'Close menu', onTap: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 28),
          _MenuItem(Icons.playlist_add_rounded, 'Add to playlist', 'add'),
          _MenuItem(
            app.favorites.contains(track.id)
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            app.favorites.contains(track.id) ? 'Remove from favorites' : 'Add to favorites',
            'favorite',
          ),
          const _MenuItem(Icons.share_outlined, 'Share song', 'share'),
          if (playlist != null)
            const _MenuItem(Icons.remove_circle_outline, 'Remove from playlist', 'remove'),
          if (track.imported)
            const _MenuItem(Icons.delete_outline_rounded, 'Delete upload', 'delete'),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  switch (action) {
    case 'favorite':
      app.toggleFavorite(track);
      toast(
        context,
        app.favorites.contains(track.id) ? 'Added to favorites' : 'Removed from favorites',
      );
    case 'add':
      await addToPlaylist(context, track);
    case 'share':
      await Clipboard.setData(ClipboardData(text: '${track.title} — ${track.artist} · Equali'));
      if (context.mounted) toast(context, 'Song details copied');
    case 'remove':
      app.removeSong(playlist!, track);
    case 'delete':
      if (await confirmDelete(
        context,
        'Delete this upload?',
        'It will also be removed from your playlists.',
      )) {
        await app.deleteImport(track);
      }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('menu-$value'),
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, size: 22),
    title: Text(label),
    onTap: () => Navigator.pop(context, value),
  );
}

Future<void> addToPlaylist(BuildContext context, Track track) async {
  final app = AppScope.of(context);
  await showEqualiSheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add to playlist', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          for (final list in app.playlists)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Artwork(list.cover),
              title: Text(list.name),
              subtitle: Text('${list.trackIds.length} songs'),
              trailing: Icon(
                list.trackIds.contains(track.id) ? Icons.check : Icons.add,
                color: EqualiColors.primary,
              ),
              onTap: () {
                app.addSongs(list, [track.id]);
                Navigator.pop(context);
                toast(context, 'Added to ${list.name}');
              },
            ),
          if (app.playlists.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Create a playlist first.')),
        ],
      ),
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, String title, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    ) ??
    false;

Future<void> playlistMenu(BuildContext context, Playlist list) async {
  final app = AppScope.of(context);
  final action = await showEqualiSheet<String>(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Artwork(list.cover),
              const SizedBox(width: 16),
              Expanded(child: Text(list.name)),
              NeuIcon(Icons.close, label: 'Close menu', onTap: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 28),
          const _MenuItem(Icons.add_circle_outline_rounded, 'Add songs', 'add'),
          const _MenuItem(Icons.edit_outlined, 'Edit name', 'rename'),
          const _MenuItem(Icons.low_priority_rounded, 'Change song position', 'reorder'),
          const _MenuItem(Icons.share_outlined, 'Share playlist', 'share'),
          const _MenuItem(Icons.delete_outline_rounded, 'Delete playlist', 'delete'),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  switch (action) {
    case 'add':
      await showAddSongs(context, list);
    case 'rename':
      await showEqualiSheet(context, _RenameSheet(playlist: list));
    case 'reorder':
      await openPage(context, ReorderPage(playlist: list));
    case 'share':
      await Clipboard.setData(
        ClipboardData(
          text:
              '${list.name}\n${app.songsFor(list).map((s) => '${s.title} — ${s.artist}').join('\n')}',
        ),
      );
      if (context.mounted) toast(context, 'Playlist copied');
    case 'delete':
      if (await confirmDelete(
        context,
        'Delete ${list.name}?',
        'Your audio files will stay in the library.',
      )) {
        app.deletePlaylist(list);
        if (context.mounted) Navigator.pop(context);
      }
  }
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.playlist});
  final Playlist playlist;
  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final _name = TextEditingController(text: widget.playlist.name);
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Edit playlist name', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        TextField(
          key: const ValueKey('rename-input'),
          controller: _name,
          maxLength: 40,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          'Save changes',
          onPressed: _name.text.trim().isEmpty
              ? null
              : () {
                  AppScope.of(context).rename(widget.playlist, _name.text);
                  Navigator.pop(context);
                },
        ),
      ],
    ),
  );
}

class ReorderPage extends StatelessWidget {
  const ReorderPage({super.key, required this.playlist});
  final Playlist playlist;
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final songs = app.songsFor(playlist);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              'Song order',
              trailing: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Hold the handle and drag to reorder.',
                style: TextStyle(color: EqualiColors.muted, fontSize: 12),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) => app.reorder(playlist, oldIndex, newIndex),
                itemCount: songs.length,
                itemBuilder: (context, index) => TrackTile(
                  songs[index],
                  key: ValueKey(songs[index].id),
                  tracks: songs,
                  trailing: ReorderableDragStartListener(
                    index: index,
                    child: const SizedBox(
                      width: 44,
                      height: 48,
                      child: Icon(Icons.drag_handle_rounded, color: EqualiColors.muted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
