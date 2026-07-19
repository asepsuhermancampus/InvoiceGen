import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_providers.dart';
import '../../database/models/company.dart';
import 'company_form_screen.dart';

class CompanyListScreen extends ConsumerStatefulWidget {
  const CompanyListScreen({super.key});

  @override
  ConsumerState<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends ConsumerState<CompanyListScreen> {
  List<Company> _companies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final companies = await ref.read(companyRepositoryProvider).getAllCompanies();
    setState(() {
      _companies = companies;
      _loading = false;
    });
  }

  Future<void> _delete(Company c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Perusahaan?'),
        content: Text('"${c.name}" akan dihapus permanen.'),
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
      await ref.read(companyRepositoryProvider).deleteCompany(c.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Perusahaan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _companies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_outlined, size: 64, color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      const Text('Belum ada data perusahaan'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Perusahaan'),
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyFormScreen()));
                          _load();
                        },
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _companies.length,
                    itemBuilder: (ctx, i) {
                      final c = _companies[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              (c.name ?? 'C').substring(0, 1).toUpperCase(),
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((c.branchName ?? '').isNotEmpty) Text(c.branchName!, style: const TextStyle(fontSize: 12)),
                              Text(c.address ?? '', style: const TextStyle(fontSize: 11)),
                              if ((c.phone ?? '').isNotEmpty) Text('Tel: ${c.phone}', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => CompanyFormScreen(company: c)));
                                  _load();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _delete(c),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyFormScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
