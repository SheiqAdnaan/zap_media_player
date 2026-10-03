import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/zmp_theme.dart';
import 'screens/library/library_screen.dart';

class ZapMediaApp extends ConsumerWidget {
  const ZapMediaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Zap Media Player',
      debugShowCheckedModeBanner: false,
      theme: ZmpTheme.darkTheme,
      home: const LibraryScreen(),
    );
  }
}
