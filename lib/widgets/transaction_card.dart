import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // تحديد النص حسب نوع العملية
    final typeText = transaction.type == TransactionType.pay ? "دفع" : "استلام";
    final typeColor = transaction.type == TransactionType.pay
        ? Colors.red
        : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor,
          child: Text(
            typeText[0], // أول حرف من الكلمة (د أو س)
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          "$typeText - ${transaction.itemType}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "روس: ${transaction.rus} | نقفة: ${transaction.naqfa} | السعر: ${transaction.price} ريال",
        ),

        trailing: Text(
          "${transaction.date.day}/${transaction.date.month}/${transaction.date.year}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
