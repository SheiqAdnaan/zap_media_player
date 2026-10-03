import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme/zmp_theme.dart';
import '../../providers/library_provider.dart';
import '../../models/video_file.dart';
import '../../services/file_scanner.dart';
import '../player/player_screen.dart';
import 'folders_tab.dart';
import 'all_videos_tab.dart';
import 'playlists_tab.dart';
import 'private_vault_tab.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin, WindowListener {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void _toggleViewMode() {
    final current = ref.read(viewModeProvider);
    ref.read(viewModeProvider.notifier).state = switch (current) {
      ViewMode.grid => ViewMode.list,
      ViewMode.list => ViewMode.folder,
      ViewMode.folder => ViewMode.grid,
    };
  }

  void _showSortMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    showMenu<SortMode>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        offset.dy,
      ),
      items: [
        const PopupMenuItem(value: SortMode.name, child: Text('Name')),
        const PopupMenuItem(value: SortMode.date, child: Text('Date Modified')),
        const PopupMenuItem(value: SortMode.size, child: Text('File Size')),
      ],
    ).then((value) {
      if (value != null) {
        ref.read(sortModeProvider.notifier).state = value;
      }
    });
  }

  Future<void> _addFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Media Folder',
    );
    if (result != null) {
      setState(() => _isScanning = true);
      final scanner = FileScanner();
      final files = await scanner.scanDirectory(result);
      final db = ref.read(databaseProvider);

      // Add scanned folder
      await db.scannedFoldersDao.addFolder(
        ScannedFoldersCompanion.insert(
          path: result,
          videoCount: Value(files.length),
          totalSizeBytes: Value(
            files.fold<int>(0, (sum, f) => sum + f.lengthSync()),
          ),
        ),
      );

      // Add video files to DB
      final companions = files.map((f) {
        final stat = f.statSync();
        return VideoFilesCompanion.insert(
          path: f.path,
          name: f.uri.pathSegments.last,
          size: stat.size,
        );
      }).toList();
      await db.videoFilesDao.insertVideos(companions);

      // Refresh providers
      ref.invalidate(scannedFoldersProvider);
      ref.invalidate(allVideosProvider);
      setState(() => _isScanning = false);
    }
  }

  Future<void> _refreshDirectories() async {
    setState(() => _isScanning = true);
    final db = ref.read(databaseProvider);
    final folders = await db.scannedFoldersDao.getAllFolders();
    final scanner = FileScanner();

    for (final folder in folders) {
      final files = await scanner.scanDirectory(folder.path);
      await db.scannedFoldersDao.addFolder(
        ScannedFoldersCompanion.insert(
          path: folder.path,
          videoCount: Value(files.length),
          totalSizeBytes: Value(
            files.fold<int>(0, (sum, f) => sum + f.lengthSync()),
          ),
        ),
      );
      final companions = files.map((f) {
        final stat = f.statSync();
        return VideoFilesCompanion.insert(
          path: f.path,
          name: f.uri.pathSegments.last,
          size: stat.size,
        );
      }).toList();
      await db.videoFilesDao.insertVideos(companions);
    }

    ref.invalidate(scannedFoldersProvider);
    ref.invalidate(allVideosProvider);
    setState(() => _isScanning = false);
  }

  void _openVideo(VideoFileModel video) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlayerScreen(video: video),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(viewModeProvider);

    return Scaffold(
      backgroundColor: ZmpTheme.windowBackground,
      body: Column(
        children: [
          // ── Custom Title Bar ──────────────────────────────────────
          _buildTitleBar(),
          // ── Header with Search & Controls ─────────────────────────
          _buildHeader(viewMode),
          // ── Tab Bar ───────────────────────────────────────────────
          _buildTabBar(),
          // ── Scanning indicator ────────────────────────────────────
          if (_isScanning)
            LinearProgressIndicator(
              backgroundColor: ZmpTheme.seekbarBg,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(ZmpTheme.accentBlue),
              minHeight: 2,
            ),
          // ── Tab Content ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FoldersTab(onVideoTap: _openVideo),
                AllVideosTab(onVideoTap: _openVideo),
                const PlaylistsTab(),
                const PrivateVaultTab(),
              ],
            ),
          ),
        ],
      ),
      // ── FAB: Add Folder ───────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFolder,
        backgroundColor: ZmpTheme.accentBlue,
        icon: const Icon(Icons.create_new_folder_outlined, size: 20),
        label: const Text('Add Folder'),
      ),
    );
  }

  /// Draggable custom title bar (replaces native title bar)
  Widget _buildTitleBar() {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        if (await windowManager.isMaximized()) {
          windowManager.unmaximize();
        } else {
          windowManager.maximize();
        }
      },
      child: Container(
        height: 36,
        color: ZmpTheme.windowBackground,
        child: Row(
          children: [
            const SizedBox(width: 16),
            // Logo + App Name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ZmpTheme.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: ZmpTheme.accentBlue, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'ZMP',
                    style: ZmpTheme.titleMedium.copyWith(
                      color: ZmpTheme.accentBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Zap Media Player',
              style: ZmpTheme.bodyMedium.copyWith(
                color: ZmpTheme.textMuted,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            // Window controls
            _WindowButton(
              icon: Icons.minimize,
              onPressed: () => windowManager.minimize(),
            ),
            _WindowButton(
              icon: Icons.crop_square,
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            _WindowButton(
              icon: Icons.close,
              onPressed: () => windowManager.close(),
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ViewMode viewMode) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: ZmpTheme.bodyMedium.copyWith(color: ZmpTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  prefixIcon: const Icon(Icons.search, size: 20,
                      color: ZmpTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // View mode toggle
          _HeaderIconButton(
            icon: switch (viewMode) {
              ViewMode.grid => Icons.grid_view_rounded,
              ViewMode.list => Icons.view_list_rounded,
              ViewMode.folder => Icons.folder_open_rounded,
            },
            tooltip: 'View: ${viewMode.name}',
            onPressed: _toggleViewMode,
          ),
          const SizedBox(width: 4),
          // Sort
          Builder(
            builder: (ctx) => _HeaderIconButton(
              icon: Icons.sort,
              tooltip: 'Sort',
              onPressed: () => _showSortMenu(ctx),
            ),
          ),
          const SizedBox(width: 4),
          // Refresh
          _HeaderIconButton(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onPressed: _refreshDirectories,
          ),
          const SizedBox(width: 4),
          // Settings
          _HeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ZmpTheme.divider, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Folders'),
          Tab(text: 'All Videos'),
          Tab(text: 'Playlists'),
          Tab(text: 'Private Vault'),
        ],
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

// ── Reusable header icon button ─────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ZmpTheme.cardSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: ZmpTheme.textSecondary),
        ),
      ),
    );
  }
}

// ── Window control button ───────────────────────────────────────────────
class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 36,
          color: _hovering
              ? (widget.isClose
                  ? ZmpTheme.dangerRed
                  : ZmpTheme.cardSurfaceHover)
              : Colors.transparent,
          child: Icon(
            widget.icon,
            size: 16,
            color: _hovering && widget.isClose
                ? Colors.white
                : ZmpTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Settings Dialog ─────────────────────────────────────────────────────
class _SettingsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: ZmpTheme.accentBlue),
                const SizedBox(width: 12),
                Text('Settings', style: ZmpTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text('General', style: ZmpTheme.titleMedium),
            const SizedBox(height: 8),
            _settingsTile(
              icon: Icons.palette_outlined,
              title: 'Theme',
              subtitle: 'Dark (default)',
            ),
            _settingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English',
            ),
            const SizedBox(height: 16),
            Text('Playback', style: ZmpTheme.titleMedium),
            const SizedBox(height: 8),
            _settingsTile(
              icon: Icons.speed,
              title: 'Default Speed Boost',
              subtitle: '2.0x',
            ),
            _settingsTile(
              icon: Icons.skip_next,
              title: 'Seek Interval',
              subtitle: '10 seconds',
            ),
            _settingsTile(
              icon: Icons.subtitles_outlined,
              title: 'OpenSubtitles API Key',
              subtitle: 'Configure for subtitle search',
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ZmpTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZmpTheme.bodyMedium.copyWith(
                    color: ZmpTheme.textPrimary)),
                Text(subtitle, style: ZmpTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: ZmpTheme.textMuted, size: 20),
        ],
      ),
    );
  }
}

// Need to import drift for companions
import 'package:drift/drift.dart' show Value;
import '../../database/database.dart';
