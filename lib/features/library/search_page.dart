import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../data/models.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'library_pages.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.playlist});
  final Playlist? playlist;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final searching = _query.text.trim().isNotEmpty;
    final results = app
        .search(_query.text)
        .where((s) => widget.playlist == null || widget.playlist!.trackIds.contains(s.id))
        .toList();
    final history = app.history
        .map((id) => app.tracks.where((s) => s.id == id).firstOrNull)
        .nonNulls
        .toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _query,
                      onChanged: (_) => setState(() {}),
                      hint: widget.playlist == null
                          ? 'Search songs, artists'
                          : 'Search this playlist',
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ],
              ),
            ),
            Expanded(
              child: searching && results.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No results',
                      message: 'Try a different song title or artist name.',
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        SectionTitle(
                          searching ? 'Results · ${results.length}' : 'Search history',
                          action: !searching && history.isNotEmpty ? 'Clear all' : null,
                          onAction: () {
                            app.history.clear();
                            app.changed();
                          },
                        ),
                        const SizedBox(height: 12),
                        if (!searching && history.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Text(
                              'Find the soundtrack to your day.\nSearch the library by song or artist.',
                              style: TextStyle(color: EqualiColors.muted, height: 1.8),
                            ),
                          ),
                        for (final song in searching ? results : history)
                          TrackTile(
                            song,
                            tracks: searching ? results : history,
                            trailing: searching
                                ? null
                                : NeuIcon(
                                    Icons.close,
                                    label: 'Remove from search history',
                                    onTap: () {
                                      app.history.remove(song.id);
                                      app.changed();
                                    },
                                  ),
                          ),
                        if (!searching) ...[
                          const SizedBox(height: 32),
                          const SectionTitle('Made for your mood'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final mood in ['Lofi', 'City', 'Space', 'Pure'])
                                ActionChip(
                                  label: Text(mood),
                                  side: BorderSide.none,
                                  backgroundColor: EqualiColors.background,
                                  labelStyle: const TextStyle(color: EqualiColors.primary),
                                  onPressed: () {
                                    _query.text = mood;
                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
