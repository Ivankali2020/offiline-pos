import 'package:abpos/data/repositories/payment_repository.dart';
import 'package:abpos/models/payment.dart';
import 'package:abpos/models/payment_account.dart';
import 'package:get/get.dart';

class PaymentController extends GetxController {
  final PaymentRepository _repository = PaymentRepository();

  final RxList<Payment> payments = <Payment>[].obs;
  final RxList<PaymentAccount> accounts = <PaymentAccount>[].obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    final loadedPayments = await _repository.findPayments();
    final loadedAccounts = await _repository.findAccounts();
    payments.assignAll(loadedPayments);
    accounts.assignAll(loadedAccounts);
  }

  List<Payment> get filteredPayments {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return payments;
    return payments.where((payment) {
      final note = payment.note?.toLowerCase() ?? '';
      final relatedAccounts = accountsForPayment(
        payment.id,
      ).map((account) => '${account.name} ${account.number}'.toLowerCase());
      return payment.name.toLowerCase().contains(query) ||
          note.contains(query) ||
          relatedAccounts.any((entry) => entry.contains(query));
    }).toList();
  }

  List<Payment> get publishedPayments =>
      payments.where((payment) => payment.isPublished).toList();

  List<PaymentAccount> accountsForPayment(int? paymentId) {
    if (paymentId == null) return const [];
    return accounts
        .where((account) => account.paymentId == paymentId)
        .toList(growable: false);
  }

  Future<void> addPayment(Payment payment) async {
    await _repository.insertPayment(payment);
    await loadData();
  }

  Future<void> updatePayment(Payment payment) async {
    await _repository.updatePayment(payment);
    await loadData();
  }

  Future<void> deletePayment(int id) async {
    await _repository.deletePayment(id);
    await loadData();
  }

  Future<void> addAccount(PaymentAccount account) async {
    await _repository.insertAccount(account);
    await loadData();
  }

  Future<void> updateAccount(PaymentAccount account) async {
    await _repository.updateAccount(account);
    await loadData();
  }

  Future<void> deleteAccount(int id) async {
    await _repository.deleteAccount(id);
    await loadData();
  }
}
