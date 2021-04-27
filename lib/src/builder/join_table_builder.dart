import '../utils.dart';
import 'case_style.dart';
import 'database_builder.dart';
import 'table_builder.dart';

class JoinTableBuilder {
  late TableBuilder first, second;
  BuilderState state;

  JoinTableBuilder(TableBuilder first, TableBuilder second, this.state) {
    var sorted = [first, second]
      ..sort((a, b) => a.tableName.compareTo(b.tableName));
    this.first = sorted.first;
    this.second = sorted.last;
  }

  String? _tableName;
  String get tableName => _tableName ??= toCaseStyle(
      '${first.tableName}-${second.tableName}', state.options.tableCaseStyle);

  String generateSchema() {
    var args = <String>[];

    args.add("'$tableName'");

    var cols = [first, second].map((t) {
      var columnName = t.getForeignKeyName();
      return "'$columnName': ColumnSchema('$columnName', type: '${t.primaryKeyColumn!.sqlType}')";
    });
    args.add("columns: {\n${cols.join(',\n').indent()},\n}");

    var cons = [];

    var compositeKey =
        [first, second].map((t) => t.getForeignKeyName()).join('", "');
    cons.add("PrimaryKeyConstraint(null, '$compositeKey')");

    for (var t in [first, second]) {
      var columnName = t.getForeignKeyName();
      var tableName = t.tableName;
      var keyName = t.primaryKeyColumn!.columnName;

      cons.add(
          "ForeignKeyConstraint(null, '$columnName', '$tableName', '$keyName', ForeignKeyAction.Cascade, ForeignKeyAction.Cascade)");
    }

    for (var t in [first, second]) {
      var isNotUnique = t.columns.any((c) => c.joinBuilder == this && c.isList);
      if (!isNotUnique) {
        cons.add("UniqueConstraint(null, '${t.getForeignKeyName()}')");
      }
    }

    args.add("constraints: [\n${cons.join(',\n').indent()},\n]");

    return "'$tableName': TableSchema(\n${args.join(',\n').indent()},\n),\n";
  }
}
