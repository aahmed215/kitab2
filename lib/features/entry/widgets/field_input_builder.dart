// ═══════════════════════════════════════════════════════════════════
// FIELD_INPUT_BUILDER.DART — All 13 Field Type Renderers
// Builds the correct input widget for each activity field type.
// See SPEC.md §5.4 for field type specification.
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/kitab_theme.dart';
import '../../../core/widgets/map_location_picker.dart';

/// Builds a form input widget for a given field type.
class FieldInputBuilder {
  const FieldInputBuilder._();

  static Widget build({
    required BuildContext context,
    required String fieldId,
    required String label,
    required String type,
    String? unit,
    Map<String, dynamic>? config,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    final decoration = InputDecoration(
      labelText: label,
      suffixText: unit,
    );

    switch (type) {
      // ─── 1. Number ───
      case 'number':
      case 'integer':
        return TextField(
          controller: controller,
          decoration: decoration,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        );

      // ─── 2. Decimal ───
      case 'decimal':
      case 'float':
        return TextField(
          controller: controller,
          decoration: decoration,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
        );

      // ─── 3. Text ───
      case 'text':
      case 'string':
        return TextField(
          controller: controller,
          decoration: decoration,
          onChanged: onChanged,
        );

      // ─── 4. Long Text ───
      case 'long_text':
      case 'textarea':
        return TextField(
          controller: controller,
          decoration: decoration.copyWith(alignLabelWithHint: true),
          maxLines: 4,
          onChanged: onChanged,
        );

      // ─── 5. Boolean / Yes-No ───
      case 'boolean':
      case 'yes_no':
        return SwitchListTile(
          title: Text(label),
          value: controller.text == 'true',
          onChanged: (v) {
            controller.text = v.toString();
            onChanged(v.toString());
          },
          contentPadding: EdgeInsets.zero,
        );

      // ─── 6. Rating (1-5 stars) ───
      case 'rating':
        final rating = int.tryParse(controller.text) ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: KitabTypography.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: KitabColors.accent,
                    size: 28,
                  ),
                  onPressed: () {
                    controller.text = (i + 1).toString();
                    onChanged((i + 1).toString());
                  },
                );
              }),
            ),
          ],
        );

      // ─── 7. Duration ───
      case 'duration':
        return TextField(
          controller: controller,
          decoration: decoration.copyWith(
            hintText: 'Minutes',
            suffixText: unit ?? 'min',
          ),
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        );

      // ─── 8. Time ───
      case 'time':
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(
            controller.text.isEmpty ? 'Tap to select' : controller.text,
          ),
          trailing: const Icon(Icons.access_time, color: KitabColors.gray400),
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              final formatted =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              controller.text = formatted;
              onChanged(formatted);
            }
          },
        );

      // ─── 9. Date ───
      case 'date':
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          subtitle: Text(
            controller.text.isEmpty ? 'Tap to select' : controller.text,
          ),
          trailing: const Icon(Icons.calendar_today, color: KitabColors.gray400),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              final formatted = DateFormat('yyyy-MM-dd').format(date);
              controller.text = formatted;
              onChanged(formatted);
            }
          },
        );

      // ─── 10. Enum / Single Select ───
      case 'enum':
      case 'select':
        final options = (config?['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        return DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(labelText: label),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            controller.text = v ?? '';
            onChanged(v ?? '');
          },
        );

      // ─── 11. Multi-Select ───
      case 'multi_select':
        final options = (config?['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final selected = controller.text.isEmpty
            ? <String>{}
            : controller.text.split(',').toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: KitabTypography.bodySmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: options.map((option) {
                final isSelected = selected.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (sel) {
                    if (sel) {
                      selected.add(option);
                    } else {
                      selected.remove(option);
                    }
                    final val = selected.join(',');
                    controller.text = val;
                    onChanged(val);
                  },
                );
              }).toList(),
            ),
          ],
        );

      // ─── 12. Slider ───
      case 'slider':
      case 'range':
        final min = (config?['min'] as num?)?.toDouble() ?? 0;
        final max = (config?['max'] as num?)?.toDouble() ?? 100;
        final step = (config?['step'] as num?)?.toDouble() ?? 1;
        final value =
            (double.tryParse(controller.text) ?? min).clamp(min, max);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: KitabTypography.bodySmall),
                Text(value.toStringAsFixed(step < 1 ? 1 : 0),
                    style: KitabTypography.mono),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              onChanged: (v) {
                controller.text = v.toString();
                onChanged(v.toString());
              },
            ),
          ],
        );

      // ─── 13. Photo ───
      case 'photo':
      case 'image':
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: controller.text.isNotEmpty
              ? const Icon(Icons.check_circle, color: KitabColors.success)
              : const Icon(Icons.add_a_photo, color: KitabColors.gray400),
          title: Text(label),
          subtitle: Text(
            controller.text.isEmpty ? 'Tap to add photo' : 'Photo attached',
          ),
          onTap: () {
            // TODO: Use image_picker to select photo
            controller.text = 'photo_placeholder';
            onChanged('photo_placeholder');
          },
        );

      // ─── 14. Location ───
      case 'location':
        // Controller stores "lat,lng|displayName"
        final parts = controller.text.split('|');
        final hasLoc = parts.length == 2 && parts[0].contains(',');
        double? lat, lng;
        String? displayName;
        if (hasLoc) {
          final coords = parts[0].split(',');
          lat = double.tryParse(coords[0]);
          lng = double.tryParse(coords[1]);
          displayName = parts[1];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: KitabTypography.bodySmall),
            const SizedBox(height: 4),
            if (hasLoc && lat != null && lng != null) ...[
              MapPreview(
                latitude: lat,
                longitude: lng,
                displayName: displayName,
                height: 120,
                onTap: () async {
                  final picked = await showMapLocationPicker(
                    context: context, initialLat: lat, initialLng: lng,
                  );
                  if (picked != null) {
                    final encoded = '${picked.latitude},${picked.longitude}|${picked.displayName}';
                    controller.text = encoded;
                    onChanged(encoded);
                  }
                },
              ),
            ] else
              OutlinedButton.icon(
                icon: const Icon(Icons.add_location, size: 18),
                label: const Text('Set Location'),
                onPressed: () async {
                  final picked = await showMapLocationPicker(context: context);
                  if (picked != null) {
                    final encoded = '${picked.latitude},${picked.longitude}|${picked.displayName}';
                    controller.text = encoded;
                    onChanged(encoded);
                  }
                },
              ),
          ],
        );

      // ─── Fallback ───
      default:
        return TextField(
          controller: controller,
          decoration: decoration,
          onChanged: onChanged,
        );
    }
  }
}
