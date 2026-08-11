import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/notetype_repository.dart';
import '../theme/app_theme.dart';

/// Anki's own "Manage Note Types": list, create and delete note types. Field
/// and template editing for an *existing* note type is intentionally left
/// out of this first version - note types are usually set up once at
/// creation time.
class NotetypeManagerScreen extends StatelessWidget {
  const NotetypeManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<NotetypeRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Типы карточек')),
      body: StreamBuilder<List<Notetype>>(
        stream: repo.watchNotetypes(),
        builder: (context, snapshot) {
          final notetypes = snapshot.data ?? const <Notetype>[];
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 100),
                itemCount: notetypes.length,
                itemBuilder: (context, i) {
                  final nt = notetypes[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kAppRadius),
                        border: Border.all(color: context.appColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(nt.name, style: Theme.of(context).textTheme.bodyLarge)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 19),
                            onPressed: () => _confirmDelete(context, nt),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNotetype(context),
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Notetype nt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить тип "${nt.name}"?'),
        content: const Text('Все заметки и карточки этого типа будут удалены безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NotetypeRepository>().deleteNotetype(nt.id);
    }
  }

  Future<void> _createNotetype(BuildContext context) async {
    final nameController = TextEditingController();
    final fieldsController = TextEditingController(text: 'Front, Back');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый тип карточки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Название')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: fieldsController, decoration: const InputDecoration(labelText: 'Поля (через запятую)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Создать')),
        ],
      ),
    );
    if (result != true || !context.mounted) return;

    final name = nameController.text.trim();
    final fields = fieldsController.text.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
    if (name.isEmpty || fields.isEmpty) return;

    final questionFormat = '{{${fields.first}}}';
    final restFields = fields.skip(1).map((f) => '{{$f}}').join('<br>');
    final answerFormat = '{{FrontSide}}<hr id="answer">$restFields';

    await context.read<NotetypeRepository>().createNotetype(
          name: name,
          fieldNames: fields,
          templates: [TemplateSpec(name: 'Card 1', questionFormat: questionFormat, answerFormat: answerFormat)],
        );
  }
}
