import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';

class AssetRowItem extends StatelessWidget {
  final AssetModel asset;
  final int index;
  final bool selected;
  final bool isTrashView;
  final String? folderName;
  final VoidCallback onTap;
  final VoidCallback? onTrash;
  final VoidCallback? onMove;
  final VoidCallback? onRestore;
  final VoidCallback? onDeleteForever;
  final VoidCallback? onGenerateTags;

  const AssetRowItem({
    super.key,
    required this.asset,
    required this.index,
    required this.onTap,
    this.selected = false,
    this.isTrashView = false,
    this.folderName,
    this.onTrash,
    this.onMove,
    this.onRestore,
    this.onDeleteForever,
    this.onGenerateTags,
  });

  String get _subtitle {
    final parts = <String>[
      asset.type.name,
      if (folderName != null) folderName!,
      if (asset.tags.isNotEmpty) asset.tags.join(', '),
    ];

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox(
          width: 32,
          child: Text(
            (index + 1).toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          asset.name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.inkSoft,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isTrashView && onGenerateTags != null)
              IconButton(
                icon: const Icon(Icons.auto_awesome, size: 18),
                tooltip: 'Generate tags',
                onPressed: onGenerateTags,
              ),
            if (!isTrashView && onMove != null)
              IconButton(
                icon: const Icon(
                  Icons.drive_file_move_outline,
                  size: 18,
                ),
                tooltip: 'Move to folder',
                onPressed: onMove,
              ),
            if (isTrashView) ...[
              IconButton(
                icon: const Icon(Icons.restore, size: 18),
                tooltip: 'Restore',
                onPressed: onRestore,
              ),
              if (onDeleteForever != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                    size: 18,
                    color: AppColors.rust,
                  ),
                  tooltip: 'Delete permanently',
                  onPressed: onDeleteForever,
                ),
            ] else
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.rust,
                ),
                tooltip: 'Move to Trash',
                onPressed: onTrash,
              ),
          ],
        ),
      ),
    );
  }
}