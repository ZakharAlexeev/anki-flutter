import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../theme/app_theme.dart';

/// Renders the (usually simple) HTML produced by [renderCard] - Anki card
/// templates are plain HTML/CSS, so this is what "shows" a question/answer.
///
/// flutter_html's defaults are tuned for document-style content (large
/// margins on `<p>`/`<div>`/`<hr>`), which reads as broken whitespace inside
/// a compact card - the overrides below flatten it back down to plain
/// inline text, matching how these templates actually look in Anki itself.
class HtmlView extends StatelessWidget {
  const HtmlView({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final body = html.trim().isEmpty ? '<i>(пусто)</i>' : html;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = context.appColors.border;

    return Html(
      data: body,
      style: {
        'body': Style(
          fontSize: FontSize(19),
          fontWeight: FontWeight.w400,
          lineHeight: const LineHeight(1.5),
          color: textColor,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          textAlign: TextAlign.center,
        ),
        'p': Style(margin: Margins.symmetric(vertical: AppSpacing.sm)),
        'div': Style(margin: Margins.zero, padding: HtmlPaddings.zero),
        'hr': Style(
          margin: Margins.symmetric(vertical: AppSpacing.lg),
          border: Border(top: BorderSide(color: borderColor)),
          height: Height(1),
        ),
      },
    );
  }
}
