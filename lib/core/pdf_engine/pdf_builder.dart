import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../database/models/invoice.dart';
import '../../database/models/company.dart';
import '../../database/models/customer.dart';

// ─── Color Palettes ───────────────────────────────────────────────────────────
class PdfColors2 {
  static const primary = PdfColor.fromInt(0xFF4A6FA5);
  static const accent = PdfColor.fromInt(0xFF5B84B1);
  static const light = PdfColor.fromInt(0xFFE8EEF5);
  static const grey100 = PdfColor.fromInt(0xFFF5F5F5);
  static const grey300 = PdfColor.fromInt(0xFFE0E0E0);
  static const grey600 = PdfColor.fromInt(0xFF8A8A8A);
  static const textDark = PdfColor.fromInt(0xFF2D2D2D);
  static const elegantGrey = PdfColor.fromInt(0xFF5F7A8A);
  static const elegantGreyLight = PdfColor.fromInt(0xFFDFE9EE);
  static const elegantDark = PdfColor.fromInt(0xFF546E7A);
  static const elegantDarkLight = PdfColor.fromInt(0xFFECF1F3);
  static const elegantTeal = PdfColor.fromInt(0xFF546E7A);
  static const elegantTealLight = PdfColor.fromInt(0xFFECF1F3);
}

// Margin konten untuk template 1 & 3
const double _kSideMargin = 40.0;
const double _kBottomMargin = 40.0;

// Helper: bungkus widget konten dengan horizontal padding
// Digunakan pada Template 1 & 3 agar header bisa full-bleed
// sementara konten tetap punya margin kiri-kanan.
pw.Widget _padded(pw.Widget child) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: _kSideMargin),
      child: child,
    );

// ─── Main PDF Builder ─────────────────────────────────────────────────────────
class PdfBuilder {
  static Future<Uint8List> build({
    required Invoice invoice,
    required int templateIndex,
  }) async {
    final doc = pw.Document();
    final company = invoice.company.value;
    final customer = invoice.customer.value;

    switch (templateIndex) {
      case 1:
        doc.addPage(_buildMultiPage1(invoice, company, customer));
        break;
      case 2:
        doc.addPage(_buildMultiPage2(invoice, company, customer));
        break;
      case 3:
        doc.addPage(_buildMultiPage3(invoice, company, customer));
        break;
      case 4:
        doc.addPage(_buildMultiPage4(invoice, company, customer));
        break;
      default:
        doc.addPage(_buildMultiPage1(invoice, company, customer));
    }
    return await doc.save();
  }

  static pw.Widget _buildPageNumber(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Text(
        'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors2.grey600),
      ),
    );
  }

  // =========================================================================
  // TEMPLATE 1: Classic Professional — full-bleed header, konten bermargin
  //
  // Strategi full-bleed:
  //   • margin page = EdgeInsets.only(bottom: 40) → header & footer
  //     menggunakan lebar penuh halaman secara natural
  //   • setiap widget di build() dibungkus _padded() untuk margin kiri/kanan
  //   • pw.Table (items) juga dibungkus _padded() agar kolom sejajar
  // =========================================================================
  static pw.MultiPage _buildMultiPage1(
      Invoice inv, Company? co, Customer? cu) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      // Tidak ada margin kiri/kanan/atas — header langsung dari tepi kertas
      margin: const pw.EdgeInsets.only(bottom: _kBottomMargin),
      header: (ctx) => _header1(inv, co),
      footer: (ctx) => _padded(_buildPageNumber(ctx)),
      build: (ctx) => [
        // Kepada
        if (cu != null) ...[
          _padded(pw.Text('KEPADA:',
              style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors2.grey600,
                  fontWeight: pw.FontWeight.bold))),
          _padded(pw.SizedBox(height: 4)),
          _padded(_buildKepadaDetails(inv, cu)),
          _padded(pw.SizedBox(height: 20)),
        ],
        // Intro
        if ((inv.introText ?? '').isNotEmpty) ...[
          _padded(pw.Text(inv.introText ?? '',
              style: const pw.TextStyle(fontSize: 9))),
          _padded(pw.SizedBox(height: 20)),
        ],
        // Tabel
        _padded(_buildItemsTable(inv, currency,
            headerBg: PdfColors2.elegantDark,
            headerText: PdfColors.white)),
        _padded(pw.SizedBox(height: 16)),
        // Summary
        _padded(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.SizedBox(
              width: 270,
              child: _buildSummary(inv, currency,
                  accentColor: PdfColors2.elegantDark),
            ),
          ],
        )),
        _padded(pw.SizedBox(height: 20)),
        // Terbilang
        _padded(pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors2.grey300),
            borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(4)),
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
        )),
        _padded(pw.SizedBox(height: 24)),
        // Tanda tangan
        _padded(_buildSignatures(inv)),
      ],
    );
  }

  // Header T1: full-bleed (margin page = 0 kiri/kanan/atas, jadi ini natural
  // menggunakan lebar penuh A4). Padding internal = _kSideMargin.
  // SizedBox di akhir = spacing antara header dan konten, muncul tiap halaman.
  static pw.Widget _header1(Invoice inv, Company? co) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(
              _kSideMargin, 36, _kSideMargin, 24),
          color: PdfColors2.elegantDark,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(co?.name ?? 'Perusahaan',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                    if ((co?.slogan ?? '').isNotEmpty)
                      pw.Text(co?.slogan ?? '',
                          style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10)),
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
              ),
              pw.SizedBox(width: 40),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(inv.documentType ?? 'INVOICE',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
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
        // Spacing header → konten, muncul di SETIAP halaman
        pw.SizedBox(height: 20),
      ],
    );
  }

  // =========================================================================
  // TEMPLATE 2: Minimalist Modern (normal margin, header dengan garis)
  // =========================================================================
  static pw.MultiPage _buildMultiPage2(
      Invoice inv, Company? co, Customer? cu) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _header2(inv, co),
      footer: (ctx) => _buildPageNumber(ctx),
      build: (ctx) => [
        if (cu != null) ...[
          pw.Text('KEPADA:',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors2.grey600)),
          pw.SizedBox(height: 4),
          _buildKepadaDetails(inv, cu),
          pw.SizedBox(height: 20),
        ],
        if ((inv.introText ?? '').isNotEmpty) ...[
          pw.Text(inv.introText ?? '',
              style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 20),
        ],
        _buildItemsTable(inv, currency,
            headerBg: PdfColors2.elegantDark,
            headerText: PdfColors.white),
        pw.SizedBox(height: 16),
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                  width: 270,
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
        pw.SizedBox(height: 24),
        _buildSignatures(inv),
      ],
    );
  }

  static pw.Widget _header2(Invoice inv, Company? co) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                      width: 6, height: 50, color: PdfColors2.elegantDark),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(co?.name ?? 'Perusahaan',
                            style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors2.textDark)),
                        if ((co?.slogan ?? '').isNotEmpty)
                          pw.Text(co?.slogan ?? '',
                              style: const pw.TextStyle(
                                  fontSize: 9,
                                  color: PdfColors2.textDark)),
                        pw.SizedBox(height: 2),
                        pw.Text(co?.address ?? '',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors2.textDark)),
                        pw.Text('Tel: ${co?.phone ?? ''}',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors2.textDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 40),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(inv.documentType ?? 'INVOICE',
                    style: pw.TextStyle(
                        fontSize: 18,
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
        pw.SizedBox(height: 16),
        pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColors2.elegantDark),
        pw.SizedBox(height: 16),
      ],
    );
  }

  // =========================================================================
  // TEMPLATE 3: Corporate Bold — full-bleed 2-row header
  //
  // Strategi sama dengan T1:
  //   • margin page = EdgeInsets.only(bottom: 40)
  //   • header menggunakan lebar penuh natural
  //   • setiap konten di-_padded()
  // =========================================================================
  static pw.MultiPage _buildMultiPage3(
      Invoice inv, Company? co, Customer? cu) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.only(bottom: _kBottomMargin),
      header: (ctx) => _header3(inv, co),
      footer: (ctx) => _padded(_buildPageNumber(ctx)),
      build: (ctx) => [
        // Kepada
        if (cu != null) ...[
          _padded(pw.Text('KEPADA:',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors2.elegantDark))),
          _padded(pw.SizedBox(height: 4)),
          _padded(_buildKepadaDetails(inv, cu)),
          _padded(pw.SizedBox(height: 20)),
        ],
        // Intro
        if ((inv.introText ?? '').isNotEmpty) ...[
          _padded(pw.Text(inv.introText ?? '',
              style: const pw.TextStyle(fontSize: 9))),
          _padded(pw.SizedBox(height: 20)),
        ],
        // Tabel
        _padded(_buildItemsTable(inv, currency,
            headerBg: PdfColors2.elegantDark,
            headerText: PdfColors.white)),
        _padded(pw.SizedBox(height: 16)),
        // Summary
        _padded(pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                  width: 270,
                  child: _buildSummary(inv, currency,
                      accentColor: PdfColors2.elegantDark)),
            ])),
        _padded(pw.SizedBox(height: 20)),
        // Terbilang
        _padded(pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          color: PdfColors2.elegantDarkLight,
          child: pw.Text('Terbilang: ${inv.terbilang ?? ''}',
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors2.elegantDark)),
        )),
        _padded(pw.SizedBox(height: 24)),
        // Tanda tangan
        _padded(_buildSignatures(inv)),
      ],
    );
  }

  // Header T3: 2 baris full-bleed, natural lebar penuh karena margin=0.
  // Baris atas = background gelap, baris bawah = background terang.
  // SizedBox di akhir = spacing tiap halaman.
  static pw.Widget _header3(Invoice inv, Company? co) {
    return pw.Column(
      children: [
        // Baris atas: background gelap
        pw.Container(
          width: double.infinity,
          color: PdfColors2.elegantDark,
          padding: const pw.EdgeInsets.fromLTRB(
              _kSideMargin, 36, _kSideMargin, 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(co?.name ?? 'Perusahaan',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold)),
                      if ((co?.slogan ?? '').isNotEmpty)
                        pw.Text(co?.slogan ?? '',
                            style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 10)),
                    ]),
              ),
              pw.Text(inv.documentType ?? 'INVOICE',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.normal)),
            ],
          ),
        ),
        // Baris bawah: background terang
        pw.Container(
          width: double.infinity,
          color: PdfColors2.elegantDarkLight,
          padding: const pw.EdgeInsets.fromLTRB(
              _kSideMargin, 8, _kSideMargin, 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Text(
                    '${co?.address ?? ''} | Tel: ${co?.phone ?? ''}',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors2.elegantDark)),
              ),
              pw.SizedBox(width: 16),
              pw.Text(
                  'No: ${inv.invoiceNumber ?? '-'} | Tgl: ${_fmtDate(inv.date)}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors2.elegantDark)),
            ],
          ),
        ),
        // Spacing header → konten, muncul di SETIAP halaman
        pw.SizedBox(height: 20),
      ],
    );
  }

  // =========================================================================
  // TEMPLATE 4: Clean Elegant (normal margin, minimal lines)
  // =========================================================================
  static pw.MultiPage _buildMultiPage4(
      Invoice inv, Company? co, Customer? cu) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(50, 50, 50, 40),
      header: (ctx) => _header4(inv, co),
      footer: (ctx) => _buildPageNumber(ctx),
      build: (ctx) => [
        if (cu != null) ...[
          pw.Text('KEPADA:',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors2.grey600)),
          pw.SizedBox(height: 4),
          _buildKepadaDetails(inv, cu),
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
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                  width: 270,
                  child: _buildSummary(inv, currency,
                      accentColor: PdfColors2.elegantDark, bordered: false)),
            ]),
        pw.SizedBox(height: 16),
        pw.Container(
            width: double.infinity,
            height: 0.5,
            color: PdfColors2.grey300),
        pw.SizedBox(height: 6),
        pw.Text('Terbilang: ${inv.terbilang ?? ''}',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors2.textDark)),
        pw.SizedBox(height: 24),
        _buildSignatures(inv),
      ],
    );
  }

  static pw.Widget _header4(Invoice inv, Company? co) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(co?.name ?? 'Perusahaan',
            style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors2.textDark,
                letterSpacing: 1)),
        if ((co?.slogan ?? '').isNotEmpty)
          pw.Text(co?.slogan ?? '',
              style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors2.textDark)),
        pw.SizedBox(height: 2),
        pw.Text('${co?.address ?? ''} | Tel: ${co?.phone ?? ''}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors2.textDark)),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(inv.documentType ?? 'INVOICE',
                        style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors2.grey300)),
                  ]),
            ),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('No. ${inv.invoiceNumber ?? '-'}',
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text('Tanggal: ${_fmtDate(inv.date)}',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors2.textDark)),
                ]),
          ],
        ),
        pw.Container(
            width: double.infinity,
            height: 0.5,
            color: PdfColors2.grey300,
            margin: const pw.EdgeInsets.symmetric(vertical: 10)),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // ─── Shared: Kepada Details ───────────────────────────────────────────────
  static pw.Widget _buildKepadaDetails(Invoice inv, Customer cu) {
    // Determine the name to show: use attn if available, else customer name
    final nama = (inv.attn ?? '').isNotEmpty
        ? inv.attn!
        : (cu.name ?? '-');

    final kepadaRows = <List<String>>[
      if ((cu.companyName ?? '').isNotEmpty)
        ['Perusahaan', cu.companyName!],
      ['Nama', nama],
      if ((cu.address ?? '').isNotEmpty)
        ['Alamat', cu.address!],
      if ((cu.phone ?? '').isNotEmpty)
        ['No. Telp', cu.phone!],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.white, width: 0),
      columnWidths: const {
        0: pw.FixedColumnWidth(55),
        1: pw.FixedColumnWidth(8),
        2: pw.FlexColumnWidth(1),
      },
      children: kepadaRows.map((r) => pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Text(r[0],
                style: r[0] == 'Nama'
                    ? pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors2.textDark)
                    : const pw.TextStyle(fontSize: 9, color: PdfColors2.textDark)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Text(':',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors2.textDark)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Text(r[1],
                style: r[0] == 'Nama'
                    ? pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors2.textDark)
                    : const pw.TextStyle(fontSize: 9, color: PdfColors2.textDark)),
          ),
        ],
      )).toList(),
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
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors2.textDark)),
              pw.SizedBox(height: 4),
              pw.Text(inv.notes ?? '-',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors2.textDark)),
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
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors2.textDark)),
              pw.SizedBox(height: 4),
              pw.Text(inv.paymentTerms ?? '-',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors2.textDark)),
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
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 50),
              pw.Text('( ${inv.signatorName ?? '..................'} )',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
        2: pw.FixedColumnWidth(35),
        3: pw.FixedColumnWidth(55),
        4: pw.FixedColumnWidth(85),
        5: pw.FixedColumnWidth(95),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBg),
          children: ['No', 'Nama Barang', 'Qty', 'Satuan', 'Harga Satuan', 'Total']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        textAlign: (h == 'No' || h == 'Qty' || h == 'Satuan')
                            ? pw.TextAlign.center
                            : pw.TextAlign.left,
                        style: pw.TextStyle(
                            color: headerText,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
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
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.itemName ?? '-',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                      if ((item.specification ?? '').isNotEmpty)
                        pw.Text(item.specification!,
                            style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors2.textDark)),
                    ]),
              ),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                      '${(item.qty ?? 0).toInt()}',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                      item.unit ?? '',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                      currency.format(item.sellingPrice ?? 0),
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
    bool bordered = true,
  }) {
    // Selalu gunakan style "Clean Elegant" (tanpa vertical border) untuk semua template
    const border = pw.TableBorder(
      horizontalInside: pw.BorderSide(color: PdfColors2.grey300, width: 0.5),
      bottom: pw.BorderSide(color: PdfColors2.grey300, width: 0.5),
    );

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
    ];

    return pw.Table(
      border: border,
      columnWidths: const {
        0: pw.FixedColumnWidth(130),
        1: pw.FixedColumnWidth(140),
      },
      children: [
        ...rows.map((r) => pw.TableRow(children: [
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r[0],
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors2.textDark))),
              pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(r[1],
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(fontSize: 9))),
            ])),
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
