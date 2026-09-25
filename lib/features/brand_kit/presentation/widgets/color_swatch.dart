import 'package:flutter/material.dart';
import '../../../../utils/hex_color_parser.dart';
import '../../../../core/theme/app_theme.dart';

class BrandColorSwatch extends StatelessWidget {
  final String hex;
  final String label;
  final ValueChanged<String>? onChanged;

  const BrandColorSwatch({super.key, required this.hex, required this.label, this.onChanged});

  Future<void> _pickHex(BuildContext context) async {
    final controller = TextEditingController(text: hex);
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) =>AlertDialog(
            title: Text('Set $label'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: 'Hex color (#5B4FE8)', errorText: errorText),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: (){
                    if (!isValidHex(controller.text)){
                      setDialogState(()=> errorText = 'Use 6 or 8 hex digits,like #5B4FE6');
                      return;
                    }
                    Navigator.pop(dialogContext, normalizeHex(controller.text));
                  },
                child: const Text('Apply'),),
            ],
          )
      )
    );
    if (result != null && onChanged != null) onChanged!(result);
  }

  @override
  Widget build(BuildContext context) {
  Color color;
  try{
    color = hexToColor(hex);
  }catch(_){
    color = AppColors.line;
  }
  return GestureDetector(
    onTap: onChanged == null ? null :() => _pickHex(context),
    child: Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle,border: Border.all(color: Colors.black12)),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        Text(hex, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      ],
    ),
  );
  }
}