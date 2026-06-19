import 'package:flutter/material.dart';
import '../models/farmer.dart';

class FarmerCard extends StatelessWidget {
  final Farmer farmer;
  final VoidCallback onTap;

  const FarmerCard({super.key, required this.farmer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(farmer.name[0])),
        title: Text(
          farmer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("عدد العمليات: ${farmer.transactionIds.length}"),
        onTap: onTap,
      ),
    );
  }
}
