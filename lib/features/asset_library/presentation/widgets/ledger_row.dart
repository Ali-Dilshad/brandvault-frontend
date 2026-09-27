import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';
import 'asset_type_chip.dart';


String relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  final weeks = diff.inDays ~/ 7;
  return '$weeks week${weeks == 1 ? '' : 's'} ago';
}


class LedgerRow extends StatelessWidget {
  static const _wideBreakpoint = 640.0;

  final AssetModel asset;
  final int index;
  final bool selected;
  final bool isTrashView;
  final VoidCallback onTap;
  final VoidCallback? onTrash;
  final VoidCallback? onMove;
  final VoidCallback? onRestore;
  final VoidCallback? onDeleteForever;

  const LedgerRow({
    super.key,
    required this.asset,
    required this.index,
    required this.onTap,
    this.selected = false,
    this.isTrashView = false,
    this.onTrash,
    this.onMove,
    this.onRestore,
    this.onDeleteForever,
  });

  String get _tagPreview => asset.tags.isEmpty ? '' : asset.tags.join(', ');

  List<Widget> _actions() {
    if (isTrashView) {
      return [
        _IconBtn(icon: Icons.restore, tooltip: 'Restore', onPressed: onRestore),
        _IconBtn(icon: Icons.close, tooltip: 'Delete forever', danger: true, onPressed: onDeleteForever),
      ];
    }
    return [
      _IconBtn(icon: Icons.drive_file_move_outline, tooltip: 'Move to folder', onPressed: onMove),
      _IconBtn(icon: Icons.delete_outline, tooltip: 'Move to Trash', danger: true, onPressed: onTrash),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        return Material(
          color: selected ? AppColors.accentSoft : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: wide ? _wideRow() : _compactRow(),
            ),
          ),
        );
      },
    );
  }

  Widget _nameBlock() => Row(
    children: [
      AssetTypeChip(type: asset.type),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(asset.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            if (_tagPreview.isNotEmpty)
              Text(_tagPreview, style: const TextStyle(fontSize: 11.5, color: AppColors.muted), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ],
  );

  Widget _wideRow() => Row(
    children: [
      SizedBox(width: 24, child: Text((index + 1).toString().padLeft(2, '0'), style: const TextStyle(color: AppColors.muted, fontSize: 12))),
      const SizedBox(width: 8),
      Expanded(child: _nameBlock()),
      SizedBox(width: 90, child: Text(asset.type.name, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft))),
      SizedBox(
        width: 110,
        child: Text(isTrashView ? relativeTime(asset.deletedAt ?? asset.updatedAt) : relativeTime(asset.updatedAt),
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
      ),
      SizedBox(
        width: 76,
        child: Row(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: _actions()),
      ),
    ],
  );

  Widget _compactRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 20, child: Text((index + 1).toString().padLeft(2, '0'), style: const TextStyle(color: AppColors.muted, fontSize: 11))),
      const SizedBox(width: 6),
      Expanded(child: _nameBlock()),
      Row(mainAxisSize: MainAxisSize.min, children: _actions()),
    ],
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool danger;
  final VoidCallback? onPressed;

  const _IconBtn({required this.icon, required this.tooltip, this.danger = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: SizedBox(
          width: 26,
          height: 26,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(26, 26),
              side: const BorderSide(color: AppColors.line),
              backgroundColor: Colors.white,
            ),
            child: Icon(icon, size: 14, color: danger ? AppColors.rust : AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}
