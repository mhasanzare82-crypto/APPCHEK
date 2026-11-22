import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data passed from the checklist domain to the Android home-screen widget.
class ChecklistWidgetBoardOption {
  final String id;
  final String title;
  final int itemCount;

  const ChecklistWidgetBoardOption({
    required this.id,
    required this.title,
    required this.itemCount,
  });
}

/// Synchronizes checklist snapshots and appearance settings with Android.
class ChecklistWidgetService {
  static const MethodChannel channel = MethodChannel('checklist_widget');

  Future<void> sync({
    required List<ChecklistWidgetBoardOption> boards,
    required String selectedBoardId,
    required int backgroundColor,
    required int textColor,
    required String fontFamily,
    required List<String> Function(ChecklistWidgetBoardOption board) itemsFor,
  }) async {
    ChecklistWidgetBoardOption? selected;
    for (final board in boards) {
      if (board.id == selectedBoardId) {
        selected = board;
        break;
      }
    }

    try {
      await channel.invokeMethod<void>('updateWidget', {
        'title': selected?.title ?? 'چک‌لیستی انتخاب نشده',
        'items': selected == null ? <String>[] : itemsFor(selected),
        'backgroundColor': backgroundColor,
        'textColor': textColor,
        'fontFamily': fontFamily,
        'selectedBoardId': selectedBoardId,
        'boardsJson': jsonEncode(boards.map((board) => {
          'id': board.id,
          'title': board.title,
          'items': itemsFor(board),
        }).toList()),
      });
    } on PlatformException {
      // Keep the checklist app usable if the native widget bridge is unavailable.
    } on MissingPluginException {
      // Keep the checklist app usable on platforms without the Android widget.
    }
  }
}

/// Appearance-only settings for the home-screen widget.
/// Checklist selection is intentionally available only by tapping the widget.
class ChecklistWidgetSettings extends StatelessWidget {
  final int backgroundColor;
  final int textColor;
  final String fontFamily;
  final VoidCallback onChangeBackground;
  final VoidCallback onChangeTextColor;
  final ValueChanged<String> onFontChanged;

  const ChecklistWidgetSettings({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.fontFamily,
    required this.onChangeBackground,
    required this.onChangeTextColor,
    required this.onFontChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'تنظیمات ویجت',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.palette_outlined, color: Color(backgroundColor)),
          title: const Text('رنگ پس‌زمینه ویجت'),
          subtitle: const Text('تغییر رنگ پس‌زمینه صفحه اصلی'),
          onTap: onChangeBackground,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.format_color_text, color: Color(textColor)),
          title: const Text('رنگ متن ویجت'),
          subtitle: const Text('تغییر رنگ نوشته‌های ویجت'),
          onTap: onChangeTextColor,
        ),
        DropdownButtonFormField<String>(
          initialValue: fontFamily,
          decoration: const InputDecoration(labelText: 'نوع فونت ویجت'),
          items: const [
            DropdownMenuItem(value: 'sans', child: Text('ساده')),
            DropdownMenuItem(value: 'serif', child: Text('سریف')),
            DropdownMenuItem(value: 'mono', child: Text('تک‌فاصله‌ای')),
          ],
          onChanged: (value) {
            if (value != null) onFontChanged(value);
          },
        ),
      ],
    );
  }
}
