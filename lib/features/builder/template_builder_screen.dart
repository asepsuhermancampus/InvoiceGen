import 'package:flutter/material.dart';
import '../../core/pdf_engine/template_models.dart';

class TemplateBuilderScreen extends StatefulWidget {
  final TemplateLayout initialLayout;
  final String templateName;
  const TemplateBuilderScreen({
    super.key,
    required this.initialLayout,
    required this.templateName,
  });

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  late TemplateLayout _layout;
  TemplateElement? _selectedElement;

  @override
  void initState() {
    super.initState();
    _layout = TemplateLayout.fromJsonString(widget.initialLayout.toJsonString());
  }

  void _onElementTap(TemplateElement el) {
    setState(() {
      _selectedElement = el;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Builder: ${widget.templateName}'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Simpan', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, _layout),
          )
        ],
      ),
      body: Row(
        children: [
          // LEFT: Toolbox + Properties
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(2, 0))],
            ),
            child: Column(
              children: [
                // Add Element buttons
                Container(
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tambah Elemen', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _toolButton(Icons.text_fields, 'Teks', () => _addElement('text')),
                          _toolButton(Icons.table_chart, 'Tabel', () => _addElement('table')),
                          _toolButton(Icons.image, 'Gambar', () => _addElement('image')),
                          _toolButton(Icons.horizontal_rule, 'Garis', () => _addElement('line')),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Properties
                Expanded(child: _buildPropertyEditor(theme)),
              ],
            ),
          ),

          // RIGHT: Canvas
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: _layout.pageWidth,
                  height: _layout.pageHeight,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black26)],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: _layout.sections.expand((section) {
                      return section.elements.map((el) => _buildDraggableElement(el));
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 14), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 12))],
        ),
      ),
    );
  }

  void _addElement(String type) {
    if (_layout.sections.isEmpty) {
      _layout.sections.add(TemplateSection(id: 'main', type: 'custom', elements: []));
    }
    final el = TemplateElement(
      id: 'el_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      x: 40,
      y: 40 + (_layout.sections.first.elements.length * 30).toDouble(),
      content: type == 'text' ? 'Teks baru' : '',
      width: type == 'table' ? 500 : 200,
      height: type == 'table' ? 200 : 40,
    );
    setState(() {
      _layout.sections.first.elements.add(el);
      _selectedElement = el;
    });
  }

  Widget _buildDraggableElement(TemplateElement el) {
    final isSelected = _selectedElement?.id == el.id;
    Widget child;

    if (el.type == 'text') {
      child = Text(
        el.content.isEmpty ? '(Teks kosong)' : el.content,
        style: TextStyle(
          fontSize: el.fontSize,
          fontWeight: el.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: el.isItalic ? FontStyle.italic : FontStyle.normal,
          color: _parseColor(el.colorHex),
        ),
      );
    } else if (el.type == 'table') {
      child = Container(
        width: el.width,
        height: el.height,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
        child: const Center(child: Text('[ Tabel Item Invoice ]', style: TextStyle(color: Colors.grey))),
      );
    } else if (el.type == 'image') {
      child = Container(
        width: el.width,
        height: el.height,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
      );
    } else if (el.type == 'line') {
      child = Container(width: el.width, height: 1, color: _parseColor(el.colorHex));
    } else {
      child = const SizedBox();
    }

    return Positioned(
      left: el.x,
      top: el.y,
      child: GestureDetector(
        onTap: () => _onElementTap(el),
        onPanUpdate: (details) {
          setState(() {
            el.x += details.delta.dx;
            el.y += details.delta.dy;
          });
        },
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  color: Colors.blue.withValues(alpha: 0.05),
                )
              : null,
          child: child,
        ),
      ),
    );
  }

  Widget _buildPropertyEditor(ThemeData theme) {
    if (_selectedElement == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, size: 48, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 8),
              Text('Tap elemen di canvas untuk mengeditnya', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      );
    }

    final el = _selectedElement!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(el.type.toUpperCase(), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  for (var s in _layout.sections) {
                    s.elements.removeWhere((e) => e.id == el.id);
                  }
                  _selectedElement = null;
                });
              },
            ),
          ],
        ),
        const Divider(),
        if (el.type == 'text') ...[
          _label('Konten / Placeholder'),
          TextField(
            key: ValueKey(el.id),
            controller: TextEditingController(text: el.content),
            decoration: const InputDecoration(
              hintText: 'Contoh: {{company_name}}',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (val) => setState(() => el.content = val),
          ),
          const SizedBox(height: 12),
          _label('Ukuran Font'),
          Slider(
            value: el.fontSize.clamp(6, 40),
            min: 6, max: 40,
            divisions: 34,
            label: el.fontSize.toStringAsFixed(0),
            onChanged: (val) => setState(() => el.fontSize = val),
          ),
          Row(
            children: [
              FilterChip(
                label: const Text('Bold'),
                selected: el.isBold,
                onSelected: (val) => setState(() => el.isBold = val),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Italic'),
                selected: el.isItalic,
                onSelected: (val) => setState(() => el.isItalic = val),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _label('Placeholder Tersedia'),
        _placeholderChips(el),
        const Divider(),
        _label('Posisi (X, Y)'),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'X', isDense: true, border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: el.x.toStringAsFixed(0)),
                onSubmitted: (val) => setState(() => el.x = double.tryParse(val) ?? el.x),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Y', isDense: true, border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: el.y.toStringAsFixed(0)),
                onSubmitted: (val) => setState(() => el.y = double.tryParse(val) ?? el.y),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
  );

  Widget _placeholderChips(TemplateElement el) {
    const placeholders = [
      '{{company_name}}', '{{company_address}}', '{{company_phone}}',
      '{{customer_name}}', '{{customer_address}}',
      '{{invoice_number}}', '{{invoice_date}}', '{{document_type}}',
      '{{subtotal}}', '{{discount}}', '{{tax}}', '{{grand_total}}', '{{terbilang}}',
    ];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: placeholders.map((p) => GestureDetector(
        onTap: () => setState(() => el.content = '${el.content}$p'),
        child: Chip(
          label: Text(p, style: const TextStyle(fontSize: 9)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      )).toList(),
    );
  }

  Color _parseColor(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.black;
    }
  }
}
