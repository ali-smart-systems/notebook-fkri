import 'package:flutter/material.dart';
import '../models/farmer.dart';
import '../models/transaction.dart';
import '../services/hive_service.dart';
import '../services/db_helper.dart';

class FarmerDetail extends StatefulWidget {
  final Farmer farmer;

  // ✅ تم الإصلاح: استخدام super.key الحديث بدلاً من التنسيق القديم
  const FarmerDetail({super.key, required this.farmer});

  @override
  State<FarmerDetail> createState() => _FarmerDetailState();
}

class _FarmerDetailState extends State<FarmerDetail> {
  final dbHelper = DBHelper();

  @override
  Widget build(BuildContext context) {
    // جلب المعاملات الخاصة بهذا المزارع
    final transactions = widget.farmer.transactionIds
        .map((id) => HiveService.transactions.get(id))
        .whereType<Transaction>()
        .toList();

    // فرز من الأحدث إلى الأقدم
    transactions.sort((a, b) => b.date.compareTo(a.date));

    final totalPayments = dbHelper.getFarmerTotalPayments(widget.farmer);
    final totalReceives = dbHelper.getFarmerTotalReceives(widget.farmer);
    final balance = dbHelper.getFarmerBalance(widget.farmer);
    final balanceColor = balance >= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل ${widget.farmer.name}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 📊 ملخص الحساب العلوي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  "إجمالي الواصل",
                  totalPayments.toStringAsFixed(0),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  "إجمالي البضاعة",
                  totalReceives.toStringAsFixed(0),
                  Colors.orange,
                ),
                _buildSummaryItem(
                  "الرصيد",
                  balance.toStringAsFixed(0),
                  balanceColor,
                ),
              ],
            ),
          ),

          // 📝 جدول البيانات الموحد (سطر واحد لكل عملية)
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text("لا توجد معاملات مسجلة لهذا المزارع"),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        // ✅ تم الإصلاح: استبدال MaterialStateProperty بـ WidgetStateProperty الحديثة
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[200],
                        ),
                        columnSpacing: 20,
                        columns: const [
                          DataColumn(label: Text('الاسم')),
                          DataColumn(label: Text('روس')),
                          DataColumn(label: Text('نقفه')),
                          DataColumn(label: Text('سعر')),
                          DataColumn(label: Text('واصل')),
                          DataColumn(label: Text('التاريخ')),
                          DataColumn(label: Text('إجراءات')),
                        ],
                        rows: transactions.map((t) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(widget.farmer.name),
                              ), // الاسم الموحد
                              // عرض الروس من الحقل المخصص
                              DataCell(
                                Center(
                                  child: Text(
                                    t.rus > 0 ? t.rus.toStringAsFixed(0) : "-",
                                  ),
                                ),
                              ),

                              // عرض النقفه من الحقل المخصص (في نفس السطر)
                              DataCell(
                                Center(
                                  child: Text(
                                    t.naqfa > 0
                                        ? t.naqfa.toStringAsFixed(0)
                                        : "-",
                                  ),
                                ),
                              ),

                              // السعر (يظهر فقط في عمليات الاستلام)
                              // ✅ تم الإصلاح: إزالة مقارنة النص الخاطئة t.type == "receive" والإبقاء على الـ Enum فقط لحل خطأ حساب السعر
                              DataCell(
                                Text(
                                  t.type == TransactionType.receive
                                      ? t.price.toStringAsFixed(0)
                                      : "-",
                                ),
                              ),

                              // واصل (يظهر فقط في عمليات الدفع)
                              // ✅ تم الإصلاح: إزالة مقارنة النص الخاطئة t.type == "pay" والإبقاء على الـ Enum فقط لحل خطأ حساب الواصل
                              DataCell(
                                Text(
                                  t.type == TransactionType.pay
                                      ? t.price.toStringAsFixed(0)
                                      : "-",
                                ),
                              ),

                              DataCell(Text("${t.date.day}/${t.date.month}")),

                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _showEditTransactionDialog(t),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      onPressed: () async {
                                        await dbHelper.deleteTransaction(t);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _showEditTransactionDialog(Transaction t) async {
    final priceController = TextEditingController(text: t.price.toString());
    final rusController = TextEditingController(text: t.rus.toString());
    final naqfaController = TextEditingController(text: t.naqfa.toString());

    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تعديل المعاملة"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: rusController,
              decoration: const InputDecoration(labelText: "كمية الروس"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: naqfaController,
              decoration: const InputDecoration(labelText: "كمية النقفه"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: "السعر أو الواصل الكلي",
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حفظ"),
          ),
        ],
      ),
    );

    if (isConfirmed == true) {
      setState(() {
        t.price = double.tryParse(priceController.text) ?? t.price;
        t.rus = double.tryParse(rusController.text) ?? t.rus;
        t.naqfa = double.tryParse(naqfaController.text) ?? t.naqfa;
      });
      await dbHelper.updateTransaction(t);
    }
  }
}
