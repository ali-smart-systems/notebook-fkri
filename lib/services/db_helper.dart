import '../models/farmer.dart';
import '../models/transaction.dart';
import 'hive_service.dart';

class DBHelper {
  // 🛡️ دالة التوحيد المطورة: تدمج (ة) و (ه) و (أإآ) و (ا) والمسافات
  String _normalizeArabic(String text) {
    if (text.isEmpty) return text;

    // 1. حذف المسافات الزائدة في البداية والنهاية
    String result = text.trim();

    // 2. تطبيق قاعدتك: تحويل كل أشكال الألف إلى (ا)
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');

    // 3. قاعدة الدمج الكبرى: تحويل كل (ة) إلى (ه) في أي مكان بالكلمة لضمان دمج "اسامة" و "اسامه"
    result = result.replaceAll(RegExp(r'ة'), 'ه');

    // 4. قاعدة المسافات: تحويل أي مسافات متعددة لمسافة واحدة فقط
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // 5. توحيد الأسماء المركبة (عبد العزيز -> عبدالعزيز)
    result = result.replaceAll(RegExp(r'عبد\s+'), 'عبد');

    return result;
  }

  // 🟢 جلب كل المزارعين
  List<Farmer> getAllFarmers() {
    return HiveService.farmers.values.toList();
  }

  // 🟢 جلب مزارع أو إنشاؤه (تم تعديل منطق البحث ليكون أكثر دقة)
  Future<Farmer> getOrCreateFarmer(String name) async {
    final normalizedInputName = _normalizeArabic(name);
    try {
      // البحث عن مزارع يطابق اسمه الاسم الموحد بعد معالجتهما معاً
      return HiveService.farmers.values.firstWhere(
        (f) => _normalizeArabic(f.name) == normalizedInputName,
      );
    } catch (e) {
      // إذا لم يوجد، ننشئ مزارعاً جديداً بالاسم الموحد
      final newFarmer = Farmer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: normalizedInputName,
        phone: null,
        transactionIds: [],
      );
      await HiveService.farmers.put(newFarmer.id, newFarmer);
      return newFarmer;
    }
  }

  // 📝 ميزة مستعادة: تعديل اسم المزارع
  Future<void> updateFarmerName(String farmerId, String newName) async {
    final farmer = HiveService.farmers.get(farmerId);
    if (farmer != null) {
      farmer.name = _normalizeArabic(newName);
      await HiveService.farmers.put(farmerId, farmer);
    }
  }

  // ❌ ميزة مستعادة: حذف مزارع نهائياً مع كافة معاملاته
  Future<void> deleteFarmer(String farmerId) async {
    final farmer = HiveService.farmers.get(farmerId);
    if (farmer != null) {
      for (var id in List.from(farmer.transactionIds)) {
        await HiveService.transactions.delete(id);
      }
      await HiveService.farmers.delete(farmerId);
    }
  }

  // 🟢 إضافة معاملة (مع الضرب في 1000 المعتاد)
  Future<void> addTransaction(Transaction transaction) async {
    transaction.itemType = _normalizeArabic(transaction.itemType);
    await HiveService.transactions.put(transaction.id, transaction);

    final farmer = HiveService.farmers.get(transaction.farmerId);
    if (farmer != null) {
      List<String> updatedIds = List.from(farmer.transactionIds);
      if (!updatedIds.contains(transaction.id)) {
        updatedIds.add(transaction.id);
        farmer.transactionIds = updatedIds;
        await HiveService.farmers.put(farmer.id, farmer);
      }
    }
  }

  // 📝 تعديل معاملة (لا تحذف لتعمل شاشة التفاصيل)
  Future<void> updateTransaction(Transaction transaction) async {
    transaction.itemType = _normalizeArabic(transaction.itemType);
    await HiveService.transactions.put(transaction.id, transaction);
  }

  // ❌ حذف معاملة (لا تحذف لتعمل شاشة التفاصيل)
  Future<void> deleteTransaction(Transaction transaction) async {
    await HiveService.transactions.delete(transaction.id);
    final farmer = HiveService.farmers.get(transaction.farmerId);
    if (farmer != null) {
      List<String> updatedIds = List.from(farmer.transactionIds);
      updatedIds.remove(transaction.id);
      farmer.transactionIds = updatedIds;
      await HiveService.farmers.put(farmer.id, farmer);
    }
  }

  // 📊 حسابات المزارع (لا تحذف لتعمل شاشة التفاصيل)
  double getFarmerTotalPayments(Farmer farmer) {
    return farmer.transactionIds
        .map((id) => HiveService.transactions.get(id))
        .whereType<Transaction>()
        .where((t) => t.type == TransactionType.pay)
        .fold(0.0, (sum, t) => sum + t.price);
  }

  double getFarmerTotalReceives(Farmer farmer) {
    return farmer.transactionIds
        .map((id) => HiveService.transactions.get(id))
        .whereType<Transaction>()
        .where((t) => t.type == TransactionType.receive)
        .fold(0.0, (sum, t) => sum + t.price);
  }

  double getFarmerBalance(Farmer farmer) {
    return getFarmerTotalReceives(farmer) - getFarmerTotalPayments(farmer);
  }

  // 📊 الميزة الجديدة: حساب إجمالي الروس والنقفة ليوم محدد
  Map<String, double> getDailyTotals(DateTime date) {
    double totalRus = 0;
    double totalNaqfa = 0;

    final dailyTx = HiveService.transactions.values.where((t) {
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    });

    for (var t in dailyTx) {
      // تم تنظيف الـ ?? 0 لعدم الحاجة لها برمجياً هنا
      totalRus += t.rus;
      totalNaqfa += t.naqfa;
    }
    return {'rus': totalRus, 'naqfa': totalNaqfa};
  }
}
