import 'package:isar/isar.dart';

part 'settings.g.dart';

@collection
class Settings {
  Id id = Isar.autoIncrement;

  bool isDarkMode = false;
  String language = 'id'; // 'id' for Indonesia, 'en' for English

  String? defaultCurrency = 'IDR';
  String? defaultDateFormat = 'dd/MM/yyyy';

  bool autoGenerateInvoiceNumber = true;
  String invoiceNumberPrefix = 'INV';
  int nextInvoiceNumber = 1;

  // Extended fields
  int? defaultCompanyId;
  String? invoicePrefix = 'INV';
  String? quotationPrefix = 'QUOT';
  String? proformaPrefix = 'PROF';

  double? defaultTaxRate = 11;
  double? defaultPphRate = 0;
  bool showTaxInPdf = true;

  String? defaultNotes;
  String? defaultFooter = 'Terima kasih atas kepercayaan Anda.';

  int? defaultTemplateIndex = 0; // 0,1,2,3 for built-in templates
}
