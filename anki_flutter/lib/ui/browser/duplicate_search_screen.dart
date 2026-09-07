import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/note_repository.dart';
import '../theme/app_theme.dart';

class DuplicateSearchScreen extends StatefulWidget {
  const DuplicateSearchScreen({super.key});

  @override
  State<DuplicateSearchScreen> createState() => _DuplicateSearchScreenState();
}

class _DuplicateSearchScreenState extends State<DuplicateSearchScreen> {
  List<DuplicateGroup>? _groups;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _groups = null);
    final groups = await context.read<NoteRepository>().findDuplicates();
    if (mounted) setState(() => _groups = groups);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final duplicateNotes = groups?.fold<int>(0, (sum, group) => sum + group.matches.length) ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск дубликатов'),
        actions: [
          IconButton(onPressed: groups == null ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Проверить снова'),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: groups == null
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? const _NoDuplicates()
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
                      children: [
                        Text('НАЙДЕНО', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: AppSpacing.sm),
                        Text('${groups.length} групп · $duplicateNotes заметок', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text(
                          'Сравнивается первое поле заметок одного типа. Регистр, HTML и лишние пробелы игнорируются.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.appColors.muted),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        for (final group in groups)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _DuplicateGroupCard(group: group, onChanged: _load),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _NoDuplicates extends StatelessWidget {
  const _NoDuplicates();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.done_all, size: 42, color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text('Дубликатов нет', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text('Первые поля заметок не повторяются.', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _DuplicateGroupCard extends StatelessWidget {
  const _DuplicateGroupCard({required this.group, required this.onChanged});

  final DuplicateGroup group;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.appColors.surface,
          borderRadius: BorderRadius.circular(kAppRadius),
          border: Border.all(color: context.appColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Text(
                group.matches.first.firstField,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Divider(height: 1, color: context.appColors.border),
            for (var i = 0; i < group.matches.length; i++)
              _DuplicateNoteRow(match: group.matches[i], index: i, onChanged: onChanged),
          ],
        ),
      );
}

class _DuplicateNoteRow extends StatelessWidget {
  const _DuplicateNoteRow({required this.match, required this.index, required this.onChanged});

  final DuplicateNoteMatch match;
  final int index;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(index == 0 ? 'Исходная заметка' : 'Возможный дубликат'),
        subtitle: Text(match.deckNames.join(', ')),
        trailing: index == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Удалить заметку',
                onPressed: () => _delete(context),
              ),
      );

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить дубликат?'),
        content: const Text('Будут удалены заметка, все её карточки и история повторений.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NoteRepository>().deleteNote(match.note.id);
      onChanged();
    }
  }
}
