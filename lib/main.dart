import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/farmer.dart';
import 'models/transaction.dart';
import 'models/document.dart';
import 'services/hive_service.dart';
import 'screens/home_screen.dart';

void main() async {
  // 1. التأكد من تهيئة الروابط قبل أي عمليات أخرى
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. تهيئة Hive
    await Hive.initFlutter();

    // 3. تسجيل المحولات بطريقة آمنة تمنع خطأ "TypeAdapter already registered"
    _registerAdapterSafely<Farmer>(1, FarmerAdapter());
    _registerAdapterSafely<Transaction>(2, TransactionAdapter());

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionTypeAdapter());
    }

    _registerAdapterSafely<Document>(4, DocumentAdapter());

    // 4. فتح الصناديق وانتظار اكتمالها
    await HiveService.init();

    debugPrint("تم تشغيل قاعدة البيانات بنجاح ✅");
  } catch (e) {
    debugPrint("حدث خطأ أثناء التهيئة: $e");
  }

  // 5. تشغيل التطبيق
  runApp(const MyApp());
}

// دالة مساعدة لتسجيل المحولات بدون كراش
void _registerAdapterSafely<T>(int id, TypeAdapter<T> adapter) {
  try {
    if (!Hive.isAdapterRegistered(id)) {
      Hive.registerAdapter(adapter);
    }
  } catch (e) {
    debugPrint("المحول رقم $id مسجل بالفعل مسبقاً");
  }
}

class MyApp extends StatelessWidget {
  // ✅ تم إصلاح التنبيه هنا باستخدام super.key الحديث والمختصر
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر التاجر الذكي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}
