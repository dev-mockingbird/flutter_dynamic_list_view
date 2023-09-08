// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_dynamic_list_view/data_provider.dart';

class ExampleItem extends Item {
  final String _id;

  ExampleItem({required String id}) : _id = id;

  @override
  String get id {
    return _id;
  }
}

class ExampleData extends ListData<ExampleItem> {}

class ExampleDataProvider extends DataProvider<ExampleItem> {
  static const int total = 1000;
  static const int _pageSize = 100;
  Item current = ExampleItem(id: "${total ~/ 2}");
  @override
  Future<ExampleData> fetch() async {
    ExampleData data = await fetchPrevious(current);
    data.insert((await fetchNext(current)).all(), CrudHint.tail);
    return data;
  }

  Future<ExampleData> fetchLatest() async {
    return _fetch(total - pageSize);
  }

  @override
  bool hasMoreNext(ExampleItem lastQueriedItem) {
    return int.parse(lastQueriedItem.id) < 999;
  }

  @override
  bool hasMorePrevious(ExampleItem lastQueriedItem) {
    if (kDebugMode) {
      print("hasMorePrevious: lastQueriedItem: ${lastQueriedItem.id}");
    }
    return int.parse(lastQueriedItem.id) > 0;
  }

  @override
  Future<ExampleData> fetchNext(Item lastItem) async {
    return _fetch(int.parse(lastItem.id));
  }

  Future<Data> fetchOldest() async {
    return _fetch(0);
  }

  @override
  Future<ExampleData> fetchPrevious(Item firstItem) {
    return _fetch(int.parse(firstItem.id) - pageSize);
  }

  Future<ExampleData> _fetch(int start) async {
    await Future.delayed(const Duration(seconds: 1));
    ExampleData data = ExampleData();
    List<ExampleItem> items = [];
    int end = start + pageSize;
    if (end > total) {
      end = total;
    }
    if (start < 0) {
      start = 0;
    }
    for (var i = start; i < end; i++) {
      items.add(ExampleItem(id: "$i"));
    }
    data.insert(items, CrudHint.tail);
    return data;
  }

  @override
  int get pageSize => _pageSize;
}
