import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../database/models/invoice.dart';
import '../../core/pdf_engine/pdf_builder.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Invoice invoice;
  final int templateIndex;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    this.templateIndex = 0,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  Uint8List? _pdfBytes;
  bool _loading = true;
  String? _error;
  late int _currentTemplate;

  @override
  void initState() {
    super.initState();
    _currentTemplate = widget.templateIndex;
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load links before passing
      final bytes = await PdfBuilder.build(
        invoice: widget.invoice,
        templateIndex: _currentTemplate,
      );
      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.invoice.invoiceNumber ?? 'invoice'}.pdf');
    await file.writeAsBytes(_pdfBytes!);
    await Share.shareXFiles([XFile(file.path)], text: 'Invoice ${widget.invoice.invoiceNumber}');
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => _pdfBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice.invoiceNumber ?? 'Preview PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Bagikan PDF',
            onPressed: _loading ? null : _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak',
            onPressed: _loading ? null : _printPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Template switcher
          Container(
            height: 50,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _templateChip(0, 'Classic'),
                _templateChip(1, 'Modern'),
                _templateChip(2, 'Corporate'),
                _templateChip(3, 'Clean Elegant'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Membuat PDF...'),
                    ],
                  ))
                : _error != null
                    ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
                    : PdfPreview(
                        build: (format) => _pdfBytes!,
                        allowPrinting: true,
                        allowSharing: true,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        pdfFileName: '${widget.invoice.invoiceNumber}.pdf',
                      ),
          ),
        ],
      ),
    );
  }

  Widget _templateChip(int index, String name) {
    final isSelected = _currentTemplate == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _currentTemplate = index);
          _generatePdf();
        },
      ),
    );
  }
}
