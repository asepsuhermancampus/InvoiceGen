import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_providers.dart';
import '../../database/models/template.dart';
import '../../core/pdf_engine/template_models.dart';
import '../builder/template_builder_screen.dart';

class TemplateListScreen extends ConsumerStatefulWidget {
  const TemplateListScreen({super.key});

  @override
  ConsumerState<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends ConsumerState<TemplateListScreen> {
  List<Template> _customTemplates = [];
  bool _loading = true;

  // Built-in template definitions
  static const _builtins = [
    {'name': 'Classic Navy', 'desc': 'Header navy, tabel profesional, cocok untuk semua industri', 'color': Color(0xFF1A237E), 'icon': Icons.business_center},
    {'name': 'Modern Teal', 'desc': 'Tampilan minimalis dengan aksen teal, kesan modern', 'color': Color(0xFF00695C), 'icon': Icons.design_services},
    {'name': 'Corporate Orange', 'desc': 'Bold orange header, kesan energik dan korporat', 'color': Color(0xFFE65100), 'icon': Icons.corporate_fare},
    {'name': 'Clean Elegant', 'desc': 'Garis tipis, tipografi besar, sangat elegan', 'color': Color(0xFF424242), 'icon': Icons.auto_awesome},
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await ref.read(templateRepositoryProvider).getAllTemplates();
    setState(() {
      _customTemplates = templates;
      _loading = false;
    });
  }

  Future<void> _deleteCustomTemplate(Template t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Template?'),
        content: Text('Template "${t.name}" akan dihapus permanen.'),
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
      await ref.read(templateRepositoryProvider).deleteTemplate(t.id);
      _loadTemplates();
    }
  }

  Future<void> _openBuilder({Template? existing}) async {
    final initialLayout = existing?.jsonStructure != null
        ? TemplateLayout.fromJsonString(existing!.jsonStructure!)
        : _emptyLayout();

    final result = await Navigator.push<TemplateLayout>(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateBuilderScreen(
          initialLayout: initialLayout,
          templateName: existing?.name ?? 'Template Baru',
        ),
      ),
    );

    if (result != null && mounted) {
      // Save to DB
      final t = existing ?? Template();
      if (t.name == null || t.name!.isEmpty) {
        // Ask for name
        final name = await _askName();
        if (name == null || name.isEmpty) return;
        t.name = name;
      }
      t.jsonStructure = result.toJsonString();
      t.isCustom = true;
      await ref.read(templateRepositoryProvider).saveTemplate(t);
      _loadTemplates();
    }
  }

  Future<String?> _askName() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nama Template'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Contoh: Template Kantor'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Simpan')),
        ],
      ),
    );
  }

  TemplateLayout _emptyLayout() {
    return TemplateLayout(sections: [
      TemplateSection(
        id: 'main',
        type: 'custom',
        elements: [
          TemplateElement(id: 'company', type: 'text', x: 40, y: 30, content: '{{company_name}}', fontSize: 18, isBold: true),
          TemplateElement(id: 'address', type: 'text', x: 40, y: 55, content: '{{company_address}}\nTel: {{company_phone}}', fontSize: 9),
          TemplateElement(id: 'doc_type', type: 'text', x: 380, y: 30, content: '{{document_type}}', fontSize: 24, isBold: true),
          TemplateElement(id: 'inv_no', type: 'text', x: 380, y: 65, content: 'No: {{invoice_number}}\nTgl: {{invoice_date}}', fontSize: 9),
          TemplateElement(id: 'customer', type: 'text', x: 40, y: 130, content: 'Kepada:\n{{customer_name}}\n{{customer_address}}', fontSize: 10),
          TemplateElement(id: 'table', type: 'table', x: 40, y: 220, width: 515, height: 300),
          TemplateElement(id: 'grand_total', type: 'text', x: 350, y: 540, content: 'Total: {{grand_total}}', fontSize: 14, isBold: true),
          TemplateElement(id: 'terbilang', type: 'text', x: 40, y: 570, content: 'Terbilang: {{terbilang}}', fontSize: 9, isItalic: true),
        ],
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Template')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Built-in Templates ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Template Bawaan', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                ..._builtins.asMap().entries.map((entry) {
                  final i = entry.key;
                  final t = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (t['color'] as Color).withValues(alpha: 0.15),
                        child: Icon(t['icon'] as IconData, color: t['color'] as Color),
                      ),
                      title: Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(t['desc'] as String, style: const TextStyle(fontSize: 12)),
                      trailing: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: t['color'] as Color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // ── Custom Templates ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Template Custom (${_customTemplates.length}/3)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (_customTemplates.length < 3)
                      FilledButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Buat Baru'),
                        onPressed: () => _openBuilder(),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_customTemplates.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.post_add, size: 56, color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text('Belum ada template custom', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 6),
                          Text('Anda bisa membuat maksimal 3 template custom dengan drag & drop builder.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.design_services),
                            label: const Text('Buka Template Builder'),
                            onPressed: () => _openBuilder(),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._customTemplates.map((t) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.draw, color: theme.colorScheme.primary),
                      ),
                      title: Text(t.name ?? 'Template Custom', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Template buatan sendiri'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: () => _openBuilder(existing: t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            tooltip: 'Hapus',
                            onPressed: () => _deleteCustomTemplate(t),
                          ),
                        ],
                      ),
                    ),
                  )),

                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
