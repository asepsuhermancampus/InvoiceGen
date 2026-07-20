import 'package:isar/isar.dart';
import '../../database/models/invoice.dart';

class InvoiceRepository {
  Isar get _isar => Isar.getInstance()!;

  Future<void> saveInvoice(Invoice invoice) async {
    await _isar.writeTxn(() async {
      await _isar.invoices.put(invoice);
      await invoice.company.save();
      await invoice.customer.save();
      await invoice.template.save();
    });
  }

  Future<List<Invoice>> getAllInvoices() async {
    return await _isar.invoices.where().findAll();
  }

  Future<Invoice?> getInvoiceById(int id) async {
    return await _isar.invoices.get(id);
  }

  Future<void> deleteInvoice(int id) async {
    await _isar.writeTxn(() async {
      await _isar.invoices.delete(id);
    });
  }

  Future<Invoice?> duplicateInvoice(int id) async {
    final original = await _isar.invoices.get(id);
    if (original == null) return null;

    final duplicate = Invoice()
      ..invoiceNumber = '${original.invoiceNumber}-Clone'
      ..date = DateTime.now()
      ..documentType = original.documentType
      ..currency = original.currency
      ..taxRate = original.taxRate
      ..pphRate = original.pphRate
      ..notes = original.notes
      ..footer = original.footer
      ..status = 'Draft'
      ..items = original.items.map((item) {
        return InvoiceItem()
          ..itemName = item.itemName
          ..specification = item.specification
          ..itemCode = item.itemCode
          ..qty = item.qty
          ..unit = item.unit
          ..costPrice = item.costPrice
          ..markupPercentage = item.markupPercentage
          ..sellingPrice = item.sellingPrice
          ..discount = item.discount
          ..subtotal = item.subtotal;
      }).toList();

    await _isar.writeTxn(() async {
      await _isar.invoices.put(duplicate);
      duplicate.company.value = original.company.value;
      duplicate.customer.value = original.customer.value;
      duplicate.template.value = original.template.value;
      await duplicate.company.save();
      await duplicate.customer.save();
      await duplicate.template.save();
    });

    return duplicate;
  }
  Future<void> updateInvoiceStatus(int id, String newStatus) async {
    final original = await _isar.invoices.get(id);
    if (original == null) return;
    
    original.status = newStatus;
    
    await _isar.writeTxn(() async {
      await _isar.invoices.put(original);
      original.company.value = original.company.value;
      original.customer.value = original.customer.value;
      original.template.value = original.template.value;
      await original.company.save();
      await original.customer.save();
      await original.template.save();
    });
  }
}
