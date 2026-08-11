import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/db/database.dart';
import '../../data/repositories/notetype_repository.dart';

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
          return ListView.separated(
            itemCount: notetypes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final nt = notetypes[i];
              return ListTile(
                title: Text(nt.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, nt),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNotetype(context),
        child: const Icon(Icons.add),
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
            const SizedBox(height: 12),
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
