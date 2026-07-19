import 'package:isar/isar.dart';
import 'company.dart';
import 'customer.dart';
import 'template.dart';

part 'invoice.g.dart';

@collection
class Invoice {
  Id id = Isar.autoIncrement;

  String? invoiceNumber;
  DateTime? date;
  
  final company = IsarLink<Company>();
  final customer = IsarLink<Customer>();
  final template = IsarLink<Template>();

  String? attn;
  String? address;
  String? phone;
  String? fax;

  // Enum as String: "Penawaran Harga", "Invoice", "Quotation", "Proforma Invoice"
  String? documentType; 
  String? currency;

  double? taxRate; // PPN e.g. 0, 11, 12
  double? pphRate; // PPH Optional

  String? notes;
  String? footer;
  String? signaturePath;

  // Status Enum as String: "Draft", "Sent", "Paid"
  String? status; 

  String? introText;
  bool hideSubtotal = false;
  bool hideTax = false;
  String? paymentTerms;
  String? signatorName;
  
  double? subtotal;
  double? discountTotal;
  double? taxTotal;
  double? grandTotal;
  String? terbilang;

  // Embedded list for items
  List<InvoiceItem> items = [];
}

@embedded
class InvoiceItem {
  String? itemName;
  String? specification;
  String? itemCode;
  
  double? qty;
  String? unit;
  
  double? costPrice;
  double? markupPercentage;
  double? sellingPrice;
  double? discount;
  
  double? subtotal;
}
