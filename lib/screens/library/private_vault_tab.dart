import 'package:flutter/material.dart';
import '../../theme/zmp_theme.dart';

class PrivateVaultTab extends StatefulWidget {
  const PrivateVaultTab({super.key});

  @override
  State<PrivateVaultTab> createState() => _PrivateVaultTabState();
}

class _PrivateVaultTabState extends State<PrivateVaultTab> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return _buildLockedView();
    }
    return _buildUnlockedView();
  }

  Widget _buildLockedView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ZmpTheme.cardSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: ZmpTheme.accentBlue.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 44,
              color: ZmpTheme.accentBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Private Vault',
            style: ZmpTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your PIN to access private files',
            style: ZmpTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 280,
            child: _PinInput(
              onComplete: (pin) {
                // TODO: Verify against stored hash
                if (pin.length >= 4) {
                  setState(() => _isUnlocked = true);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_open_rounded,
            size: 80,
            color: ZmpTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'Vault is empty',
            style:
                ZmpTheme.titleMedium.copyWith(color: ZmpTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Right-click any video and select "Move to Vault"',
            style: ZmpTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => setState(() => _isUnlocked = false),
            icon: const Icon(Icons.lock, size: 16),
            label: const Text('Lock Vault'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ZmpTheme.dangerRed,
              side: const BorderSide(color: ZmpTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinInput extends StatefulWidget {
  final void Function(String) onComplete;
  const _PinInput({required this.onComplete});

  @override
  State<_PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<_PinInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: ZmpTheme.titleLarge.copyWith(letterSpacing: 12),
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '• • • •',
            hintStyle: ZmpTheme.titleLarge.copyWith(
              color: ZmpTheme.textMuted,
              letterSpacing: 12,
            ),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: ZmpTheme.accentBlue.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ZmpTheme.accentBlue),
            ),
          ),
          onSubmitted: widget.onComplete,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => widget.onComplete(_controller.text),
          style: FilledButton.styleFrom(
            backgroundColor: ZmpTheme.accentBlue,
            minimumSize: const Size(double.infinity, 44),
          ),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
