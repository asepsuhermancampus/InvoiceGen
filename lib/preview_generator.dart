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
    ..address = 'Jl. Jend. Sudirman No. 1, Gedung Cyber Lt. 24, Kawasan Bisnis Sudirman (SCBD), Kebayoran Baru, Jakarta Selatan, DKI Jakarta, 12190, Indonesia - Dekat halte TransJakarta Gelora Bung Karno'
    ..phone = '021-1234567';

  final customer = Customer()
    ..name = 'Bapak Budi'
    ..companyName = 'CV Jaya Abadi'
    ..address = 'Jl. Merdeka No. 45, Bandung'
    ..phone = '081234567890';

  final items = List.generate(20, (i) {
    return InvoiceItem()
      ..itemName = 'Barang / Jasa No. ${i + 1}'
      ..specification = 'Spesifikasi detail untuk item nomor ${i + 1}'
      ..qty = (i + 1).toDouble()
      ..unit = 'Unit'
      ..sellingPrice = 500000 + (i * 100000);
  });

  final invoice = Invoice()
    ..invoiceNumber = 'INV-2026-020'
    ..date = DateTime.now()
    ..documentType = 'INVOICE'
    ..introText =
        'Terima kasih atas kepercayaan Anda menggunakan layanan kami. '
        'Berikut adalah rincian tagihan untuk pengadaan barang dan jasa.'
    ..terbilang = 'Lima Belas Juta Lima Ratus Ribu Rupiah'
    ..notes =
        'Pembayaran ditransfer ke rekening BCA 1234567890 a/n PT Makmur Sentosa'
    ..paymentTerms = 'Termin 1 (50%) - 14 Hari setelah invoice diterima'
    ..signatorName = 'Andi Susanto'
    ..subtotal = 15500000
    ..discountTotal = 0
    ..taxRate = 11
    ..taxTotal = 1705000
    ..pphRate = 0
    ..grandTotal = 17205000
    ..hideTax = false
    ..hideSubtotal = false
    ..items = items;

  invoice.company.value = company;
  invoice.customer.value = customer;

  // ─── Output Directory ─────────────────────────────────────────────────────
  const outputDir = 'lib/preview_output';
  Directory(outputDir).createSync(recursive: true);

  // ─── Generate Semua Template ──────────────────────────────────────────────
  final templateNames = {
    1: 'classic',
    2: 'modern',
    3: 'corporate',
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
      final absDir = Directory(outputDir).absolute.path;
      final file = File('$absDir/template_${index}_${name}_v35.pdf');
      file.writeAsBytesSync(pdfBytes);
      print('✅  Template $index ($name) → ${file.absolute.path}');
    } catch (e) {
      print('❌  Template $index ($name) gagal: $e');
    }
  }

  print('\nSelesai! Buka folder "$outputDir" untuk melihat hasil preview.');
}
