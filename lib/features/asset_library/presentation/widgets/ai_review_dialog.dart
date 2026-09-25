import 'package:flutter/material.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';
import '../../data/services/asset_service.dart';

class AiReviewDialog extends StatefulWidget {
  final AssetModel asset;
  final AssetService service;

  const AiReviewDialog({super.key, required this.asset, required this.service});

  @override
  State<AiReviewDialog> createState() => _AiReviewDialogState();
}

class _AiReviewDialogState extends State<AiReviewDialog> {
  AiSuggestion? _suggestion;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final suggestion = await widget.service.generateAiTags(widget.asset.id);
      if (!mounted) return;
      setState(() {
        _suggestion = suggestion;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is FormatException
            ? 'The AI did not return a valid suggestion. Try again.'
            : errorMessage(e, fallback: 'The AI did not return a valid suggestion. Try again.');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_suggestion == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.service.saveAiTags(widget.asset.id, _suggestion!);
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e, fallback: 'Could not save the suggestion.');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestion;

    return AlertDialog(
      title: Text('AI suggestion — ${widget.asset.name}'),
      content: SizedBox(
        width: 360,
        child: _loading
            ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestion != null) ...[
              const Text('Review before saving', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: suggestion.tags
                    .map((t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.accentSoft,
                  labelStyle: const TextStyle(color: AppColors.accent),
                  visualDensity: VisualDensity.compact,
                ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Text(suggestion.description, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text(suggestion.usageSuggestion, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            ],
            if (_error != null) ...[
              if (suggestion != null) const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.rust, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Discard')),
        if (!_loading && suggestion == null) ElevatedButton(onPressed: _generate, child: const Text('Try again')),
        if (suggestion != null)
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
      ],
    );
  }
}