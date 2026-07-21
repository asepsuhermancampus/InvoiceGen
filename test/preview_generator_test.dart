import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/database/models/invoice.dart';
import 'package:invoice_generator/database/models/company.dart';
import 'package:invoice_generator/database/models/customer.dart';
import 'package:invoice_generator/database/models/template.dart';
import 'package:invoice_generator/core/pdf_engine/pdf_builder.dart';
import 'package:intl/date_symbol_data_local.dart';

String _terbilang(int angka) {
  final satuan = ['', 'Satu', 'Dua', 'Tiga', 'Empat', 'Lima', 'Enam', 'Tujuh', 'Delapan', 'Sembilan', 'Sepuluh', 'Sebelas'];
  if (angka < 12) return satuan[angka];
  if (angka < 20) return '${_terbilang(angka - 10)} Belas';
  if (angka < 100) return '${_terbilang(angka ~/ 10)} Puluh ${_terbilang(angka % 10)}';
  if (angka < 200) return 'Seratus ${_terbilang(angka - 100)}';
  if (angka < 1000) return '${_terbilang(angka ~/ 100)} Ratus ${_terbilang(angka % 100)}';
  if (angka < 2000) return 'Seribu ${_terbilang(angka - 1000)}';
  if (angka < 1000000) return '${_terbilang(angka ~/ 1000)} Ribu ${_terbilang(angka % 1000)}';
  if (angka < 1000000000) return '${_terbilang(angka ~/ 1000000)} Juta ${_terbilang(angka % 1000000)}';
  return '${_terbilang(angka ~/ 1000000000)} Milyar ${_terbilang(angka % 1000000000)}';
}

void main() {
  test('Generate Previews', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);

    final invoice = Invoice()
      ..invoiceNumber = 'INV-2026-10-0045'
      ..date = DateTime.now()
      ..attn = 'Bpk. Budi Santoso (Direktur Pembelian)'
      ..address = 'Kawasan Industri MM2100, Jl. Bali Blok J No. 5-7, Cikarang Barat, Bekasi, Jawa Barat 17530'
      ..phone = '+62 21 898 4567'
      ..documentType = 'Invoice'
      ..currency = 'IDR'
      ..taxRate = 11.0
      ..pphRate = 0.0
      ..notes = 'Pembayaran harap ditransfer ke rekening BCA 1234567890 a.n PT. Inovasi Teknologi Nusantara Makmur selambat-lambatnya 14 hari kerja setelah invoice diterima. Bukti transfer mohon diemail ke finance@inovasiteknologi.co.id.'
      ..footer = 'Terima kasih atas kepercayaan Anda menggunakan layanan kami.'
      ..introText = 'Bersama surat ini kami lampirkan tagihan atas pekerjaan dan barang yang telah dikirimkan pada bulan ini sesuai dengan PO nomor PO-998877.'
      ..hideSubtotal = false
      ..hideTax = false
      ..paymentTerms = 'Net 14 Days'
      ..signatorName = 'Andi Wijaya, M.Kom';

    final c = Company()
      ..name = 'PT. Inovasi Teknologi Nusantara Makmur'
      ..branchName = 'Kantor Pusat Jakarta'
      ..slogan = 'Solusi IT Terpercaya untuk Bisnis Anda'
      ..address = 'Gedung Cyber Tower Lantai 15, Jl. Jend. Sudirman Kav. 21, Jakarta Selatan, DKI Jakarta 12920'
      ..phone = '+62 21 555 1234'
      ..email = 'info@inovasiteknologi.co.id'
      ..website = 'www.inovasiteknologi.co.id';

    final cust = Customer()
      ..companyName = 'PT. Maju Mundur Sejahtera Abadi'
      ..name = 'Budi Santoso'
      ..address = 'Kawasan Industri MM2100, Jl. Bali Blok J No. 5-7, Cikarang Barat, Bekasi, Jawa Barat 17530'
      ..phone = '+62 21 898 4567'
      ..email = 'purchasing@majumundur.com';

    invoice.company.value = c;
    invoice.customer.value = cust;

    final items = List.generate(25, (index) {
      final isService = index % 3 == 0;
      return InvoiceItem()
        ..itemName = isService ? 'Jasa Implementasi Server ${index + 1}' : 'Server Rackmount Type-${String.fromCharCode(65 + (index % 26))} Unit ${index + 1}'
        ..specification = isService ? 'Instalasi dan konfigurasi server di lokasi klien, termasuk testing' : 'Intel Xeon E-2224, 16GB RAM, 2TB HDD Enterprise, Redundant PSU'
        ..qty = (index % 5) + 1.0
        ..unit = isService ? 'Lot' : 'Unit'
        ..sellingPrice = isService ? 5000000.0 : 25000000.0;
    });

    invoice.items.addAll(items);

    // Calculate totals correctly
    double sub = 0;
    for (final item in items) {
      sub += (item.qty ?? 0) * (item.sellingPrice ?? 0);
    }
    invoice.subtotal = sub;
    invoice.taxTotal = sub * (invoice.taxRate ?? 0) / 100;
    invoice.grandTotal = sub + (invoice.taxTotal ?? 0); // No PPh logic to affect the total in this dummy
    
    // Setup dynamic Terbilang based on grand total
    final totalInt = invoice.grandTotal?.round() ?? 0;
    invoice.terbilang = '${_terbilang(totalInt).trim()} Rupiah';

    const templates = ['Classic', 'Modern', 'Corporate', 'Clean Elegant'];
    const version = 'FullDummy';
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
