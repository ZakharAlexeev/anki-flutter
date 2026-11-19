import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small building blocks that make screens read as native iOS: inset grouped
/// lists (like Settings), Cupertino dialogs and action sheets.

/// Distance from the screen edge to text inside a grouped row: the
/// section's own inset plus the row's padding. Captions above and below a
/// section use it too, so everything shares one left edge.
const double kRowTextInset = AppSpacing.md * 2;

/// The grey caption above a grouped section ("КОЛОДЫ").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lines up with the text inside the rows below: section inset + row padding.
      padding: const EdgeInsets.fromLTRB(kRowTextInset, AppSpacing.lg, kRowTextInset, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(fontSize: 12.5, letterSpacing: 0.3, color: context.appColors.muted),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Grey footnote under a grouped section.
class SectionFooter extends StatelessWidget {
  const SectionFooter(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kRowTextInset, 6, kRowTextInset, 0),
      child: Text(text, style: TextStyle(fontSize: 12.5, height: 1.35, color: context.appColors.muted)),
    );
  }
}

/// A rounded white block of rows separated by inset hairlines.
class GroupedSection extends StatelessWidget {
  const GroupedSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: Container(height: 0.5, color: colors.border),
        ));
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(color: colors.surface, child: Column(children: rows)),
      ),
    );
  }
}

/// One row of a [GroupedSection]: optional coloured icon tile, title, value
/// and a chevron when it navigates somewhere.
class GroupedRow extends StatelessWidget {
  const GroupedRow({
    super.key,
    required this.title,
    this.icon,
    this.iconColor = AppColors.accent,
    this.trailing,
    this.chevron = true,
    this.destructive = false,
    this.muted = false,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;
  final bool chevron;
  final bool destructive;
  final bool muted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleColor = destructive ? AppColors.again : (muted ? colors.muted : colors.text);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(7)),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, color: titleColor, letterSpacing: -0.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpacing.sm), trailing!],
              if (chevron) ...[
                const SizedBox(width: 6),
                Icon(CupertinoIcons.chevron_right, size: 15, color: colors.muted.withValues(alpha: 0.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- form rows (iOS Settings / Contacts style) ------------------------------

/// A borderless text field for use inside a [GroupedSection]: the field
/// is the row, as in Notes or Contacts. Multi-line by default.
class GroupedTextArea extends StatelessWidget {
  const GroupedTextArea({
    super.key,
    required this.controller,
    this.placeholder,
    this.focusNode,
    this.autofocus = false,
    this.multiline = true,
    this.serif = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? placeholder;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool multiline;

  /// Card content reads like the card itself (Georgia), as on the study screen.
  final bool serif;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        minLines: 1,
        maxLines: multiline ? null : 1,
        keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(fontSize: serif ? 19 : 16, fontFamily: serif ? 'Georgia' : null, color: colors.text),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(fontSize: 16, fontFamily: null, color: colors.muted.withValues(alpha: 0.7)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }
}

/// "Label ............ value" with the value editable in place, right
/// aligned - the iOS Settings pattern for numbers and short text.
class GroupedValueField extends StatelessWidget {
  const GroupedValueField({
    super.key,
    required this.label,
    required this.controller,
    this.suffix,
    this.numeric = true,
    this.placeholder,
    this.fieldWidth = 96,
  });

  final String label;
  final TextEditingController controller;
  final String? suffix;
  final bool numeric;
  final String? placeholder;
  final double fieldWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: colors.text, letterSpacing: -0.2))),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: fieldWidth,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.end,
                keyboardType: numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                style: TextStyle(fontSize: 16, color: context.accentForeground),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: TextStyle(color: colors.muted.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 4),
              Text(suffix!, style: TextStyle(fontSize: 16, color: colors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Label .... value >" that opens a choice (an action sheet).
class GroupedPickerRow extends StatelessWidget {
  const GroupedPickerRow({super.key, required this.label, required this.value, required this.onTap, this.icon, this.iconColor});

  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GroupedRow(
      title: label,
      icon: icon,
      iconColor: iconColor ?? AppColors.accent,
      onTap: onTap,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 16, color: context.appColors.muted),
        ),
      ),
    );
  }
}

/// "Label ............ (switch)".
class GroupedSwitchRow extends StatelessWidget {
  const GroupedSwitchRow({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GroupedRow(
      title: label,
      chevron: false,
      trailing: CupertinoSwitch(value: value, activeTrackColor: AppColors.accent, onChanged: onChanged),
    );
  }
}

/// A text button for the navigation bar ("Добавить", "Готово"), bold like
/// iOS's primary bar action.
class NavBarAction extends StatelessWidget {
  const NavBarAction({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.md), child: CupertinoActivityIndicator());
    }
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: onPressed == null ? context.appColors.muted : context.accentForeground,
        ),
      ),
    );
  }
}

/// iOS-style alert with a single text field; returns the trimmed text, or
/// null when cancelled.
Future<String?> showNamePrompt(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initial = '',
  String placeholder = '',
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showCupertinoDialog<String>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: controller,
          autofocus: true,
          placeholder: placeholder,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
      ),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// iOS-style confirmation for a destructive action.
Future<bool> showDestructiveConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class SheetAction<T> {
  const SheetAction(this.value, this.label, {this.destructive = false});
  final T value;
  final String label;
  final bool destructive;
}

/// iOS action sheet sliding up from the bottom; returns the chosen value.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  required List<SheetAction<T>> actions,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      actions: [
        for (final a in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: a.destructive,
            onPressed: () => Navigator.pop(context, a.value),
            child: Text(a.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
    ),
  );
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
