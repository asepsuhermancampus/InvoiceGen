import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_providers.dart';
import '../../database/models/company.dart';
import '../../database/models/settings.dart';
import '../company/company_form_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Settings? _settings;
  List<Company> _companies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final companyRepo = ref.read(companyRepositoryProvider);
    final s = await settingsRepo.getSettings();
    final c = await companyRepo.getAllCompanies();
    setState(() {
      _settings = s;
      _companies = c;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;
    await ref.read(settingsRepositoryProvider).saveSettings(_settings!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan tersimpan!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Company Section ──────────────────────────────────────
                _sectionHeader('Informasi Perusahaan', theme),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      if (_companies.isEmpty)
                        ListTile(
                          leading: const Icon(Icons.business_outlined),
                          title: const Text('Belum ada data perusahaan'),
                          subtitle: const Text('Tambahkan perusahaan terlebih dahulu'),
                          trailing: FilledButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah'),
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyFormScreen()));
                              _loadData();
                            },
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Perusahaan Default'),
                            initialValue: _settings?.defaultCompanyId,
                            items: _companies.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name ?? ''),
                            )).toList(),
                            onChanged: (val) => setState(() => _settings!.defaultCompanyId = val),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.add_business),
                          title: const Text('Tambah Perusahaan Baru'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyFormScreen()));
                            _loadData();
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Invoice Number Prefix ─────────────────────────────────
                _sectionHeader('Penomoran Invoice', theme),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _settings?.invoicePrefix ?? 'INV',
                          decoration: const InputDecoration(
                            labelText: 'Prefix Invoice',
                            hintText: 'Contoh: INV / QUOT / PO',
                          ),
                          onChanged: (val) => _settings?.invoicePrefix = val,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _settings?.quotationPrefix ?? 'QUOT',
                          decoration: const InputDecoration(
                            labelText: 'Prefix Quotation / Penawaran',
                          ),
                          onChanged: (val) => _settings?.quotationPrefix = val,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _settings?.proformaPrefix ?? 'PROF',
                          decoration: const InputDecoration(
                            labelText: 'Prefix Proforma Invoice',
                          ),
                          onChanged: (val) => _settings?.proformaPrefix = val,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tax Settings ──────────────────────────────────────────
                _sectionHeader('Pengaturan Pajak Default', theme),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: (_settings?.defaultTaxRate ?? 11).toString(),
                                decoration: const InputDecoration(labelText: 'PPN Default (%)'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => _settings?.defaultTaxRate = double.tryParse(val) ?? 11,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: (_settings?.defaultPphRate ?? 0).toString(),
                                decoration: const InputDecoration(labelText: 'PPH Default (%)'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => _settings?.defaultPphRate = double.tryParse(val) ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text('Tampilkan PPN di PDF'),
                          subtitle: const Text('Jika off, PPN tidak ditampilkan di invoice'),
                          value: _settings?.showTaxInPdf ?? true,
                          onChanged: (val) => setState(() => _settings!.showTaxInPdf = val),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Currency ──────────────────────────────────────────────
                _sectionHeader('Mata Uang', theme),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Mata Uang Default'),
                      initialValue: _settings?.defaultCurrency ?? 'IDR',
                      items: const [
                        DropdownMenuItem(value: 'IDR', child: Text('IDR - Rupiah')),
                        DropdownMenuItem(value: 'USD', child: Text('USD - Dollar')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                        DropdownMenuItem(value: 'SGD', child: Text('SGD - Dollar Singapura')),
                        DropdownMenuItem(value: 'MYR', child: Text('MYR - Ringgit')),
                      ],
                      onChanged: (val) => setState(() => _settings!.defaultCurrency = val ?? 'IDR'),
                    ),
                  ),
                ),

                // ── Footer Text ───────────────────────────────────────────
                _sectionHeader('Catatan & Footer Default', theme),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: _settings?.defaultNotes ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Catatan Default',
                            hintText: 'Akan muncul di bagian bawah invoice',
                          ),
                          maxLines: 3,
                          onChanged: (val) => _settings?.defaultNotes = val,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _settings?.defaultFooter ?? 'Terima kasih atas kepercayaan Anda.',
                          decoration: const InputDecoration(labelText: 'Footer Default'),
                          maxLines: 2,
                          onChanged: (val) => _settings?.defaultFooter = val,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
