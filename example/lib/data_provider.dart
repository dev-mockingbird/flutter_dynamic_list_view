// Copyright (c) 2023 Yang,Zhong
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT

import 'package:flutter_dynamic_list_view/data_provider.dart';

class ExampleItem extends Item {
  final String _id;

  ExampleItem({required String id}) : _id = id;

  @override
  String get id {
    return _id;
  }
}

class ExampleData extends ListData {
  @override
  int get maintainSize {
    return 20;
  }
}

class ExampleDataProvider extends DataProvider {
  static const int total = 1000;
  static const int _pageSize = 100;
  Item current = ExampleItem(id: "${total ~/ 2}");
  @override
  Future<Data> fetch() async {
    Data data = await fetchPrevious(current);
    data.insert((await fetchNext(current)).all(), CrudHint.tail);
    return data;
  }

  Future<Data> fetchLatest() async {
    return _fetch(total - pageSize);
  }

  @override
  Future<Data> fetchNext(Item lastItem) async {
    print(lastItem.id);
    return _fetch(int.parse(lastItem.id));
  }

  Future<Data> fetchOldest() async {
    return _fetch(0);
  }

  @override
  Future<Data> fetchPrevious(Item firstItem) {
    return _fetch(int.parse(firstItem.id) - pageSize);
  }

  Future<Data> _fetch(int start) async {
    await Future.delayed(const Duration(seconds: 1));
    Data data = ExampleData();
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
