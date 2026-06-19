import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart'; // تأكد من إضافة هذا الاستيراد
import '../models/farmer.dart';
import '../models/transaction.dart';
import '../models/document.dart';
import 'package:flutter/foundation.dart';

class HiveService {
  static late Box<Farmer> farmers;
  static late Box<Transaction> transactions;
  static late Box<Document> documents;

  static Future<void> init() async {
    try {
      // فتح الصناديق وانتظارها بالترتيب
      farmers = await Hive.openBox<Farmer>('farmers');
      transactions = await Hive.openBox<Transaction>('transactions');
      documents = await Hive.openBox<Document>('documents');

      // تم تعديل هذا السطر لطباعة رسالة نجاح بدلاً من الخطأ
      debugPrint("Hive boxes initialized successfully!");
    } catch (e) {
      // في حال وجود ملفات تالفة في ذاكرة الهاتف تمنع الفتح
      debugPrint("Error loading data: $e");

      // محاولة أخيرة: إذا فشل الفتح، قد يكون بسبب تعارض البيانات القديمة
      // يمكن تفعيل السطر التالي فقط إذا استمرت المشكلة لمسح الذاكرة التالفة:
      // await Hive.deleteBoxFromDisk('farmers');
    }
  }
}
