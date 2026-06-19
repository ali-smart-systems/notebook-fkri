import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/db_helper.dart';
import '../models/transaction.dart';

class LensHandler {
  final DBHelper dbHelper = DBHelper();

  // 🛡️ الحارس الأمين: دالة التوحيد الملتزمة بقاعدة الألف (ا)
  String _normalizeArabic(String text) {
    if (text.isEmpty) {
      return text;
    }
    String result = text.trim();
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا'); // التزام تام بقاعدتك
    result = result.replaceAll(RegExp(r'ة\b'), 'ه');
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    result = result.replaceAll(RegExp(r'عبد\s+'), 'عبد');
    return result;
  }

  // 1️⃣ المهمة الأولى: مشاركة الصورة فقط (لتجنب تعليق جيميناي)
  // 1️⃣ المهمة الأولى: مشاركة الصورة فقط (لتجنب تعليق جيميناي)
  Future<void> shareImageOnly(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    try {
      // تم التعديل هنا واستخدام image.path بدلاً من imagePath
      await SharePlus.instance.share(ShareParams(files: [XFile(image.path)]));
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      _showError(context, "فشلت عملية المشاركة: $e");
    }
  }

  // 2️⃣ المهمة الثانية: نسخ "الأمر الدائم" لذاكرة جيميناي
  Future<void> copyMemoryPrompt(BuildContext context) async {
    const String memoryPrompt = """
احفظ هذه التعليمات في ذاكرتك الدائمة لاستخدامها مع كل الصور التي سأرسلها لك لاحقاً:
1. استخرج البيانات من الصورة داخل صندوق كود (Code Block) فقط.
2. الترتيب: (الاسم) ثم (الروس) ثم (النقفة) then (السعر) ثم (الواصل).
3. ضع الرقم (0) مكان أي خانة فارغة لضمان وجود 4 أرقام لكل اسم.
4. لا تكتب أي نصوص إضافية، فقط صندوق الكود.
هل استوعبت هذه القواعد؟ طبقها من الآن فصاعداً.
    """;

    await Clipboard.setData(const ClipboardData(text: memoryPrompt));
    if (!context.mounted) {
      return;
    }
    _showSuccess(
      context,
      "تم نسخ أمر الذاكرة! الصقه في جيميناي لمرة واحدة ليحفظه.",
    );
  }

  // --- دوال المعالجة والحفظ المحمية بالكامل ---

  void _showReviewDialog(BuildContext context, String initialText) {
    final controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("مراجعة البيانات المستخرجة"),
        content: TextField(controller: controller, maxLines: 6),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              await processSmartLines(controller.text);
              if (!context.mounted) {
                return;
              }
              Navigator.pop(context);
              _showSuccess(context, "تم الحفظ والدمج بنجاح ✅");
            },
            child: const Text("تأكيد الحفظ"),
          ),
        ],
      ),
    );
  }

  Future<void> processClipboardText(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    if (!context.mounted) {
      return;
    }

    if (data == null || data.text == null || data.text!.trim().isEmpty) {
      _showError(context, "الحافظة فارغة!");
      return;
    }
    String rawText = data.text!.replaceAll(
      RegExp(r'[\u00A0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000]'),
      ' ',
    );
    if (!RegExp(r'\d').hasMatch(rawText) ||
        !RegExp(r'[a-zA-Zأ-ي]').hasMatch(rawText)) {
      _showError(context, "النص غير صالح!");
      return;
    }
    _showReviewDialog(context, rawText);
  }

  Future<void> processSmartLines(String fullText) async {
    String cleanText = normalizeNumbers(fullText);
    List<String> lines = cleanText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    for (String line in lines) {
      List<String> words = line
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      String currentName = "";
      List<double> values = [];
      int j = 0;

      while (j < words.length) {
        // تم إضافة الأقواس المجعدة هنا لحل تنبيه التنسيق الصارم (السطر 76)
        if (RegExp(r'\d').hasMatch(words[j]) || words[j] == '-') {
          break;
        }
        currentName = currentName.isEmpty
            ? words[j]
            : "$currentName ${words[j]}";
        j++;
      }

      while (j < words.length) {
        if (words[j] == '-') {
          values.add(0.0);
        } else {
          final val = double.tryParse(
            words[j].replaceAll(RegExp(r'[^\d.]'), ''),
          );
          if (val != null) {
            values.add(val);
          }
        }
        j++;
      }

      if (currentName.isNotEmpty && values.isNotEmpty) {
        currentName = _normalizeArabic(currentName);
        final farmer = await dbHelper.getOrCreateFarmer(currentName);

        double r = values.isNotEmpty ? values[0] : 0;
        double n = values.length > 1 ? values[1] : 0;
        double s = values.length > 2 ? values[2] : 0;
        double w = values.length > 3 ? values[3] : 0;

        if (r > 0 || n > 0 || (s > 0 && w == 0)) {
          await dbHelper.addTransaction(
            Transaction(
              id: "${DateTime.now().microsecondsSinceEpoch}_${farmer.id.hashCode}_b",
              farmerId: farmer.id,
              type: TransactionType.receive,
              itemType: "بضاعة",
              price: s * 1000,
              rus: r,
              naqfa: n,
              date: DateTime.now(),
            ),
          );
        }

        if (w > 0) {
          await dbHelper.addTransaction(
            Transaction(
              id: "${DateTime.now().microsecondsSinceEpoch}_${farmer.id.hashCode}_p",
              farmerId: farmer.id,
              type: TransactionType.pay,
              itemType: "نقد",
              price: w * 1000,
              rus: 0,
              naqfa: 0,
              date: DateTime.now(),
            ),
          );
        }
      }
    }
  }

  String normalizeNumbers(String input) {
    const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      input = input.replaceAll(ar[i], i.toString());
    }
    return input;
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccess(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }
}
