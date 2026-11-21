import 'package:postgres/postgres.dart';

Future<List<Map<String, Object?>>> query(
  Session db,
  String sql, [
  Map<String, Object?> parameters = const {},
]) async {
  final rows = await db.execute(Sql.named(sql), parameters: parameters);
  return rows.map((row) => row.toColumnMap()).toList();
}
