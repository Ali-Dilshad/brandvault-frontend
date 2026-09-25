import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/folder_model.dart';

class FolderCard extends StatelessWidget{
  final FolderModel folder;
  final int depth;
  final bool selected;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.folder,
    this.depth = 1,
    this.selected = false,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: 8.0 + (depth -1) * 14, right: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text(
          folder.name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: depth > 1 ? 12.5 : 13, color: selected ? AppColors.accent : AppColors.inkSoft),
        ),
        onTap: onTap,
      ),
    );
  }
}