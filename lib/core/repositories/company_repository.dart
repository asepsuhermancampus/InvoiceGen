import 'package:isar/isar.dart';
import '../../database/models/company.dart';

class CompanyRepository {
  Isar get _isar => Isar.getInstance()!;

  Future<void> saveCompany(Company company) async {
    await _isar.writeTxn(() async {
      await _isar.companys.put(company);
    });
  }

  Future<List<Company>> getAllCompanies() async {
    return await _isar.companys.where().findAll();
  }

  Future<void> deleteCompany(int id) async {
    await _isar.writeTxn(() async {
      await _isar.companys.delete(id);
    });
  }

  Future<Company?> getDefaultCompany() async {
    return await _isar.companys.filter().isDefaultEqualTo(true).findFirst();
  }
}
