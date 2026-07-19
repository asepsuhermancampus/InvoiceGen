import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/company_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/template_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/history_repository.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});
