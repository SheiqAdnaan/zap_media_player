import 'package:flutter/material.dart';
import '../theme/zmp_theme.dart';
import '../models/video_file.dart';

class VideoCard extends StatefulWidget {
  final VideoFileModel video;
  final bool isListMode;
  final VoidCallback onTap;

  const VideoCard({
    super.key,
    required this.video,
    required this.isListMode,
    required this.onTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _hovering = false;

  String _formatDuration(int? ms) {
    if (ms == null) return '--:--:--';
    final d = Duration(milliseconds: ms);
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get _formatExt {
    final name = widget.video.name;
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '';
    return name.substring(dot + 1).toUpperCase();
  }

  void _showContextMenu(BuildContext context, TapDownDetails details) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'play',
          child: _ContextMenuItem(icon: Icons.play_arrow, label: 'Play'),
        ),
        const PopupMenuItem(
          value: 'resume',
          child: _ContextMenuItem(icon: Icons.fast_forward, label: 'Resume'),
        ),
        const PopupMenuItem(
          value: 'play_beginning',
          child: _ContextMenuItem(
              icon: Icons.replay, label: 'Play from Beginning'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'add_queue',
          child:
              _ContextMenuItem(icon: Icons.playlist_add, label: 'Add to Queue'),
        ),
        const PopupMenuItem(
          value: 'add_playlist',
          child: _ContextMenuItem(
              icon: Icons.playlist_add_check, label: 'Add to Playlist'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'rename',
          child: _ContextMenuItem(icon: Icons.edit, label: 'Rename File'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: _ContextMenuItem(
              icon: Icons.delete_outline, label: 'Delete File'),
        ),
        const PopupMenuItem(
          value: 'open_folder',
          child: _ContextMenuItem(
              icon: Icons.folder_open, label: 'Open Containing Folder'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'properties',
          child: _ContextMenuItem(icon: Icons.info_outline, label: 'Properties'),
        ),
      ],
    ).then((value) {
      if (value == 'play' || value == 'resume') {
        widget.onTap();
      }
      // TODO: Handle other context menu actions
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isListMode) {
      return _buildListItem();
    }
    return _buildGridItem();
  }

  Widget _buildGridItem() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (d) => _showContextMenu(context, d),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovering ? ZmpTheme.cardSurfaceHover : ZmpTheme.cardSurface,
            borderRadius: BorderRadius.circular(8),
            border: _hovering
                ? Border.all(
                    color: ZmpTheme.accentBlue.withValues(alpha: 0.2),
                    width: 1)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail area
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8)),
                      child: widget.video.thumbnailBlob != null
                          ? Image.memory(
                              widget.video.thumbnailBlob!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: ZmpTheme.cardSurfaceActive,
                              child: const Icon(
                                Icons.movie_outlined,
                                size: 48,
                                color: ZmpTheme.textMuted,
                              ),
                            ),
                    ),
                    // Hover play overlay
                    if (_hovering)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Duration badge
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: ZmpTheme.durationBadge,
                        child: Text(
                          _formatDuration(widget.video.durationMs),
                          style: ZmpTheme.timecodeSmall,
                        ),
                      ),
                    ),
                    // New badge
                    if (widget.video.isNew)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: ZmpTheme.newBadge,
                          child: Text('NEW', style: ZmpTheme.badge),
                        ),
                      ),
                    // Progress bar at bottom
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 3,
                        color: ZmpTheme.seekbarBg,
                        // TODO: Fill based on actual resume progress
                      ),
                    ),
                  ],
                ),
              ),
              // Info section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.name,
                      style: ZmpTheme.bodyMedium.copyWith(
                        color: ZmpTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Format badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: ZmpTheme.formatBadge(),
                          child: Text(
                            _formatExt,
                            style: ZmpTheme.badge
                                .copyWith(color: ZmpTheme.accentBlue, fontSize: 9),
                          ),
                        ),
                        if (widget.video.resolution != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration:
                                ZmpTheme.formatBadge(color: ZmpTheme.accentAmber),
                            child: Text(
                              widget.video.resolution!,
                              style: ZmpTheme.badge.copyWith(
                                  color: ZmpTheme.accentAmber, fontSize: 9),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatSize(widget.video.size),
                          style: ZmpTheme.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (d) => _showContextMenu(context, d),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovering ? ZmpTheme.cardSurfaceHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 120,
                  height: 68,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      widget.video.thumbnailBlob != null
                          ? Image.memory(widget.video.thumbnailBlob!,
                              fit: BoxFit.cover)
                          : Container(
                              color: ZmpTheme.cardSurfaceActive,
                              child: const Icon(Icons.movie_outlined,
                                  size: 28, color: ZmpTheme.textMuted),
                            ),
                      // Duration badge
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: ZmpTheme.durationBadge,
                          child: Text(
                            _formatDuration(widget.video.durationMs),
                            style: ZmpTheme.timecodeSmall.copyWith(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.video.name,
                      style: ZmpTheme.titleMedium.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: ZmpTheme.formatBadge(),
                          child: Text(
                            _formatExt,
                            style: ZmpTheme.badge
                                .copyWith(color: ZmpTheme.accentBlue, fontSize: 9),
                          ),
                        ),
                        if (widget.video.resolution != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: ZmpTheme.formatBadge(
                                color: ZmpTheme.accentAmber),
                            child: Text(
                              widget.video.resolution!,
                              style: ZmpTheme.badge.copyWith(
                                  color: ZmpTheme.accentAmber, fontSize: 9),
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                        Text(
                          _formatSize(widget.video.size),
                          style: ZmpTheme.bodySmall,
                        ),
                        if (widget.video.codec != null) ...[
                          Text('  •  ', style: ZmpTheme.bodySmall),
                          Text(widget.video.codec!, style: ZmpTheme.bodySmall),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Play button
              if (_hovering)
                IconButton(
                  icon: const Icon(Icons.play_circle_filled,
                      color: ZmpTheme.accentBlue, size: 36),
                  onPressed: widget.onTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Context Menu Item Widget ────────────────────────────────────────────
class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContextMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ZmpTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
