import 'package:hive/hive.dart';

part 'farmer.g.dart';

@HiveType(typeId: 0)
class Farmer {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  List<String> transactionIds;

  Farmer({
    required this.id,
    required this.name,
    this.phone,
    List<String>? transactionIds,
  }) : transactionIds = transactionIds ?? [];
}
