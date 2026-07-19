import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_providers.dart';
import '../../database/models/customer.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  List<Customer> _customers = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final customers = await ref.read(customerRepositoryProvider).getAllCustomers();
    setState(() {
      _customers = customers;
      _loading = false;
    });
  }

  List<Customer> get _filtered {
    if (_search.isEmpty) return _customers;
    return _customers.where((c) =>
        (c.name ?? '').toLowerCase().contains(_search.toLowerCase()) ||
        (c.companyName ?? '').toLowerCase().contains(_search.toLowerCase())).toList();
  }

  Future<void> _delete(Customer c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Customer?'),
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
      await ref.read(customerRepositoryProvider).deleteCustomer(c.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Customer'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama / perusahaan...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      Text(_search.isEmpty ? 'Belum ada data customer' : 'Tidak ada hasil untuk "$_search"'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final c = items[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE0F2F1),
                            child: Text(
                              (c.name ?? 'C').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((c.companyName ?? '').isNotEmpty)
                                Text(c.companyName!, style: const TextStyle(fontSize: 12)),
                              if ((c.address ?? '').isNotEmpty)
                                Text(c.address!, style: const TextStyle(fontSize: 11)),
                              if ((c.phone ?? '').isNotEmpty)
                                Text('Tel: ${c.phone}', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () async {
                                  await Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => CustomerFormScreen(customer: c),
                                  ));
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
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerFormScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
