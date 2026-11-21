import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/media/pronunciation_service.dart';
import '../common/ios.dart';
import '../theme/app_theme.dart';

/// Voices a whole deck: adds pronunciations where there are none, or
/// re-voices the app's earlier recordings in the current accent. Runs while
/// the screen is open; leaving it stops after the current word.
class VoiceDeckScreen extends StatefulWidget {
  const VoiceDeckScreen({super.key, required this.deckId, required this.deckName});

  final int deckId;
  final String deckName;

  @override
  State<VoiceDeckScreen> createState() => _VoiceDeckScreenState();
}

class _VoiceDeckScreenState extends State<VoiceDeckScreen> {
  bool _replace = false;
  bool _running = false;
  bool _cancel = false;
  VoiceDeckProgress? _progress;
  Accent _accent = Accent.british;

  @override
  void initState() {
    super.initState();
    PronunciationService.accent().then((a) {
      if (mounted) setState(() => _accent = a);
    });
  }

  @override
  void dispose() {
    _cancel = true; // stop after the word in progress
    super.dispose();
  }

  String get _accentName => _accent == Accent.british ? 'британском' : 'американском';

  Future<void> _start() async {
    setState(() {
      _running = true;
      _cancel = false;
    });
    final service = context.read<PronunciationService>();
    final result = await service.voiceDeck(
      widget.deckId,
      replace: _replace,
      cancelled: () => _cancel,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _progress = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    final colors = context.appColors;
    final finished = !_running && p != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Озвучка колоды')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          SectionHeader(widget.deckName),
          GroupedSection(children: [
            _ModeRow(
              title: 'Добавить звук, где его нет',
              selected: !_replace,
              onTap: _running ? null : () => setState(() => _replace = false),
            ),
            _ModeRow(
              title: 'Переозвучить в $_accentName акценте',
              selected: _replace,
              onTap: _running ? null : () => setState(() => _replace = true),
            ),
          ]),
          SectionFooter(
            _replace
                ? 'Звук, добавленный приложением, заменится записью в $_accentName акценте. '
                    'Если такой записи нет, прежний звук останется. Звук из импортированных колод не меняется.'
                : 'Ищет произношение для карточек без звука: сначала в $_accentName акценте, '
                    'потом в другом. Около секунды на слово, нужен интернет.',
          ),
          const SectionHeader('Ход'),
          GroupedSection(children: [
            if (_running)
              GroupedRow(
                title: 'Остановить',
                icon: CupertinoIcons.stop_fill,
                iconColor: AppColors.again,
                chevron: false,
                onTap: _cancel ? null : () => setState(() => _cancel = true),
              )
            else
              GroupedRow(
                title: finished ? 'Запустить ещё раз' : 'Начать',
                icon: CupertinoIcons.speaker_2_fill,
                iconColor: AppColors.accent,
                chevron: false,
                onTap: _start,
              ),
            if (p != null)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _running
                                ? (_cancel ? 'Останавливаю…' : 'Озвучиваю…')
                                : (p.done < p.total ? 'Остановлено' : 'Готово'),
                            style: TextStyle(fontSize: 16, color: colors.text),
                          ),
                        ),
                        Text('${p.done} из ${p.total}', style: TextStyle(fontSize: 14, color: colors.muted)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        minHeight: 5,
                        value: p.total == 0 ? 1 : p.done / p.total,
                        backgroundColor: colors.surfaceAlt,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
          ]),
          if (p != null && p.done > 0) ...[
            const SectionHeader('Итог'),
            GroupedSection(children: [
              _CountRow('Добавлено', p.added, AppColors.good),
              if (_replace || p.replaced > 0) _CountRow('Переозвучено', p.replaced, AppColors.good),
              if (p.otherAccent > 0)
                _CountRow(
                  'Из них ${_accent == Accent.british ? 'британской' : 'американской'} записи не нашлось',
                  p.otherAccent,
                  AppColors.hard,
                ),
              _CountRow('Пропущено (уже есть звук или не английское)', p.skipped, colors.muted),
              _CountRow('Нет записи в словарях', p.notFound, colors.muted),
              if (p.networkErrors > 0) _CountRow('Ошибка сети', p.networkErrors, AppColors.again),
            ]),
            if (p.networkErrors > 0 && !_running)
              const SectionFooter('Карточки с ошибкой сети можно доозвучить, запустив ещё раз.'),
          ],
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.title, required this.selected, required this.onTap});

  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GroupedRow(
        title: title,
        chevron: false,
        onTap: onTap,
        trailing: selected ? Icon(CupertinoIcons.checkmark_alt, size: 20, color: context.accentForeground) : null,
      );
}

class _CountRow extends StatelessWidget {
  const _CountRow(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => GroupedRow(
        title: label,
        chevron: false,
        trailing: Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
      );
}
