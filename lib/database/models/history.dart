import 'package:isar/isar.dart';

part 'history.g.dart';

@collection
class History {
  Id id = Isar.autoIncrement;

  DateTime? timestamp;
  
  // Action type: "Export PDF", "Print", "Share"
  String? action; 
  
  String? invoiceNumber;
  String? customerName;
  String? details;
}
