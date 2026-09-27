import 'package:flutter/material.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/brand_model.dart';
import '../../data/services/brand_service.dart';
import '../widgets/color_swatch.dart';
import '../widgets/brand_preview.dart';

class BrandKitPage extends StatefulWidget {
  const BrandKitPage({super.key});

  @override
  State<BrandKitPage> createState() => _BrandKitPageState();
}

class _BrandKitPageState extends State<BrandKitPage> {
  final _service = BrandService();

  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  final _fontController = TextEditingController();
  String _primaryHex = '#5B4FE8';
  String _secondaryHex = '#1C1F22';
  String? _existingId;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _fontController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final brand = await _service.getBrand();
      if (!mounted) return;
      if (brand != null) {
        _existingId = brand.id;
        _nameController.text = brand.name;
        _primaryHex = brand.primaryColor;
        _secondaryHex = brand.secondaryColor;
        _logoController.text = brand.logoUrl ?? '';
        _fontController.text = brand.fontName ?? '';
      }
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = errorMessage(e, fallback: 'Could not load your brand kit.');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.saveBrand(BrandModel(
        id: _existingId,
        name: _nameController.text,
        primaryColor: _primaryHex,
        secondaryColor: _secondaryHex,
        logoUrl: _logoController.text,
        fontName: _fontController.text,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorMessage(e, fallback: 'Could not save brand kit.');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brand kit'), backgroundColor: AppColors.paperRaised, foregroundColor: AppColors.ink),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, style: const TextStyle(color: AppColors.rust)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      )
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_nameController, _logoController, _fontController]),
                  builder: (_, __) => BrandPreview(
                    name: _nameController.text,
                    primaryColor: _primaryHex,
                    secondaryColor: _secondaryHex,
                    logoUrl: _logoController.text,
                    fontName: _fontController.text.trim().isEmpty ? null : _fontController.text.trim(),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Brand name *')),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    BrandColorSwatch(hex: _primaryHex, label: 'Primary *', onChanged: (v) => setState(() => _primaryHex = v)),
                    BrandColorSwatch(hex: _secondaryHex, label: 'Secondary *', onChanged: (v) => setState(() => _secondaryHex = v)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _logoController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Logo URL (optional)', hintText: 'https://…'),
                ),
                const SizedBox(height: 12),
                TextField(controller: _fontController, decoration: const InputDecoration(labelText: 'Font name (optional)')),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.rust, fontSize: 12)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save brand kit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}