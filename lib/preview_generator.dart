// ignore_for_file: avoid_print
// ─── Preview Generator ───────────────────────────────────────────────────────
// Script ini digunakan untuk men-generate preview PDF dari semua template
// tanpa perlu menjalankan aplikasi Flutter secara penuh.
//
// Cara menjalankan (dari root project):
//   dart lib/preview_generator.dart
//
// Output akan disimpan di folder:
//   lib/preview_output/
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'database/models/company.dart';
import 'database/models/customer.dart';
import 'database/models/invoice.dart';
import 'core/pdf_engine/pdf_builder.dart';

void main() async {
  await initializeDateFormatting('id_ID', null);

  // ─── Data Contoh (Dummy) ──────────────────────────────────────────────────
  final company = Company()
    ..name = 'PT MAKMUR SENTOSA'
    ..slogan = 'Solusi IT Terbaik Anda'
    ..branchName = 'Cabang Utama'
    ..address = 'Jl. Jend. Sudirman No. 1, Jakarta'
    ..phone = '021-1234567';

  final customer = Customer()
    ..name = 'Bapak Budi'
    ..companyName = 'CV Jaya Abadi'
    ..address = 'Jl. Merdeka No. 45, Bandung'
    ..phone = '081234567890';

  final item1 = InvoiceItem()
    ..itemName = 'Pembuatan Sistem'
    ..qty = 1
    ..sellingPrice = 15000000;

  final item2 = InvoiceItem()
    ..itemName = 'Maintenance Server'
    ..qty = 3
    ..sellingPrice = 1500000;

  final invoice = Invoice()
    ..invoiceNumber = 'INV-2026-008'
    ..date = DateTime.now()
    ..documentType = 'INVOICE'
    ..introText =
        'Terima kasih atas kepercayaan Anda menggunakan layanan kami. '
        'Berikut adalah rincian tagihan:'
    ..terbilang = 'Sembilan Belas Juta Lima Ratus Ribu Rupiah'
    ..notes =
        'Pembayaran ditransfer ke rekening BCA 1234567890 a/n PT Makmur Sentosa'
    ..paymentTerms = 'Termin 1 (50%) - 14 Hari setelah invoice diterima'
    ..signatorName = 'Andi Susanto'
    ..subtotal = 19500000
    ..discountTotal = 0
    ..taxRate = 11
    ..taxTotal = 2145000
    ..pphRate = 0
    ..grandTotal = 21645000
    ..hideTax = false
    ..hideSubtotal = false
    ..items = [item1, item2];

  invoice.company.value = company;
  invoice.customer.value = customer;

  // ─── Output Directory ─────────────────────────────────────────────────────
  const outputDir = 'lib/preview_output';
  Directory(outputDir).createSync(recursive: true);

  // ─── Generate Semua Template ──────────────────────────────────────────────
  final templateNames = {
    1: 'classic_professional',
    2: 'minimalist_modern',
    3: 'corporate_bold',
    4: 'clean_elegant',
  };

  for (final entry in templateNames.entries) {
    final index = entry.key;
    final name = entry.value;
    try {
      final pdfBytes = await PdfBuilder.build(
        invoice: invoice,
        templateIndex: index,
      );
      final file = File('$outputDir/template_${index}_${name}_v7.pdf');
      file.writeAsBytesSync(pdfBytes);
      print('✅  Template $index ($name) → ${file.path}');
    } catch (e) {
      print('❌  Template $index ($name) gagal: $e');
    }
  }

  print('\nSelesai! Buka folder "$outputDir" untuk melihat hasil preview.');
}
