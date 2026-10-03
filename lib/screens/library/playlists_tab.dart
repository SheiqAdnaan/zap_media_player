import 'package:flutter/material.dart';
import '../../theme/zmp_theme.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to PlaylistsDao
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 80,
            color: ZmpTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No playlists yet',
            style: ZmpTheme.titleMedium.copyWith(color: ZmpTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Right-click any video and select "Add to Playlist"',
            style: ZmpTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showCreatePlaylistDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Playlist'),
            style: FilledButton.styleFrom(
              backgroundColor: ZmpTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Save playlist to database
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
