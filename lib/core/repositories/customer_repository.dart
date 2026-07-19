import 'package:isar/isar.dart';
import '../../database/models/customer.dart';

class CustomerRepository {
  Isar get _isar => Isar.getInstance()!;

  Future<void> saveCustomer(Customer customer) async {
    await _isar.writeTxn(() async {
      await _isar.customers.put(customer);
    });
  }

  Future<List<Customer>> getAllCustomers() async {
    return await _isar.customers.where().findAll();
  }

  Future<void> deleteCustomer(int id) async {
    await _isar.writeTxn(() async {
      await _isar.customers.delete(id);
    });
  }
}
