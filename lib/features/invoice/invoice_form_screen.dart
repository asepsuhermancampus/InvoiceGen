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
  
  List<Company> _companies = [];
  List<Customer> _customers = [];
  bool _isLoadingData = true;
  
  // Teks Pembuka
  static const String _kCustomIntro = '__custom__';
  String _selectedIntroKey = '';
  static final Map<String, String> _introTemplates = {
    'Penawaran Harga': 'Bersama dengan ini kami sampaikan penawaran harga untuk kebutuhan Anda. '
        'Kami berharap penawaran ini dapat memenuhi harapan Anda.',
    'Invoice': 'Berikut kami sampaikan tagihan atas pekerjaan/barang yang telah diselesaikan/dikirimkan. '
        'Mohon pembayaran dapat dilakukan sesuai dengan syarat pembayaran yang tercantum.',
    'Quotation': 'Thank you for the opportunity to quote. Please find our price quotation as follows. '
        'We hope to be of service to you.',
    'Proforma Invoice': 'Berikut kami sampaikan proforma invoice sebagai dasar pembayaran di muka '
        'sebelum pengiriman barang/jasa dilakukan.',
    'Kosong (Tanpa Teks)': '',
    'Custom': _kCustomIntro,
  };

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
    
    // Set initial dropdown selection for intro text
    final existingIntro = widget.invoice?.introText ?? '';
    if (existingIntro.isEmpty) {
      _selectedIntroKey = 'Kosong (Tanpa Teks)';
    } else {
      final matchedKey = _introTemplates.entries
          .where((e) => e.value == existingIntro && e.value != _kCustomIntro)
          .map((e) => e.key)
          .firstOrNull;
      _selectedIntroKey = matchedKey ?? 'Custom';
      if (_selectedIntroKey == 'Custom') {
        _introTextController.text = existingIntro;
      }
    }
    
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
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final companies = await ref.read(companyRepositoryProvider).getAllCompanies();
    final customers = await ref.read(customerRepositoryProvider).getAllCustomers();
    
    if (mounted) {
      setState(() {
        _companies = companies;
        _customers = customers;
        
        // Find matching references from the loaded list to avoid identity mismatch in dropdowns
        if (_selectedCompany != null) {
          _selectedCompany = _companies.where((c) => c.id == _selectedCompany!.id).firstOrNull ?? _selectedCompany;
        } else {
          _selectedCompany = _companies.where((c) => c.isDefault).firstOrNull;
        }

        if (_selectedCustomer != null) {
          _selectedCustomer = _customers.where((c) => c.id == _selectedCustomer!.id).firstOrNull ?? _selectedCustomer;
        }
        
        _isLoadingData = false;
      });
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
    showDialog(context: context, builder: (_) => _ItemDialog(
      onSave: (item) {
        setState(() {
          _items.add(item);
          _recalculateTotals();
        });
      },
    ));
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (_) => _ItemDialog(
        existing: _items[index],
        onSave: (updatedItem) {
          setState(() {
            _items[index] = updatedItem;
            _recalculateTotals();
          });
        },
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: Text('Apakah Anda yakin ingin menghapus "${_items[index].itemName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _items.removeAt(index);
                _recalculateTotals();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      // Save the intro text from controller (which is always kept in sync)
      newInvoice.introText = (_selectedIntroKey == 'Kosong (Tanpa Teks)') ? '' : _introTextController.text;
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
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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

            // ── Teks Pembuka ───────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _selectedIntroKey.isEmpty ? null : _selectedIntroKey,
              decoration: const InputDecoration(
                labelText: 'Teks Pembuka',
                prefixIcon: Icon(Icons.short_text),
              ),
              items: _introTemplates.keys
                  .map((key) => DropdownMenuItem(value: key, child: Text(key)))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedIntroKey = val;
                  if (val != 'Custom') {
                    final tplValue = _introTemplates[val] ?? '';
                    _introTextController.text = tplValue == _kCustomIntro ? '' : tplValue;
                  }
                });
              },
            ),
            if (_selectedIntroKey == 'Custom') ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _introTextController,
                decoration: const InputDecoration(
                  labelText: 'Teks Pembuka (Custom)',
                  hintText: 'Tulis teks pembuka Anda di sini...',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
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
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('Belum ada item ditambahkan.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final total = (item.qty ?? 0) * (item.sellingPrice ?? 0);
                  final qtyDisplay = (item.qty ?? 0).toInt();
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    title: Text(item.itemName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('$qtyDisplay ${item.unit ?? ''} x ${currencyFormat.format(item.sellingPrice)}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currencyFormat.format(total),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Item',
                          onPressed: () => _editItem(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          tooltip: 'Hapus Item',
                          onPressed: () => _deleteItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
            const Divider(),
            
            // Tax & Totals
            TextFormField(
              initialValue: _taxRate.toString(),
              decoration: const InputDecoration(labelText: 'PPN (%)'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                _taxRate = double.tryParse(val) ?? 0;
                _recalculateTotals();
              },
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
    return DropdownButtonFormField<Company>(
      initialValue: _selectedCompany,
      decoration: const InputDecoration(labelText: 'Pilih Company'),
      items: _companies.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? ''))).toList(),
      onChanged: (val) => setState(() => _selectedCompany = val),
    );
  }
  
  Widget _buildCustomerSelector() {
    return DropdownButtonFormField<Customer?>(
      initialValue: _selectedCustomer,
      decoration: const InputDecoration(labelText: 'Pilih Customer (Opsional)'),
      items: [
        const DropdownMenuItem<Customer?>(value: null, child: Text('Tidak Ada (Kosong)')),
        ..._customers.map((c) => DropdownMenuItem<Customer?>(value: c, child: Text(c.name ?? ''))),
      ],
      onChanged: (val) {
        setState(() {
          _selectedCustomer = val;
        });
      },
    );
  }
}

class _ItemDialog extends StatefulWidget {
  final InvoiceItem? existing;
  final Function(InvoiceItem) onSave;
  const _ItemDialog({this.existing, required this.onSave});

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  static const _satuanList = [
    'Pcs', 'Unit', 'Set', 'Psg', 'Lbr', 'Pack', 'Box', 'Dus', 'Roll', 'Sak', 
    'Lusin', 'Kg', 'Ons', 'Ton', 'Mm', 'Cm', 'M', 'Mtr', 'Km', 'Inch'
  ];

  late TextEditingController _nameCtrl;
  late TextEditingController _specCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _markupCtrl;
  late TextEditingController _sellingCtrl;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.itemName ?? '');
    _specCtrl = TextEditingController(text: e?.specification ?? '');
    _qtyCtrl = TextEditingController(text: e != null ? (e.qty ?? 1).toInt().toString() : '1');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _costCtrl = TextEditingController(text: e != null ? (e.costPrice ?? 0).toStringAsFixed(0) : '0');
    _markupCtrl = TextEditingController(text: e != null ? (e.markupPercentage ?? 0).toStringAsFixed(0) : '0');
    _sellingCtrl = TextEditingController(text: e != null ? (e.sellingPrice ?? 0).toStringAsFixed(0) : '0');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _specCtrl.dispose(); _qtyCtrl.dispose();
    _unitCtrl.dispose(); _costCtrl.dispose(); _markupCtrl.dispose();
    _sellingCtrl.dispose();
    super.dispose();
  }

  void _calculateSelling() {
    double cost = double.tryParse(_costCtrl.text) ?? 0;
    double markup = double.tryParse(_markupCtrl.text) ?? 0;
    double selling = cost + (cost * markup / 100);
    setState(() => _sellingCtrl.text = selling.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Item' : 'Tambah Item'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Barang')),
              const SizedBox(height: 8),
              TextField(controller: _specCtrl, decoration: const InputDecoration(labelText: 'Spesifikasi (Opsional)')),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _satuanList.contains(_unitCtrl.text) ? _unitCtrl.text : (_satuanList.isNotEmpty ? _satuanList.first : null),
                    decoration: const InputDecoration(labelText: 'Satuan'),
                    items: _satuanList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) _unitCtrl.text = val;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () {
            final item = (widget.existing ?? InvoiceItem())
              ..itemName = _nameCtrl.text
              ..specification = _specCtrl.text
              ..qty = double.tryParse(_qtyCtrl.text) ?? 1
              ..unit = _unitCtrl.text
              ..costPrice = double.tryParse(_costCtrl.text) ?? 0
              ..markupPercentage = double.tryParse(_markupCtrl.text) ?? 0
              ..sellingPrice = double.tryParse(_sellingCtrl.text) ?? 0;
            widget.onSave(item);
            Navigator.pop(context);
          },
          child: Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
