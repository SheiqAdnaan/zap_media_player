import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/zmp_theme.dart';
import '../../providers/library_provider.dart';
import '../../models/video_file.dart';
import '../../widgets/video_card.dart';

class AllVideosTab extends ConsumerWidget {
  final void Function(VideoFileModel) onVideoTap;
  const AllVideosTab({super.key, required this.onVideoTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(filteredVideosProvider);
    final viewMode = ref.watch(viewModeProvider);
    final sortMode = ref.watch(sortModeProvider);

    return videosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ZmpTheme.accentBlue),
      ),
      error: (err, _) => Center(
        child: Text('Error: $err', style: ZmpTheme.bodyMedium),
      ),
      data: (videos) {
        if (videos.isEmpty) {
          return _EmptyVideosView();
        }

        // Sort videos
        final sorted = List<VideoFileModel>.from(videos);
        switch (sortMode) {
          case SortMode.name:
            sorted.sort((a, b) => a.name.compareTo(b.name));
          case SortMode.date:
            sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          case SortMode.size:
            sorted.sort((a, b) => b.size.compareTo(a.size));
        }

        if (viewMode == ViewMode.list) {
          return _buildListView(sorted);
        }
        return _buildGridView(sorted, context);
      },
    );
  }

  Widget _buildGridView(List<VideoFileModel> videos, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / 280).floor().clamp(2, 6);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 16 / 12,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(
          video: videos[index],
          isListMode: false,
          onTap: () => onVideoTap(videos[index]),
        );
      },
    );
  }

  Widget _buildListView(List<VideoFileModel> videos) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return VideoCard(
          video: videos[index],
          isListMode: true,
          onTap: () => onVideoTap(videos[index]),
        );
      },
    );
  }
}

class _EmptyVideosView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: ZmpTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No videos found',
            style: ZmpTheme.titleMedium.copyWith(color: ZmpTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a folder to start scanning for videos',
            style: ZmpTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
