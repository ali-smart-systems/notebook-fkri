import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 3) // تأكد أن typeId لا يتصادم مع غيره
enum TransactionType {
  @HiveField(0)
  receive, // استلام بضاعة
  @HiveField(1)
  pay, // دفع (واصل)
}

@HiveType(typeId: 2)
class Transaction {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String farmerId;
  @HiveField(2)
  TransactionType type; // تأكد أنها TransactionType وليس String
  @HiveField(3)
  String itemType;
  @HiveField(4)
  double price;
  @HiveField(5)
  double rus;
  @HiveField(6)
  double naqfa;
  @HiveField(7)
  final DateTime date;

  Transaction({
    required this.id,
    required this.farmerId,
    required this.type,
    this.itemType = "",
    required this.price,
    this.rus = 0,
    this.naqfa = 0,
    required this.date,
  });
}
