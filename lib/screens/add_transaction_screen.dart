import 'package:flutter/material.dart';
import '../models/farmer.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  // ✅ تم الإصلاح: استخدام super.key الحديث
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final DBHelper dbHelper = DBHelper();
  final TextEditingController farmerController = TextEditingController();
  final TextEditingController itemController = TextEditingController();

  final TextEditingController rusController = TextEditingController();
  final TextEditingController naqfaController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  TransactionType type = TransactionType.receive;

  // دالة الحفظ المحسنة والآمنة
  Future<void> _saveTransaction() async {
    final name = farmerController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("أدخل اسم المزارع")));
      return;
    }

    // إظهار مؤشر تحميل بسيط لمنع الضغط المتكرر
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. الحصول على المزارع
      final Farmer matchedFarmer = await dbHelper.getOrCreateFarmer(name);

      double s = double.tryParse(priceController.text) ?? 0;
      double r = double.tryParse(rusController.text) ?? 0;
      double n = double.tryParse(naqfaController.text) ?? 0;

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        farmerId: matchedFarmer.id,
        type: type,
        itemType: itemController.text.trim().isEmpty
            ? "بضاعة"
            : itemController.text.trim(),
        price: s * 1000,
        rus: r,
        naqfa: n,
        date: DateTime.now(),
      );

      // 2. الانتظار الحقيقي للحفظ في Hive
      await dbHelper.addTransaction(transaction);

      // ✅ تم الإصلاح: فحص متقدم لحماية الـ BuildContext بعد عمليات الـ await
      if (!mounted) return;

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم حفظ العملية بنجاح")));

      // 3. العودة مع إرسال 'true' للشاشة السابقة لتخبرنا بضرورة التحديث
      Navigator.pop(context, true);
    } catch (e) {
      // ✅ تم الإصلاح: حماية السياق في حالة حدوث خطأ ودخول بلوك الـ catch
      if (!mounted) return;
      Navigator.pop(context); // إغلاق التحميل في حال الخطأ
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ في الحفظ: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة عملية جديدة"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: farmerController,
                  decoration: const InputDecoration(
                    labelText: "اسم المزارع (ا، عبدالعزيز)",
                    prefixIcon: Icon(Icons.person),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // اختيار النوع بشكل أوضح
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.receive,
                  label: Text("استلام بضاعة"),
                  icon: Icon(Icons.download),
                ),
                ButtonSegment(
                  value: TransactionType.pay,
                  label: Text("دفع (واصل)"),
                  icon: Icon(Icons.upload),
                ),
              ],
              selected: {type},
              onSelectionChanged: (Set<TransactionType> newSelection) {
                setState(() {
                  type = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 20),

            if (type == TransactionType.receive) ...[
              _buildInputCard(
                rusController,
                "كمية الروس",
                Icons.shopping_basket,
              ),
              _buildInputCard(
                naqfaController,
                "كمية النقفه",
                Icons.inventory_2,
              ),
              _buildInputCard(
                priceController,
                "السعر (مثلاً: 20 لـ 20000)",
                Icons.attach_money,
              ),
            ] else ...[
              _buildInputCard(
                priceController,
                "المبلغ الواصل (بالآلاف)",
                Icons.money_off,
              ),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "حفظ في الدفتر",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}
