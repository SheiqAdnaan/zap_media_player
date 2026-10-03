import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/zmp_theme.dart';
import '../../providers/library_provider.dart';
import '../../models/video_file.dart';
import '../../widgets/video_card.dart';

class FoldersTab extends ConsumerWidget {
  final void Function(VideoFileModel) onVideoTap;
  const FoldersTab({super.key, required this.onVideoTap});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(scannedFoldersProvider);

    return foldersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ZmpTheme.accentBlue),
      ),
      error: (err, _) => Center(
        child: Text('Error: $err', style: ZmpTheme.bodyMedium),
      ),
      data: (folders) {
        if (folders.isEmpty) {
          return _EmptyFoldersView();
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return _FolderCard(
              folderPath: folder.path,
              videoCount: folder.videoCount,
              totalSize: _formatSize(folder.totalSizeBytes),
              onVideoTap: onVideoTap,
            );
          },
        );
      },
    );
  }
}

class _EmptyFoldersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 80,
            color: ZmpTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No folders added yet',
            style: ZmpTheme.titleMedium.copyWith(color: ZmpTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add Folder" to scan a directory for videos',
            style: ZmpTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends ConsumerStatefulWidget {
  final String folderPath;
  final int videoCount;
  final String totalSize;
  final void Function(VideoFileModel) onVideoTap;

  const _FolderCard({
    required this.folderPath,
    required this.videoCount,
    required this.totalSize,
    required this.onVideoTap,
  });

  @override
  ConsumerState<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends ConsumerState<_FolderCard> {
  bool _expanded = false;

  String get _folderName {
    final parts = widget.folderPath.replaceAll('\\', '/').split('/');
    return parts.last.isNotEmpty ? parts.last : parts[parts.length - 2];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Folder header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ZmpTheme.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: _expanded
                    ? Border.all(
                        color: ZmpTheme.accentBlue.withValues(alpha: 0.3),
                        width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ZmpTheme.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_rounded,
                        color: ZmpTheme.accentBlue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_folderName, style: ZmpTheme.titleMedium),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.folderPath,
                              style: ZmpTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('  •  ', style: ZmpTheme.bodySmall),
                            Text(
                              '${widget.videoCount} Videos',
                              style: ZmpTheme.bodySmall.copyWith(
                                  color: ZmpTheme.accentBlue),
                            ),
                            Text('  •  ', style: ZmpTheme.bodySmall),
                            Text(widget.totalSize, style: ZmpTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        color: ZmpTheme.textMuted, size: 24),
                  ),
                ],
              ),
            ),
          ),
          // Expanded file list
          if (_expanded) _buildFileList(),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    final allVideosAsync = ref.watch(allVideosProvider);

    return allVideosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(color: ZmpTheme.accentBlue),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $err'),
      ),
      data: (videos) {
        final folderVideos = videos
            .where((v) => v.path.startsWith(widget.folderPath))
            .toList();
        if (folderVideos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No videos found', style: ZmpTheme.bodyMedium),
          );
        }
        return Container(
          margin: const EdgeInsets.only(left: 24, top: 4),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: ZmpTheme.accentBlue.withValues(alpha: 0.2), width: 2),
            ),
          ),
          child: Column(
            children: folderVideos.map((video) {
              return VideoCard(
                video: video,
                isListMode: true,
                onTap: () => widget.onVideoTap(video),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
