import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../database/models/invoice.dart';
import '../../database/models/company.dart';
import '../../database/models/customer.dart';

// ─── Color Palettes ───────────────────────────────────────────────────────────
class PdfColors2 {
  static const primary = PdfColor.fromInt(0xFF1A237E);    // Deep navy
  static const accent = PdfColor.fromInt(0xFF0D47A1);
  static const light = PdfColor.fromInt(0xFFE3F2FD);
  static const grey100 = PdfColor.fromInt(0xFFF5F5F5);
  static const grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static const grey600 = PdfColor.fromInt(0xFF757575);
  static const textDark = PdfColor.fromInt(0xFF212121);
  static const teal = PdfColor.fromInt(0xFF00695C);
  static const tealLight = PdfColor.fromInt(0xFFE0F2F1);
  static const orange = PdfColor.fromInt(0xFFE65100);
  static const orangeLight = PdfColor.fromInt(0xFFFFF3E0);
}

// ─── Main PDF Builder ─────────────────────────────────────────────────────────
class PdfBuilder {
  static Future<Uint8List> build({
    required Invoice invoice,
    required int templateIndex, // 0,1,2,3
  }) async {
    final doc = pw.Document();

    // Load links
    final company = invoice.company.value;
    final customer = invoice.customer.value;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          switch (templateIndex) {
            case 1:
              return _template2(invoice, company, customer, ctx);
            case 2:
              return _template3(invoice, company, customer, ctx);
            case 3:
              return _template4(invoice, company, customer, ctx);
            default:
              return _template1(invoice, company, customer, ctx);
          }
        },
      ),
    );

    return await doc.save();
  }

  // ─── Template 1: Classic Professional (Navy + White) ─────────────────────
  static pw.Widget _template1(Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header bar
        pw.Container(
          width: double.infinity,
          color: PdfColors2.primary,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(co?.name ?? 'Perusahaan',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  if ((co?.branchName ?? '').isNotEmpty)
                    pw.Text(co?.branchName ?? '',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(co?.address ?? '',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                  pw.Text('Tel: ${co?.phone ?? ''}',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(inv.documentType ?? 'INVOICE',
                      style: pw.TextStyle(color: PdfColors.white, fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('No: ${inv.invoiceNumber ?? '-'}',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                  pw.Text('Tgl: ${_fmtDate(inv.date)}',
                      style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        // Billed to
        pw.Container(
          color: PdfColors2.light,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
          child: pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DITAGIHKAN KEPADA:', style: pw.TextStyle(fontSize: 8, color: PdfColors2.grey600, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(cu?.name ?? '-', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors2.textDark)),
                  if ((cu?.companyName ?? '').isNotEmpty)
                    pw.Text(cu?.companyName ?? '', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(cu?.address ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
                  pw.Text('Tel: ${cu?.phone ?? ''}', style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
                ],
              ),
            ],
          ),
        ),

        // Items Table
        pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: _buildItemsTable(inv, currency, headerBg: PdfColors2.primary, headerText: PdfColors.white),
        ),

        // Summary
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 40),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 280,
                child: _buildSummary(inv, currency),
              ),
            ],
          ),
        ),

        // Terbilang
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          child: pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors2.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TERBILANG:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors2.grey600)),
                pw.Text(inv.terbilang ?? '', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),

        // Footer
        if ((inv.notes ?? '').isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 40),
            child: pw.Text('Catatan: ${inv.notes}', style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
          ),

        pw.Spacer(),
        // Footer bar
        pw.Container(
          width: double.infinity,
          height: 6,
          color: PdfColors2.primary,
        ),
      ],
    );
  }

  // ─── Template 2: Minimalist Modern (Teal accent) ─────────────────────────
  static pw.Widget _template2(Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Padding(
      padding: const pw.EdgeInsets.all(50),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 6, height: 40, color: PdfColors2.teal,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(co?.name ?? 'Perusahaan',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors2.textDark)),
                  pw.Text(co?.address ?? '', style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
                  pw.Text('Tel: ${co?.phone ?? ''}', style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(inv.documentType ?? 'INVOICE',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors2.teal)),
                  pw.SizedBox(height: 6),
                  pw.Text('No: ${inv.invoiceNumber ?? '-'}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Tgl: ${_fmtDate(inv.date)}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Container(width: double.infinity, height: 1, color: PdfColors2.teal),
          pw.SizedBox(height: 16),

          // Customer
          pw.Text('Kepada:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors2.grey600)),
          pw.Text(cu?.name ?? '-', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          if ((cu?.companyName ?? '').isNotEmpty) pw.Text(cu?.companyName ?? '', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(cu?.address ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
          pw.SizedBox(height: 20),

          _buildItemsTable(inv, currency, headerBg: PdfColors2.teal, headerText: PdfColors.white),
          pw.SizedBox(height: 12),

          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Container(width: 260, child: _buildSummary(inv, currency, accentColor: PdfColors2.teal)),
          ]),
          pw.SizedBox(height: 16),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors2.tealLight,
            child: pw.Text('Terbilang: ${inv.terbilang ?? ''}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors2.teal)),
          ),

          pw.Spacer(),
          if ((inv.notes ?? '').isNotEmpty)
            pw.Text('Catatan: ${inv.notes}', style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
          pw.SizedBox(height: 10),
          pw.Container(width: double.infinity, height: 2, color: PdfColors2.teal),
        ],
      ),
    );
  }

  // ─── Template 3: Corporate Bold (Orange Header) ───────────────────────────
  static pw.Widget _template3(Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Column(
      children: [
        // Diagonal header
        pw.Container(
          width: double.infinity,
          color: PdfColors2.orange,
          padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(co?.name ?? 'Perusahaan',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text(inv.documentType ?? 'INVOICE',
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors2.orangeLight,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${co?.address ?? ''} | Tel: ${co?.phone ?? ''}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors2.orange)),
              pw.Text('No: ${inv.invoiceNumber ?? '-'} | Tgl: ${_fmtDate(inv.date)}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors2.orange)),
            ],
          ),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('KEPADA:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors2.orange)),
              pw.Text(cu?.name ?? '-', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              if ((cu?.companyName ?? '').isNotEmpty) pw.Text(cu?.companyName ?? ''),
              pw.Text(cu?.address ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
              pw.SizedBox(height: 20),
              _buildItemsTable(inv, currency, headerBg: PdfColors2.orange, headerText: PdfColors.white),
              pw.SizedBox(height: 12),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Container(width: 260, child: _buildSummary(inv, currency, accentColor: PdfColors2.orange)),
              ]),
              pw.SizedBox(height: 16),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                color: PdfColors2.orangeLight,
                child: pw.Text('Terbilang: ${inv.terbilang ?? ''}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors2.orange)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Template 4: Clean Elegant (Minimal lines) ────────────────────────────
  static pw.Widget _template4(Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(50, 50, 50, 30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Large company name
          pw.Text(co?.name ?? 'Perusahaan',
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors2.textDark, letterSpacing: 1)),
          pw.SizedBox(height: 2),
          pw.Text('${co?.address ?? ''} | ${co?.phone ?? ''}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
          pw.SizedBox(height: 30),

          // Title + number side by side
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(inv.documentType ?? 'INVOICE',
                    style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors2.grey300)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('No. ${inv.invoiceNumber ?? '-'}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Tanggal: ${_fmtDate(inv.date)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
              ]),
            ],
          ),
          pw.Container(width: double.infinity, height: 0.5, color: PdfColors2.grey300, margin: const pw.EdgeInsets.symmetric(vertical: 10)),

          // Customer
          pw.Text(cu?.name ?? '-', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if ((cu?.companyName ?? '').isNotEmpty) pw.Text(cu?.companyName ?? '', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(cu?.address ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
          pw.SizedBox(height: 24),

          _buildItemsTable(inv, currency, headerBg: PdfColors2.grey100, headerText: PdfColors2.textDark, bordered: false),
          pw.SizedBox(height: 20),

          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Container(width: 280, child: _buildSummary(inv, currency)),
          ]),
          pw.SizedBox(height: 16),
          pw.Container(width: double.infinity, height: 0.5, color: PdfColors2.grey300),
          pw.SizedBox(height: 6),
          pw.Text('Terbilang: ${inv.terbilang ?? ''}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
          pw.Spacer(),
          if ((inv.notes ?? '').isNotEmpty)
            pw.Text('Catatan: ${inv.notes}', style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
        ],
      ),
    );
  }

  // ─── Shared: Items Table ──────────────────────────────────────────────────
  static pw.Widget _buildItemsTable(
    Invoice inv,
    NumberFormat currency, {
    required PdfColor headerBg,
    required PdfColor headerText,
    bool bordered = true,
  }) {
    final border = bordered
        ? pw.TableBorder.all(color: PdfColors2.grey300, width: 0.5)
        : pw.TableBorder(
            horizontalInside: const pw.BorderSide(color: PdfColors2.grey300, width: 0.5),
            bottom: const pw.BorderSide(color: PdfColors2.grey300, width: 0.5),
          );

    return pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FixedColumnWidth(30),
        1: pw.FlexColumnWidth(3),
        2: pw.FixedColumnWidth(50),
        3: pw.FixedColumnWidth(80),
        4: pw.FixedColumnWidth(90),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBg),
          children: ['No', 'Uraian / Item', 'Qty', 'Harga Satuan', 'Total']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(color: headerText, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        // Rows
        ...inv.items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final total = (item.qty ?? 0) * (item.sellingPrice ?? 0);
          final isEven = i % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? PdfColors.white : PdfColors2.grey100),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(item.itemName ?? '-', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  if ((item.specification ?? '').isNotEmpty)
                    pw.Text(item.specification!, style: const pw.TextStyle(fontSize: 7, color: PdfColors2.grey600)),
                ]),
              ),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.qty ?? 0} ${item.unit ?? ''}', style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(currency.format(item.sellingPrice ?? 0), style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(currency.format(total), style: const pw.TextStyle(fontSize: 8))),
            ],
          );
        }),
      ],
    );
  }

  // ─── Shared: Summary Table ────────────────────────────────────────────────
  static pw.Widget _buildSummary(
    Invoice inv,
    NumberFormat currency, {
    PdfColor accentColor = PdfColors2.primary,
  }) {
    final rows = [
      ['Subtotal', currency.format(inv.subtotal ?? 0)],
      if ((inv.discountTotal ?? 0) > 0) ['Diskon', '-${currency.format(inv.discountTotal ?? 0)}'],
      if ((inv.taxRate ?? 0) > 0) ['PPN ${inv.taxRate?.toStringAsFixed(0)}%', currency.format(inv.taxTotal ?? 0)],
      if ((inv.pphRate ?? 0) > 0) ['PPH ${inv.pphRate?.toStringAsFixed(0)}%', '-${currency.format(inv.pphRate ?? 0)}'],
    ];

    return pw.Table(
      children: [
        ...rows.map((r) => pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              child: pw.Text(r[0], style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600))),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              child: pw.Text(r[1], textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
        ])),
        // Grand Total
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('GRAND TOTAL', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(currency.format(inv.grandTotal ?? 0),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
          ],
        ),
      ],
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd MMMM yyyy', 'id_ID').format(d);
  }
}
