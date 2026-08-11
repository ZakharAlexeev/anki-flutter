import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// Renders the (usually simple) HTML produced by [renderCard] - Anki card
/// templates are plain HTML/CSS, so this is what "shows" a question/answer.
class HtmlView extends StatelessWidget {
  const HtmlView({super.key, required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final body = html.trim().isEmpty ? '<i>(пусто)</i>' : html;
    return Html(
      data: body,
      style: {
        'body': Style(
          fontSize: FontSize(20),
          margin: Margins.zero,
          textAlign: TextAlign.center,
        ),
      },
    );
  }
}
