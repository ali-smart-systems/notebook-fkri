import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  // استبدل السطر القديم بهذا السطر الحديث:
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String language = "ar"; // افتراضي عربي

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الإعدادات")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🌙 تغيير الثيم
            SwitchListTile(
              title: const Text("الوضع الداكن"),
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                // هنا ممكن تضيف منطق لتغيير الثيم في التطبيق كله
              },
            ),

            const SizedBox(height: 20),

            // 🌐 تغيير اللغة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("اللغة"),
                DropdownButton<String>(
                  value: language,
                  items: const [
                    DropdownMenuItem(value: "ar", child: Text("العربية")),
                    DropdownMenuItem(value: "en", child: Text("English")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      language = value!;
                    });
                    // هنا ممكن تضيف منطق لتغيير اللغة في التطبيق كله
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ℹ️ معلومات عن التطبيق
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("عن التطبيق"),
              subtitle: const Text(
                "دفتر التاجر الذكي - لإدارة المزارعين والمعاملات",
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "دفتر التاجر الذكي",
                  applicationVersion: "1.0.0",
                  applicationLegalese: "© 2026",
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
