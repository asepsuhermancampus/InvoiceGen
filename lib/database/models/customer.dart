import 'package:isar/isar.dart';

part 'customer.g.dart';

@collection
class Customer {
  Id id = Isar.autoIncrement;

  String? name;
  String? companyName;
  String? address;
  String? city;
  String? phone;
  String? email;
  String? pic;
  String? notes;
}
