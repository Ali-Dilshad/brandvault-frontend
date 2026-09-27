import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';
import '../../data/services/asset_service.dart';
import 'asset_type_chip.dart';


class AssetDetailPanel extends StatefulWidget {
  final AssetModel asset;
  final String? folderName;
  final AssetService service;
  final ValueChanged<AssetModel> onUpdated;

  const AssetDetailPanel({
    super.key,
    required this.asset,
    required this.service,
    required this.onUpdated,
    this.folderName,
  });

  @override
  State<AssetDetailPanel> createState() => _AssetDetailPanelState();
}

class _AssetDetailPanelState extends State<AssetDetailPanel> {
  AiSuggestion? _draft;
  bool _generating = false;
  bool _saving = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
      _draft = null;
    });
    try {
      final suggestion = await widget.service.generateAiTags(widget.asset.id);
      if (!mounted) return;
      setState(() {
        _draft = suggestion;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is FormatException
            ? 'The AI did not return a valid suggestion. Try again.'
            : errorMessage(e, fallback: 'The AI did not return a valid suggestion. Try again.');
        _generating = false;
      });
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.service.saveAiTags(widget.asset.id, draft);
      if (!mounted) return;
      setState(() {
        _draft = null;
        _saving = false;
      });
      widget.onUpdated(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e, fallback: 'Could not save the suggestion.');
        _saving = false;
      });
    }
  }

  void _discard() => setState(() {
    _draft = null;
    _error = null;
  });

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.asset.url));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL copied')));
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.asset;
    final updated = asset.updatedAt.toLocal().toString().substring(0, 16);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AssetTypeChip(type: asset.type),
              const SizedBox(width: 10),
              Expanded(
                child: Text(asset.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${asset.type.name} · ${widget.folderName ?? 'No folder'} · updated $updated',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _copyUrl,
            child: Row(
              children: [
                Expanded(
                  child: Text(asset.url, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_outlined, size: 14, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (asset.hasAiMetadata) ...[
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
            if (asset.description != null) ...[
              const SizedBox(height: 10),
              Text(asset.description!, style: const TextStyle(fontSize: 13)),
            ],
            if (asset.usageSuggestion != null) ...[
              const SizedBox(height: 4),
              Text(asset.usageSuggestion!, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            ],
            const SizedBox(height: 14),
          ],
          if (_generating)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.accent),
                label: Text(asset.hasAiMetadata ? 'Regenerate tags' : 'Generate tags'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  backgroundColor: AppColors.accentSoft,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.rust, fontSize: 12)),
          ],
          if (_draft != null) ...[
            const SizedBox(height: 14),
            CustomPaint(
              painter: _DashedRoundedBorder(color: AppColors.accent, radius: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.paperRaised, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Review before saving', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _draft!.tags
                          .map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.accentSoft,
                        labelStyle: const TextStyle(color: AppColors.accent),
                        visualDensity: VisualDensity.compact,
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(_draft!.description, style: const TextStyle(fontSize: 12.5)),
                    const SizedBox(height: 4),
                    Text(_draft!.usageSuggestion, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(onPressed: _saving ? null : _discard, child: const Text('Discard')),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save to asset'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _DashedRoundedBorder extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  _DashedRoundedBorder({
    required this.color,
    this.radius = 8,
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius || oldDelegate.strokeWidth != strokeWidth;
}