import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../database/models/invoice.dart';
import '../../database/models/customer.dart';
import '../../database/models/company.dart';
import '../../database/models/template.dart';
import '../../core/providers/database_providers.dart';
import '../../services/calculation_service.dart';

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final Invoice? invoice;
  const InvoiceFormScreen({super.key, this.invoice});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _invoiceNumberController;
  late TextEditingController _notesController;
  late TextEditingController _introTextController;
  late TextEditingController _paymentTermsController;
  late TextEditingController _signatorNameController;
  
  DateTime _selectedDate = DateTime.now();
  
  Customer? _selectedCustomer;
  Company? _selectedCompany;
  Template? _selectedTemplate;
  String _docType = 'Invoice';
  String _status = 'Draft';
  String _currency = 'IDR';
  
  bool _hideSubtotal = false;
  bool _hideTax = false;
  
  List<InvoiceItem> _items = [];
  
  double _taxRate = 11.0;
  double _pphRate = 0.0;
  
  // Totals
  double _subtotal = 0;
  double _discountTotal = 0;
  double _taxTotal = 0;
  double _grandTotal = 0;
  String _terbilang = '';

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.invoice?.notes ?? '');
    _introTextController = TextEditingController(text: widget.invoice?.introText ?? '');
    _paymentTermsController = TextEditingController(text: widget.invoice?.paymentTerms ?? '');
    _signatorNameController = TextEditingController(text: widget.invoice?.signatorName ?? '');
    
    if (widget.invoice != null) {
      _invoiceNumberController = TextEditingController(text: widget.invoice!.invoiceNumber ?? '');
      _selectedDate = widget.invoice!.date ?? DateTime.now();
      _selectedCustomer = widget.invoice!.customer.value;
      _selectedCompany = widget.invoice!.company.value;
      _selectedTemplate = widget.invoice!.template.value;
      _docType = widget.invoice!.documentType ?? 'Invoice';
      _status = widget.invoice!.status ?? 'Draft';
      _currency = widget.invoice!.currency ?? 'IDR';
      _items = List.from(widget.invoice!.items);
      _taxRate = widget.invoice!.taxRate ?? 11.0;
      _pphRate = widget.invoice!.pphRate ?? 0.0;
      _hideSubtotal = widget.invoice!.hideSubtotal;
      _hideTax = widget.invoice!.hideTax;
      _recalculateTotals();
    } else {
      final prefix = _getPrefixForType(_docType);
      final ts = DateTime.now();
      _invoiceNumberController = TextEditingController(
        text: '$prefix-${ts.year}${ts.month.toString().padLeft(2,'0')}${ts.day.toString().padLeft(2,'0')}-001',
      );
    }
  }

  String _getPrefixForType(String type) {
    switch (type) {
      case 'Penawaran Harga': return 'PH';
      case 'Quotation': return 'QT';
      case 'Proforma Invoice': return 'PI';
      default: return 'INV';
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _introTextController.dispose();
    _paymentTermsController.dispose();
    _signatorNameController.dispose();
    super.dispose();
  }

  void _recalculateTotals() {
    final totals = CalculationService.calculateInvoiceTotals(
      items: _items.map((i) => {
        'qty': i.qty ?? 0,
        'sellingPrice': i.sellingPrice ?? 0,
        'discount': i.discount ?? 0,
      }).toList(),
      taxRate: _taxRate,
      pphRate: _pphRate,
    );

    setState(() {
      _subtotal = totals['subtotal'] ?? 0;
      _discountTotal = totals['discountTotal'] ?? 0;
      _taxTotal = totals['taxTotal'] ?? 0;
      _grandTotal = totals['grandTotal'] ?? 0;
      _terbilang = '${CalculationService.terbilang(_grandTotal)} Rupiah';
    });
  }

  void _addItem() {
    // Show a dialog to add an item
    showDialog(context: context, builder: (_) => _AddItemDialog(
      onAdd: (item) {
        setState(() {
          _items.add(item);
          _recalculateTotals();
        });
      },
    ));
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCompany == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Company')));
        return;
      }

      final repo = ref.read(invoiceRepositoryProvider);
      final newInvoice = widget.invoice ?? Invoice();
      
      newInvoice.invoiceNumber = _invoiceNumberController.text;
      newInvoice.date = _selectedDate;
      newInvoice.documentType = _docType;
      newInvoice.status = _status;
      newInvoice.currency = _currency;
      newInvoice.taxRate = _taxRate;
      newInvoice.pphRate = _pphRate;
      newInvoice.notes = _notesController.text;
      newInvoice.introText = _introTextController.text;
      newInvoice.paymentTerms = _paymentTermsController.text;
      newInvoice.signatorName = _signatorNameController.text;
      newInvoice.hideSubtotal = _hideSubtotal;
      newInvoice.hideTax = _hideTax;
      
      newInvoice.subtotal = _subtotal;
      newInvoice.discountTotal = _discountTotal;
      newInvoice.taxTotal = _taxTotal;
      newInvoice.grandTotal = _grandTotal;
      newInvoice.terbilang = _terbilang;
      newInvoice.items = _items;

      newInvoice.company.value = _selectedCompany;
      newInvoice.customer.value = _selectedCustomer;
      if (_selectedTemplate != null) {
        newInvoice.template.value = _selectedTemplate;
      }
      
      await repo.saveInvoice(newInvoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'Buat Invoice' : 'Edit Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Document Type ─────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _docType,
              decoration: const InputDecoration(labelText: 'Jenis Dokumen', prefixIcon: Icon(Icons.description)),
              items: const [
                DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
                DropdownMenuItem(value: 'Penawaran Harga', child: Text('Penawaran Harga')),
                DropdownMenuItem(value: 'Quotation', child: Text('Quotation')),
                DropdownMenuItem(value: 'Proforma Invoice', child: Text('Proforma Invoice')),
              ],
              onChanged: (val) => setState(() => _docType = val ?? 'Invoice'),
            ),
            const SizedBox(height: 12),
            // ── Company & Customer ────────────────────────────────
            _buildCompanySelector(),
            const SizedBox(height: 12),
            _buildCustomerSelector(),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(labelText: 'Nomor Invoice'),
                    validator: (val) => val != null && val.isEmpty ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Tanggal Invoice'),
                      child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _introTextController,
              decoration: const InputDecoration(
                labelText: 'Teks Pembuka (Opsional)', 
                hintText: 'Cth: Dengan Hormat,\nBersama dengan ini kami berikan penawaran harga sebagai berikut :',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items', style: Theme.of(context).textTheme.titleLarge),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item'),
                )
              ],
            ),
            const Divider(),
            ..._items.map((item) => ListTile(
              title: Text(item.itemName ?? ''),
              subtitle: Text('${item.qty} x ${currencyFormat.format(item.sellingPrice)}'),
              trailing: Text(currencyFormat.format((item.qty ?? 0) * (item.sellingPrice ?? 0))),
            )),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada item ditambahkan.'),
              ),
              
            const Divider(),
            
            // Tax & Totals
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _taxRate.toString(),
                    decoration: const InputDecoration(labelText: 'PPN (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _taxRate = double.tryParse(val) ?? 0;
                      _recalculateTotals();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _pphRate.toString(),
                    decoration: const InputDecoration(labelText: 'PPH (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _pphRate = double.tryParse(val) ?? 0;
                      _recalculateTotals();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Sembunyikan Subtotal', style: TextStyle(fontSize: 12)),
                    value: _hideSubtotal,
                    onChanged: (val) => setState(() => _hideSubtotal = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Sembunyikan PPN', style: TextStyle(fontSize: 12)),
                    value: _hideTax,
                    onChanged: (val) => setState(() => _hideTax = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Text('Subtotal: ${currencyFormat.format(_subtotal)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Diskon: ${currencyFormat.format(_discountTotal)}'),
            Text('PPN: ${currencyFormat.format(_taxTotal)}'),
            Text('Total: ${currencyFormat.format(_grandTotal)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Terbilang: $_terbilang', style: const TextStyle(fontStyle: FontStyle.italic)),
            
            const SizedBox(height: 24),
            const Divider(),
            Text('Informasi Tambahan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Keterangan (Kiri)', alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paymentTermsController,
              decoration: const InputDecoration(labelText: 'Syarat Pembayaran (Tengah)', alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _signatorNameController,
              decoration: const InputDecoration(labelText: 'Nama Penandatangan (Kanan)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanySelector() {
    return FutureBuilder<List<Company>>(
      future: ref.read(companyRepositoryProvider).getAllCompanies(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return DropdownButtonFormField<Company>(
          initialValue: _selectedCompany,
          decoration: const InputDecoration(labelText: 'Pilih Company'),
          items: items.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? ''))).toList(),
          onChanged: (val) => setState(() => _selectedCompany = val),
        );
      }
    );
  }
  
  Widget _buildCustomerSelector() {
    return FutureBuilder<List<Customer>>(
      future: ref.read(customerRepositoryProvider).getAllCustomers(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final dropdownItems = [
          const DropdownMenuItem<Customer>(value: null, child: Text('Tidak Ada (Kosong)')),
          ...items.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? ''))),
        ];
        return DropdownButtonFormField<Customer>(
          initialValue: _selectedCustomer,
          decoration: const InputDecoration(labelText: 'Pilih Customer (Opsional)'),
          items: dropdownItems,
          onChanged: (val) => setState(() => _selectedCustomer = val),
        );
      }
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final Function(InvoiceItem) onAdd;
  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _costCtrl = TextEditingController(text: '0');
  final _markupCtrl = TextEditingController(text: '0');
  final _sellingCtrl = TextEditingController(text: '0');

  void _calculateSelling() {
    double cost = double.tryParse(_costCtrl.text) ?? 0;
    double markup = double.tryParse(_markupCtrl.text) ?? 0;
    double selling = cost + (cost * markup / 100);
    _sellingCtrl.text = selling.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Barang')),
            const SizedBox(height: 8),
            TextField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(
              controller: _costCtrl, 
              decoration: const InputDecoration(labelText: 'Harga Modal'), 
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateSelling(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _markupCtrl, 
              decoration: const InputDecoration(labelText: 'Markup (%)'), 
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateSelling(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sellingCtrl, 
              decoration: const InputDecoration(labelText: 'Harga Jual'), 
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final item = InvoiceItem()
              ..itemName = _nameCtrl.text
              ..qty = double.tryParse(_qtyCtrl.text) ?? 1
              ..costPrice = double.tryParse(_costCtrl.text) ?? 0
              ..markupPercentage = double.tryParse(_markupCtrl.text) ?? 0
              ..sellingPrice = double.tryParse(_sellingCtrl.text) ?? 0;
            widget.onAdd(item);
            Navigator.pop(context);
          },
          child: const Text('Tambah'),
        )
      ],
    );
  }
}
