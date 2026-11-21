import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/deck_repository.dart';
import '../browser/card_browser_screen.dart';
import '../common/ios.dart';
import '../export/export_progress_dialog.dart';
import '../stats/stats_screen.dart';
import 'deck_settings_screen.dart';
import 'voice_deck_screen.dart';

Future<void> createDeckWithPrompt(BuildContext context) async {
  final name = await showNamePrompt(
    context,
    title: 'Новая колода',
    confirmLabel: 'Создать',
    placeholder: 'Например: Phrasal verbs',
  );
  if (name == null || name.isEmpty || !context.mounted) return;
  try {
    await context.read<DeckRepository>().createDeck(name);
  } catch (_) {
    if (context.mounted) showToast(context, 'Колода «$name» уже существует');
  }
}

enum _DeckAction { browse, stats, voice, settings, export, rename, delete }

/// The long-press menu of a deck row. Returns once the chosen action (if
/// any) has finished, so the caller can refresh its numbers.
Future<void> showDeckActions(BuildContext context, Deck deck) async {
  final action = await showActionSheet<_DeckAction>(
    context,
    title: deck.name,
    actions: const [
      SheetAction(_DeckAction.browse, 'Карточки колоды'),
      SheetAction(_DeckAction.stats, 'Статистика'),
      SheetAction(_DeckAction.voice, 'Озвучить колоду'),
      SheetAction(_DeckAction.settings, 'Настройки колоды'),
      SheetAction(_DeckAction.export, 'Экспорт .apkg'),
      SheetAction(_DeckAction.rename, 'Переименовать'),
      SheetAction(_DeckAction.delete, 'Удалить колоду', destructive: true),
    ],
  );
  if (action == null || !context.mounted) return;

  Future<void> push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  switch (action) {
    case _DeckAction.browse:
      await push(CardBrowserScreen(deckId: deck.id, deckName: deck.name));
    case _DeckAction.stats:
      await push(StatsScreen(deckId: deck.id, title: deck.name));
    case _DeckAction.voice:
      await push(VoiceDeckScreen(deckId: deck.id, deckName: deck.name));
    case _DeckAction.settings:
      await push(DeckSettingsScreen(deckId: deck.id, deckName: deck.name));
    case _DeckAction.export:
      await exportDecksToFile(context, deckIds: [deck.id], suggestedFileName: deck.name);
    case _DeckAction.rename:
      final name = await showNamePrompt(
        context,
        title: 'Переименовать колоду',
        confirmLabel: 'Сохранить',
        initial: deck.name,
      );
      if (name == null || name.isEmpty || name == deck.name || !context.mounted) return;
      try {
        await context.read<DeckRepository>().renameDeck(deck.id, name);
      } catch (_) {
        if (context.mounted) showToast(context, 'Колода «$name» уже существует');
      }
    case _DeckAction.delete:
      final ok = await showDestructiveConfirm(
        context,
        title: 'Удалить «${deck.name}»?',
        message: 'Все карточки этой колоды и их история будут удалены безвозвратно.',
        confirmLabel: 'Удалить',
      );
      if (ok && context.mounted) await context.read<DeckRepository>().deleteDeck(deck.id);
  }
}
