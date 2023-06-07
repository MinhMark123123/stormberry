import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;

import 'elements/join_table_element.dart';
import 'elements/table_element.dart';
import 'utils.dart';

final schemaResource = Resource<SchemaState>(() => SchemaState());

class SchemaState {
  final Map<AssetId, AssetState> _assets = {};
  bool _didFinalize = false;

  Map<Element, TableElement> get tables =>
      _assets.values.map((a) => a.tables).fold({}, (a, b) => a..addAll(b));

  Map<String, JoinTableElement> get joinTables =>
      _assets.values.map((a) => a.joinTables).fold({}, (a, b) => a..addAll(b));

  bool hasAsset(AssetId assetId) {
    return _assets.containsKey(assetId);
  }

  AssetState createForAsset(AssetId assetId) {
    assert(!_didFinalize, 'Schema was already finalized.');
    var asset = AssetState(p.basename(assetId.path), assetId.path);
    return _assets[assetId] = asset;
  }

  AssetState? getForAsset(AssetId assetId) {
    final path = _assets[assetId]?.filePath;
    if (path == assetId.path) {
      action(_assets[assetId]?.tables);
    }
    return _assets[assetId];
  }

  void action(Map<Element, TableElement>? tables) {
    if (tables == null) return;
    for (var element in tables.values) {
      element.prepareColumns();
    }
    for (var element in tables.values) {
      element.sortColumns();
    }
    for (var element in tables.values) {
      element.analyzeViews();
    }
  }
/*
  void finalize() {
    tables.forEach((key, value) {
      print("table name: ${value.tableName}");
    });

    if (!_didFinalize) {
      for (var element in tables.values) {
        print("---------> do finazlize ${element.tableName}");
        element.prepareColumns();
      }
      for (var element in tables.values) {
        element.sortColumns();
      }
      for (var element in tables.values) {
        element.analyzeViews();
      }
      _didFinalize = true;
    }
  }*/
}

class AssetState {
  final String filename;
  final String filePath;

  Map<Element, TableElement> tables = {};
  Map<String, JoinTableElement> joinTables = {};

  AssetState(this.filename, this.filePath);
}

class BuilderState {
  GlobalOptions options;
  SchemaState schema;
  AssetState asset;

  BuilderState(this.options, this.schema, this.asset);
}
