import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/database/models/invoice.dart';
import 'package:invoice_generator/database/models/company.dart';
import 'package:invoice_generator/database/models/customer.dart';
import 'package:invoice_generator/database/models/template.dart';
import 'package:invoice_generator/core/pdf_engine/pdf_builder.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  test('Generate Previews', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);

    final invoice = Invoice()
      ..invoiceNumber = 'INV-2023-001'
      ..date = DateTime.now()
      ..documentType = 'Invoice'
      ..currency = 'Rp'
      ..notes = 'Terima kasih atas kepercayaannya.'
      ..paymentTerms = 'Transfer Bank BCA 123456789 a/n PT ABC'
      ..signatorName = 'Budi Santoso'
      ..hideSubtotal = false
      ..hideTax = false
      ..taxRate = 11.0
      ..pphRate = 2.0;

    final c = Company()
      ..name = 'PT Teknologi Maju'
      ..address = 'Jl. Jendral Sudirman No. 1, Jakarta\nTelp: 021-123456'
      ..email = 'info@teknologimaju.com'
      ..website = 'www.teknologimaju.com';

    final cust = Customer()
      ..name = 'PT Pelanggan Setia'
      ..address = 'Jl. Gatot Subroto No. 2, Bandung';

    invoice.company.value = c;
    invoice.customer.value = cust;

    final items = [
      InvoiceItem()
        ..itemName = 'Website Development'
        ..specification = 'Company Profile 5 pages'
        ..qty = 1
        ..unit = 'Paket'
        ..sellingPrice = 5000000,
      InvoiceItem()
        ..itemName = 'Domain & Hosting'
        ..specification = '1 Year (.com + 2GB)'
        ..qty = 1
        ..unit = 'Tahun'
        ..sellingPrice = 750000,
      InvoiceItem()
        ..itemName = 'Maintenance'
        ..specification = 'Bulanan'
        ..qty = 3
        ..unit = 'Bulan'
        ..sellingPrice = 500000,
    ];

    invoice.items.addAll(items);

    // Calculate totals
    double sub = 0;
    for (final item in items) {
      sub += (item.qty ?? 0) * (item.sellingPrice ?? 0);
    }
    invoice.subtotal = sub;
    invoice.taxTotal = sub * (invoice.taxRate ?? 0) / 100;
    invoice.grandTotal =
        sub + (invoice.taxTotal ?? 0) - (sub * (invoice.pphRate ?? 0) / 100);

    const templates = ['Classic', 'Modern', 'Corporate', 'Clean Elegant'];
    const version = 'v38';
    final dir = Directory('C:/Users/asep.suherman/Downloads/Surat Penawaran');

    for (int i = 0; i < templates.length; i++) {
      final t = Template()..name = templates[i];
      invoice.template.value = t;
      try {
        final pdfBytes =
            await PdfBuilder.build(invoice: invoice, templateIndex: i + 1);
        final file = File(
            '${dir.path}/${t.name!.replaceAll(' ', '_')}_$version.pdf');
        await file.writeAsBytes(pdfBytes);
      } catch (e) {
        // ignore: avoid_print
        debugPrint('Error generating ${t.name}: $e');
      }
    }
  });
}
