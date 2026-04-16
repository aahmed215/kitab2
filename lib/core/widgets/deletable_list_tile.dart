// ═══════════════════════════════════════════════════════════════════
// DELETABLE_LIST_TILE.DART — Platform-Adaptive Deletable Tile
// Native: swipe left to reveal delete button.
// Web: hover to reveal delete button.
// Delete button is hidden by default on both platforms.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/kitab_theme.dart';

class DeletableListTile extends StatefulWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final String deleteConfirmTitle;
  final String deleteConfirmMessage;

  const DeletableListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.onDelete,
    this.deleteConfirmTitle = 'Delete?',
    this.deleteConfirmMessage = 'This cannot be undone.',
  });

  @override
  State<DeletableListTile> createState() => _DeletableListTileState();
}

class _DeletableListTileState extends State<DeletableListTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebTile();
    }
    return _buildNativeTile();
  }

  /// Web: hover to reveal delete icon.
  Widget _buildWebTile() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: ListTile(
        leading: widget.leading,
        title: widget.title,
        subtitle: widget.subtitle,
        trailing: AnimatedOpacity(
          opacity: _hovering ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: IconButton(
            icon: const Icon(Icons.delete_outline, color: KitabColors.error, size: 20),
            onPressed: () => _confirmDelete(context),
          ),
        ),
        onTap: widget.onTap,
      ),
    );
  }

  /// Native: swipe left to reveal delete.
  Widget _buildNativeTile() {
    return Dismissible(
      key: ValueKey(widget.key ?? widget.title.hashCode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: KitabColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: KitabColors.error),
      ),
      child: ListTile(
        leading: widget.leading,
        title: widget.title,
        subtitle: widget.subtitle,
        onTap: widget.onTap,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.deleteConfirmTitle),
        content: Text(widget.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KitabColors.error),
            onPressed: () {
              Navigator.pop(ctx, true);
              widget.onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
