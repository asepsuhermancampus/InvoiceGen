import 'package:isar/isar.dart';
import '../../database/models/template.dart';

class TemplateRepository {
  Isar get _isar => Isar.getInstance()!;

  Future<void> saveTemplate(Template template) async {
    await _isar.writeTxn(() async {
      await _isar.templates.put(template);
    });
  }

  Future<List<Template>> getAllTemplates() async {
    return await _isar.templates.where().findAll();
  }

  Future<void> deleteTemplate(int id) async {
    await _isar.writeTxn(() async {
      await _isar.templates.delete(id);
    });
  }
}
