import 'package:moor/moor.dart';
part 'moor_database.g.dart';

class Orders extends Table {
  TextColumn get price => text()();
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productName => text()();
}

@UseMoor(tables: [Orders])
class AppDatabase {}
