import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

import 'core/theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'database/models/company.dart';
import 'database/models/customer.dart';
import 'database/models/invoice.dart';
import 'database/models/template.dart';
import 'database/models/settings.dart';
import 'database/models/history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await _initIsar();
  runApp(
    const ProviderScope(
      child: InvoiceGeneratorApp(),
    ),
  );
}

Future<void> _initIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  final appDir = Directory('${dir.path}/Invoice Generator');
  if (!await appDir.exists()) {
    await appDir.create(recursive: true);
  }

  if (Isar.instanceNames.isEmpty) {
    await Isar.open(
      [
        CompanySchema,
        CustomerSchema,
        InvoiceSchema,
        TemplateSchema,
        SettingsSchema,
        HistorySchema,
      ],
      directory: appDir.path,
    );
  }
}

class InvoiceGeneratorApp extends ConsumerWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Inv Gen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
