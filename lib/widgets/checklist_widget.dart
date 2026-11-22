import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Appearance settings for the Android home-screen checklist widget.
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
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withOpacity(.65);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard_customize_rounded,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طراحی ظاهری ویجت',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('رنگ‌ها و فونت نمایش چک‌لیست را تنظیم کن',
                        style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WidgetAppearanceTile(
            icon: Icons.format_color_fill_rounded,
            title: 'رنگ پس‌زمینه',
            subtitle: 'زمینه کارت ویجت در صفحه اصلی',
            color: Color(backgroundColor),
            onTap: onChangeBackground,
          ),
          const SizedBox(height: 9),
          _WidgetAppearanceTile(
            icon: Icons.format_color_text_rounded,
            title: 'رنگ نوشته‌ها',
            subtitle: 'عنوان، موارد چک‌لیست و راهنما',
            color: Color(textColor),
            onTap: onChangeTextColor,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.font_download_rounded,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('فونت ویجت',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: fontFamily,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: border),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'sans', child: Text('ساده  •  پیش‌فرض')),
              DropdownMenuItem(value: 'serif', child: Text('سریف')),
              DropdownMenuItem(value: 'mono', child: Text('تک‌فاصله‌ای')),
              DropdownMenuItem(value: 'condensed', child: Text('فشرده')),
              DropdownMenuItem(value: 'casual', child: Text('دست‌نویس')),
            ],
            onChanged: (value) {
              if (value != null) onFontChanged(value);
            },
          ),
          const SizedBox(height: 7),
          Text(
            'فونت انتخاب‌شده روی عنوان، متن و نوشته پایین ویجت اعمال می‌شود.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetAppearanceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WidgetAppearanceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withOpacity(.82),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(.55),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(.28),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_left_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
