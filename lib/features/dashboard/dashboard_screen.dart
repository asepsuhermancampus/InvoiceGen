import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/database_providers.dart';
import '../../database/models/invoice.dart';
import '../company/company_list_screen.dart';
import '../customer/customer_list_screen.dart';
import '../invoice/invoice_list_screen.dart';
import '../invoice/invoice_form_screen.dart';
import '../template/template_list_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _totalInvoice = 0;
  int _totalCompany = 0;
  int _totalCustomer = 0;
  double _totalRevenue = 0;
  List<Invoice> _recentInvoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final invoiceRepo = ref.read(invoiceRepositoryProvider);
    final companyRepo = ref.read(companyRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);

    final invoices = await invoiceRepo.getAllInvoices();
    final companies = await companyRepo.getAllCompanies();
    final customers = await customerRepo.getAllCustomers();

    double revenue = 0;
    for (final inv in invoices) {
      revenue += inv.grandTotal ?? 0;
    }

    setState(() {
      _totalInvoice = invoices.length;
      _totalCompany = companies.length;
      _totalCustomer = customers.length;
      _totalRevenue = revenue;
      _recentInvoices = invoices.take(5).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Inv Gen', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              _loadStats();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Stats Row ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: _statCard('Invoice', '$_totalInvoice', Icons.receipt_long, theme.colorScheme.primary, theme)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('Customer', '$_totalCustomer', Icons.people, const Color(0xFF00695C), theme)),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard('Company', '$_totalCompany', Icons.business, const Color(0xFFE65100), theme)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Revenue card full width
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary, size: 36),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Nilai Invoice', style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12)),
                              Text(
                                currency.format(_totalRevenue),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Quick Actions ─────────────────────────────────────
                  Text('Aksi Cepat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _actionCard(context, Icons.add_circle_outline, 'Buat\nInvoice', theme.colorScheme.primary, () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));
                        _loadStats();
                      }),
                      _actionCard(context, Icons.list_alt, 'Daftar\nInvoice', const Color(0xFF1565C0), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen()));
                      }),
                      _actionCard(context, Icons.business, 'Daftar\nCompany', const Color(0xFF00695C), () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyListScreen()));
                        _loadStats();
                      }),
                      _actionCard(context, Icons.people, 'Daftar\nCustomer', const Color(0xFFE65100), () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()));
                        _loadStats();
                      }),
                      _actionCard(context, Icons.design_services, 'Template\nPDF', const Color(0xFF6A1B9A), () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateListScreen()));
                      }),
                      _actionCard(context, Icons.settings, 'Pengaturan', const Color(0xFF37474F), () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        _loadStats();
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Recent Invoices ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Invoice Terbaru', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(
                        child: const Text('Lihat Semua'),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceListScreen())),
                      ),
                    ],
                  ),
                  if (_recentInvoices.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 56, color: theme.colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            Text('Belum ada invoice', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 6),
                            Text('Tap tombol "Buat Invoice" untuk memulai', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentInvoices.map((inv) => _recentInvoiceCard(inv, currency, theme)),

                  const SizedBox(height: 24),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));
          _loadStats();
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Invoice'),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentInvoiceCard(Invoice inv, NumberFormat currency, ThemeData theme) {
    final statusColor = inv.status == 'Paid' ? Colors.green : inv.status == 'Sent' ? Colors.orange : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.receipt, color: theme.colorScheme.primary, size: 18),
        ),
        title: Text(inv.invoiceNumber ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          inv.date != null ? DateFormat('dd MMM yyyy').format(inv.date!) : '-',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(currency.format(inv.grandTotal ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(inv.status ?? 'Draft', style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
