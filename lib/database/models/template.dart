import 'package:isar/isar.dart';

part 'template.g.dart';

@collection
class Template {
  Id id = Isar.autoIncrement;

  String? name;
  String? description;
  bool isDefault = false;
  bool isCustom = false;  // Added field
  
  // Storing template structure as JSON string for flexibility
  String? jsonStructure;

  bool isBuiltIn = false; // Indicates if this is one of the 4 default templates
}
