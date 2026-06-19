import 'package:flutter/material.dart';
import '../services/db_helper.dart';
import '../models/farmer.dart';
import '../models/transaction.dart';
import 'farmer_detail.dart';
import 'add_transaction_screen.dart';
import '../widgets/main_drawer.dart';
import '../services/lens_handler.dart';

class HomeScreen extends StatefulWidget {
  // ✅ تم الإصلاح: استخدام super.key الحديث بدلاً من الشكل القديم
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBHelper dbHelper = DBHelper();
  final LensHandler lensHandler = LensHandler();

  List<Farmer> allFarmers = [];
  List<Farmer> filteredFarmers = [];
  TextEditingController inputController = TextEditingController();

  DateTime selectedSummaryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    final list = dbHelper.getAllFarmers();
    list.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) {
      setState(() {
        allFarmers = list;
        filteredFarmers = list;
      });
    }
  }

  String _normalize(String text) {
    if (text.isEmpty) return text;
    String result = text.trim();
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا'); // الالتزام بقاعدة (ا)
    result = result.replaceAll(RegExp(r'ة'), 'ه');
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    result = result.replaceAll(RegExp(r'عبد\s+'), 'عبد');
    return result.toLowerCase();
  }

  void _runFilter(String enteredKeyword) {
    String searchKey = _normalize(enteredKeyword);
    setState(() {
      filteredFarmers = allFarmers.where((f) {
        return _normalize(f.name).contains(searchKey);
      }).toList();
    });
  }

  Future<void> _processInput(String input) async {
    if (input.trim().isEmpty) return;
    try {
      final numberMatches = RegExp(r'\d+').allMatches(input).toList();
      final List<double> numbers = numberMatches
          .map((m) => double.tryParse(m.group(0)!) ?? 0.0)
          .toList();

      String rawName = "";
      if (numberMatches.isNotEmpty) {
        rawName = input.substring(0, numberMatches.first.start).trim();
      } else {
        rawName = input.trim();
      }

      if (rawName.isEmpty) return;
      final Farmer matchedFarmer = await dbHelper.getOrCreateFarmer(rawName);

      if (numbers.length >= 4) {
        double rus = numbers[0];
        double naqfa = numbers[1];
        double price = numbers[2];
        double wasel = numbers[3];

        await dbHelper.addTransaction(
          Transaction(
            id: "${DateTime.now().millisecondsSinceEpoch}_b",
            farmerId: matchedFarmer.id,
            type: TransactionType.receive,
            itemType: "بضاعه",
            price: price * 1000,
            rus: rus,
            naqfa: naqfa,
            date: DateTime.now(),
          ),
        );

        if (wasel > 0) {
          await dbHelper.addTransaction(
            Transaction(
              id: "${DateTime.now().millisecondsSinceEpoch}_p",
              farmerId: matchedFarmer.id,
              type: TransactionType.pay,
              itemType: "نقد",
              price: wasel * 1000,
              rus: 0,
              naqfa: 0,
              date: DateTime.now(),
            ),
          );
        }
      } else if (numbers.length == 3) {
        await dbHelper.addTransaction(
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            farmerId: matchedFarmer.id,
            type: TransactionType.receive,
            itemType: "بضاعه",
            price: numbers[2] * 1000,
            rus: numbers[0],
            naqfa: numbers[1],
            date: DateTime.now(),
          ),
        );
      } else if (numbers.length == 2) {
        await dbHelper.addTransaction(
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            farmerId: matchedFarmer.id,
            type: TransactionType.receive,
            itemType: "بضاعه",
            price: numbers[1] * 1000,
            rus: numbers[0],
            naqfa: 0,
            date: DateTime.now(),
          ),
        );
      } else if (numbers.length == 1) {
        bool isPay =
            input.contains("واصل") ||
            input.contains("دفع") ||
            input.contains("-");
        await dbHelper.addTransaction(
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            farmerId: matchedFarmer.id,
            type: isPay ? TransactionType.pay : TransactionType.receive,
            itemType: isPay ? "نقد" : "بضاعة",
            price: numbers[0] * 1000,
            rus: 0,
            naqfa: 0,
            date: DateTime.now(),
          ),
        );
      }

      inputController.clear();
      await _loadFarmers();

      // ✅ تم الإصلاح: حماية الـ BuildContext بعد الـ await
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم الحفظ بنجاح ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // ✅ تم الإصلاح: حماية الـ BuildContext داخل الـ catch
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  void _showDailySummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final totals = dbHelper.getDailyTotals(selectedSummaryDate);
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ملخص الروس والنقفة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedSummaryDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now(),
                          );
                          // ✅ تم الإصلاح: إضافة الأقواس المتعرجة للهيكل الشرطي
                          if (picked != null) {
                            setModalState(() => selectedSummaryDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  Text(
                    "التاريخ: ${selectedSummaryDate.year}-${selectedSummaryDate.month}-${selectedSummaryDate.day}",
                  ),
                  const Divider(height: 30),
                  _buildSummaryRow(
                    "إجمالي الروس",
                    totals['rus']!,
                    Colors.green,
                  ),
                  const SizedBox(height: 15),
                  _buildSummaryRow(
                    "إجمالي النقفة",
                    totals['naqfa']!,
                    Colors.blue,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // ✅ تم الإصلاح: استخدام withValues بدلاً من الدالة القديمة المستبعدة مع فلاتر الحديث
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showFarmerOptions(Farmer farmer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.orange),
            title: const Text("تعديل الاسم"),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(farmer);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("حذف المزارع"),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(farmer);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(Farmer farmer) {
    TextEditingController renameController = TextEditingController(
      text: farmer.name,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تعديل الاسم"),
        content: TextField(controller: renameController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbHelper.updateFarmerName(farmer.id, renameController.text);
              // ✅ تم التحديث: فحص الـ mounted الخاص بالـ BuildContext الحالي للحوار
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadFarmers();
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Farmer farmer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: Text(
          "هل أنت متأكد من حذف ${farmer.name}؟ سيتم حذف جميع معاملاته أيضاً!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              await dbHelper.deleteFarmer(farmer.id);
              // ✅ تم التحديث: فحص الـ mounted الخاص بالـ BuildContext هنا أيضاً
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadFarmers();
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("دفتر التاجر الذكي"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showDailySummary,
            tooltip: "ملخص اليوم",
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: inputController,
              decoration: InputDecoration(
                labelText: "ابحث أو أضف سرياً...",
                hintText: "الاسم روس نقفه سعر واصل",
                prefixIcon: const Icon(Icons.person_search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () => _processInput(inputController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _runFilter,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFarmers,
              child: filteredFarmers.isEmpty
                  ? const Center(child: Text("لا توجد سجلات"))
                  : ListView.builder(
                      itemCount: filteredFarmers.length,
                      itemBuilder: (context, index) {
                        final farmer = filteredFarmers[index];
                        final balance = dbHelper.getFarmerBalance(farmer);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueGrey[800],
                              child: Text(
                                farmer.name.isNotEmpty ? farmer.name[0] : "?",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              farmer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "الرصيد: ${balance.toStringAsFixed(0)} ريال",
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FarmerDetail(farmer: farmer),
                              ),
                            ).then((_) => _loadFarmers()),
                            onLongPress: () => _showFarmerOptions(farmer),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 🧠 زر نسخ أمر الذاكرة
          FloatingActionButton(
            heroTag: "mem_btn",
            backgroundColor: Colors.orange[800],
            mini: true,
            tooltip: "نسخ تعليمات الذاكرة",
            onPressed: () => lensHandler.copyMemoryPrompt(context),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
            ), // ✅ تم الإصلاح: الـ child في نهاية الخصائص
          ),
          const SizedBox(height: 10),
          // 📸 زر الكاميرا
          FloatingActionButton(
            heroTag: "camera_btn",
            backgroundColor: Colors.purple[800],
            mini: true,
            tooltip: "تصوير ومشاركة الصورة فقط",
            onPressed: () async {
              await lensHandler.shareImageOnly(context);
              _loadFarmers();
            },
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
            ), // ✅ تم الإصلاح: الـ child في النهاية
          ),
          const SizedBox(height: 10),
          // 📋 زر اللصق من الحافظة
          FloatingActionButton(
            heroTag: "p_btn",
            backgroundColor: Colors.blue[800],
            mini: true,
            tooltip: "لصق من الحافظة",
            onPressed: () async {
              await lensHandler.processClipboardText(context);
              _loadFarmers();
            },
            child: const Icon(
              Icons.paste,
              color: Colors.white,
            ), // ✅ تم الإصلاح: الـ child في النهاية
          ),
          const SizedBox(height: 10),
          // ➕ زر إضافة معاملة يدوية
          FloatingActionButton(
            heroTag: "a_btn",
            backgroundColor: Colors.green[700],
            tooltip: "إضافة مزارع/معاملة",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            ).then((_) => _loadFarmers()),
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ), // ✅ تم الإصلاح: الـ child في النهاية
          ),
        ],
      ),
    );
  }
}
