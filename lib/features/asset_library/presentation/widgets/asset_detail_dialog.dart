import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';

const _labelStyle = TextStyle(fontSize: 11, color: AppColors.muted);

class AssetDetailDialog extends StatelessWidget {
  final AssetModel asset;
  final String? folderName;

  const AssetDetailDialog({super.key, required this.asset, this.folderName});

  Widget _field(String label, Widget value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label, style: _labelStyle), const SizedBox(height: 2), value],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final updated = asset.updatedAt.toLocal().toString().substring(0, 16);
    return AlertDialog(
      title: Text(asset.name),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field('Type', Text(asset.type.name, style: const TextStyle(fontSize: 13))),
              _field('Folder', Text(folderName ?? 'No folder', style: const TextStyle(fontSize: 13))),
              _field('Updated', Text(updated, style: const TextStyle(fontSize: 13))),
              _field('URL', SelectableText(asset.url, style: const TextStyle(fontSize: 13))),
              if (!asset.hasAiMetadata)
                const Text(
                  'No AI tags yet — tap the ✦ button on the asset row to generate some.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              if (asset.tags.isNotEmpty)
                _field(
                  'Tags',
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: asset.tags
                        .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.accentSoft,
                      labelStyle: const TextStyle(color: AppColors.accent),
                      visualDensity: VisualDensity.compact,
                    ))
                        .toList(),
                  ),
                ),
              if (asset.description != null) _field('Description', Text(asset.description!, style: const TextStyle(fontSize: 13))),
              if (asset.usageSuggestion != null)
                _field('Usage suggestion', Text(asset.usageSuggestion!, style: const TextStyle(fontSize: 13))),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: asset.url));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied')));
            }
          },
          child: const Text('Copy URL'),
        ),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}