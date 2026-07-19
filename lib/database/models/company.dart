import 'package:isar/isar.dart';

part 'company.g.dart';

@collection
class Company {
  Id id = Isar.autoIncrement;

  String? logoPath;
  String? name;
  String? branchName;
  String? address;
  String? city;
  String? province;
  String? postalCode;
  String? phone;
  String? fax;
  String? whatsapp;
  String? email;
  String? website;
  String? npwp;
  String? bankName;
  String? bankAccount;
  String? accountName;
  String? slogan;

  bool isDefault = false;
}
