import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/models/company.dart';
import '../../core/providers/database_providers.dart';

class CompanyFormScreen extends ConsumerStatefulWidget {
  final Company? company;
  const CompanyFormScreen({super.key, this.company});

  @override
  ConsumerState<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends ConsumerState<CompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _branchController;
  late TextEditingController _sloganController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name);
    _branchController = TextEditingController(text: widget.company?.branchName);
    _sloganController = TextEditingController(text: widget.company?.slogan);
    _addressController = TextEditingController(text: widget.company?.address);
    _phoneController = TextEditingController(text: widget.company?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _sloganController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(companyRepositoryProvider);
      final newCompany = widget.company ?? Company();
      newCompany.name = _nameController.text;
      newCompany.branchName = _branchController.text;
      newCompany.slogan = _sloganController.text;
      newCompany.address = _addressController.text;
      newCompany.phone = _phoneController.text;
      
      await repo.saveCompany(newCompany);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.company == null ? 'Tambah Company' : 'Edit Company'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Perusahaan *'),
              validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sloganController,
              decoration: const InputDecoration(labelText: 'Tagline/Slogan (Opsional)'),
            ),
            const SizedBox(height: 12),
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(labelText: 'Cabang (Opsional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telepon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
