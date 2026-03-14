import '../models/bank.dart';

abstract class BankRepository {
  Future<List<Bank>> getAll();
}
