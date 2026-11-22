import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Data passed from the checklist domain to the home-screen widget module.
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

/// Owns the Flutter-side communication and selection UI for the Android widget.
class ChecklistWidgetService {
  static const MethodChannel channel = MethodChannel('checklist_widget');

  Future<void> sync({
    required List<ChecklistWidgetBoardOption> boards,
    required String selectedBoardId,
    required int backgroundColor,
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
        'fontFamily': fontFamily,
        'selectedBoardId': selectedBoardId,
        // Send a native-owned snapshot. The Android picker must not depend on
        // the private SharedPreferences key format used by Flutter plugins.
        'boardsJson': jsonEncode(boards.map((board) => {
          'id': board.id,
          'title': board.title,
          'items': itemsFor(board),
        }).toList()),
      });
    } on PlatformException {
      // The app remains usable if the Android widget bridge is unavailable.
    } on MissingPluginException {
      // The app remains usable on platforms without the Android widget bridge.
    }
  }

  Future<String?> selectChecklist({
    required BuildContext context,
    required List<ChecklistWidgetBoardOption> boards,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        if (boards.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('ابتدا یک چک‌لیست بساز'),
            ),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'انتخاب چک‌لیست برای ویجت',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...boards.map(
                (board) => ListTile(
                  leading: const Icon(Icons.checklist_rounded),
                  title: Text(board.title),
                  subtitle: Text('${board.itemCount} مورد'),
                  onTap: () => Navigator.pop(sheetContext, board.id),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget-specific appearance and selection controls shown in app settings.
class ChecklistWidgetSettings extends StatelessWidget {
  final String selectedChecklistTitle;
  final int backgroundColor;
  final String fontFamily;
  final VoidCallback onSelectChecklist;
  final VoidCallback onChangeBackground;
  final ValueChanged<String> onFontChanged;

  const ChecklistWidgetSettings({
    super.key,
    required this.selectedChecklistTitle,
    required this.backgroundColor,
    required this.fontFamily,
    required this.onSelectChecklist,
    required this.onChangeBackground,
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
          leading: const Icon(Icons.checklist_rounded),
          title: const Text('انتخاب چک‌لیست ویجت'),
          subtitle: Text(
            selectedChecklistTitle.isEmpty
                ? 'هنوز انتخاب نشده'
                : selectedChecklistTitle,
          ),
          onTap: onSelectChecklist,
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.palette_outlined, color: Color(backgroundColor)),
          title: const Text('رنگ پس‌زمینه ویجت'),
          subtitle: const Text('تغییر رنگ پس‌زمینه صفحه اصلی'),
          onTap: onChangeBackground,
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
