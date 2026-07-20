import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../database/models/invoice.dart';
import '../../database/models/company.dart';
import '../../database/models/customer.dart';

// ─── Color Palettes ───────────────────────────────────────────────────────────
class PdfColors2 {
  // Template 1 (Classic): Soft slate blue - tidak terlalu biru tua
  static const primary = PdfColor.fromInt(0xFF4A6FA5);
  static const accent = PdfColor.fromInt(0xFF5B84B1);
  static const light = PdfColor.fromInt(0xFFE8EEF5);

  // Neutral greys
  static const grey100 = PdfColor.fromInt(0xFFF5F5F5);
  static const grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static const grey600 = PdfColor.fromInt(0xFF8A8A8A);
  static const textDark = PdfColor.fromInt(0xFF2D2D2D);

  // Template 2 (Modern): Muted blue-grey (Blue Grey 600)
  static const elegantGrey = PdfColor.fromInt(0xFF5F7A8A);
  static const elegantGreyLight = PdfColor.fromInt(0xFFDFE9EE);

  // Template 3 (Corporate): Tosca tua abu-abu (muted teal-grey) — same as all templates
  static const elegantDark = PdfColor.fromInt(0xFF546E7A);      // Blue Grey 600 - tosca tua
  static const elegantDarkLight = PdfColor.fromInt(0xFFECF1F3); // Sangat terang (off-white teal)

  // Template 4 (Clean Elegant): Tosca tua abu-abu (Muted Teal-Grey)
  static const elegantTeal = PdfColor.fromInt(0xFF546E7A);   // Blue Grey 600
  static const elegantTealLight = PdfColor.fromInt(0xFFECF1F3); // sangat terang
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
  static pw.Widget _template1(
      Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(40),
          color: PdfColors2.elegantDark,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(co?.name ?? 'Perusahaan',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                  if ((co?.slogan ?? '').isNotEmpty)
                    pw.Text(co?.slogan ?? '',
                        style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 10, fontStyle: pw.FontStyle.italic)),
                  if ((co?.branchName ?? '').isNotEmpty)
                    pw.Text(co?.branchName ?? '',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(co?.address ?? '',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 9)),
                  pw.Text('Tel: ${co?.phone ?? ''}',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 9)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(inv.documentType ?? 'INVOICE',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('No: ${inv.invoiceNumber ?? '-'}',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 10)),
                  pw.Text('Tgl: ${_fmtDate(inv.date)}',
                      style: const pw.TextStyle(
                          color: PdfColors.white, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        // Body
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Customer Info
                if (cu != null) ...[
                  pw.Text('KEPADA:',
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors2.grey600,
                          fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  _buildKepadaDetails(cu),
                  pw.SizedBox(height: 20),
                ],

                // Intro Text
                if ((inv.introText ?? '').isNotEmpty) ...[
                  pw.Text(inv.introText ?? '',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 20),
                ],
                  
                // Items Table
                _buildItemsTable(inv, currency,
                    headerBg: PdfColors2.elegantDark, headerText: PdfColors.white),
                pw.SizedBox(height: 16),

                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 280,
                      child: _buildSummary(inv, currency, accentColor: PdfColors2.elegantDark),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Terbilang
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors2.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('TERBILANG:',
                          style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors2.grey600)),
                      pw.Text(inv.terbilang ?? '',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),

                pw.Spacer(),
                _buildSignatures(inv),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Template 2: Minimalist Modern (Elegant Grey accent) ─────────────────────────
  static pw.Widget _template2(
      Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Padding(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 6,
                    height: 40,
                    color: PdfColors2.elegantDark,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(co?.name ?? 'Perusahaan',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors2.textDark)),
                      if ((co?.slogan ?? '').isNotEmpty)
                        pw.Text(co?.slogan ?? '',
                            style: pw.TextStyle(
                                fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors2.grey600)),
                      pw.SizedBox(height: 2),
                      pw.Text(co?.address ?? '',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors2.grey600)),
                      pw.Text('Tel: ${co?.phone ?? ''}',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors2.grey600)),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(inv.documentType ?? 'INVOICE',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors2.elegantDark)),
                  pw.SizedBox(height: 6),
                  pw.Text('No: ${inv.invoiceNumber ?? '-'}',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Tgl: ${_fmtDate(inv.date)}',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Container(
              width: double.infinity, height: 1, color: PdfColors2.elegantDark),
          pw.SizedBox(height: 20),

          // Customer
          if (cu != null) ...[
            pw.Text('KEPADA:',
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors2.grey600)),
            pw.SizedBox(height: 4),
            _buildKepadaDetails(cu),
            pw.SizedBox(height: 20),
          ],

          if ((inv.introText ?? '').isNotEmpty) ...[
            pw.Text(inv.introText ?? '',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 20),
          ],

          _buildItemsTable(inv, currency,
              headerBg: PdfColors2.elegantDark, headerText: PdfColors.white),
          pw.SizedBox(height: 16),

          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Container(
                width: 280,
                child:
                    _buildSummary(inv, currency, accentColor: PdfColors2.elegantDark)),
          ]),
          pw.SizedBox(height: 20),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            color: PdfColors2.elegantDarkLight,
            child: pw.Text('Terbilang: ${inv.terbilang ?? ''}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors2.elegantDark)),
          ),

          pw.Spacer(),
          _buildSignatures(inv),
        ],
      ),
    );
  }

  // ─── Template 3: Corporate Bold (Elegant Dark Header) ───────────────────────────
  static pw.Widget _template3(
      Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Column(
      children: [
        // Diagonal header
        pw.Container(
          width: double.infinity,
          color: PdfColors2.elegantDark,
          padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 20),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(co?.name ?? 'Perusahaan',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold)),
                  if ((co?.slogan ?? '').isNotEmpty)
                    pw.Text(co?.slogan ?? '',
                        style: pw.TextStyle(
                            color: PdfColors.white, fontSize: 10, fontStyle: pw.FontStyle.italic)),
                ]
              ),
              pw.Text(inv.documentType ?? 'INVOICE',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.Container(
          color: PdfColors2.elegantDarkLight,
          padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${co?.address ?? ''} | Tel: ${co?.phone ?? ''}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors2.elegantDark)),
              pw.Text(
                  'No: ${inv.invoiceNumber ?? '-'} | Tgl: ${_fmtDate(inv.date)}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors2.elegantDark)),
            ],
          ),
        ),

        // Body
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 30, 40, 40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (cu != null) ...[
                  pw.Text('KEPADA:',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors2.elegantDark)),
                  pw.SizedBox(height: 4),
                  _buildKepadaDetails(cu),
                  pw.SizedBox(height: 20),
                ],
                
                if ((inv.introText ?? '').isNotEmpty) ...[
                  pw.Text(inv.introText ?? '',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 20),
                ],

                _buildItemsTable(inv, currency,
                    headerBg: PdfColors2.elegantDark, headerText: PdfColors.white),
                pw.SizedBox(height: 16),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                  pw.Container(
                      width: 280,
                      child: _buildSummary(inv, currency,
                          accentColor: PdfColors2.elegantDark)),
                ]),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors2.elegantDarkLight,
                  child: pw.Text('Terbilang: ${inv.terbilang ?? ''}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors2.elegantDark)),
                ),
                pw.Spacer(),
                _buildSignatures(inv),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Template 4: Clean Elegant (Minimal lines) ────────────────────────────
  static pw.Widget _template4(
      Invoice inv, Company? co, Customer? cu, pw.Context ctx) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(50, 50, 50, 30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Large company name
          pw.Text(co?.name ?? 'Perusahaan',
              style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors2.textDark,
                  letterSpacing: 1)),
          if ((co?.slogan ?? '').isNotEmpty)
            pw.Text(co?.slogan ?? '',
                style: pw.TextStyle(
                    fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors2.grey600)),
          pw.SizedBox(height: 2),
          pw.Text('${co?.address ?? ''} | Tel: ${co?.phone ?? ''}',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
          pw.SizedBox(height: 30),

          // Title + number side by side
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(inv.documentType ?? 'INVOICE',
                        style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors2.grey300)),
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('No. ${inv.invoiceNumber ?? '-'}',
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Tanggal: ${_fmtDate(inv.date)}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors2.grey600)),
                  ]),
            ],
          ),
          pw.Container(
              width: double.infinity,
              height: 0.5,
              color: PdfColors2.grey300,
              margin: const pw.EdgeInsets.symmetric(vertical: 10)),

          // Customer
          if (cu != null) ...[
            pw.Text('KEPADA:',
                style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors2.grey600)),
            pw.SizedBox(height: 4),
            _buildKepadaDetails(cu),
            pw.SizedBox(height: 20),
          ],
          
          if ((inv.introText ?? '').isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Text(inv.introText ?? '',
                  style: const pw.TextStyle(fontSize: 9)),
            ),

          _buildItemsTable(inv, currency,
              headerBg: PdfColors2.elegantDarkLight,
              headerText: PdfColors2.elegantDark,
              bordered: false),
          pw.SizedBox(height: 20),

          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Container(width: 280, child: _buildSummary(inv, currency, accentColor: PdfColors2.elegantDark)),
          ]),
          pw.SizedBox(height: 16),
          pw.Container(
              width: double.infinity, height: 0.5, color: PdfColors2.grey300),
          pw.SizedBox(height: 6),
          pw.Text('Terbilang: ${inv.terbilang ?? ''}',
              style:
                  pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors2.textDark)),
          pw.Spacer(),
          _buildSignatures(inv),
        ],
      ),
    );
  }

  // ─── Shared: Kepada Details ───────────────────────────────────────────────
  static pw.Widget _buildKepadaDetails(Customer cu) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Nama: ${cu.name ?? '-'}',
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors2.textDark)),
        pw.SizedBox(height: 2),
        if ((cu.companyName ?? '').isNotEmpty) ...[
          pw.Text('Perusahaan: ${cu.companyName}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 2),
        ],
        pw.Text('Alamat: ${cu.address ?? '-'}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
        pw.SizedBox(height: 2),
        pw.Text('No.Telp/Fax: ${cu.phone ?? '-'}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors2.grey600)),
      ],
    );
  }
  
  // ─── Shared: Bottom Signatures ──────────────────────────────────────────
  static pw.Widget _buildSignatures(Invoice inv) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Keterangan:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(inv.notes ?? '-',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Syarat Pembayaran:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(inv.paymentTerms ?? '-',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600)),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Hormat Kami,',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 50),
              pw.Text('( ${inv.signatorName ?? '..................'} )',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ],
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
        : const pw.TableBorder(
            horizontalInside:
                pw.BorderSide(color: PdfColors2.grey300, width: 0.5),
            bottom: pw.BorderSide(color: PdfColors2.grey300, width: 0.5),
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
          children: ['No', 'Nama Barang', 'Qty', 'Harga Satuan', 'Total']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: headerText,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold)),
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
            decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.white : PdfColors2.grey100),
            children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${i + 1}',
                      style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.itemName ?? '-',
                          style: pw.TextStyle(
                              fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      if ((item.specification ?? '').isNotEmpty)
                        pw.Text(item.specification!,
                            style: const pw.TextStyle(
                                fontSize: 7, color: PdfColors2.grey600)),
                    ]),
              ),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${(item.qty ?? 0) % 1 == 0 ? (item.qty ?? 0).toInt() : (item.qty ?? 0)} ${item.unit ?? ''}'.trim(),
                      style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(currency.format(item.sellingPrice ?? 0),
                      style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(currency.format(total),
                      style: const pw.TextStyle(fontSize: 8))),
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
      if (!inv.hideSubtotal)
        ['Subtotal', currency.format(inv.subtotal ?? 0)],
      if ((inv.discountTotal ?? 0) > 0)
        ['Diskon', '-${currency.format(inv.discountTotal ?? 0)}'],
      if (!inv.hideTax && (inv.taxRate ?? 0) > 0)
        [
          'PPN ${inv.taxRate?.toStringAsFixed(0)}%',
          currency.format(inv.taxTotal ?? 0)
        ],
      if (!inv.hideTax && (inv.pphRate ?? 0) > 0)
        [
          'PPH ${inv.pphRate?.toStringAsFixed(0)}%',
          '-${currency.format(inv.pphRate ?? 0)}'
        ],
    ];

    return pw.Table(
      children: [
        ...rows.map((r) => pw.TableRow(children: [
              pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  child: pw.Text(r[0],
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors2.grey600))),
              pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  child: pw.Text(r[1],
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 9))),
            ])),
        // Grand Total
        pw.TableRow(
          decoration: pw.BoxDecoration(color: accentColor),
          children: [
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text('TOTAL',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10))),
            pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(currency.format(inv.grandTotal ?? 0),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10))),
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
