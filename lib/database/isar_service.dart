import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'models/company.dart';
import 'models/customer.dart';
import 'models/invoice.dart';
import 'models/template.dart';
import 'models/settings.dart';
import 'models/history.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      // App custom directory for saving everything inside
      final appDir = Directory('${dir.path}/Invoice Generator');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }

      return await Isar.open(
        [
          CompanySchema,
          CustomerSchema,
          InvoiceSchema,
          TemplateSchema,
          SettingsSchema,
          HistorySchema,
        ],
        directory: appDir.path,
        inspector: true,
      );
    }

    return Future.value(Isar.getInstance());
  }
}
