import 'package:isar/isar.dart';
import '../../database/models/history.dart';

class HistoryRepository {
  Isar get _isar => Isar.getInstance()!;

  Future<void> saveHistory(History history) async {
    await _isar.writeTxn(() async {
      await _isar.historys.put(history);
    });
  }

  Future<List<History>> getAllHistory() async {
    return await _isar.historys.where().sortByTimestampDesc().findAll();
  }
}
