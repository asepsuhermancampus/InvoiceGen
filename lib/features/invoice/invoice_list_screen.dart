import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/database_providers.dart';
import '../../database/models/invoice.dart';
import 'invoice_form_screen.dart';
import 'invoice_preview_screen.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  List<Invoice> _invoices = [];
  String _filter = 'Semua'; // Semua, Draft, Sent, Paid
  bool _loading = true;

  final _filters = ['Semua', 'Draft', 'Sent', 'Paid'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final invoices = await ref.read(invoiceRepositoryProvider).getAllInvoices();
    setState(() {
      _invoices = invoices;
      _loading = false;
    });
  }

  List<Invoice> get _filtered {
    if (_filter == 'Semua') return _invoices;
    return _invoices.where((i) => (i.status ?? 'Draft') == _filter).toList();
  }

  Future<void> _delete(Invoice inv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Invoice?'),
        content: Text('Invoice "${inv.invoiceNumber}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(invoiceRepositoryProvider).deleteInvoice(inv.id);
      _load();
    }
  }

  Future<void> _duplicate(Invoice inv) async {
    await ref.read(invoiceRepositoryProvider).duplicateInvoice(inv.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice berhasil digandakan!'), backgroundColor: Colors.green),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Invoice'),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            height: 50,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              )).toList(),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            Text(_filter == 'Semua' ? 'Belum ada invoice' : 'Tidak ada invoice $_filter'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final inv = items[i];
                            return _invoiceCard(inv, currency, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _invoiceCard(Invoice inv, NumberFormat currency, ThemeData theme) {
    final statusColor = inv.status == 'Paid' ? Colors.green : inv.status == 'Sent' ? Colors.orange : Colors.blueGrey;
    final docIcon = _docIcon(inv.documentType);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => InvoicePreviewScreen(invoice: inv),
          ));
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left icon
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(docIcon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              // Middle content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(inv.invoiceNumber ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(inv.status ?? 'Draft', style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inv.documentType ?? 'Invoice',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                    ),
                    Text(
                      inv.date != null ? DateFormat('dd MMM yyyy').format(inv.date!) : '-',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              // Right: Amount + actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(inv.grandTotal ?? 0),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => _duplicate(inv),
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy, size: 16, color: Colors.blue)),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => InvoiceFormScreen(invoice: inv),
                          ));
                          _load();
                        },
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.edit, size: 16, color: Colors.orange)),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => _delete(inv),
                        child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 16, color: Colors.red)),
                      ),
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _docIcon(String? type) {
    switch (type) {
      case 'Penawaran Harga': return Icons.handshake_outlined;
      case 'Quotation': return Icons.request_quote_outlined;
      case 'Proforma Invoice': return Icons.assignment_outlined;
      default: return Icons.receipt_long_outlined;
    }
  }
}
