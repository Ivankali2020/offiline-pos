import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/payment.dart';
import 'package:abpos/models/payment_account.dart';

class PaymentRepository {
  Future<List<Payment>> findPayments() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query(
      'payments',
      orderBy: 'is_published DESC, name ASC',
    );
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<PaymentAccount>> findAccounts() async {
    final db = await DBProvider.instance.database;
    final maps = await db.rawQuery('''
      SELECT
        pa.*,
        p.name AS payment_name
      FROM payment_accounts pa
      INNER JOIN payments p ON p.id = pa.payment_id
      ORDER BY p.name ASC, pa.name ASC
      ''');
    return maps.map((map) => PaymentAccount.fromMap(map)).toList();
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await DBProvider.instance.database;
    return db.insert('payments', payment.toMap());
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await DBProvider.instance.database;
    return db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  Future<void> deletePayment(int id) async {
    final db = await DBProvider.instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'payment_accounts',
        where: 'payment_id = ?',
        whereArgs: [id],
      );
      await txn.delete('payments', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> insertAccount(PaymentAccount account) async {
    final db = await DBProvider.instance.database;
    return db.insert('payment_accounts', account.toMap());
  }

  Future<int> updateAccount(PaymentAccount account) async {
    final db = await DBProvider.instance.database;
    return db.update(
      'payment_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await DBProvider.instance.database;
    return db.delete('payment_accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> ensureDefaultPaymentSelection({
    required int? preferredId,
    required int? fallbackId,
  }) async {
    final db = await DBProvider.instance.database;
    final updates = <String, Object?>{
      'default_payment_id': preferredId ?? fallbackId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await db.update('settings', updates, where: 'id = ?', whereArgs: [1]);
  }
}
