import 'package:hive/hive.dart';

part 'document.g.dart';

@HiveType(typeId: 3)
class Document {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String farmerId;

  @HiveField(2)
  final String transactionId;

  @HiveField(3)
  final String? filePath; // سمحنا أن يكون null

  @HiveField(4)
  final DateTime date;

  Document({
    required this.id,
    required this.farmerId,
    required this.transactionId,
    this.filePath, // ممكن يكون null
    required this.date,
  });
}
